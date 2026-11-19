function erzeuge_praesentationsdaten(modus)
%ERZEUGE_PRAESENTATIONSDATEN Daten fuer die Vortragsdiagramme erzeugen.
%   Trainiert ein direktes MLP und ein POD-MLP auf den vorhandenen modalen
%   FEM-Daten (6 Eigenfrequenzen), vergleicht sie mit FEM und Euler-Bernoulli
%   und exportiert CSV-Dateien nach ../daten. Zusaetzlich wird je ein
%   statisches MLP/POD-MLP mit den Gewinnerkonfigurationen der statischen
%   Studie fuer ein anschauliches Beispiel trainiert.
%
%   Architektur und Training folgen den Konventionen aus Code v2
%   (tanh-Schichten, lineare Ausgabe, Adam, trainnet, 200 Epochen, Batch 32,
%   Normierung nur mit Trainingsstatistik). Die modalen Modelle sind eine
%   Ergaenzung fuer den Vortrag, keine versiegelte Studie.
%
%   Aufruf (MATLAB, Ordner Praesentation/skripte):
%       erzeuge_praesentationsdaten              % alles (~15 min)
%       erzeuge_praesentationsdaten("verlust")   % nur Verlustkurven
%       erzeuge_praesentationsdaten("statisch")  % nur statisches Beispiel
%
%   Hinweis: Die POD-Hilfen aus Code v2 benoetigen Java (SHA-256). Damit das
%   Skript auch ohne Java laeuft, sind MLP/POD-MLP hier mit derselben
%   Mathematik (gewichtete POD, weighted_field_mse) lokal nachgebildet.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
code = fullfile(root, 'Code v2');
out  = fullfile(fileparts(here), 'daten');
if ~exist(out, 'dir'), mkdir(out); end
addpath(code); setupProject;

%% ---------------------------------------------------------------- Modal
tr = load(fullfile(code,'data_generation','data','modal','train.mat')).D;
te = load(fullfile(code,'data_generation','data','modal','test.mat')).D;
Xtr = double(tr.X); Ftr = double(tr.frequencyHz);
Xte = double(te.X); Fte = double(te.frequencyHz);
fprintf('Modal: %d Training, %d Test\n', size(Xtr,1), size(Xte,1));

if nargin < 1, modus = "alles"; end
modus = string(modus);
cfgMlp = struct('hiddenWidth',128,'hiddenLayers',3,'learningRate',1e-3);
% Rang 5: kleinster Rang mit Projektionsfehler < 0,1 % (siehe Spektrum);
% die sechs Frequenzen sind wegen Modenkreuzungen kaum komprimierbar.
cfgPod = struct('hiddenWidth',80,'hiddenLayers',3,'learningRate',1e-3,'rank',5);

if modus ~= "alles"
    if modus == "verlust"   % nur Verlustverlaeufe (Seed 42) neu exportieren
        [~,histM] = fitDirect(Xtr,Ftr,cfgMlp,42); [~,histP] = fitPodMlp(Xtr,Ftr,cfgPod,42);
        writetable(histM, fullfile(out,'modal_loss_mlp.csv'));
        writetable(histP, fullfile(out,'modal_loss_podmlp.csv'));
    elseif modus == "statisch"
        statischerTeil(code,out);
    end
    disp('Fertig.'); return
end

