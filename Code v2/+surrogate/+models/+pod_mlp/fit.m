function [state,report] = fit(data,config)

%fit Train a weighted POD-MLP on static displacement fields.
% data enthaelt die FEM-Trainingsfelder und die zugehoerigen Eingabeparameter.
% config muss alle POD- und Netzparameter explizit enthalten.

% Diese Implementierung ist nur fuer statische Verschiebungsfelder vorgesehen.
assert(string(data.modality)=="static",'surrogate:pod_mlp:Task', ...
    'POD-MLP supports static displacement fields only.');

% Diese Einstellungen muessen im config-Struct explizit angegeben werden.
% Fehlende Felder werden gemeinsam in einer Fehlermeldung aufgelistet.
required={'rank','hiddenWidth','maxEpochs','miniBatchSize', ...
    'learningRate','hiddenLayers'};
assert(isstruct(config) && isscalar(config), ...
    'surrogate:pod_mlp:Config','config must be a scalar struct.');
missing=required(~isfield(config,required));
assert(isempty(missing),'surrogate:pod_mlp:Config', ...
    'Missing required config fields: %s.',strjoin(missing,', '));

% Parameter, die ganze positive Zahlen sein muessen.
integers={'rank','hiddenWidth','maxEpochs','miniBatchSize','hiddenLayers'};
for k=1:numel(integers)
    value=config.(integers{k});
    % Verhindert z.B. NaN, Vektoren, komplexe Werte, Null und Nachkommastellen.
    assert(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value>=1 && value==fix(value), ...
        'surrogate:pod_mlp:Config','%s must be a positive integer.',integers{k});
end

% Lernrate muss eine einzelne endliche positive Zahl sein.
assert(isnumeric(config.learningRate) && isreal(config.learningRate) && ...
    isscalar(config.learningRate) && isfinite(config.learningRate) && config.learningRate>0, ...
    'surrogate:pod_mlp:Config','learningRate must be positive and finite.');

% POD-Kompression der FEM-Felder:
% Jede Spalte von fields ist ein Trainingsfeld; jede Zeile eine
% Verschiebungskomponente an einem Rasterpunkt. double sorgt fuer numerische
% Berechnungen in doppelter Genauigkeit.
fields=double(data.displacementFields);

% Positive Gewichte legen fest, wie stark die einzelnen Feldkomponenten
% in der gewichteten Fehlernorm beruecksichtigt werden.
weights=double(data.displacementComponentWeights(:));

% Die POD wird auf den um das mittlere Trainingsfeld zentrierten Daten gebildet.
% fieldMean hat eine Komponente pro Zeile von fields.
fieldMean=mean(fields,2);

% Multiplikation mit sqrt(weights) transformiert die gewichtete Feldmetrik
% in die gewoehnliche euklidische Metrik, auf der die SVD arbeitet.
weightedFields=sqrt(weights).*(fields-fieldMean);

% SVD zerlegt die gewichteten, zentrierten Trainingsfelder.
% "econ" berechnet nur die benoetigten duennen Matrizen; U enthaelt die
% raeumlichen Muster, S deren Singulaerwerte. Die rechte Matrix wird hier
% nicht benoetigt.
[U,S,~]=svd(weightedFields,'econ');

% Singulaerwerte beschreiben den Beitrag der POD-Moden; sehr kleine Werte
% unterhalb der Gleitkomma-Aufloesung zaehlen nicht zum numerischen Rang.
singularValues=diag(S);
numericalRank=sum(singularValues>max(size(weightedFields))*eps(max(singularValues)));

% Eine groessere POD-Rangzahl als der numerische Rang waere nicht sinnvoll
% und koennte nicht durch unabhaengige Moden getragen werden.
assert(config.rank<=numericalRank,'surrogate:pod_mlp:Rank', ...
    'Requested POD rank %d exceeds numerical training rank %d.',config.rank,numericalRank);

% Die ersten rank Spalten von U sind die wichtigsten gewichteten Muster.
% Division durch sqrt(weights) bringt sie zurueck in die urspruengliche
% Feldskalierung; basis ist damit in der gewichteten Metrik orthonormal.
basis=U(:,1:config.rank)./sqrt(weights);

