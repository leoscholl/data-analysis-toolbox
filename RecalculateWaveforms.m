function RecalculateWaveforms(DataDir, AnimalID, WhichUnits)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

Units = FindUnits(DataDir, AnimalID, WhichUnits);

for unt = 1:length(Units(:,1))
    
    DataPath = ([DataDir,AnimalID,'\',deblank(Units(unt,:)),'\']);
    Files = ls([DataPath,'*.nev']); %#ok<*NOPTS>
    
    disp(Units(unt,:));
    
    if isempty(Files)
        warning(['No files found in ', DataPath]);
    end
    
    for f = 1:length(Files(:,1))
        [~, FileName, ~] = fileparts(Files(f,:));
        disp(FileName);
        [SpikeTimesMat, ~, Waveforms] = LoadSpikes(DataPath, FileName);
        
        %% Plot waveforms
        if ~isempty(Waveforms)
            disp('Plotting waveforms...');
            if size(SpikeTimesMat,1) ~= size(Waveforms,1)
                error('Not enough waveforms');
            end
            
            PlotWaveforms(DataPath, FileName, SpikeTimesMat, Waveforms);
        end
    end
end

