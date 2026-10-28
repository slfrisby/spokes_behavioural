% Take visual model features extracted with extract_visual_model_activations.py, then
% compute an RSM and an embedding from these.

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/03_triplets_1/';
addpath([root, '/src/']);
addpath(['/group/mlr-lab/Saskia/spokes_behavioural/dependencies/WISC_MVPA/src/']);

% load features from model
features = load([root,'/work/vision_model_features/features.txt']);

% calculate RSM

RSM = zeros(size(features,1), size(features,1));

for r = 1:size(features,1)
    for c = 1:size(features,1)
        RSM(r,c) = corr2(features(r,:), features(c,:));
    end
end

% convert RSM to embedding
[C,z] = embed_similarity_matrix(RSM,4);
U = rescale_embedding(C,z);

% save outputs
writematrix(RSM,[root,'/work/image_model_RSM.txt'])
writematrix(U,[root,'/work/image_model_embedding.txt'])
