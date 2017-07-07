%% Parameters

% Maintenance variables
rawDataDir = 'I:\Data\';
dataDir = 'I:\DataExport';

% Experiment info  
animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
    'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629', ...
    'R1701', 'R1702' };
units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
    [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13], [2:11], [1:9]};


%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = units{i};
    whichFiles = [];
    
    [~, ~, Files] = findFiles(dataDir, animalID, whichUnits, ...
        '*[CatRFfast].mat', whichFiles);

    for f = 1:size(Files, 1)
        
        fileName = Files.fileName{f};
        fileNo = Files.fileNo(f);
        unit = Files.unit{f};
        unitNo = Files.unitNo(f);
        disp(fileName);
        
        % Covert parameters
        dataPath = fullfile(rawDataDir, animalID, unit, filesep);
        Params = convertLogMat( dataPath, fileName );
        
        % Overwrite the old exported file
        exportPath = fullfile(dataDir, animalID, unit, fileName);
        m = matfile(exportPath, 'Writable', true);
        dataset = m.dataset;
        for i=1:length(dataset)
            dataset(i).ex.Params = Params;
        end
        m.dataset = dataset;
        
    end
    
end
