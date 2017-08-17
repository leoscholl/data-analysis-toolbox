function convertExpoDataset(dataDir, exportDir, animalID)


if strcmp(animalID, 'R1504')
    unitFile = fullfile(dataDir, animalID, 'R1501', 'Figures', 'CellsUnits.mat');
else
    unitFile = fullfile(dataDir, animalID, animalID, 'Figures', 'CellsUnits.mat');
end
unitFile = load(unitFile);
unitNums = unitFile.A_pastespecial(:,1);

[~, ~, Files] = findFiles(dataDir, animalID, [], '*.mat');

for f=1:size(Files, 1)
    
    disp(['Exporting dataset:    ', Files.fileName{f}]);
    
    [filePath, fileName, ~] = fileparts(Files.rawFileName{f});
    xmlFile = fullfile(filePath, [fileName, '.xml']);
    if ~exist(xmlFile, 'file')
        xmlFile = fullfile(filePath, 'xml files', [fileName, '.xml']);
        if ~exist(xmlFile, 'file')
            disp('Exporting dataset:    could not find file.');
            continue;
        end
    end
    
    expoData = ReadExpoXML(xmlFile, 0, 0);
    if Files.fileNo(f) == 22 && strcmp(animalID, 'R1504')
        stimType = 'Ori_16';
    else
        stimType = Files.stimType{f};
    end
    dataset = convertSingle(expoData, stimType);
    dataset.ex.unitNo = unitFile.unity(find(Files.fileNo(f) >= unitNums, 1, 'last'));
    dataset.ex.unit = sprintf('Unit%d', dataset.ex.unitNo);
    dataset.ex.animalID = animalID;
    dataset.ex.fileName = Files.fileName{f};
    dataset.ex.expNo = Files.fileNo(f);
    dataset.ex.stimType = Files.stimType{f};
    dataset.source = Files.rawFileName{f};
    dataset.sourceformat = 'Expo';
    
    savePath = fullfile(exportDir, animalID, Files.fileName{f});
    if ~exist(fullfile(exportDir, animalID), 'dir')
        mkdir(fullfile(exportDir, animalID));
    end
    save(savePath, 'dataset', '-v7.3');
    disp('Exporting dataset:    Done.');
    
end
    
end

function dataset = convertSingle(z, stimType)

dataset = [];

% Spike data
electrodeids = z.spiketimes.IDs;
spike = [];
for i=1:length(electrodeids)
    spike(i).time = z.spiketimes.Times{i}./10000;
    spike(i).electrodeid = electrodeids(i);
    spike(i).data = [];
    spike(i).unitid = zeros(length(spike(i).time),1)';
end

% Experimental data
ex = [];

stimTimes = double(z.passes.StartTimes)'./10000;
stimOffTimes = double(z.passes.EndTimes)'./10000;
conditionNo = z.passes.BlockIDs' + 1;

ex.nTrials = max(histc(conditionNo, 1:length(unique(conditionNo))));

% Collect all data
nSurfaces = length(z.blocks.routines{1, 1}.Params);
columnNames = cellfun(@(x)x.Names, z.blocks.routines{1, 1}.Params, 'Un', 0);

for i = 1:length(columnNames)
    for j = 1:length(columnNames{i})
        columnNames{i}{j} = strrep(columnNames{i}{j}, '-', '_');
        columnNames{i}{j} = strrep(columnNames{i}{j}, ' ', '_');
        if i > 2
            columnNames{i}{j} = sprintf('Surface_%d_%s', ...
                ceil(i/2), columnNames{i}{j});
        end
    end
end

events = z.passes.events;
nColumns = sum(cellfun(@length, columnNames));
data = zeros(length(events),nColumns);
for e=1:length(events)
    row = [];
    if isempty(events{e}.Times)
        row = [row, zeros(1, nColumns)];
    else
        for i=1:nSurfaces
            for j=1:length(columnNames{i})      
                row = [row, events{e}.Data{i}(j)];
            end
        end
    end
    data(e, :) = row;
end

% Collect all possible conditions
routines = z.blocks.routines;
conditions = zeros(length(routines),sum(cellfun(@length, columnNames)));
for b=1:length(routines)
    row = [];
    for i=1:nSurfaces
        for j=1:length(columnNames{i})
            row = [row, routines{b}.Params{i}.Evalues{j};];
        end
    end
    conditions(b, :) = row;
end

% Convert conditions to structure
variableNames = [columnNames{:}];
variableNames = strrep(variableNames, ' ', '_');
Data = struct;
Conditions = struct;
for i=1:length(variableNames)
    Conditions.(variableNames{i}) = conditions(:,i);
end

% And data to table
Data = array2table(data);
Data.Properties.VariableNames = variableNames;
Data.conditionNo = conditionNo;
Data.stimTime = stimTimes;
Data.stimOffTime = stimOffTimes;

if ~any(Data.Drift_Rate == 0)
    Data.tf = Data.Drift_Rate; % Add tf column for FFT analysis
end

ex.Data = Data;

% Only keep conditions that are relevant
F = fieldnames(Conditions);
D = struct2cell(Conditions);
if contains(stimType, 'Aperture')
    keep = strcmp(F, 'Width');
elseif contains(stimType, 'Annulus')
    keep = strcmp(F, 'Surface_2_Width');
elseif contains(stimType, 'Spat')
    keep = strcmp(F, 'Spatial_Frequency_X');
elseif contains(stimType, 'Temp')
    keep = strcmp(F, 'Drift_Rate');
elseif contains(stimType, 'Ori')
    keep = strcmp(F, 'Orientation');
elseif contains(stimType, 'Cont')
    keep = strcmp(F, 'Contrast');
elseif contains(stimType, 'Cen')
    keep = strcmp(F, 'Orientation');
    D{keep}(end) = -3;
elseif contains(stimType, 'spont')
    keep = strcmp(F, 'Orientation');
    D{keep} = {'on', 'off', 'white', 'black'};
    F{keep} = 'Visible';
    ex.Data.Visible = ex.Data.Orientation;
    ex.Data.Visible(ex.Data.Visible ~= 90) = 0;
    ex.Data.Visible(ex.Data.Visible == 90) = 1;
else
    keep = ones(length(F), 1);
end
ex.Conditions = cell2struct(D(keep), F(keep));

% Add everything to dataset
dataset.spike = spike;
dataset.ex = ex;

end