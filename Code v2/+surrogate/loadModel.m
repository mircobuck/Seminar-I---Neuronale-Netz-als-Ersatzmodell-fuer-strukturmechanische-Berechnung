function model = loadModel(filePath)
%loadModel Load a saved model artifact.
loaded=load(filePath,'model');
model=loaded.model;
end
