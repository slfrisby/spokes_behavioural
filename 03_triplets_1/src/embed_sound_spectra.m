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
    % longer than the others
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

% compute RSM by calculating elementwise correlations between the
% modulation spectra (not sure whether this is the best approach, but it
% works for now!).

RSM = zeros(length(audioFiles),length(audioFiles));

for r = 1:length(audioFiles)
    for c = 1:length(audioFiles)
        RSM(r,c) = corr2(spectra(r).modulationSpectrum, spectra(c).modulationSpectrum);
    end
end

% convert RSM to embedding
[C,z] = embed_similarity_matrix(RSM,4);
U = rescale_embedding(C,z);

% save outputs
writematrix(RSM,[root,'/work/sound_model_RSM.txt'])
writematrix(U,[root,'/work/sound_model_embedding.txt'])





