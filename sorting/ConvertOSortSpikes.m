function ConvertOSortSpikes(DataDir, AnimalID, UnitNo, filenames)

Unit = ['Unit',deblank(num2str(UnitNo))];
DataPath = fullfile(DataDir,AnimalID,Unit,filesep);

LogFile = [DataPath,AnimalID,Unit,'.mat'];
load(LogFile);
Files

StartTime = 0;
for f = 1:length(Files(:,1))
    
    [~, FileName, ~] = fileparts(Files(f,:));
    disp(FileName);
    
    WaveformsAll_OSort = [];
    SpikeTimesAll_OSort = [];
    ElectrodeNames_OSort = [];
    
    % Each electrode is stored in a different file - load it each time...
    lastCount = 0;
    for i=1:length(filenames)
       
        if ~exist(filenames{i},'file')
            fprintf(2, ['No file for electrode ' i]);
            continue;
        end
        
        load(filenames{i}, 'assignedNegative', 'newTimestampsNegative', ...
            'useNegative', 'newSpikesNegative');
        
        newTimestampsNegative = ...
            newTimestampsNegative./1000000; % microseconds -> seconds
        
        inds = newTimestampsNegative>=StartTime & ...
            newTimestampsNegative <= EndTimes(f,3);
        count = length(find(inds));
        
        assignments = assignedNegative(inds)';
        temps = unique(assignments);
        [~, assignments_new] = sort(temps, 'descend');
        for t = 1:length(assignments_new)
            assignments(assignments == temps(t)) = assignments_new(t) - 1;
        end
        
        SpikeTimesAll_OSort(lastCount+1:lastCount+count,:) = ...
            [repmat(i,count,1), newTimestampsNegative(inds)'-StartTime, ...
            assignments];
        WaveformsAll_OSort(lastCount+1:lastCount+count,:) = ...
            [repmat(i,count,1), assignments, newSpikesNegative(inds,:)];
        
        ElectrodeNames_OSort{i} = ['elec',num2str(i)];
        
        lastCount = lastCount + count;
        
    end
    
    % Assume StimTimes are already saved in this file
    if exist([DataPath,FileName,'-export.mat'],'file')      
        save([DataPath,FileName,'-export.mat'],'SpikeTimesAll_OSort',...
            'WaveformsAll_OSort','ElectrodeNames_OSort','-append')
        disp(['saved ',FileName,'-export.mat']);
    else
        warning('-export.mat file does not exist. Convert the ripple spikes first.');
    end
    
    StartTime = EndTimes(f,3);
   
end
disp('Done');

