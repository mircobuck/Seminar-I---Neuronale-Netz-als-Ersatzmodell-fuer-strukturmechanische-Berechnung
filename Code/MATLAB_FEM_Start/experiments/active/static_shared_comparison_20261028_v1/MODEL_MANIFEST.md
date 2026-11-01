# Frozen model manifest

Study: static_shared_comparison_20261028_v1
Git revision: aca50b7d74e9d49b3e19fc074c88b9deb25feba6
Tracked worktree dirty at freeze: true
Config SHA-256: 027651959ed97df5c8c3b17841199da40025dce784a078cf31fd0b9b8f8ca188
Holdout-design SHA-256: 9b90d829615927b6040f8becb928a1e00b0c7440f94fdede0ec6b8f311d0121d
Training IDs: 384 (ranges 1–12, 25–396); validation IDs: 13–18.
No final holdout labels were read or generated before this freeze.

| Model | Seed | Representation / POD rank | Scaling | Architecture / kernel | Selection | Training time (s), provenance |
|---|---:|---|---|---|---|---|
| Beam_theory_field | 0 | full analytical Euler-Bernoulli displacement field / 0 | none; SI parameter inputs and metre-valued outputs | closed-form cantilever beam field | no fitted parameters or validation selection | 0; not applicable; analytical baseline |
| POD_MLP | 42 | weighted POD of full displacement field / 4 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 32; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 185.3474; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| POD_MLP | 43 | weighted POD of full displacement field / 2 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 64; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 252.1411; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| POD_MLP | 44 | weighted POD of full displacement field / 2 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 64; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 379.0768; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| Beam_Residual_MLP | 42 | analytical beam field plus weighted POD residual / 2 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 32; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 159.9668; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| Beam_Residual_MLP | 43 | analytical beam field plus weighted POD residual / 2 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 32; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 252.2416; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| Beam_Residual_MLP | 44 | analytical beam field plus weighted POD residual / 2 | training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor | two fully connected tanh layers, width 64; Adam | minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first | 291.7451; historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured |
| POD_GPR | 42 | weighted POD of full displacement field / 11 | training-only weighted POD; standardized inputs and POD coefficients from training data | independent GPR coefficient regressors; ARD Matérn 5/2 | historical minimum validation field error over the configured POD-rank candidates | 57.5772; historical train_models time; candidate ranks and validation selection; hardware/timing conditions not controlled |
| Beam_Field_POD_GPR | 42 | Euler-Bernoulli field plus weighted POD of residual field / 12 | beam residual, weighted POD mean/basis, input and coefficient scaling use training data only | independent GPR coefficient regressors; ardmatern52 | minimum validation mean relative weighted field L2 over preregistered ranks and kernels | 104.9985; new fitBeamField time in this MATLAB run; includes all preregistered rank/kernel candidates and validation |

## SHA-256 inputs, source files, and model artifacts

