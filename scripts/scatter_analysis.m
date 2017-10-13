
% Maintenance variables
dataDir = 'I:\DataExport';
sortingDir = 'I:\Sorting';
figuresDir = 'I:\Figures';
sourceFormat = {'WaveClus', 'Plexon', 'Ripple', 'Expo'};

% Plotting parameters
plotFigures = false; % overrides everything else
plotLFP = false;
summaryFig = false; % faster without summary figs (can't do parallel pool)

% Experiment info  
load('locations.mat');
animals = fieldnames(Locations);

%% Sorting
for a = 22:length(animals)
    
    animalID = animals{a};
    
    makeFilesForSorting(dataDir, sortingDir, animalID, []);
    sortWithWaveclus(sortingDir, animalID, []);
    convertWavSpikes(dataDir, sortingDir, animalID, []);
end

%% Recalculate
for a = 1:length(animals)
    
    animalID = animals{a};
    
    % Recalculate
    recalculate(dataDir, figuresDir, animalID, [], [], ...
        [], plotFigures, plotLFP, true, sourceFormat)

end

%% Plot?
for a = 8:length(animals)
    animalID = animals{a};
    
    % Plot figures
    plotIndividual(dataDir, figuresDir, animalID, [], [], [], ...
        'tcs', sourceFormat, true)
end

%% Summarize
cells = {};
parfor a = 1:length(animals)

    animalID = animals{a};
    
    disp(animalID);
    
    % Generate summary table for this animal
    s = summaryTable( dataDir, animalID, sourceFormat);
    s.autoSelect('MaxResponse');

    % Append the summary
    cells{a} = s.uniqueCells();

end
Cells = [];
for a = 1:length(animals)
    if ~isempty(fieldnames(cells{a}))
        Cells = [Cells; cells{a}];
    end
end

save('C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.mat', 'Cells');


%% CSV file

% load('C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.mat');

csv = {};
for c = 1:length(Cells)
    cell = Cells(c);
    animal = cell.subject;
    unit = sscanf(cell.session, 'Unit%d');
    if unit > 100
        unit = unit/10;
    end
    cellNo = cell.cell;
    elecNo = cell.electrodeid;
       
    osi = [];
    dsi = [];
    sf = [];
    tf = [];
    apt = [];
    con = [];
    lat = [];
    background = []; % baseline
    nSpikes = []; % peak firing rate
    
    % Add fields for cells that have them and have significant responses
    if isfield(cell.response, 'Orientation') && cell.response.Orientation.ttest < 0.05
        osi = cell.response.Orientation.osi;
        dsi = cell.response.Orientation.dsi;
    end
    if isfield(cell.response, 'Spatial') && cell.response.Spatial.ttest < 0.05
        sf = cell.response.Spatial.pref;
    end
    if isfield(cell.response, 'Temporal') && cell.response.Temporal.ttest < 0.05
        tf = cell.response.Temporal.pref;
    end
    if isfield(cell.response, 'Aperture') && cell.response.Aperture.ttest < 0.05
        apt = cell.response.Aperture.pref;
    end
    if isfield(cell.response, 'Contrast') && cell.response.Contrast.ttest < 0.05
        con = cell.response.Contrast.pref;
    end
    if isfield(cell.response, 'Latency') && (cell.response.Latency.peak > 10 || cell.response.Latency.ttest < 0.05)
        lat = cell.response.Latency.latency;
    end
    
    % Background calculation
    tests = fieldnames(cell.response);
    for s = 1:length(tests)
        background(s) = cell.response.(tests{s}).baseline;
        peak(s) = cell.response.(tests{s}).peak;
        nSpikes(s) = cell.response.(tests{s}).numSpikes;
        
    end
    background = mean(background);
    peak = max(peak);
    nSpikes = sum(nSpikes);
    
    response = nSpikes > 100 && any(structfun(@(x)x.ttest < 0.005, cell.response));
%     surprise = any(structfun(@(x)mean([x.surprise]) > 4, cell.response));
    tuning = response & any(structfun(@(x)x.anova < 0.005, cell.response));

    location = cell.location;
    
    % Add to table
    csv(c,:) = {animal, unit, elecNo, cellNo, location, response, tuning, ...
        osi, dsi, sf, tf, apt, con, lat, background, peak, nSpikes};
    
end

Summary = cell2table(csv);
Summary.Properties.VariableNames = {'AnimalID', 'Unit', 'Elec', 'Cell', ...
    'Location', 'Response', 'Tuning', 'OSI', 'DSI', 'SF', ...
    'TF', 'Apt', 'Con', 'Latency', 'BG', 'Peak', 'NumSpikes'};

% Sort
Summary = sortrows(Summary,{'AnimalID', 'Unit', 'Elec', 'Cell'});

% Export a csvFile for excel
csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
writetable(Summary,csvFile,'WriteRowNames',true,'QuoteStrings',true);

%% Import csv file 
csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
Summary = readtable(csvFile);

%% Inspect responsive cells
if ~ismember('Checked', Summary.Properties.VariableNames)
    Summary.Checked = repmat(0, size(Summary,1), 1);
end
for c = 1:size(Summary,1)
    
    % Change the decimal places for some thigns
    Summary.OSI(c) = round(Summary.OSI(c), 3);
    Summary.DSI(c) = round(Summary.DSI(c), 3);
    Summary.Apt(c) = round(Summary.Apt(c), 0);
    Summary.BG(c) = round(Summary.BG(c), 1);
    Summary.Peak(c) = round(Summary.Peak(c), 1);
    
    cell = table2struct(Summary(c,:));
    
    if cell.Checked || isempty(cell.Location) || ~cell.Response
        continue;
    end
    
    % Try to find the figures for this cell (waveclus)
    cellDir = fullfile(figuresDir,cell.AnimalID,['Unit',num2str(cell.Unit)],'WaveClus',...
        ['Ch',sprintf('%02d',cell.Elec)]);
    figs = dir(fullfile(cellDir,['*_',num2str(cell.Cell),'El',num2str(cell.Elec),'_tc.png']));
    
    if isempty(figs) % Try expo
        cellDir = fullfile(figuresDir,cell.AnimalID,['Unit',num2str(cell.Unit)],'Expo',...
            ['Ch',sprintf('%02d',cell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(cell.Cell),'El',num2str(cell.Elec),'_tc.png']));
    end
    
    if isempty(figs) % Try ripple
        cellDir = fullfile(figuresDir,cell.AnimalID,['Unit',num2str(cell.Unit)],'Ripple',...
            ['Ch',sprintf('%02d',cell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(cell.Cell),'El',num2str(cell.Elec),'_tc.png']));
    end
    
    
    for i=1:size(figs,1)
        I = imread(fullfile(figs(i).folder,figs(i).name));
        figure;
        imshow(I)
    end
    toShow = table2struct(Summary(c,{'AnimalID','Unit','Elec','Cell','SF','TF','Apt','Con','Latency','Peak'}));
    text = evalc('disp(toShow)');
    
    tilefigs;
    
    options = struct;
    options.Default = 'No';
    options.Interpreter = 'tex';
    choice = questdlg(text,'Response?', 'Yes', 'No', 'Cancel',options);
    switch choice
        case 'Yes'
            Summary.Response(c) = 1;
        case 'No'
            Summary.Response(c) = 0;
            Summary.Tuning(c) = 0;
        otherwise
            close all;
            break;
    end
    
    Summary.Checked(c) = 1;
    close all;
end

Summary = Summary(:,~ismember(Summary.Properties.VariableNames,'Checked'));
csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
writetable(Summary,csvFile,'WriteRowNames',true,'QuoteStrings',true);


%% Export each subdivision to a new file
locations = unique(Summary.Location);
for i=1:length(locations)
    csvFile = fullfile('C:\Users\leo\Google Drive\Matlab\manual analysis', ...
        sprintf('Cells_%s.csv', locations{i}));
    writetable(Summary(cellfun(@(x)strcmp(x,locations{i}),Summary.Location),:),...
        csvFile, 'QuoteStrings', true);
end

% Export good cells
csvFile = fullfile('C:\Users\leo\Google Drive\Matlab\manual analysis', ...
    sprintf('Cells_%s.csv', 'Responding'));
writetable(Summary(logical(Summary.Response),:),...
    csvFile, 'QuoteStrings', true);

%% Plot scatters for each stim type
close all;
Responding = Summary(logical(Summary.Response),:);
[locs,locNames] = grp2idx(categorical(Responding.Location));
stimTypes = {'SF','TF','OSI','DSI','Apt','Con','Latency'};
for i = 1:length(stimTypes)
    
    stim = Responding.(stimTypes{i});
    stim = stim + 2*(rand(size(stim))-0.5)*0.05;
    
    n = size(stim,1);
    
%     A=[locs, stim];
%     [Auniq,~,IC] = unique(A,'rows');
%     cnt = accumarray(IC,1);
%     
    figure(i);
    scatter(locs, stim, 'kx'); %Auniq(:,1),Auniq(:,2), [], cnt);
    title(stimTypes{i}, 'Interpreter', 'none');
%     colorbar;
%     colormap(jet)
    xlabel('Location');
    ylabel('Preference');
    xlim([0 length(locNames)+1])
    xticks(1:length(locNames));
    xticklabels(locNames);
    ylim auto;
    
    
    
%     dim = [.2 .5 .3 .3];
%     str = sprintf('%d/%d cells responding (p < 0.05)', size(stim, 1), n);
%     annotation('textbox',dim,'String',str,'FitBoxToText','on');
    
end
tilefigs;

