%% Import csv file and cells table
%csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
% csvFile = 'C:\Users\leo\Google Drive\LP Results\Rat summary for LP.xlsm';
csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\individual\Rat summary for LP - 10-26-17 - LPMR.csv';
Summary = readtable(csvFile);
% Summary.Checked = repmat(0, size(Summary,1), 1);

load('C:\Users\leo\Google Drive\Matlab\manual analysis\RippleCells.mat');
Cells = struct2table(Cells);
Cells.subject = categorical(Cells.subject);
Cells.session = categorical(Cells.session);

%% Adjust OSI and DSI for all cells
for c = 1:size(Summary,1)
    csvCell = table2struct(Summary(c,:));
    
    if isempty(csvCell.AnimalID)
        continue;
    end
    
    ind = find(Cells.subject == csvCell.AnimalID & ...
        Cells.session == sprintf('Unit%d',csvCell.Unit) & ...
        Cells.electrodeid == csvCell.Elec & ...
        Cells.cell == csvCell.Cell);
    
    if isempty(ind)
        warning('Cell not found -- %s unit %d elec %d cell %d', ...
            csvCell.AnimalID, csvCell.Unit, csvCell.Elec, csvCell.Cell);
        continue;
    end
    
    goodCell = table2struct(Cells(ind,:));

    % Add Latency if none
    if isfield(goodCell.response, 'Latency') && ...
            (goodCell.response.Latency.peak > 10 || ...
            goodCell.response.Latency.ttest < 0.01)
        Summary.Latency(c) = round(goodCell.response.Latency.latency,2);
    end
    
    % Background calculation
    tests = fieldnames(goodCell.response);
    for s = 1:length(tests)
        background(s) = goodCell.response.(tests{s}).baseline;
        peak(s) = goodCell.response.(tests{s}).peak;
        nSpikes(s) = goodCell.response.(tests{s}).numSpikes;
        
    end
    background = mean(background);
    peak = max(peak);
    nSpikes = sum(nSpikes);
    

        Summary.BG(c) = round(background,1);
        Summary.Peak(c) = round(peak,1);
        Summary.NumSpikes(c) = nSpikes;

    
    % Location if none
    if isempty(Summary.Location(c))
        Summary.Location(c) = goodCell.location;
    end
    
    
end

%%
writetable(Summary, csvFile, 'QuoteStrings', true);






%% Import csv file and cells table
%csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
% csvFile = 'C:\Users\leo\Google Drive\LP Results\Rat summary for LP.xlsm';
csvGood = 'C:\Users\leo\Google Drive\Matlab\manual analysis\individual\NEW Rat summary for LP - 11-08-17 - V1.csv';
Good = readtable(csvGood);
Good.AnimalID = categorical(Good.AnimalID);

csvRipple = 'C:\Users\leo\Google Drive\Matlab\manual analysis\RippleSummary.csv';
Ripple = readtable(csvRipple);
Ripple.AnimalID = categorical(Ripple.AnimalID);

csvSorted = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Summary.csv';
Sorted = readtable(csvSorted);
Sorted.AnimalID = categorical(Sorted.AnimalID);

%% Figure out non-responsive cells based on responsive cells
for c = 1:size(Good,1)
    goodCell = table2struct(Good(c,:));
    
    if ismissing(goodCell.AnimalID)
        continue;
    end
    
    
    
    if goodCell.sorted
        
        ind = Sorted.AnimalID == goodCell.AnimalID & ...
            Sorted.Unit == goodCell.Unit & ...
            Sorted.Elec == goodCell.Elec & ...
            Sorted.Cell == goodCell.Cell;
        
        Sorted = Sorted(~ind,:);
        
    else
        
        ind = Ripple.AnimalID == goodCell.AnimalID & ...
            Ripple.Unit == goodCell.Unit & ...
            Ripple.Elec == goodCell.Elec & ...
            Ripple.Cell == goodCell.Cell;
        
        Ripple = Ripple(~ind,:);
        
    end
    
end


