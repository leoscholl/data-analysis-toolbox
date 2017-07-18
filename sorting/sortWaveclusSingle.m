function sortWaveclusSingle( dataDir, sortingDir, animalID, whichUnits, whichFiles )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[~, ~, Files] = findFiles(dataDir, animalID, whichUnits, '*.mat', whichFiles);

for f = 1:size(Files,1)
    
    fileName = Files.fileName{f};
    unit = Files.unit{f};
    sortingPath = fullfile(sortingDir, animalID, unit);
    if ~exist(sortingPath, 'dir')
        mkdir(sortingPath);
    end
    files = {};
    
    % if the file has been exported, then use that data
    expFile = matfile(fullfile(dataDir, animalID, ...
        unit, fileName),'Writable', true);

    varNames = who(expFile);
    if ismember('dataset', varNames)
        dataset = expFile.dataset;
        whichData = find(strcmp({dataset.sourceformat}, 'Ripple'), ...
            1, 'last');
        dataset = dataset(:,whichData);
        nChannels = length(dataset.spike);
        for i = 1:nChannels
            spikes = dataset.spike(i).data';
            index = 1000*dataset.spike(i).time';
            sr = 3000;
            electrodeid = dataset.spike(i).electrodeid;
            files{i} = [fileName, '-', num2str(electrodeid), 'ch.mat'];
            
            parsave(fullfile(sortingPath, files{i}), spikes, index, sr);
        end
    else
        warning([fileName, ' has not been exported yet']);
        continue;
    end
    

    % Waveclus    
    cd(sortingPath)
    Get_spikes(files);
    par = struct;
    par.min_clus = 100;
    par.max_spk = 50000;
    par.maxtemp = 0.251;
    Do_clustering(files, 'par', par);
    
    % Convert back into database
    spike = struct;
    for n = 1:length(electrodeid) % for each channel
        
        electrodeid = sscanf(files{n}, [Files.fileName{f}, '-%dch.mat']);
        waveclus = load(fullfile(sortingPath, ['times_', files{n}]));

        spike(n).time = (waveclus.cluster_class(:, 2)')./1000;
        spike(n).unitid = waveclus.cluster_class(:, 1)';
        spike(n).data = waveclus.spikes';
        spike(n).electrodeid = electrodeid;
        
    end
    
    % Save the new dataset
    dataset = expFile.dataset(1,1);
    dataset.spike = spike;
    dataset.source = fullfile(sortingPath, Files.fileName{f});
    dataset.sourceformat = 'WaveClus';
    expFile.dataset(1,end+1) = dataset;
end

end

function parsave(filename, spikes, index, sr)
save(filename, 'spikes', 'index', 'sr');
end