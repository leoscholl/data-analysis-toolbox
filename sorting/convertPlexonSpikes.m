function convertPlexonSpikes(plexonDir, dataDir, animalID, whichUnits, suffix)
%convertPlexonSpikes Turns spikes from -spikes.mat (default) file into 
% data export format

if nargin < 4 || isempty(suffix)
    suffix = '-spikes';
end

for UnitNo = whichUnits
    
    unit = ['Unit', deblank(num2str(UnitNo))];
    plexonPath = fullfile(plexonDir, animalID, unit, filesep);
    dataPath = fullfile(dataDir, animalID, unit, filesep);
    
    logFile = [plexonPath,animalID,unit,'.mat'];
    spikesFile = [plexonPath,animalID,unit,suffix,'.mat'];
    
    disp(['Splitting files from ', spikesFile]);
    
    if exist(spikesFile,'file') && exist(logFile, 'file')
        load(spikesFile);
        load(logFile);
        disp(Files.fileName);
        
        clear elec*;
        varNames = who('adc*');
        
        % Collect spikes for each electrode
        spikes = cell(length(varNames),1);
        electrodeid = cell(length(varNames),1);
        for n = 1:length(varNames)
            electrodeName = varNames{n};
            electrodeid{n} = sscanf(electrodeName, 'adc%d');
            eval(sprintf('spikes{%d} = %s;',n,electrodeName));
            
            if isempty(spikes{n})    
                disp(['No spikes in channel ',varNames{n}]);
            end
        end
        clear adc*;
        
        % Cut the spikes into individual datasets
        for f = 1:size(Files,1)
            
            fileName = Files.fileName{f};
            disp(fileName);
            
            expFile = matfile(fullfile(dataPath, fileName),'Writable', true);

            startTime = Files.time(f,1);
            endTime = Files.time(f,2);
            samples = Files.samples(f);
            spike = struct;
            for n = 1:size(spikes,1) % for each channel
                
                whichSpikes = spikes{n}(:,2) > startTime & spikes{n}(:,2) <= endTime;
                
                spike(n).time = spikes{n}(whichSpikes, 2)'-startTime;
                spike(n).unitid = spikes{n}(whichSpikes, 3)';
                spike(n).data = spikes{n}(whichSpikes, 5:end)';
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