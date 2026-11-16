% Take psycholinguistic variable data and see if there are notable
% differences between categories. 
% setup

root = '/group/mlr-lab/Saskia/spokes_behavioural/04_triplets_2/';
addpath([root, '/src/']);

% load psycholinguistic variable data:
% - British National Corpus frequency and semantic diversity from Hoffman
% et al. 2013
semanticDiversity = readtable([root,'/src/psycholinguistic_variables/hoffman_semantic_diversity.xlsx']);
% - concreteness from Brysbaert et al. 2013
concreteness = readtable([root,'/src/psycholinguistic_variables/brysbaert_concreteness.xlsx']);
% - age of acquisition from Kuperman et al. 2013
ageOfAcquisition = readtable([root,'/src/psycholinguistic_variables/kuperman_age_of_acquisition.xlsx']);

% load list of stimuli
stimuli = readcell([root,'/src/stimuli.csv']);

% initialise output table
psycholinguisticVariables = array2table(nan(length(stimuli),6), 'VariableNames', {'Stimulus', 'Category', 'Frequency', 'Concreteness', 'Age of Acquisition', 'Semantic Diversity'});
% assign stimuli names to the first column
psycholinguisticVariables.Stimulus = stimuli;

% assign each thing to a category:
% 1 - land animal
% 2 - bird
% 3 - other animal
% 4 - person action
% 5 - vehicle
% 6 - musical instrument
% 7 - household appliance
% 8 - other inanimate

% stimuli from most recent experiment
% categories = [5, 6, 6, 8, 5, 1, 2, 1, 4, 8, 2, 8, 4, 1, 3, 2, 4, 6, 1, 1, 8, 8, 6, 2, 1, 8, 6, 3, 4, 6, 8, 7, 8, 5, 7, 1, 5, 4, 6, 6, 2, 8, 6, 1, 7, 8, 8, 8, 4, 2, 1, 8, 4, 4, 4, 8, 8, 5, 6, 6, 4, 8, 1, 4, 8];
% candidate new stimuli
categories = [6, 6, 8, 5, 1, 2, 1, 4, 8, 2, 8, 4, 1, 3, 2, 4, 1, 1, 8, 8, 2, 1, 8, 6, 3, 4, 6, 8, 7, 8, 5, 7, 1, 4, 1, 6, 2, 8, 6, 1, 7, 8, 8, 8, 4, 2, 1, 4, 4, 4, 8, 8, 5, 6, 6, 4, 8, 1, 4, 8];

psycholinguisticVariables.Category = categories';

% for each stimulus
for s = 1:length(stimuli)

    % frequency first (and semantic diversity while we are at it!)
    % get the row of the Hoffman table that corresponds to that word
    wordSemanticDiversity = semanticDiversity(find(strcmp(semanticDiversity.x_term,stimuli{s})),:);
    % if the stimulus is missing from the table
    if size(wordSemanticDiversity, 1) == 0
        % flag it
        warning([psycholinguisticVariables{s,1}{1}, ' is missing from the Hoffman frequency and semantic diversity data.'])
        else
        % otherwise fill in the output table
        psycholinguisticVariables(s,"Frequency") = table(wordSemanticDiversity.BNC_freq);
        psycholinguisticVariables(s,"Semantic Diversity") = table(wordSemanticDiversity.SemD);
    end

    % then concreteness
    wordConcreteness = concreteness(find(strcmp(concreteness.Word,stimuli{s})),:);
    % if the stimulus is missing from the table
    if size(wordConcreteness, 1) == 0
        % flag it
        warning([psycholinguisticVariables{s,1}{1}, ' is missing from the Brysbaert concreteness data.'])
        else
        % otherwise, fill in the output table
        psycholinguisticVariables(s,"Concreteness") = table(wordConcreteness.Conc_M);
    end

    % then age of acquisition
    wordAgeOfAcquisition = ageOfAcquisition(find(strcmp(ageOfAcquisition.Word,stimuli{s})),:);
    % if the stimulus is missing from the table
    if size(wordAgeOfAcquisition, 1) == 0
        % flag it
        warning([psycholinguisticVariables{s,1}{1}, ' is missing from the Kuperman age of acquisition data.'])
        else
        % otherwise, fill in the output table
        psycholinguisticVariables(s,"Age of Acquisition") = table(wordAgeOfAcquisition.Rating_Mean);
    end

end

% statistics

% the largest category is "other inanimate" with 17 items

statistics = struct();
statistics.frequency = nan(20,8);
statistics.concreteness = nan(20,8);
statistics.ageOfAcquisition = nan(20,8);
statistics.semanticDiversity = nan(20,8);

% for each category
for c = 1:8 

    % index the output table
    categoryPsycholingusticVariables = psycholinguisticVariables(find(psycholinguisticVariables.Category == c), :);

    % fill those variables into the struct
    statistics.frequency(1:size(categoryPsycholingusticVariables,1),c) = categoryPsycholingusticVariables.Frequency;
    statistics.concreteness(1:size(categoryPsycholingusticVariables,1),c) = categoryPsycholingusticVariables.Concreteness;
    statistics.ageOfAcquisition(1:size(categoryPsycholingusticVariables,1),c) = categoryPsycholingusticVariables.("Age of Acquisition");
    statistics.semanticDiversity(1:size(categoryPsycholingusticVariables,1),c) = categoryPsycholingusticVariables.("Semantic Diversity");

end

% Kruskal-Wallis tests for difference

[p, tbl, stats] = kruskalwallis(statistics.frequency, [], 'off');
s = multcompare(stats);

[p, tbl, stats] = kruskalwallis(statistics.concreteness, [], 'off');
s = multcompare(stats);

[p, tbl, stats] = kruskalwallis(statistics.ageOfAcquisition, [], 'off');
s = multcompare(stats);

[p, tbl, stats] = kruskalwallis(statistics.semanticDiversity, [], 'off');
s = multcompare(stats);

% collapse categories into animate/inanimate. Test for differences with
% Mann-Whitney U test

[p,h,stats] = ranksum(reshape(statistics.frequency(:,1:4),[],1),reshape(statistics.frequency(:,5:8),[],1)); 
p

[p,h,stats] = ranksum(reshape(statistics.concreteness(:,1:4),[],1),reshape(statistics.concreteness(:,5:8),[],1)); 
p

[p,h,stats] = ranksum(reshape(statistics.ageOfAcquisition(:,1:4),[],1),reshape(statistics.ageOfAcquisition(:,5:8),[],1)); 
p

[p,h,stats] = ranksum(reshape(statistics.semanticDiversity(:,1:4),[],1),reshape(statistics.semanticDiversity(:,5:8),[],1)); 
p

% save relevant variables
writetable(psycholinguisticVariables,[root,'/work/psycholinguistic_variables.csv'])
writematrix(categories,[root,'/work/category_index.csv'])