%% Import csv file and cells table
%csvFile = 'C:\Users\leo\Google Drive\Matlab\manual analysis\Cells.csv';
% csvFile = 'C:\Users\leo\Google Drive\LP Results\Rat summary for LP.xlsm';
csvGood = 'C:\Users\leo\Google Drive\Matlab\manual analysis\individual\NEW Rat summary for LP - 11-08-17 - LPLR.csv';
Good = readtable(csvGood);
Good.Checked = zeros(size(Good,1), 1);

%% Inspect tuning
test = 'Latency';
for c = 1:size(Good,1)
    goodCell = table2struct(Good(c,:));
    goodCell.AnimalID = strrep(goodCell.AnimalID, '''', '');
    
    if goodCell.Checked || any(ismissing(goodCell.AnimalID))
        continue;
    end
    
    if  ismissing(goodCell.FlashResponse) || ~goodCell.FlashResponse || ...
        ~ismissing(goodCell.Latency)
        continue;
    end
    
    if ~ismissing(goodCell.sorted) && goodCell.sorted
            
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'WaveClus',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*[',test,'*]_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'*.png']));
    
    else
        % Try expo
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Expo',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*[',test,'*]_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'*.png']));

    
        if isempty(figs) % Try ripple
            cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Ripple',...
                ['Ch',sprintf('%02d',goodCell.Elec)]);
            figs = dir(fullfile(cellDir,['*[',test,'*]_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'*.png']));
        end
    end
    
    for i=1:size(figs,1)
        I = imread(fullfile(figs(i).folder,figs(i).name));
        figure;
        imshow(I)
    end
    
    tilefigs;
    
    text = sprintf('%s Unit %d Elec %d Cell %d', goodCell.AnimalID, goodCell.Unit, ...
        goodCell.Elec, goodCell.Cell);
    
    choice = questdlg(text, 'Continue?', 'Yes', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            Good.Checked(c) = 1;
            close all;
        otherwise
            close all;
            break;
    end
    
    
end

%% re-Plot all data and import R1511
sourceFormat = {'WaveClus'};
for a = 5:length(animals)
    animalID = animals{a};
    
    % Plot figures
    plotIndividual(dataDir, figuresDir, animalID, [], [], [], ...
        'tcs', sourceFormat, true)
end
sourceFormat = {'Ripple', 'Expo'};
for a = 1:length(animals)
    animalID = animals{a};
    
    % Plot figures
    plotIndividual(dataDir, figuresDir, animalID, [], [], [], ...
        'tcs', sourceFormat, true)
end

export_batch;

%% Inspect responsive cells
for c = 1:size(Summary,1)
    
    goodCell = table2struct(Summary(c,:));
    
    if goodCell.Checked || isempty(goodCell.Location) || ~goodCell.Response
        continue;
    end
    
    % Try to find the latency figures for this cell (waveclus)
    cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'WaveClus',...
        ['Ch',sprintf('%02d',goodCell.Elec)]);
    figs = dir(fullfile(cellDir,['*[LatencyTest]_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'*_psth.png']));
    
    if isempty(figs) % Try expo
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Expo',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'_tc.png']));
    end
    
    if isempty(figs) % Try ripple
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Ripple',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'_tc.png']));
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

%% Reset checked
Summary.Checked = repmat(0, size(Summary,1), 1);

%% Inspect tuned cells
for c = 1:size(Summary,1)

    goodCell = table2struct(Summary(c,:));
    
    if goodCell.Checked || isempty(goodCell.Location) || ~goodCell.Tuning
        continue;
    end
    
    % Try to find the tuning curve figures for this cell (waveclus)
    cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'WaveClus',...
        ['Ch',sprintf('%02d',goodCell.Elec)]);
    figs = dir(fullfile(cellDir,['*_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'*_tc.png']));
    
    if isempty(figs) % Try expo
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Expo',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'_tc.png']));
    end
    
    if isempty(figs) % Try ripple
        cellDir = fullfile(figuresDir,goodCell.AnimalID,['Unit',num2str(goodCell.Unit)],'Ripple',...
            ['Ch',sprintf('%02d',goodCell.Elec)]);
        figs = dir(fullfile(cellDir,['*_',num2str(goodCell.Cell),'El',num2str(goodCell.Elec),'_tc.png']));
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
    choice = questdlg(text,'Tuning?', 'Yes', 'No', 'Cancel',options);
    switch choice
        case 'Yes'
            Summary.Tuning(c) = 1;
        case 'No'
            Summary.Tuning(c) = 0;
        otherwise
            close all;
            break;
    end
    
    Summary.Checked(c) = 1;
    close all;
end


%% Save new summary
Summary = Summary(:,~ismember(Summary.Properties.VariableNames,'Checked'));



%% Plot scatters for TF vs OSI
close all;

pResponse = 0.005;

% Separate responding cells
Complete = Cells(arrayfun(@(x)isfield(x.response,'Orientation') && ...
    isfield(x.response,'Temporal'), Cells),:);
nComplete = size(Complete, 1);
nCompleteLP = sum(arrayfun(@(x)contains(x.location, 'LP') || ...
    strcmp(x.location, 'Border'), Complete));

Responding = Complete(arrayfun(@(x)x.response.Orientation.ttest < pResponse && ...
    x.response.Temporal.ttest < pResponse, Complete),:);
nResponding = size(Responding, 1);

% Plot Ori vs TF response
V1 = arrayfun(@(x)strcmp(x.location, 'V1'), Responding);
LPMR = arrayfun(@(x)strcmp(x.location, 'LPMR'), Responding);
LPLR = arrayfun(@(x)strcmp(x.location, 'LPLR'), Responding);
Border = arrayfun(@(x)strcmp(x.location, 'Border'), Responding);
LP = LPMR | LPLR | Border;
LGN = arrayfun(@(x)strcmp(x.location, 'LGN'), Responding);

% Separate by location
locationNames = {'V1', 'LP', 'LGN', 'Unknown', 'LPLR', 'LPMR', 'Border'};
locations = {V1, LP, LGN, ~LP & ~LGN & ~V1, LPLR, LPMR, Border};
tf = struct;
osi = struct;
for i = 1:length(locations)
    tf.(locationNames{i}) = arrayfun(@(x)x.response.Temporal.pref, Responding(locations{i}));
    osi.(locationNames{i}) = arrayfun(@(x)x.response.Orientation.osi, Responding(locations{i}));
end

% Scatter plots
figure(1);
hold on
scatter(tf.V1, osi.V1);
scatter(tf.LP, osi.LP);
scatter(tf.LGN, osi.LGN);
scatter(tf.Unknown, osi.Unknown);

title('OSI vs TF');
xlabel('TF preference');
ylabel('OSI');
axis tight
legend({'V1', 'LP', 'LGN', 'Unknown'});

dim = [.2 .5 .3 .3];
str = sprintf('%d/%d cells responding (p < %g)', nResponding, nComplete, pResponse);
annotation('textbox',dim,'String',str,'FitBoxToText','on');
hold off;

figure(2);
hold on
scatter(tf.LPLR, osi.LPLR);
scatter(tf.LPMR, osi.LPMR);
scatter(tf.Border, osi.Border);

title('OSI vs TF');
xlabel('TF selectivity');
ylabel('OSI');
axis tight
legend({'LPLR', 'LPMR', 'Border'});

dim = [.2 .5 .3 .3];
str = sprintf('%d/%d cells responding (p < %g)', size(Responding(LP), 1), nCompleteLP, pResponse);
annotation('textbox',dim,'String',str,'FitBoxToText','on');
hold off;


% Bar plots
figure(3)
tf_ = rmfield(tf, {'LPMR', 'LPLR', 'Border'});
osi_ = rmfield(osi, {'LPMR', 'LPLR', 'Border'});
bar([1 1 1 1; 2 2 2 2], [structfun(@mean, tf_)'; structfun(@mean, osi_)']);
xticklabels({'TF selectivity', 'OSI'});
legend(fieldnames(tf_), 'Location', 'BestOutside');
hold off

figure(4)
tf_ = rmfield(tf, {'LP', 'V1', 'LGN', 'Unknown'});
osi_ = rmfield(osi, {'LP', 'V1', 'LGN', 'Unknown'});

bar([1 1 1; 2 2 2], [structfun(@mean, tf_)'; structfun(@mean, osi_)']);
xticklabels({'TF selectivity', 'OSI'});
legend(fieldnames(tf_), 'Location', 'BestOutside');
hold off

% ANOVA for TF
tf_ = rmfield(tf, {'LPMR', 'LPLR', 'Border'});
osi_ = rmfield(osi, {'LPMR', 'LPLR', 'Border'});
locs = fieldnames(tf_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [tf_.(locs{i}) repmat(i, length(tf_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

tf_ = rmfield(tf, {'LP', 'V1', 'LGN', 'Unknown'});
osi_ = rmfield(osi, {'LP', 'V1', 'LGN', 'Unknown'});
locs = fieldnames(tf_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [tf_.(locs{i}) repmat(i, length(tf_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

%% Plot Latency
close all;

pResponse = 0.01;

% Separate responding cells
Complete = Cells(arrayfun(@(x)isfield(x.response,'Latency'), Cells),:);
nComplete = size(Complete, 1);

Responding = Complete(arrayfun(@(x)any(structfun(...
    @(y)y.ttest < pResponse, x.response)), Complete),:);
nResponding = size(Responding, 1);

% Collect each ROI
V1 = arrayfun(@(x)strcmp(x.location, 'V1'), Responding);
LPMR = arrayfun(@(x)strcmp(x.location, 'LPMR'), Responding);
LPLR = arrayfun(@(x)strcmp(x.location, 'LPLR'), Responding);
Border = arrayfun(@(x)strcmp(x.location, 'Border'), Responding);
LP = LPMR | LPLR | Border;
LGN = arrayfun(@(x)strcmp(x.location, 'LGN'), Responding);

% Separate by location
locationNames = {'V1', 'LP', 'LGN', 'Unknown', 'LPLR', 'LPMR', 'Border'};
locations = {V1, LP, LGN, ~LP & ~LGN & ~V1, LPLR, LPMR, Border};
latency = struct;
for i = 1:length(locations)
    latency.(locationNames{i}) = arrayfun(@(x)x.response.Latency.latency, Responding(locations{i}));
end

% Bar plots
figure(3)
latency_ = rmfield(latency, {'LPMR', 'LPLR', 'Border'});

bar(structfun(@nanmean, latency_));
xticklabels(fieldnames(latency_));
hold off

figure(4)
latency_ = rmfield(latency, {'LP', 'V1', 'LGN', 'Unknown'});
bar(structfun(@nanmean, latency_));
xticklabels(fieldnames(latency_));
hold off


% ANOVA
latency_ = rmfield(latency, {'LPMR', 'LPLR', 'Border'});
locs = fieldnames(latency_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [latency_.(locs{i}) repmat(i, length(latency_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

latency_ = rmfield(latency, {'LP', 'V1', 'LGN', 'Unknown'});
locs = fieldnames(latency_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [latency_.(locs{i}) repmat(i, length(latency_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

% PCA
% nCells = size(UCells, 1);
% CompleteCells = UCells(arrayfun(@(x)length(fieldnames(x.response)) == ...
%     length(desiredStims),UCells));
% data = nan(length(CompleteCells), length(desiredStims)*6);
% for c = 1:length(CompleteCells)
%     for s = 1:length(desiredStims)
%         stim = desiredStims{s};
%         names = fieldnames(CompleteCells(c).response.(stim));
%         for i = 1:length(names)
%             data(c,(s-1)*6 + i) = CompleteCells(c).response.(stim).(names{i});
%         end
%     end
% end
% 
% [coeff,score,latent,tsquared,explained,mu] = pca(data);
% plot3(score(:,1), score(:,2), score(:,3),'+');
% xlabel('PCA 1');
% ylabel('PCA 2');
% zlabel('PCA 3');
% 
% 