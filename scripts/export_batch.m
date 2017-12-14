%% Parameters

% Maintenance variables
rawDataDir = '\\STUDENTLYONLAB\f\Data_2015-2017';
dataDir = 'I:\DataExport';

diaryFilename = 'batch_output.txt';
diary(diaryFilename);

overwrite = 1; % for exporting data

% % Experiment info
% load('locations.mat');
% animals = fieldnames(Locations);
animals = {'R1511'};   
whichUnits = [11:13];

fileType = 'unsorted'; % bin, osort, unsorted

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    
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

fprintf(1, 'End of all runs\n\n');
diary off
