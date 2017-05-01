function ConvertPlexonSpikes(DataDir, AnimalID, WhichUnits, Suffix)
%ConvertPlexonSpikes Turns spikes from -spikes.mat (default) file into 
%data export format

if nargin < 4 || isempty(Suffix)
    Suffix = '-spikes';
end

for UnitNo = WhichUnits
    
    Unit = ['Unit', deblank(num2str(UnitNo))];
    DataPath = fullfile(DataDir, AnimalID, Unit, filesep);
    
    LogFile = [DataPath,AnimalID,Unit,'.mat'];
    SpikesFile = [DataPath,AnimalID,Unit,Suffix,'.mat'];
    
    disp(['Splitting files from ', SpikesFile]);
    
    if exist(SpikesFile,'file')
        load(SpikesFile);
        load(LogFile);
        Files
        
        clear elec*;
        VarNames = who('adc*');
        
        [ElectrodeNames_Plexon] = FindElecNames(Files(end,1:strfind(Files(end,:),']')),DataPath);
        
        for n = 1:length(VarNames)
            
            ChannelName = VarNames{n};
            try
                eval(['Spikes = ',ChannelName,';']);
                SpikeTimesUnit{n,1} = Spikes;
            catch e
                disp(['No spikes in channel ',VarNames{n}]);
            end
        end
        clear adc*;
        disp([num2str(length(SpikeTimesUnit)), ' channels']);
        
        StartTime = 0;
        for f = 1:length(Files(:,1))
            
            [~, FileName, ~] = fileparts(Files(f,:));
            disp(FileName);
            
            SpikeTimesAll_Plexon = [];
            WaveformsAll_Plexon = [];
            for n = 1:size(SpikeTimesUnit,1)
                
                SpikesAll = SpikeTimesUnit{n,1};
                Spikes = SpikesAll(find(SpikesAll(:,2)>=StartTime & SpikesAll(:,2)<=EndTimes(f,3)),:);
                Spikes(:,2) = Spikes(:,2)-StartTime;

                if isempty(Spikes)
                    % no spikes in this file for this channel
                    continue;
                end
                
                % collect waveforms
                if length(Spikes(1,:)) > 5
                    Waveforms = Spikes(:,[1,3,5:end]);
                else
                    Waveforms = [];
                end
                
                % only save the electrode, spike times, and unit numbers
                if strcmp(VarNames{1,1}(1,1),'r')
                    Spikes = Spikes(:,[1,3,2]);
                else
                    Spikes = Spikes(:,1:3);
                end
                
                SpikeTimesAll_Plexon = [SpikeTimesAll_Plexon; Spikes];
                WaveformsAll_Plexon = [WaveformsAll_Plexon; Waveforms];
                
            end
            StimTimes = StimTimesAll{f};
            StartTime = EndTimes(f,3);
            
            if exist([DataPath,FileName,'-export.mat'],'file')      
                save([DataPath,FileName,'-export.mat'],'SpikeTimesAll_Plexon',...
                    'WaveformsAll_Plexon','ElectrodeNames_Plexon','-append')
                disp(['saved ',FileName,'-export.mat']);
            else
                warning('-export.mat file does not exist. Convert the ripple spikes first.');
            end
            
        end
        disp('Done');
    else
        warning(['No such file ', SpikesFile]);
        continue;
    end
end