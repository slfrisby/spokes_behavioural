% all 60 stimuli used in this triplet judgement task were part of a set of
% stimuli used in a previous naming experiment. We need to report the
% naming accuracies for just those stimuli (not the ones that were
% subsequently excluded). 

% setup (note different root directory to usual)
root = '/group/mlr-lab/Saskia/spokes_behavioural/';
addpath([root, '/02_naming_1/src/']);
addpath([root, '/04_triplets_2/src/']);

% run the naming analysis. There are 81 stimuli used at this stage.
analyse_JATOS_data;

% make a table (featuring the accuracy of just the 24 participants who had
% good performance overall)
accuracy = meanAccuracyGoodParticipants;
namingData = table(stimuli,accuracy);

% get rid of the other variables that are not needed
clearvars -except namingData 
% root has changed - reset it
root = '/group/mlr-lab/Saskia/spokes_behavioural/';

% load the new set of stimuli
stimuli = readcell([root,'/04_triplets_2/src/stimuli.csv']);

% get the naming accuracy for just those
newStimuliIndex = find(ismember(namingData.stimuli,stimuli));
newNamingData = namingData(newStimuliIndex,:);

% write .csv
writetable(newNamingData,[root,'/04_triplets_2/work/naming_data.csv']);


