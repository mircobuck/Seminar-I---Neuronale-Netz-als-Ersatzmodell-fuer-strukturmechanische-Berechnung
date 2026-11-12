function Y = predict(state,X)
%predict Return physical fields (1575-by-N) or frequencies (N-by-6).
Y=surrogate.models.shared.predictNeural(state,X);
end
