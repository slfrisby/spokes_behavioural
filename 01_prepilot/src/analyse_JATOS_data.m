% takes files that have been generated with preprocess_JATOS_data.m AND
% hand-coded for accuracy. Analyses these to enable generation of a new and
% improved stimulus set. 

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/01_prepilot';
addpath([root,'/src']);

% create output directories
if ~exist([root,'/derviatives/figures/feedback/'])
    mkdir([root,'/derviatives/figures/feedback/all/'])
    mkdir([root,'/derviatives/figures/feedback/british/'])
end

% load demographic data
load([root,'/derviatives/demographics.mat']);

% initialise separate variables to store responses, accuracy, and feedback.
responses = cell(100,10);
accuracy = zeros(100,10);
feedback = zeros(100,10);

% for each participant
for p = 1:10 

    % load data
    tmp = readcell(sprintf([root,'/work/sub-%03d/scoring.csv'],p));

    % get the stimulus names
    if p == 1
        stimuli = tmp(:,1);
    end

    % fill in accuracy, response, and feedback variables
    responses(:,p) = tmp(:,2);
    accuracy(:,p) = cell2mat(tmp(:,3));
    feedback(:,p) = cell2mat(tmp(:,4));

end

% Then generate some summaries. 

% find the number of stimuli with over 80% accuracy.
meanAccuracyAll = mean(accuracy,2);
tmp = meanAccuracyAll >= 0.8;
disp([num2str(sum(tmp)),' stimuli were named with over 80% accuracy.'])

% Find the same statistic for just the British participants.
britishIndex = contains(demographics.country,'I was born and grew up in the UK');
tmp = accuracy(:,britishIndex);
meanAccuracyBritish = mean(tmp,2);
tmp = meanAccuracyBritish >= 0.8;
disp(['For the British participants, ',num2str(sum(tmp)),' stimuli were named with over 80% accuracy.']) 

% Identify stimuli named with over 80% accuracy by the Brits, but not in
% the whole sample. 
culturalDifferences = find(meanAccuracyAll < 0.8 & meanAccuracyBritish >=0.8);

% Plot a histogram showing the distribution of accuracies over stimuli.
f = figure;
f = histogram(meanAccuracyAll,-0.05:0.1:0.95);

% for each stimulus, generate bar plots of the feedback given
for s = 1:100
    
    % first plot results for all participants.

    f = figure;

    % if the stimulus was named with over 80% accuracy
    if meanAccuracyAll(s) >= 0.8
        % plot the histogram in green. Ensure that the histogram has 6 bins, centred on the numbers 0 to 6
        f = histogram(feedback(s,:),-0.5:1:5.5,'FaceColor','green')
    else
        % plot it in red
        f = histogram(feedback(s,:),-0.5:1:5.5,'FaceColor','red')
    end

    % adjust and label axes
    xticklabels({'perceived correct','too quiet','bad exemplar','specificity','unfamiliar','other error'})
    ylim([0,10])
    ylabel('Response count')

    % add title
    title(stimuli{s})

    % save the figure and close it
    saveas(f,[root,'/derviatives/figures/feedback/all/',stimuli{s},'.png'])
    close;

    % then plot results just for British participants.

    f = figure;

    % if the stimulus was named with over 80% accuracy
    if meanAccuracyBritish(s) >= 0.8
        % plot the histogram in green. Ensure that the histogram has 6 bins, centred on the numbers 0 to 6
        f = histogram(feedback(s,britishIndex),-0.5:1:5.5,'FaceColor','green')
    else
        % plot it in red
        f = histogram(feedback(s,britishIndex),-0.5:1:5.5,'FaceColor','red')
    end

    % adjust and label axes
    xticklabels({'perceived correct','too quiet','bad exemplar','specificity','unfamiliar','other error'})
    ylim([0,5])
    ylabel('Response count')

    % add title
    title(stimuli{s})

    % save the figure and close it
    saveas(f,[root,'/derviatives/figures/feedback/british/',stimuli{s},'.png'])
    close;

end

% save useful variables
save([root,'/derviatives/analysis.mat'],'responses','accuracy','feedback','meanAccuracyAll','meanAccuracyBritish');





