% load raw JATOS data (in the form of a comma-delimited text file) and
% reformat it so that accuracy can be hand-coded.

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/02_naming_1';
addpath([root,'/src']);

% stop the user from overwriting meticulously hand-coded results!
check = input('Rerunning this script will overwrite any hand-coding of responses. Do you really want to continue? [Y/N] ','s');
if ~strcmp(check,'Y')
    return
end

% load data. All participants' data is saved as a single file.
tmp = dir([root,'/data/*']);
resultsFilename = tmp(~[tmp.isdir],:).name;
opts = detectImportOptions([root,'/data/',resultsFilename]);
opts.DataLine = 1;
opts.VariableNamesLine = 0;
rawData = readtable([root,'/data/',resultsFilename],opts);

% for each participant (there are 409 lines of results per participant)
for p = 1:size(rawData,1)/409

    % get the data for just that participant
    participantData = rawData(409*(p-1)+1:409*p,:); 

    % extract the main data of interest: (1) what the stimulus actually was, (2) what the person wrote, (3) a blank column inserted to enable manual accuracy scoring, (4) their feedback button-press response. 
    % initialise 
    organisedData = cell(81,2);

    % for every stimulus (there are 81)
    for s = 1:81

        % index information about which stimulus was presented
        tmp = participantData{s*5+1,15}{1};
        % get rid of irrelevant bits of the filepath
        tmp = extractBetween(tmp,'audio/','.wav');
        organisedData(s,1) = tmp;

        % index what the participant wrote
        tmp = participantData{s*5+2,16}{1};
        % split the character vector
        tmp = split(tmp,'"');
        % fill in the cell array
        organisedData(s,2) = tmp(4);

    end

    % sort alphabetically
    [~, i] = sort(organisedData(:,1));
    organisedData = organisedData(i,:);

    % make a work directory for that participant
    if ~exist(sprintf([root,'/work/sub-%03d'],p))
        mkdir(sprintf([root,'/work/sub-%03d'],p));
    end

    % write the sorted data as a .csv
    writecell(organisedData,sprintf([root,'/work/sub-%03d/scoring.csv'],p));

    % the data must then be hand-scored for accuracy.

    % also save that participant's Prolific ID (separately to the data)
    prolificID = participantData{2,10}{1};
    writematrix(prolificID,sprintf([root,'/work/sub-%03d/prolific.txt'],p));

end


