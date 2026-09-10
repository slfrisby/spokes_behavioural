% Take .wav files and computes a representation of the spectrogram. 

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/03_triplets_1/';
addpath([root, '/src/']);

% get cell array of all audio files
tmp = dir([root, '/src/audio/']);
tmp = struct2cell(tmp(~[tmp.isdir]));
audioFiles = tmp(1,:)';

% initialise output 
spectra = struct();

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





