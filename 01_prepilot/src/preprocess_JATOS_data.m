% load raw JATOS data (in the form of a comma-delimited text file) and
% reformat it so that accuracy can be hand-coded.

% setup
root = '/group/mlr-lab/Saskia/spokes_behavioural/01_prepilot';
addpath([root,'/src']);

% load data. All participants' data is saved as a single file.
opts = detectImportOptions([root,'/data/jatos_results_20260615102140.txt']);
opts.DataLine = 1;
opts.VariableNamesLine = 0;
rawData = readtable([root,'/data/jatos_results_20260615102140.txt'],opts);

% initialise a structure for storing demographic information
demographics = struct;
demographics.age = {};
demographics.country = {};
% initialise a cell array for storing feedback
feedback = cell(10,1);

% for each participant (there are 10)
for p = 1:10

    % get the data for just that participant (each participant's data is
    % 507 lines long)
    participantData = rawData(507*(p-1)+1:507*p,:); 

    % first, extract participant demographic information. Index the
    % information, which is stored as a big long character vector
    tmp = participantData{4,12}{1};
    % split the character vector up into sections delimited by "
    tmp = split(tmp,'"');
    % store the demographic information in a structure 
    demographics.age(p,1) = tmp(4);
    demographics.country(p,1) = tmp(8);

    % then extract any feedback they gave at the end of the experiment.
    tmp = participantData{506,12}{1};
    tmp = split(tmp,'"');
    feedback(p,1) = tmp(4);

    % now extract the main data of interest: (1) what the stimulus actually was, (2) what the person wrote, (3) a blank column inserted to enable manual accuracy scoring, (4) their feedback button-press response. 
    % initialise 
    organisedData = cell(100,4);

    % for every stimulus
    for s = 1:100

        % index information about which stimulus was presented
        tmp = participantData{s*5+3,15}{1};
        % get rid of irrelevant bits of the filepath
        tmp = extractBetween(tmp,'audio/','.wav');
        organisedData(s,1) = tmp;

        % index what the participant wrote
        tmp = participantData{s*5+4,12}{1};
        % split the character vector
        tmp = split(tmp,'"');
        % fill in the cell array
        organisedData(s,2) = tmp(4);

        % index the participant's button-press feedback
        tmp = str2double(participantData{s*5+5,12}{1});
        % fill in the cell array
        organisedData(s,4) = {tmp};

    end

    % sort alphabetically
    [~, i] = sort(organisedData(:,1));
    organisedData = organisedData(i,:);

    % make a work directory for that participant
    if ~exist(sprintf([root,'/work/sub-%03d'],p))
        mkdir(sprintf([root,'/work/sub-%03d'],p));
    end

    % write the sorted data as a .csv
    % writecell(organisedData,sprintf([root,'/work/sub-%03d/scoring.csv'],p));

    % the data must then be hand-scored for accuracy.

end

% save the demographic data
if ~exist([root,'/derviatives/'])
    mkdir([root,'/derviatives/'])
end
save([root,'/derviatives/demographics.mat'],'demographics');

