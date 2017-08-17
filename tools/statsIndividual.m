function Stats = statsIndividual(dataDir, animalID, whichUnits, whichFiles, ...
    whichElectrode, whichCell, sourceFormat)
%statsIndividual get statistics for file

if nargin < 7 || isempty(sourceFormat)
    sourceFormat = {'WaveClus', 'Plexon', 'Ripple'};
end
if nargin < 6
    whichCell = 0;
end
if nargin < 5
    whichElectrode = 1;
end


% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*.mat', whichFiles);

% Display some info about duration
nFiles = size(Files,1);
if nFiles < 1
    return;
end

% Plot for all files
for f = 1:size(Files,1)
    
    fileNo = Files.fileNo(f);
    analysis = loadResults(dataDir, animalID, fileNo, sourceFormat);
    
    spike = analysis.spike;

    % Only look a trials for this cell
    cell = spike(whichElectrode).Statistics(...
        spike(whichElectrode).Statistics.cell == whichCell, :);
    
    % Group the trials by condition number
    corr = cellfun(@(x, y)x - y, cell.meanTrials, cell.blankTrials, ...
        'UniformOutput', false);
    groups = arrayfun(@(x,y)repmat(x,1,y), cell.conditionNo, ...
        cellfun(@length, corr), 'UniformOutput', false);
    
    % Run ANOVA
    Stats.anova = anova1([corr{:}], [groups{:}], 'off');
    
    % Selectivity
    Params = analysis.Params;
    rMax = max(cell.tCurve);
    rMin = min(cell.tCurve);
    baseline = mean(cell.blank);
    Stats.dos = (Params.nConds - sum(arrayfun(@(x)x/rMax,cell.tCurve)))/(Params.nConds - 1);
    rNorm = (cell.tCurve - rMin)/(rMax - rMin);
    Stats.breadth = 1 - median(rNorm);
    Stats.si = (rMax - rMin)/(rMax + rMin);
    
    % Wilcoxon rank-sum for each condition
    Stats.ranksum = cellfun(@ranksum, cell.meanTrials, cell.blankTrials);
    Stats.broadnessW = mean(Stats.ranksum < 0.01);
    
    % Percent of cells with firing rates >25% over baseline
    Stats.broadnessP = mean(cell.tCurveCorr > max(cell.tCurveCorr)*.25);

%     [~, Stats.ttest] = cellfun(@ttest, cell.meanTrials, cell.blankTrials);
    
    % All trials vs all blank trials
    [~, Stats.ttest] = ttest([cell.meanTrials{:}], [cell.blankTrials{:}]);
    
end
