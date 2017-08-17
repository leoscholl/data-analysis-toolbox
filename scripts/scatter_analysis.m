
% Maintenance variables
dataDir = 'I:\DataExport';
figuresDir = 'I:\Figures';
sourceFormat = {'WaveClus', 'Plexon', 'Ripple', 'Expo'};

% Plotting parameters
plotFigures = false; % overrides everything else
plotLFP = false;
summaryFig = false; % faster without summary figs (can't do parallel pool)

% Experiment info  
animals = {'R1504', 'R1506', 'R1508', ... % R1511
    'R1518', 'R1520', 'R1521', 'R1522', ...
    'R1524', 'R1525', 'R1526', 'R1527', ...
    'R1528', 'R1536', 'R1601', 'R1603', ...
    'R1604', 'R1605', 'R1629', 'R1701', ...
    'R1702' };

Cells = [];
for a = 1:length(animals)
    
    animalID = animals{a};
    
    % Recalculate without plotting
    recalculate(dataDir, figuresDir, animalID, [], [], [], ...
        plotFigures, plotLFP, summaryFig, sourceFormat)

    % Generate summary table for this animal
    s = summaryTable( dataDir, animalID, sourceFormat);
    s.autoSelect('MaxResponse');

    % Append the summary
    [~, S] = s.export(notes);
    Cells = [Cells; S];
    .......,.,.....,.
end

% Finally, plot the results
S = statsSummary(Cells);