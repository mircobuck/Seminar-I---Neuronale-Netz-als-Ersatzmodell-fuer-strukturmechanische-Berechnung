function r=registry()
%REGISTRY Inventory; unsupported modal outputs are explicit.
ids=["Scalar_GPR","POD_GP","POD_RBF","POD_MLP","Beam_theory", ...
    "Beam_plus_GPR","POD_Galerkin","DeepONet","Frequency_GPR"];
outputs=["static scalars","static field","static field","static field", ...
    "static scalar","static scalar","static field","static field","modal frequencies"];
for i=1:numel(ids)
    r(i)=struct('id',ids(i),'outputs',outputs(i),'modalShapes',false, ...
        'status',"existing: adapter pending",'fit',[],'predict',[]); %#ok<AGROW>
    modelID=ids(i);
    r(i).predict=@(artifact,X,services) femstudy.models.predictLegacy(modelID,artifact,X,services);
end
r(end).status="implemented: integration pending";
r(end).fit=@femstudy.models.fitFrequency;
r(end).predict=@(artifact,X,services) femstudy.models.predictFrequency(artifact,X);
r(end+1)=struct('id',"Beam_Field_POD_GPR",'outputs',"static field", ...
    'modalShapes',false,'status',"implemented: validation pending", ...
    'fit',@femstudy.models.fitBeamField, ...
    'predict',@(artifact,X,services) femstudy.models.predictBeamField(artifact,X));
end
