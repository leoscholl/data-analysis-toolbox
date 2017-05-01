function DataExport( DataDir, CopyDir, AnimalID, WhichUnits, WhichFiles )
%DataExport exports specified units and directories from DataDir to CopyDir

narginchk(3,5);

if nargin < 5
    WhichFiles = [];
end
if nargin < 4
    WhichUnits = [];
end

[FileNames, FileUnits] = ...
    FindFiles(DataDir, AnimalID, WhichUnits, '*.nev', WhichFiles);

for i=1:size(FileNames,1)
    [~, File, ~] = fileparts(deblank(FileNames(i,:)));
    UnitNo = FileUnits(i,:);
    [AnimalID, FileNo, ~] = ParseFile(File);
    DataPath = fullfile(DataDir, AnimalID, ['Unit',num2str(UnitNo)]);
    DestPath = fullfile(CopyDir, AnimalID, ['Unit',num2str(UnitNo)]);
    ExportFile = fullfile(DataPath, [File, '-export.mat']);
    
    if ~exist(ExportFile,'file')
        
        % Try exporting all the data
        ConvertLogMats(DataDir, AnimalID, UnitNo, FileNo);
        ConvertRippleSpikes(DataDir, AnimalID, UnitNo, FileNo);
        ConvertRippleLFP(DataDir, AnimalID, UnitNo, FileNo);
        
    else
        
        % Exported data exists, check it first
        m = matfile(ExportFile,'Writable',false);
        if length(whos(m,'SpikeTimesAll_Ripple', ...
                'WaveformsAll_Ripple', 'ElectrodeNames_Ripple', ...
                'StimTimesParallel', 'StimTimesPhotodiode')) < 5
            % Redo spikes
            ConvertRippleSpikes(DataDir, AnimalID, UnitNo, FileNo);
        end
        if isempty(whos(m,'Params'))
            % Redo Params
            ConvertLogMats(DataDir, AnimalID, UnitNo, FileNo);
            
        end
        if length(whos(m,'LFPDataAll','LFPEndTime', ...
                'LFPSampleRate','LFPElectrodeNames')) < 4
            % Redo LFP
            ConvertRippleLFP(DataDir, AnimalID, UnitNo, FileNo);
        end
    end
    
    % Finally, copy anything that exists
    CopyFiles ([File,'-export.mat'], DataPath, DestPath);
end

disp('done.');