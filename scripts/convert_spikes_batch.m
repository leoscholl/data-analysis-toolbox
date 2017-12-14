%% Parameters

% Maintenance variables
dataDir = 'I:\DataExport';
exportDir = 'I:\Andrzej';

diaryFilename = 'batch_output.txt';
diary(diaryFilename);

overwrite = 1; % for exporting data

% % Experiment info
load('locations.mat');
animals = fieldnames(Locations);

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = [];
    whichFiles = [];
    
    fprintf(1, '\n\n----------------- %s -------------------\n', animalID);
    
    % Begin
    try
        % Convert sorted spikes into andrzej's format
        [~, ~, Files] = ...
            findFiles(dataDir, animalID, whichUnits, '*', whichFiles);
        nFiles = size(Files,1);
        
        parfor f = 1:size(Files,1)
            SpikeTimesMat = {};
            dataset = loadExperiment(dataDir, animalID, Files.fileNo(f), 'WaveClus');
            if isempty(dataset) || ~isfield(dataset, 'spike') || isempty(dataset.spike)
                continue; % doesn't exist
            end
            
            for j = 1:length(dataset.spike)
                SpikeTimesMat{j, 1} = [dataset.spike(j).time; dataset.spike(j).unitid]';
                SpikeTimesMat{j, 2} = sprintf('elec%d', dataset.spike(j).electrodeid);
            end
            
            unit = dataset.ex.unit;
            fileName = Files.fileName{f};
            
            saveDir = fullfile(exportDir, animalID, unit);
            if ~exist(saveDir, 'dir')
                mkdir(saveDir);
            end
            
            parsave(saveDir, fileName, SpikeTimesMat);
        end
    catch e
        
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
    end
    
    fprintf(1, '--------------------------------------------\n\n');
    
end

fprintf(1, 'End of all runs\n\n');
diary off

function parsave(dir, name, SpikeTimesMat)
    save(fullfile(dir, name), 'SpikeTimesMat');
end