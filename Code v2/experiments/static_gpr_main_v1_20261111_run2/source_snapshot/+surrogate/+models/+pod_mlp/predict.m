function Y = predict(state,X)
%predict Rekonstruiere statische Verschiebungsfelder in Metern.
%   state stammt aus pod_mlp.fit; X hat die Groesse [nCases x nParameter].
%   Y enthaelt rekonstruierte Felder mit der Groesse [nDof x nCases].
%   Eigene Fehler-IDs: keine; Fehler aus minibatchpredict werden weitergegeben.

% Wende die im Training gespeicherte Eingabenormierung und das Netz an.
normalizedInputs=(double(X)-state.inputMean)./state.inputScale;
normalizedCoefficients=double(minibatchpredict( ...
    state.network,normalizedInputs,ExecutionEnvironment="cpu"));

% Skaliere Koeffizienten zurueck; konstante Koeffizienten bleiben konstant.
coefficients=normalizedCoefficients.*state.coefficientScale+state.coefficientMean;
coefficients(:,state.constantCoefficients)=state.coefficientMean(state.constantCoefficients);

% Projiziere die Koeffizienten zurueck in den Feldraum und addiere den Mittelwert.
Y=state.fieldMean+state.basis*coefficients';
end
