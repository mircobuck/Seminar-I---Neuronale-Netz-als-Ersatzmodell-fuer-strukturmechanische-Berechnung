classdef staticGprStudyTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addPaths(t)
            folder=fileparts(mfilename('fullpath')); root=fileparts(folder);
            t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'studies','static_gpr_v1')));
        end
    end
    methods (Test)
        function tuningCannotRequestTest(t)
            t.verifyError(@()studyReference(tempname,"tune","interpolation"),'study:TestLabelGate');
        end
        function testRequiresFreezeBeforeFileAccess(t)
            t.verifyError(@()studyReference(tempname,"evaluate","interpolation"),'study:FreezeRequired');
        end
        function freezeDetectsChangedArtifact(t)
            folder=tempname; mkdir(folder); t.addTeardown(@()rmdir(folder,'s'));
            paths=string({fullfile(folder,'source_manifest.csv');fullfile(folder,'candidate_design.mat'); ...
                fullfile(folder,'selections.mat');fullfile(folder,'training.complete'); ...
                fullfile(folder,'references','val','val.mat');fullfile(folder,'references','interpolation','test.mat'); ...
                fullfile(folder,'references','extrapolation','test.mat');fullfile(folder,'runs','fit','model.mat')});
            hashes=strings(size(paths));
            for k=1:numel(paths)
                parent=fileparts(paths(k)); if ~isfolder(parent), mkdir(parent); end
                writelines("original",paths(k)); hashes(k)=string(studyHash(paths(k)));
            end
            T=table(paths,hashes,'VariableNames',{'Path','SHA256'}); file=fullfile(folder,'freeze_manifest.csv');
            writetable(T,file); writelines(string(studyHash(file)),fullfile(folder,'freeze_manifest.sha256'));
            studyCheckFrozen(folder); writelines("modified",paths(3));
            t.verifyError(@()studyCheckFrozen(folder),'study:FreezeChanged');
        end
        function frozenSyntheticPipeline(t)
            folder=tempname; mkdir(folder); t.addTeardown(@()rmdir(folder,'s'));
            testFolder=fileparts(mfilename('fullpath')); root=fileparts(testFolder);
            staticGprStudyTest.makeSyntheticStudy(root,folder);
            studyFreeze(root,fullfile(root,'studies','static_gpr_v1'),folder);
            unlisted=fullfile(folder,'runs','n999_rep1_mlp_seed42'); mkdir(unlisted);
            source=fullfile(folder,'runs','n002_rep1_mlp_seed42');
            copyfile(fullfile(source,'result.mat'),fullfile(unlisted,'result.mat'));
            copyfile(fullfile(source,'model.mat'),fullfile(unlisted,'model.mat'));
            copyfile(fullfile(source,'result.sha256'),fullfile(unlisted,'result.sha256'));
            cfg=struct('reference_floor',0,'prediction_repetitions',2,'training_sizes',2);
            studyEvaluation(root,folder,cfg); studyReport(folder,cfg);
            python=fullfile(getenv('LOCALAPPDATA'),'Programs','Python','Python312','python.exe');
            command=sprintf('"%s" "%s" "%s"',python,fullfile(root,'studies','static_gpr_v1','studyPlots.py'),folder);
            [status,~]=system(command);
            t.verifyEqual(status,0);
            t.verifyFalse(isfolder(fullfile(folder,'evaluation','runs','n999_rep1_mlp_seed42')));
            t.verifyTrue(isfile(fullfile(folder,'plots','interpolation_error_vs_data.png')));
            t.verifyTrue(isfile(fullfile(folder,'pipeline_summary.csv')));
            t.verifyTrue(isfile(fullfile(folder,'case_results.csv')));
            writelines("tamper",fullfile(folder,'training.complete'));
            t.verifyError(@()studyReference(folder,"evaluate","interpolation"),'study:FreezeChanged');
        end
        function fitResumeRejectsChangedConfig(t)
            folder=tempname; mkdir(folder); t.addTeardown(@()rmdir(folder,'s'));
            metadata=struct('startedPosix',posixtime(datetime('now','TimeZone','UTC')), ...
                'budgetSeconds',3600,'pilotSpentSeconds',0); save(fullfile(folder,'environment.mat'),'metadata');
            train=makeContractData("static","train"); val=makeContractData("static","val");
            cfg=struct('seed',42,'datasetId',"synthetic"); dest=fullfile(folder,'fit');
            result=studyFitCheckpoint(dest,"dummy",train,val,cfg);
            t.verifyEqual(result.status,"ok");
            t.verifyEqual(studyFitCheckpoint(dest,"dummy",train,val,cfg).modelHash,result.modelHash);
            changed=cfg; changed.seed=43;
            t.verifyError(@()studyFitCheckpoint(dest,"dummy",train,val,changed),'study:CheckpointChanged');
        end
    end
    methods (Static, Access=private)
        function makeSyntheticStudy(root,folder)
            metadata=struct('startedPosix',posixtime(datetime('now','TimeZone','UTC')), ...
                'budgetSeconds',3600,'pilotSpentSeconds',0); save(fullfile(folder,'environment.mat'),'metadata');
            files=studySources(root,fullfile(root,'studies','static_gpr_v1'));
            writetable(files,fullfile(folder,'source_manifest.csv'));
            dummy=1; save(fullfile(folder,'candidate_design.mat'),'dummy');
            writelines("dummy",fullfile(folder,'candidate_design.csv'));
            writelines(string(studyHash(fullfile(folder,'candidate_design.mat'))),fullfile(folder,'candidate_design.sha256'));
            save(fullfile(folder,'selections.mat'),'dummy'); save(fullfile(folder,'distribution_ids.mat'),'dummy');
            writelines(string(studyHash(fullfile(folder,'selections.mat'))),fullfile(folder,'selections.sha256'));
            writelines("complete",fullfile(folder,'training.complete'));
            writelines(["method,start_utc,elapsed_seconds";"all,2026-01-01T00:00:00Z,1"], ...
                fullfile(folder,'search_sessions.csv'));
            for method=["mlp","rbf","pod_mlp","pod_gpr"]
                target=fullfile(folder,'tuning',method); mkdir(target);
                info=struct('attempted',1,'candidates',1,'spentSeconds',1,'winner',1);
                save(fullfile(target,'search_summary.mat'),'info');
                writelines(["method,start_utc,elapsed_seconds";method+",2026-01-01T00:00:00Z,1"], ...
                    fullfile(target,'search_sessions.csv'));
            end
            staticGprStudyTest.writeReference(folder,"val",2,1001);
            staticGprStudyTest.writeReference(folder,"interpolation",128,2001);
            staticGprStudyTest.writeReference(folder,"extrapolation",128,3001);
            train=makeContractData("static","train");
            val=studyReference(folder,"train","val");
            cfg=struct('seed',42,'datasetId',"synthetic",'hiddenWidth',4, ...
                'hiddenLayers',1,'maxEpochs',1,'miniBatchSize',2);
            result=studyFitCheckpoint(fullfile(folder,'runs','n002_rep1_mlp_seed42'),"mlp",train,val,cfg);
            assert(result.status=="ok",result.message);
        end
        function writeReference(folder,role,n,firstId)
            target=fullfile(folder,'references',role); mkdir(target); c=surrogate.contract("static");
            x=(1:n)'; X=[x x+1 x+2 x+3 x+4 x+5]; ids=(firstId:firstId+n-1)';
            split="test"; if role=="val", split="val"; end
            D=struct('schema',"static-displacement-fields-v1",'modality',"static",'split',split, ...
                'id',ids,'X',X,'S',ones(1575,n),'Y',ones(n,2), ...
                'xi',c.grid,'w',ones(1575,1)/525,'seconds',ones(n,1),'nodes',ones(n,1));
            design=array2table([ids X],'VariableNames',[{'id'},cellstr(c.parameterNames)]);
            design.split=repmat(split,n,1); writetable(design,fullfile(target,'design.csv'));
            filename=fullfile(target,split+'.mat'); save(filename,'D','-v7.3');
            writelines(string(studyHash(filename)),fullfile(target,'data.sha256'));
            status=repmat("ok",n,1); solver_seconds=ones(n,1);
            writetable(table(ids,status,solver_seconds),fullfile(target,'ledger.csv'));
            writelines(["role,start_utc,elapsed_seconds";role+",2026-01-01T00:00:00Z,1"], ...
                fullfile(target,'generation_sessions.csv'));
        end
    end
end
