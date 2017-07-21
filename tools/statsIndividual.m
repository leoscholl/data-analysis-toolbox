function spike = statsIndividual(dataDir, animalID, whichUnits, whichFiles, ...
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
        spike(whichElectrode).Statistics.cell == whichCell, ...
        {'meanTrials', 'blankTrials', 'conditionNo'});
    
    % Group the trials by condition number
    corr = cellfun(@(x, y)x - y, cell.meanTrials, cell.blankTrials, ...
        'UniformOutput', false);
    groups = arrayfun(@(x,y)repmat(x,1,y), cell.conditionNo, ...
        cellfun(@length, corr), 'UniformOutput', false);
    
    % Run ANOVA
    anova1([corr{:}], [groups{:}]);

end
