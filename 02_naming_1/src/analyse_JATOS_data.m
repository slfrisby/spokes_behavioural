% takes files that have been generated with preprocess_JATOS_data.m AND
% hand-coded for accuracy. Analyses these to enable generation of a new and
% improved stimulus set. 

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/02_naming_1';
addpath([root,'/src']);

% create output directories
if ~exist([root,'/derivatives/'])
    mkdir([root,'/derivatives/'])
end

% find number of participants
tmp = dir([root,'/work/sub-*']);
nParticipants = size(tmp,1);

% initialise separate variables to store responses and feedback.
responses = cell(81,nParticipants);
accuracy = zeros(81,nParticipants);

% for each participant
for p = 1:nParticipants

    % load data
    tmp = readcell(sprintf([root,'/work/sub-%03d/scoring.csv'],p));

    % get the stimulus names
    if p == 1
        stimuli = tmp(:,1);
    end

    % fill in accuracy and response variables
    responses(:,p) = tmp(:,2);
    accuracy(:,p) = cell2mat(tmp(:,3));

end

% Then generate some summaries. 

% find the number of stimuli with over 85% accuracy.
meanAccuracyAll = mean(accuracy,2);
tmp = meanAccuracyAll >= 0.85;
disp([num2str(sum(tmp)),' stimuli were named with over 85% accuracy.'])

% inspect the distributions of accuracies across participants. 
f = figure;
f = histogram(sum(accuracy),-5:10:95);

% 24 participants had an overall accuracy of over 50%. Based on data just
% from these participants, how many sounds are named with >85% accuracy?
tmp = accuracy(:,sum(accuracy) > 50);
meanAccuracyGoodParticipants = mean(tmp,2);
tmp = meanAccuracyGoodParticipants >= 0.85;
disp(['The participants who scored over 50% overall named ', num2str(sum(tmp)),' stimuli with over 85% accuracy.'])

% create sub-lists of stimuli - named accurately enough if all participants
% included, named accurately enough if low-scoring participants excluded, not named
% accurately enough irrespective of inclusion/exclusion criteria
tmp = [mean(accuracy,2),mean(accuracy(:,sum(accuracy) > 50),2)];
stimuliNamedAccuratelyEnough = stimuli(tmp(:,1) >= 0.85);
stimuliToQuery = stimuli(tmp(:,1) < 0.85 & tmp(:,2) >= 0.85);
stimuliNotNamedAccuratelyEnough = stimuli(tmp(:,2) < 0.85);



% % Find the same statistic for just the British participants.
% britishIndex = contains(demographics.country,'I was born and grew up in the UK');
% tmp = accuracy(:,britishIndex);
% meanAccuracyBritish = mean(tmp,2);
% tmp = meanAccuracyBritish >= 0.8;
% disp(['For the British participants, ',num2str(sum(tmp)),' stimuli were named with over 80% accuracy.']) 
% 
% % Identify stimuli named with over 80% accuracy by the Brits, but not in
% % the whole sample. 
% culturalDifferences = find(meanAccuracyAll < 0.8 & meanAccuracyBritish >=0.8);
% 
% % Plot a histogram showing the distribution of accuracies over stimuli.
% f = figure;
% f = histogram(meanAccuracyAll,-0.05:0.1:0.95);
% 
% % for each stimulus, generate bar plots of the feedback given
% for s = 1:100
% 
%     % first plot results for all participants.
% 
%     f = figure;
% 
%     % if the stimulus was named with over 80% accuracy
%     if meanAccuracyAll(s) >= 0.8
%         % plot the histogram in green. Ensure that the histogram has 6 bins, centred on the numbers 0 to 6
%         f = histogram(feedback(s,:),-0.5:1:5.5,'FaceColor','green')
%     else
%         % plot it in red
%         f = histogram(feedback(s,:),-0.5:1:5.5,'FaceColor','red')
%     end
% 
%     % adjust and label axes
%     xticklabels({'perceived correct','too quiet','bad exemplar','specificity','unfamiliar','other error'})
%     ylim([0,10])
%     ylabel('Response count')
% 
%     % add title
%     title(stimuli{s})
% 
%     % save the figure and close it
%     saveas(f,[root,'/derviatives/figures/feedback/all/',stimuli{s},'.png'])
%     close;
% 
%     % then plot results just for British participants.
% 
%     f = figure;
% 
%     % if the stimulus was named with over 80% accuracy
%     if meanAccuracyBritish(s) >= 0.8
%         % plot the histogram in green. Ensure that the histogram has 6 bins, centred on the numbers 0 to 6
%         f = histogram(feedback(s,britishIndex),-0.5:1:5.5,'FaceColor','green')
%     else
%         % plot it in red
%         f = histogram(feedback(s,britishIndex),-0.5:1:5.5,'FaceColor','red')
%     end
% 
%     % adjust and label axes
%     xticklabels({'perceived correct','too quiet','bad exemplar','specificity','unfamiliar','other error'})
%     ylim([0,5])
%     ylabel('Response count')
% 
%     % add title
%     title(stimuli{s})
% 
%     % save the figure and close it
%     saveas(f,[root,'/derviatives/figures/feedback/british/',stimuli{s},'.png'])
%     close;
% 
% end
% 
% % save useful variables
% save([root,'/derviatives/analysis.mat'],'responses','accuracy','feedback','meanAccuracyAll','meanAccuracyBritish');
% 
% 
% 
% 
% 
