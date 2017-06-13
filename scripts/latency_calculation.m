function Latencies = latency_calculation(resultsDir, animalID)
%latency_calculation Determine latency for all units for given animalID

% Default parameters
whichUnits = [];
showFigures = 0;

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(resultsDir, animalID, whichUnits, '*[LatencyTest]-results*');

% Display some info about duration
nFiles = size(Files,1);
fprintf('There are %d files to be analyzed.\n', nFiles);
if nFiles < 1
    return;
end

% Recalculate all files
latCell = [];
for f = 1:nFiles
       
    % Data comes from the DataDir
    fileName = Files.fileName{f};
    unit = Files.unit{f};
    unitNo = Files.unitNo(f);
    fileNo = Files.fileNo(f);
    disp(fileName);
    
    filePath = fullfile(resultsDir, animalID, unit, [fileName, '-results.mat']);
    load(filePath);
    
    if ~exist('Results') || ~isfield(Results,'Electrodes') || ...
        size(Results.StatisticsAll{1}, 2) < 11
        disp('Skipping');
        continue;
    end
    
    Electrodes = Results.Electrodes;    
    nElectrodes = Params.nElectrodes;
    
    % All electrodes
    for i = 1:nElectrodes
        elecNo = Electrodes.number(i);
        
        Statistics = Results.StatisticsAll{elecNo};
        nStats = size(Statistics,1);
        latCell = [latCell; ...
            repmat(unitNo, nStats, 1), repmat(fileNo, nStats, 1), ...
            repmat(elecNo, nStats, 1), ...
            Statistics.conditionNo, Statistics.unit, Statistics.latency];

    end % Electrodes loop
end % Files loop

Latencies = array2table(latCell);
Latencies.Properties.VariableNames = {'unitNo', 'fileNo', 'elecNo', ...
    'c', 'u', 'latency'};


end