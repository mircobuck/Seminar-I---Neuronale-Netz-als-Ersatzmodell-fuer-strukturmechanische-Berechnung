classdef deeponetTest < matlab.unittest.TestCase
    properties
        M
        D
    end
    methods (TestClassSetup)
        function loadFixture(test)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'));
            a=load(fullfile(root,'experiments','deeponet_20261023_v1', ...
                'tiny_overfit','model.mat')); test.M=a.model;
            a=load(fullfile(root,'experiments','training_size_12_24_48_20261023', ...
                'n12','train.mat')); test.D=a.D;
        end
    end
    methods (Test)
        function tensorAndComponents(test)
            H=predict_deeponet(test.M,test.D.X(1:2,:),test.D.xi);
            B=stripdims(forward(test.M.branch,dlarray(single( ...
                ((test.D.X(1:2,:)-test.M.meanX)./test.M.stdX)'),'CB')));
            T=stripdims(forward(test.M.trunk, ...
                dlarray(single(2*test.D.xi-1),'CB')));
            p=test.M.options.latent; q=size(test.D.xi,2);
            expected=double(extractdata(T'*B(p+(1:p),:))) .* ...
                test.D.xi(1,:)'*test.M.scaleU;
            test.verifySize(H,[3*q 2]);
            test.verifyEqual(H(q+(1:q),:),expected,AbsTol=1e-10);
        end
        function exactClamp(test)
            H=predict_deeponet(test.M,test.D.X,test.D.xi);
            clamp=repmat(test.D.xi(1,:)'==0,3,1);
            test.verifyEqual(max(abs(H(clamp,:)),[],'all'),0,AbsTol=0);
        end
        function batchEquality(test)
            H=predict_deeponet(test.M,test.D.X(1:2,:),test.D.xi);
            A=predict_deeponet(test.M,test.D.X(1,:),test.D.xi);
            test.verifyLessThan(norm(H(:,1)-A)/max(norm(A),eps),2e-5);
        end
        function queryPermutation(test)
            order=size(test.D.xi,2):-1:1;
            H=predict_deeponet(test.M,test.D.X(1:2,:),test.D.xi);
            P=predict_deeponet(test.M,test.D.X(1:2,:),test.D.xi(:,order));
            q=size(test.D.xi,2);
            test.verifyEqual(P,H([order q+order 2*q+order],:),AbsTol=1e-10);
        end
        function finiteGradients(test)
            Z=((test.D.X(1:2,:)-test.M.meanX)./test.M.stdX)';
            [loss,b,t]=dlfeval(@deeponet_gradients,test.M.branch, ...
                test.M.trunk,Z,test.D.xi,test.M.options.latent, ...
                test.D.S(:,1:2)/test.M.scaleU,test.D.w);
            finite=@(x) all(isfinite(extractdata(x)),'all');
            test.verifyTrue(isfinite(double(extractdata(loss))));
            test.verifyTrue(all(cellfun(finite,b.Value)));
            test.verifyTrue(all(cellfun(finite,t.Value)));
        end
        function tinyOverfit(test)
            H=predict_deeponet(test.M,test.D.X(1:2,:),test.D.xi);
            e=field_error(test.D.S(:,1:2),H,test.D.w);
            test.verifyLessThan(max(e),.03);
        end
        function checkpointRestoration(test)
            root=fileparts(fileparts(mfilename('fullpath')));
            folder=tempname;
            test.assertTrue(startsWith(string(folder),string(tempdir)));
            mkdir(folder);
            test.addTeardown(@() rmdir(folder,'s'));
            copyfile(fullfile(root,'experiments','deeponet_20261023_v1', ...
                'tiny_overfit','checkpoint.mat'),folder);
            tinyData=test.D; tinyData.X=tinyData.X(1:2,:); tinyData.S=tinyData.S(:,1:2);
            tinyData.Y=tinyData.Y(1:2,:); tinyData.id=tinyData.id(1:2);
            model=fit_deeponet(tinyData,tinyData,test.M.options,folder);
            actual=predict_deeponet(model,tinyData.X,tinyData.xi);
            expected=predict_deeponet(test.M,tinyData.X,tinyData.xi);
            test.verifyEqual(actual,expected,AbsTol=0);
        end
    end
end
