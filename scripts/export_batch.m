%% Parameters

% Maintenance variables
rawDataDir = 'J:\Data';
dataDir = 'I:\DataExport';

diaryFilename = 'batch_output.txt';
diary(diaryFilename);

% Plotting parameters
plotFigures = 0;
plotLFP = 0;
overwrite = 1; % for exporting data

% % Experiment info
load('locations.mat');
animals = fieldnames(Locations);

fileType = 'unsorted'; % bin, osort, unsorted

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = [];
    whichFiles = [];
    
    fprintf(1, '\n\n----------------- %s -------------------\n', animalID);
    
    % Begin
    try
        % Convert ripple spikes into matlab format
        dataExportNA( rawDataDir, dataDir, animalID, whichUnits, ...
            whichFiles, overwrite);
    catch e
        
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
    end
    
    fprintf(1, '--------------------------------------------\n\n');
    
end

fprintf(log, 'End of all runs\n\n');
fclose(log);
diary off
