function convertPlexonSpikes(plexonDir, dataDir, animalID, whichUnits, suffix)
%convertPlexonSpikes Turns spikes from -spikes.mat (default) file into 
% data export format

if nargin < 4 || isempty(suffix)
    suffix = '-spikes';
end

parfor unitNo = whichUnits
    
    unit = ['Unit', deblank(num2str(unitNo))];
    plexonPath = fullfile(plexonDir, animalID, filesep);
    dataPath = fullfile(dataDir, animalID, unit, filesep);
    
    logFile = [plexonPath,animalID,unit,'.mat'];
    spikesFile = [plexonPath,animalID,unit,suffix,'.mat'];
    
    disp(['Splitting files from ', spikesFile]);
    
    if exist(spikesFile,'file') && exist(logFile, 'file')
        log = load(logFile);
        
        if isfield(log, 'Files') && ~istable(log.Files) && ...
                isfield(log, 'EndTimes')
            % convert from old format
            nFiles = size(log.Files, 1);
            fileNames = cellfun(@stripFileName, cellstr(log.Files), ...
                'UniformOutput', false);
            [~, fileNos, stimTypes] = cellfun(@parseFileName, fileNames, ...
                'UniformOutput', false);
            units = repmat({unit}, nFiles, 1);
            unitNos = repmat(unitNo, nFiles, 1);
            
            % EndTimes spills over from the previous file... :(
            duration = log.EndTimes(1:nFiles,1);
            samples = log.EndTimes(1:nFiles,2);
            time = [log.EndTimes(1:nFiles,3) - log.EndTimes(1:nFiles,1), ...
                log.EndTimes(1:nFiles,3)];
            
            Files = table(fileNames, fileNos, stimTypes, units, unitNos, ...
                duration, samples, time);
            Files.Properties.VariableNames = ...
                {'fileName', 'fileNo', 'stimType', 'unit', 'unitNo', ...
                'duration', 'samples', 'time'};
        else
            Files = log.Files;
        end
        disp(Files.fileName);
        
        % Load spikes
        plexon = load(spikesFile);
        spikes = struct2cell(plexon);
        varNames = fieldnames(plexon);
        
        % Collect electrode ids
        electrodeid = cell(length(varNames),1);
        for n = 1:length(varNames)
            electrodeid{n} = sscanf(varNames{n}, 'adc%d');
        end
        
        % Cut the spikes into individual datasets
        for f = 1:size(Files,1)
            
            fileName = Files.fileName{f};
            disp(fileName);
            
            expFile = matfile(fullfile(dataPath, fileName),'Writable', true);

            startTime = Files.time(f,1);
            endTime = Files.time(f,2);
            spike = struct;
            for n = 1:size(spikes,1) % for each channel
                
                if int8(spikes{n}(:,2)) == spikes{n}(:,2)
                    unitCol = 2;
                    timeCol = 3;
                else
                    unitCol = 3;
                    timeCol = 2;
                end
                
                if int8(spikes{n}(:,4)) == spikes{n}(:,4)
                    waveCol = 5;
                else
                    waveCol = 4;
                end
                
                whichSpikes = spikes{n}(:,timeCol) > startTime & ...
                    spikes{n}(:,timeCol) <= endTime;
                
                spike(n).time = spikes{n}(whichSpikes, timeCol)'-startTime;
                spike(n).unitid = spikes{n}(whichSpikes, unitCol)';
                spike(n).data = spikes{n}(whichSpikes, waveCol:end)';
                spike(n).electrodeid = electrodeid{n};
                
            end
                       
            % Save the new dataset
            dataset = expFile.dataset(1,1);
            dataset.spike = spike;
            dataset.source = fullfile(dataPath, fileName);
            dataset.sourceformat = 'Plexon';
            expFile.dataset(1,end+1) = dataset;
            
        end
        disp('Done');
    else
        warning(['No such file ', spikesFile]);
        continue;
    end
end