function generate_dataset(c)
assert(exist('femodel','file')~=0,'PDE Toolbox required; MATLAB R2024a+.');
T=readtable(c.design,TextType="string");
assert(height(T)==sum(c.counts));
X=T{:,c.names};
assert(all(X>=c.lower & X<=c.upper,'all'));
assert(size(unique(X,'rows'),1)==height(T),'Duplicate physical cases.');
manifest=fullfile(c.out,'manifest.mat');
physics=struct('schema',c.schema,'gridSize',c.gridSize, ...
    'meshDivisor',c.meshDivisor,'order',c.geometricOrder, ...
    'saveRawMesh',c.saveRawMesh,'maxDeflectionRatio',c.maxDeflectionRatio);
if isfile(manifest)
    old=load(manifest);
    assert(isequaln(old.T,T) && isequaln(old.physics,physics), ...
        'Configuration changed. Use a NEW run folder; do not mix data.');
else
    save(manifest,'T','physics');
end
caseDir=fullfile(c.out,'cases'); if ~isfolder(caseDir), mkdir(caseDir); end
for i=1:height(T)
    file=fullfile(caseDir,sprintf('case_%04d.mat',T.id(i)));
    if isfile(file)
        a=load(file,'out'); assert(isequal(a.out.x,X(i,:)));
        fprintf('Reuse %d/%d\n',i,height(T)); continue;
    end
    fprintf('FEM %d/%d (%s)\n',i,height(T),T.split(i));
    out=solve_case(X(i,:),c); %#ok<NASGU>
    tmp = string(file) + ".tmp.mat";
    save(tmp,'out','-v7.3'); movefile(tmp,file);
end
% Separate files: training code never loads test.mat.
for label=["train","val","test"]
    ids=find(T.split==label); Xpart=X(ids,:);
    S=[]; Y=[]; seconds=zeros(numel(ids),1); nodes=seconds;
    for j=1:numel(ids)
        a=load(fullfile(caseDir,sprintf('case_%04d.mat',T.id(ids(j)))));
        if j==1
            S=zeros(numel(a.out.S),numel(ids));
            Y=zeros(numel(ids),numel(a.out.Y));
            xi=a.out.xi; w=a.out.w;
        end
        S(:,j)=a.out.S; Y(j,:)=a.out.Y;
        seconds(j)=a.out.seconds; nodes(j)=a.out.nNodes;
    end
    D=struct('X',Xpart,'S',S,'Y',Y,'xi',xi,'w',w, ...
        'id',T.id(ids),'seconds',seconds,'nodes',nodes, ...
        'physics',physics,'label',label);
    save(fullfile(c.out,label+'.mat'),'D','-v7.3');
end
fprintf('Data ready in %s\n',c.out);
end
