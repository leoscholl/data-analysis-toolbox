
% Maintenance variables
dataDir = 'I:\DataExport';
sortingDir = 'I:\Sorting';
figuresDir = 'I:\Figures';
sourceFormat = {'Ripple', 'Expo'};

% Plotting parameters
plotFigures = false;
plotLFP = false;

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
parfor a = 1:length(animals)

    animalID = animals{a};
    
    disp(animalID);
    
    % Generate summary table for this animal
    s = summaryTable( dataDir, animalID, sourceFormat);
    
    % Save each summary table
    S{a} = s;
end
save('C:\Users\leo\Google Drive\Matlab\manual analysis\RippleSummary.mat', 'S');


%% Collect unique cells
% load('C:\Users\leo\Google Drive\Matlab\manual analysis\Summary.mat');
cells = {};
parfor a = 1:length(animals)

    animalID = animals{a};
    
    disp(animalID);
    
    % Generate summary table for this animal
    s = S{a};
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

save('C:\Users\leo\Google Drive\Matlab\manual analysis\RippleCells.mat', 'Cells');

%% CSV file
% 
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
       
    osi = NaN;
    dsi = NaN;
    sf = NaN;
    tf = NaN;
    apt = NaN;
    con = NaN;
    lat = NaN;
    background = NaN; % baseline
    nSpikes = NaN; % peak firing rate
    
    % Add fields for cells that have them and have significant responses
    if isfield(cell.response, 'Orientation') && ...
            cell.response.Orientation.ttest < 0.01
        osi = cell.response.Orientation.osi;
        dsi = cell.response.Orientation.dsi;
    end
    if isfield(cell.response, 'Spatial') && ...
            cell.response.Spatial.prefP < 0.05 && ...
            cell.response.Spatial.anova < 0.05
        sf = cell.response.Spatial.pref;
    end
    if isfield(cell.response, 'Temporal') && ...
            cell.response.Temporal.prefP < 0.05 && ...
            cell.response.Temporal.anova < 0.05
        tf = cell.response.Temporal.pref;
    end
    if isfield(cell.response, 'Aperture') && ...
            cell.response.Aperture.prefP < 0.05 && ...
            cell.response.Aperture.anova < 0.05
        apt = cell.response.Aperture.pref;
    end
    if isfield(cell.response, 'Contrast') && ...
            cell.response.Contrast.prefP < 0.05 && ...
            cell.response.Contrast.anova < 0.05
        con = cell.response.Contrast.pref;
    end
    if isfield(cell.response, 'Latency') && ...
            (cell.response.Latency.peak > 10 || ...
            cell.response.Latency.ttest < 0.01)
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
    
    response = nSpikes > 100 && ...
        any(~arrayfun(@isnan, [osi, sf, tf, apt, con, lat])) && ...
        ~all(arrayfun(@isnan, [osi, sf, tf, apt, con, lat]));
%     surprise = any(structfun(@(x)mean([x.surprise]) > 4, cell.response));
    gResponse = response & any(~arrayfun(@isnan, [osi, sf, tf, apt, con]));

    tuning = response & any(structfun(@(x)x.anova < 0.005, cell.response));
    location = cell.location;
    
    % Change the decimal places for some thigns
    osi = round(osi, 3);
    dsi = round(dsi, 3);
    apt = round(apt, 0);
    lat = round(lat, 2);
    background = round(background, 1);
    peak = round(peak, 1);
    
    % Add to table
    csv(c,:) = {animal, unit, elecNo, cellNo, location, response, tuning, ...
        osi, dsi, sf, tf, apt, con, lat, background, peak, nSpikes};
    
end

Summary = cell2table(csv);
Summary.Properties.VariableNames = {'AnimalID', 'Unit', 'Elec', 'Cell', ...
    'Location', 'Response', 'Tuning', 'OSI', 'DSI', 'SF', ...
    'TF', 'Apt', 'Con', 'Latency', 'BG', 'Peak', 'NumSpikes'};

% Sort
% Summary = sortrows(Summary,{'AnimalID', 'Unit', 'Elec', 'Cell'});
% 
% % Export a csvFile for excel
csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Summary.csv';
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
csvFile = 'C:\Users\leo\Google Drive\LP Results\Rat summary sheet new.xlsm';
Responding = readtable(csvFile);
[locs,locNames] = grp2idx(categorical(Responding.Location));
stimTypes = {'SF','TF','OSI','DSI','Apt','Con','Latency'};
for i = 1:length(stimTypes)
    
    stim = Responding.(stimTypes{i});
%     stim = stim + 2*(rand(size(stim))-0.5)*0.005;
    
    n = size(stim,1);
    
%     A=[locs, stim];
%     [Auniq,~,IC] = unique(A,'rows');
%     cnt = accumarray(IC,1);
%     
    figure(i);
    scatter(locs, stim, 'kx', 'jitter', 'on', 'jitteramount', 0.01); %Auniq(:,1),Auniq(:,2), [], cnt);
    title(stimTypes{i}, 'Interpreter', 'none');
%     colorbar;
%     colormap(jet)
    xlabel('Location');
    ylabel('Preference');
    xlim([0 length(locNames)+1])
    xticks(1:length(locNames));
    xticklabels(locNames);
    ylim auto;
    
end
tilefigs;

