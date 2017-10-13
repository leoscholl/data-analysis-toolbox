%% Parameters

% Maintenance variables
rawDataDir = '\\STUDENTLYONLAB\g\Data\';
dataDir = 'I:\DataExport';

% Experiment info  
% animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
%     'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629', ...
%     'R1701', 'R1702' };
% units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
%     [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13], [2:11], [1:9]};
% 

animals = {'R1511'};

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = [];
    whichFiles = [];
    
    [~, ~, Files] = findFiles(dataDir, animalID, whichUnits, ...
        '*Spatial].mat', whichFiles);

    % parfor
    for f = 1:size(Files, 1)
        
        fileName = Files.fileName{f};
        fileNo = Files.fileNo(f);
        disp(fileName);
        
        try
            
            exportPath = fullfile(dataDir, animalID, fileName);
            m = load(exportPath);
            unit = m.dataset(1).ex.unit;
            
            % Covert parameters
            dataPath = fullfile(rawDataDir, animalID, unit, filesep);
            Params = convertLogFile( dataPath, fileName );
            if isempty(Params)
                continue;
            end
        
            % Modify the old exported file
            for j=1:length(m.dataset)
                if isfield(m.dataset(j), 'ex')
                    m.dataset(j).ex = Params;
                end
            end
            
            parsave(exportPath, m);
            
        catch e
            warning(getReport(e));
        end
        
    end
    
end

function parsave(path, m)
save(path, '-struct', 'm', '-v7.3');
end