% --- POD-Spektrum der Trainingsfrequenzen
mu = mean(Ftr,1); [~,S,V] = svd(Ftr-mu,'econ'); s = diag(S);
energy = cumsum(s.^2)/sum(s.^2);
T = table((1:numel(s))',s,energy,'VariableNames',{'rank','singularValue','cumEnergy'});
proj = zeros(numel(s),1);
for r = 1:numel(s)
    Fp = mu + (Fte-mu)*V(:,1:r)*V(:,1:r)';
    proj(r) = mean(abs(Fp-Fte)./Fte,'all');
end
T.testProjectionError = proj;
writetable(T, fullfile(out,'modal_pod_spektrum.csv'));
writematrix([(1:6)' V], fullfile(out,'modal_pod_basis.csv'));
disp(T)

% --- Hauptmodelle N=384, drei Initialisierungen
seeds = [42 43 44];
Pm = zeros([size(Fte) numel(seeds)]); Pp = Pm; tim = zeros(numel(seeds),4);
for k = 1:numel(seeds)
    [mm,histM,tfM] = fitDirect(Xtr,Ftr,cfgMlp,seeds(k));
    [mp,histP,tfP] = fitPodMlp(Xtr,Ftr,cfgPod,seeds(k));
    Pm(:,:,k) = predDirect(mm,Xte); Pp(:,:,k) = predPod(mp,Xte);
    tim(k,:) = [tfM tfP timePred(@()predDirect(mm,Xte(1,:))) timePred(@()predPod(mp,Xte(1,:)))];
    if k == 1
        writetable(histM, fullfile(out,'modal_loss_mlp.csv'));
        writetable(histP, fullfile(out,'modal_loss_podmlp.csv'));
    end
end
writetable(array2table([seeds' tim],'VariableNames', ...
    {'seed','fitMlp_s','fitPodMlp_s','predMlpSingle_s','predPodMlpSingle_s'}), ...
    fullfile(out,'modal_zeiten.csv'));
writetable(table(mean(te.seconds),median(te.seconds),'VariableNames', ...
    {'femMean_s','femMedian_s'}), fullfile(out,'modal_fem_zeit.csv'));

% --- Analytische Euler-Bernoulli-Frequenzen (6 niedrigste aus y- und z-Biegung)
[Fan, famLabel] = eulerBernoulli(Xte);

% --- Export Testvorhersagen (lang: Fall x Mode)
rows = {};
for i = 1:size(Xte,1)
    for j = 1:6
        rows(end+1,:) = {te.id(i), j, Fte(i,j), Fan(i,j), famLabel(i,j), ...
            mean(Pm(i,j,:)), mean(Pp(i,j,:)), Pm(i,j,1), Pp(i,j,1)}; %#ok<AGROW>
    end
end
P = cell2table(rows,'VariableNames',{'id','mode','fem','analytic','analyticFamily', ...
    'mlpMean','podMlpMean','mlpSeed42','podMlpSeed42'});
writetable(P, fullfile(out,'modal_test_vorhersagen.csv'));
writetable(array2table([te.id Xte],'VariableNames',{'id','L','b','h','E','nu','rho'}), ...
    fullfile(out,'modal_test_parameter.csv'));

% --- POD-Rangstudie (Seed 42..44)
rr = [];
for r = 1:6
    c = cfgPod; c.rank = r; e = zeros(numel(seeds),1);
    for k = 1:numel(seeds)
        m = fitPodMlp(Xtr,Ftr,c,seeds(k));
        e(k) = mean(abs(predPod(m,Xte)-Fte)./Fte,'all');
    end
    rr(end+1,:) = [r mean(e) min(e) max(e) proj(r)]; %#ok<AGROW>
end
writetable(array2table(rr,'VariableNames',{'rank','meanErr','minErr','maxErr','projErr'}), ...
    fullfile(out,'modal_rangstudie.csv'));

% --- Lernkurve
Ns = [24 48 96 192 384]; lc = [];
for N = Ns
    for rep = 1:3
        rng(20261111+rep,'twister'); idx = randperm(size(Xtr,1),N);
        if N == size(Xtr,1), idx = 1:N; seed = seeds(rep); else, seed = 42; end
        mm = fitDirect(Xtr(idx,:),Ftr(idx,:),cfgMlp,seed);
        mp = fitPodMlp(Xtr(idx,:),Ftr(idx,:),cfgPod,seed);
        em = abs(predDirect(mm,Xte)-Fte)./Fte; ep = abs(predPod(mp,Xte)-Fte)./Fte;
        lc(end+1,:) = [N rep mean(em,'all') prctile(em(:),95) mean(ep,'all') prctile(ep(:),95)]; %#ok<AGROW>
        fprintf('N=%d rep=%d  MLP %.3f %%  POD-MLP %.3f %%\n',N,rep,100*lc(end,3),100*lc(end,5));
    end
end
writetable(array2table(lc,'VariableNames',{'N','rep','mlpMean','mlpP95','podMean','podP95'}), ...
    fullfile(out,'modal_lernkurve.csv'));

%% ------------------------------------------------- Eigenformen (FEM)
res = fullfile(code,'studies','fem_reference_validation_v1','results');
for cid = [910037 910159 910349]
    R = load(fullfile(res,sprintf('modal_case_%d_mesh_06_attempt_001.mat',cid))).record;
    q = R.result;
    % Spalten: x y z, dann je Mode [ux uy uz]
    writematrix([q.queryCoordinates' reshape(q.queryModes,525,[])], ...
        fullfile(out,sprintf('eigenformen_%d.csv',cid)));
    writetable(table((1:numel(q.frequencyHz))',q.frequencyHz,'VariableNames',{'mode','fHz'}), ...
        fullfile(out,sprintf('eigenfrequenzen_%d.csv',cid)));
    writematrix(R.parameters, fullfile(out,sprintf('parameter_%d.csv',cid)));
end
copyfile(fullfile(res,'modal_analytical_mode_matches.csv'), fullfile(out,'modal_mac_zuordnung.csv'));

statischerTeil(code,out);
disp('Fertig.');
end

%% ================================================================ Helfer
function statischerTeil(code,out)
% Gewinnerkonfigurationen der statischen Studie, N = 768, Seed 42.
tr = load(fullfile(code,'data_generation','data','static','train.mat')).D;
te = load(fullfile(code,'data_generation','data','static','test.mat')).D;
w = double(te.w(:)); X = double(tr.X); Y = double(tr.S)';   % N x 1575
Xt = double(te.X); Yt = double(te.S);                       % 1575 x Nt
cm = struct('hiddenWidth',128,'hiddenLayers',3,'learningRate',1e-3);
cp = struct('hiddenWidth',80,'hiddenLayers',3,'learningRate',1e-3,'rank',2);
% --- direktes MLP mit weighted_field_mse (wie fitNeural)
rng(42,'twister');
m.xm = mean(X,1); m.xs = std(X,0,1); m.ym = mean(Y,1);
sc = sqrt(mean((Y-m.ym).^2.*w','all')); m.ys = sc./sqrt(w');
m.net = trainMlp((X-m.xm)./m.xs,(Y-m.ym)./m.ys,cm);
YM = (double(minibatchpredict(m.net,(Xt-m.xm)./m.xs,ExecutionEnvironment="cpu")).*m.ys+m.ym)';
% --- POD-MLP mit gewichteter POD (wie fitPod / pod_mlp.fit)
rng(42,'twister');
mu = mean(Y,1)'; Cc = Y'-mu; [U,~,~] = svd(sqrt(w).*Cc,'econ');
Phi = U(:,1:cp.rank)./sqrt(w);
A = (Phi'*(w.*Cc))';                                 % Koeffizienten N x r
p.xm = mean(X,1); p.xs = std(X,0,1); p.am = mean(A,1);
p.as = sqrt(mean((A-p.am).^2,'all'));
p.net = trainMlp((X-p.xm)./p.xs,(A-p.am)./p.as,cp);
Ah = double(minibatchpredict(p.net,(Xt-p.xm)./p.xs,ExecutionEnvironment="cpu")).*p.as+p.am;
YP = mu + Phi*Ah';
relErr = @(B) sqrt(sum(w.*(B-Yt).^2,1))./sqrt(sum(w.*Yt.^2,1));
eM = relErr(YM)'; eP = relErr(YP)';
writetable(table(te.id,eM,eP,'VariableNames',{'id','mlp','podMlp'}), ...
    fullfile(out,'statisch_testfehler.csv'));
[~,ord] = sort(eP); i = ord(round(numel(ord)/2));   % typischer Fall (Median)
xi = double(te.xi);
writematrix([xi' reshape(Yt(:,i),525,3) reshape(YM(:,i),525,3) reshape(YP(:,i),525,3)], ...
    fullfile(out,'statisch_beispielfeld.csv'));
writematrix([te.id(i) Xt(i,:) eM(i) eP(i)], fullfile(out,'statisch_beispielparameter.csv'));
writematrix([xi' reshape(mu,525,3) reshape(Phi(:,1),525,3) reshape(Phi(:,2),525,3)], ...
    fullfile(out,'statisch_podmoden.csv'));
fprintf('Statisch: MLP %.2f %%, POD-MLP %.2f %% (Mittel, 64 Testfaelle)\n',100*mean(eM),100*mean(eP));
end

function [m,hist,t] = fitDirect(X,F,cfg,seed)
rng(seed,'twister');
m.xm = mean(X,1); m.xs = std(X,0,1);
m.ym = mean(F,1); m.ys = std(F,0,1);
Xn = (X-m.xm)./m.xs; Yn = (F-m.ym)./m.ys;
[m.net,hist,t] = trainMlp(Xn,Yn,cfg);
end
function Y = predDirect(m,X)
Y = double(minibatchpredict(m.net,(X-m.xm)./m.xs,ExecutionEnvironment="cpu")).*m.ys+m.ym;
end

function [m,hist,t] = fitPodMlp(X,F,cfg,seed)
rng(seed,'twister');
m.fm = mean(F,1); [~,~,V] = svd(F-m.fm,'econ'); m.V = V(:,1:cfg.rank);
C = (F-m.fm)*m.V;                                   % POD-Koeffizienten
m.xm = mean(X,1); m.xs = std(X,0,1);
m.cm = mean(C,1); m.cs = sqrt(mean((C-m.cm).^2,'all')); % gemeinsame Skala
[m.net,hist,t] = trainMlp((X-m.xm)./m.xs,(C-m.cm)./m.cs,cfg);
end
function Y = predPod(m,X)
C = double(minibatchpredict(m.net,(X-m.xm)./m.xs,ExecutionEnvironment="cpu")).*m.cs+m.cm;
Y = m.fm + C*m.V';
end

function [net,hist,t] = trainMlp(Xn,Yn,cfg)
layers = featureInputLayer(size(Xn,2),Normalization="none");
for k = 1:cfg.hiddenLayers
    layers = [layers; fullyConnectedLayer(cfg.hiddenWidth); tanhLayer]; %#ok<AGROW>
end
layers = [layers; fullyConnectedLayer(size(Yn,2))];
opts = trainingOptions("adam",MaxEpochs=200,MiniBatchSize=32, ...
    InitialLearnRate=cfg.learningRate,Shuffle="every-epoch", ...
    OutputNetwork="last-iteration",ExecutionEnvironment="cpu",Verbose=false);
tic; [net,info] = trainnet(Xn,Yn,layers,"mse",opts); t = toc;
h = info.TrainingHistory;   % Spaltennamen je nach MATLAB-Version verschieden
keep = varfun(@isnumeric,h,'OutputFormat','uniform');
hist = h(:,keep);
end

function t = timePred(f)
f(); n = 50; tic; for k = 1:n, f(); end; t = toc/n;
end

function [Fs,lab] = eulerBernoulli(X)
% Kragtraeger: f = (lambda^2/(2*pi*L^2))*sqrt(E*I/(rho*A))
lam = [1.875104068711961 4.694091132974175 7.854757438237613];
L=X(:,1); b=X(:,2); h=X(:,3); E=X(:,4); rho=X(:,6); A=b.*h;
Iy = h.*b.^3/12; Iz = b.*h.^3/12;   % Biegung in y bzw. z
fy = (lam.^2./(2*pi*L.^2)).*sqrt(E.*Iy./(rho.*A));
fz = (lam.^2./(2*pi*L.^2)).*sqrt(E.*Iz./(rho.*A));
all = [fy fz]; names = ["y1" "y2" "y3" "z1" "z2" "z3"];
[Fs,ix] = sort(all,2); lab = names(ix);
end
