%% Parameters

% Maintenance variables
rawDataDir = 'I:\Data\';
dataDir = 'I:\DataExport';

% Experiment info  
% animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
%     'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629', ...
%     'R1701', 'R1702' };
% units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
%     [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13], [2:11], [1:9]};
% 

animals = {'R1701'};
units = {9};

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = units{i};
    whichFiles = [];
    
    [~, ~, Files] = findFiles(dataDir, animalID, whichUnits, ...
        '*.mat', whichFiles); % WON'T WORK WITH FILES EXPORTED INTO ANIMAL DIR ONLY BECAUSE OF UNIT NOS

    % parfor
    for f = 1:size(Files, 1)
        
        fileName = Files.fileName{f};
        fileNo = Files.fileNo(f);
        unit = Files.unit{f};
        unitNo = Files.unitNo(f);
        disp(fileName);
        
        try
            exportPath = fullfile(dataDir, animalID, unit, fileName);
            m = load(exportPath);
            unit = m.dataset.ex.unit;
            
            % Covert parameters
            dataPath = fullfile(rawDataDir, animalID, unit, filesep);
            Params = convertLogFile( dataPath, fileName );
            if isempty(Params)
                continue;
            end
        
            % Overwrite the old exported file
            for j=1:length(m.dataset)
                if isfield(m.dataset(j), 'ex')
                    m.dataset(j).ex = Params;
                end
            end
            if isfield(m, 'analysis')
                m = rmfield(m, 'analysis');
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