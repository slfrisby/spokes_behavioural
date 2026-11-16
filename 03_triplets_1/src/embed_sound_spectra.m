% Take .wav files and computes a representation of the spectrogram, then
% compute an RSM and an embedding from these.

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/03_triplets_1/';
addpath([root, '/src/']);
addpath(['/group/mlr-lab/Saskia/spokes_behavioural/dependencies/WISC_MVPA/src/']);

% get cell array of all audio files
tmp = dir([root, '/src/audio/']);
tmp = struct2cell(tmp(~[tmp.isdir]));
audioFiles = tmp(1,:)';

% initialise outputs 
spectra = struct();
features = [];

% compute and store spectra
for a = 1:length(audioFiles)
    
    % load data
    [data, samplingRate] = audioread([root, '/src/audio/', audioFiles{a}]);

    % truncate data to all be the same length ("flute" is very slightly
    % longer than the others)
    data = data(1:192000,1);

    % store filename
    spectra(a).name = erase(audioFiles{a},'.wav');
    % compute and store modulation spectrum
    spectra(a).modulationSpectrum = compute_modulation_spectra(data, samplingRate);

    % flatten matrix to make a single vector for each concept. This
    % flattens columnwise (entries 1 to n in the vector come from
    % the first column, entries n + 1 to 2n come from the second column, etc.)
    features(a,:) = reshape(spectra(a).modulationSpectrum, 1, []);

end

% the resulting matrix is massive. Conduct an SVD (a "full" SVD, without 
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

% save outputs
writematrix(U, [root,'/work/sound_model_features.txt'])