| Role | Path | SHA-256 |
|---|---|---|
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\configs\static_shared_comparison_20261028_v1.json` | `027651959ed97df5c8c3b17841199da40025dce784a078cf31fd0b9b8f8ca188` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\prepared.mat` | `f94a969c4f97763f3ac2b2acba4fea998bf19bd46a8f6fbe6d1ef10bac6b6204` |
| sealed-design | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\holdout_design.csv` | `9b90d829615927b6040f8becb928a1e00b0c7440f94fdede0ec6b8f311d0121d` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\training_size_12_24_48_20261023\n384\train.mat` | `0ef09c4360774c9a8192f0c9edb3e7d2ed7eeef62361afec1c9e37b4df2bb182` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\training_size_12_24_48_20261023\n384\val.mat` | `1cbaedf8765ea7ebb0696bcb81f97d42ebdb72975173e085000de44f97916613` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\training_size_12_24_48_20261023\n384\test.mat` | `34303299365a7e304eaec20cee6e827796d531195c78d54fe8f77b24aa3cbe4d` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\training_size_12_24_48_20261023\n384\models.mat` | `e5882e5eba5f3dccaa1a85e311c1c81710efae34addf8b54b8eac72c4771cc77` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed42\pod.mat` | `1493707ee171c01413c9c834df2bb2b21b0346bc276b0fd8de138bedb2c948fb` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed42\residual.mat` | `f2ae0c4169e03c64aa6e90b0c779deee00e64318782bfce73a5c5ce169a816b6` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed43\pod.mat` | `5843bc8daf187c5c853f7137ed061255ba0e264bf304d3050f36aabdc6ebe34a` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed43\residual.mat` | `2a1e05aa12b1cd4b81e549c035730b194a281d85ca880f22c9df88dcdb681f6c` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed44\pod.mat` | `5740bb3165fc9984fa06d0026e8e56888136e3dc940c6e2e0230764e3877933d` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\n384\seed44\residual.mat` | `2005adf32a9a56052612f1d981579288c8914355096c86f77cd1b96b7bfa687a` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_pod_seed42.mat` | `e44b84979045fc13761e37c85283c637c3f8453e035d94bce2183ef713dd02a8` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_residual_seed42.mat` | `b16cdab5fc255f07fdd832068d2e34b0f411d54ded6ca0d160351a008819baa7` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_pod_seed43.mat` | `c4fa0bafd64f2178c340fcd99a9cad65a3865a138493ea63be68f65d66954918` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_residual_seed43.mat` | `71a2c77aa2e8a0148a0d1fca0eaad68e0b70b2cfb3715dc977a0bac8be90e909` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_pod_seed44.mat` | `541d6539126dc849a53717576df3f0b3ecfac5a9a9e61541e4c0bdda723b3656` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\neural_residual_seed44.mat` | `525c51135dcbf0ceb77c364bedea5d4192be9f9a045694c6de2c94d7c42b6c78` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\pod_gpr.mat` | `752838421ad2dd9ff48bbc3617ccef6da27f4809c196805c3ff5c21839ea0697` |
| model | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_shared_comparison_20261028_v1\models\beam_residual_gpr.mat` | `fea74c0ed297a7f81ca77f83918cf266d2d766a613428bd3896657f632e589e3` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+fem\beamField.m` | `116bdb0d53a434f48a2db70d0e65beb02d17f5e177dc35377a788033f493a448` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+models\fitNeural.m` | `581534399675ab41fc370f797bd98c85c6ce351fb4fe977d794a22ce0e18d0a0` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+models\predictNeural.m` | `fa0f6b46d91d78070669d297d6d2a57c2af04efd050dfbdff790700e48c606d6` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+models\fitBeamField.m` | `b719554b36bc67b3b86dd58c411e0f7f7f99e6111a29ed5ecd220c422c2cb59a` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+models\predictBeamField.m` | `36d6132cea6bae21fc420b6e39749f3d8e0bf248204ca3eddb770d79d61a9899` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\+femstudy\+metrics\field.m` | `90eae14ae6f7b1f6f82f5dbb920889e486a8159663292661769a48778baa7e63` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\pod_fit.m` | `13d4313ec1785edf8b1751aaa65e7da6f6163dd84544809b710cdeccb5f1c45c` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\pod_encode.m` | `1bab540d0e182fa50e7be6854228275dee29ef890643778a5eb5c41bbc20d6d2` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\fit_gps.m` | `d95d52ed1a93c300948879b7d147b40b0eed3d4a9b5825d110b1a19d8a6d7dfa` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\predict_reg.m` | `fbd17dc52b6f5e2059ab57d3fe4295d34bfdf2efa656fd73229d6e9b6b8cf337` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\fit_mlp.m` | `f37308aa58f2217bb06433073a3014a8523046ed416bc2b26c848e4a0753fb9a` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\scripts\matlab\run_training_size_study_impl.m` | `d7fb0f92ff04d6586e83a744dc0a1290460504d8f0a23c3cc961ca76f313e211` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\src\train_models.m` | `4443faec8489de9cbc8a46526bfb83feca623c8a9da72e9edd100579978f8249` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\static_confirmation_v1\design.csv` | `6ee8c54f229fd5553acbeae3d5b573f9a94feeedea211ecf6d5e0107e7b4b32a` |
| source | `C:\Users\dietz\Downloads\MATLAB_FEM_Start\github_dd_branch\Code\MATLAB_FEM_Start\experiments\active\neural_comparison_20261027_v1\static_final_design.csv` | `8d1dcf6c82b38189ce94eb01e5b5c1c1597651847ecd99a03f0deb5cd25bed01` |
