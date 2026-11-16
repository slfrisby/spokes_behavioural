% Take visual model features extracted with extract_visual_model_activations.py, then
% compute an RSM and an embedding from these.

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/03_triplets_1/';
addpath([root, '/src/']);
addpath(['/group/mlr-lab/Saskia/spokes_behavioural/dependencies/WISC_MVPA/src/']);

% load features from model
features = load([root,'/work/vision_model_features/features.txt']);

% Conduct an SVD (a "full" SVD, without 
% specifying the number of components, explains 100% of the variance. 

% mean-centre the features first
m = mean(features, 1);
features = features - m;

% then do the SVD. "econ" excludes zeros and makes the computation far
% faster while preserving all the necessary information. 
[C, z, ~] = svd(features, "econ");
z = diag(z);

% rescale, just as we do for usual RSL
U = rescale_embedding(C,z);

% inspect percentage variance explained by each component
varianceExplained = 100 * z.^2 / sum(z.^2);
cumulativeVariance = cumsum(varianceExplained);
plot(cumulativeVariance, 'o-');
xlabel('Component');
ylabel('Cumulative % variance');

writematrix(U,[root,'/work/image_model_features.txt'])
