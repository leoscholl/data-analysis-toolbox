function convertWavSpikes( dataDir, sortingDir, animalID, whichUnits )

for i = 1:length(whichUnits)
    
    unitNo = whichUnits(i);
    sortingPath = fullfile(sortingDir, animalID); 
    fileName = [animalID, 'Unit', num2str(unitNo)];
    log = fullfile(sortingPath,[fileName, '.mat']);

    files = dir(fullfile(sortingPath,['times_', fileName, '*ch.mat']));
    files = files(~vertcat(files.isdir)); % just for good measure
    files = {files.name};
    files = unique(files);

    %
    % dur = length(spikes(:,1));
    % adc001 = [ones(dur,1), cluster_class(:,2)./1000, cluster_class(:,1), -1*ones(dur,1), spikes];
    % save([path,filesep,name,'-waveclus-spikes.mat'], 'adc001');

    % Collect electrode ids
    electrodeid = cell(length(files),1);
    spikes = {};
    cluster_class = {};
    for n = 1:length(files)
        electrodeid{n} = sscanf(files{n}, ['times_', fileName, '-%dch.mat']);
        waveclus = load(fullfile(sortingPath, files{n}));
        spikes{n} = waveclus.spikes;
        cluster_class{n} = waveclus.cluster_class;
    end

    log = load(log);
    Files = log.Files;

    % Cut the spikes into individual datasets
    for f = 1:size(Files,1)

        fileName = Files.fileName{f};
        disp(fileName);

        expFile = matfile(fullfile(dataDir, Files.animalID{f}, ...
            Files.unit{f}, fileName),'Writable', true);

        startTime = Files.time(f,1);
        endTime = Files.time(f,2);
        spike = struct;
        for n = 1:length(electrodeid) % for each channel

            whichSpikes = cluster_class{n}(:,2) > startTime & ...
                cluster_class{n}(:,2) <= endTime;

            spike(n).time = (cluster_class{n}(whichSpikes, 2)'-startTime)./1000;
            spike(n).unitid = cluster_class{n}(whichSpikes, 1)';
            spike(n).data = spikes{n}(whichSpikes, :)';
            spike(n).electrodeid = electrodeid{n};

        end

        % Save the new dataset
        dataset = expFile.dataset(1,1);
        dataset.spike = spike;
        dataset.source = fullfile(sortingPath, fileName);
        dataset.sourceformat = 'WaveClus';
        expFile.dataset(1,end+1) = dataset;

    end
end