% Projektion jedes zentrierten Trainingsfeldes auf die POD-Basis.
% Das Ergebnis hat eine Zeile pro Fall und einen Koeffizienten pro POD-Mode;
% genau diese Koeffizienten sagt anschliessend das neuronale Netz voraus.
coefficients=(basis'*(weights.*(fields-fieldMean)))';

% Normierung fuer das MLP. Alle Mittelwerte und Skalen werden ausschliesslich
% aus den Trainingsdaten berechnet und spaeter im Modell gespeichert, damit
% Vorhersagen mit exakt derselben Transformation arbeiten.
X=double(data.inputParameters);
% Eingaben: sechs Material-, Geometrie- und Lastparameter pro Trainingsfall.
% Mittelwert und Standardabweichung werden spaltenweise bestimmt.
inputMean=mean(X,1);
inputScale=std(X,0,1);

% Falls ein Eingabeparameter in allen Trainingsfaellen konstant ist, wird
% durch 1 statt durch 0 geteilt; seine normierte Spalte bleibt dann null.
inputScale(inputScale==0)=1;

% Auch jeder POD-Koeffizient wird ueber die Trainingsfaelle standardisiert.
coefficientMean=mean(coefficients,1);
coefficientScale=std(coefficients,0,1);

% Konstante POD-Koeffizienten haben Standardabweichung 0. Ihre Skala wird
% fuer die Division auf 1 gesetzt; die Markierung wird fuer predict.m
% gespeichert, damit diese Koeffizienten spaeter konstant bleiben.
constantCoefficients=coefficientScale==0;
coefficientScale(constantCoefficients)=1;

% Standardisierung von Eingaben und Lernzielen: Mittelwert 0 und, sofern
% variabel, Standardabweichung 1. Das verbessert typischerweise das Training.
X=(X-inputMean)./inputScale;
Y=(coefficients-coefficientMean)./coefficientScale;

% Netzaufbau: sechs Eingabewerte ohne zusaetzliche automatische Normierung.
layers=featureInputLayer(size(X,2),Normalization="none");

% Jede versteckte Schicht ist voll verbunden und verwendet tanh.
% Die gleiche Neuronenzahl wird in allen versteckten Schichten verwendet.
for k=1:config.hiddenLayers
    layers=[layers; fullyConnectedLayer(config.hiddenWidth); tanhLayer]; %#ok<AGROW>
end

% Lineare Ausgabeschicht mit einem Ausgang pro behaltenem POD-Koeffizienten.
layers=[layers; fullyConnectedLayer(config.rank)];

% Adam optimiert den mittleren quadratischen Fehler der normierten
% POD-Koeffizienten. Die Daten werden pro Epoche gemischt; nach der letzten
% Epoche wird das Netz dieser letzten Trainingsiteration zurueckgegeben.
% Das Training laeuft auf der CPU und erzeugt keine laufende Textausgabe.
options=trainingOptions("adam",MaxEpochs=config.maxEpochs, ...
    MiniBatchSize=config.miniBatchSize,InitialLearnRate=config.learningRate, ...
    Shuffle="every-epoch",OutputNetwork="last-iteration", ...
    ExecutionEnvironment="cpu",Verbose=false);

% trainnet lernt die Abbildung von normierten Eingabeparametern X auf
% normierte POD-Koeffizienten Y.
net=trainnet(X,Y,layers,"mse",options);

% state enthaelt alles, was predict.m zur spaeteren Vorhersage benoetigt:
% Netz, POD-Basis und Feldmittelwert sowie Eingabe-/Koeffizientennormierung.
state=struct('network',net,'basis',basis,'fieldMean',fieldMean, ...
    'inputMean',inputMean,'inputScale',inputScale, ...
    'coefficientMean',coefficientMean,'coefficientScale',coefficientScale, ...
    'constantCoefficients',constantCoefficients,'settings',config);

% report fasst Trainingsumfang und POD-Informationen zusammen.
% retainedEnergy ist der Anteil der gesamten quadrierten Singulaerwerte,
% der durch die ersten rank Moden repraesentiert wird.
report=struct('method',"pod_mlp",'trainingCount',size(X,1), ...
    'numericalRank',numericalRank,'podRank',config.rank, ...
    'retainedEnergy',sum(singularValues(1:config.rank).^2)/sum(singularValues.^2), ...
    'optimizer',"adam",'settings',config);
end
