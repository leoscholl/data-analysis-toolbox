function [ Statistics ] = statsSummary( Cells )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

Statistics = struct;
cells = unique(Cells.id);

for c = 1:length(cells)
    
    % Only look a trials for this cell
    cell = struct;
    stimuli = Cells(Cells.id == cells(c),:);
    cell.id = stimuli.id(1);
    cell.electrodeid = stimuli.electrodeid(1);
    cell.session = stimuli.session{1};
    cell.sessionid = stimuli.sessionid(1);
    cell.cell = stimuli.cell(1);
    
    for s = 1:size(stimuli,1)
        
        % Calculate statistics for each stim type
        stats = stimuli.Statistics{s};
        Stats = cell;
        
        % Average number of spikes per trial
        numSpikes = cellfun(@length, {stimuli.SpikeData{s}.raster});
        Stats.meanSpikes = mean(numSpikes);
        Stats.stdSpikes = std(numSpikes);
        Stats.maxSpikes = max(numSpikes);
        
        % Remove cells with low firing rates
        if Stats.meanSpikes < 1 || Stats.maxSpikes < 10
            continue;
        end

        % Group the trials by condition number
        corr = cellfun(@(x, y)x - y, {stats.meanTrials}, {stats.blankTrials}, ...
            'UniformOutput', false);
        groups = arrayfun(@(x,y)repmat(x,1,y), [stats.conditionNo], ...
            cellfun(@length, corr), 'UniformOutput', false);
        
        % Run ANOVA
        Stats.anova = anova1([corr{:}], [groups{:}], 'off');
        
        % Wilcoxon rank-sum for each condition
        Stats.ranksum = cellfun(@ranksum, {stats.meanTrials}, {stats.blankTrials});
        Stats.broadnessW = mean(Stats.ranksum < 0.01);
        
        % All trials vs all blank trials
        [~, Stats.ttest] = ttest([stats.meanTrials], [stats.blankTrials]);
        
        % Selectivity
        stats = struct2table(stats);
        nConds = length(stats.conditionNo);
        rMax = max(stats.tCurve);
        rMin = min(stats.tCurve);
        baseline = mean(stats.blank);
        Stats.dos = (nConds - sum(arrayfun(@(x)x/rMax,stats.tCurve)))/(nConds - 1);
        rNorm = (stats.tCurve - rMin)/(rMax - rMin);
        Stats.breadth = 1 - median(rNorm);
        Stats.si = (rMax - rMin)/(rMax + rMin);
        
        % Preferred stimulus
        dimensions = fieldnames(stimuli.Conditions{s});
        Stats.pref = stimuli.Conditions{s}.(dimensions{1});
        [~, ind] = max(rNorm);
        if isnumeric(Stats.pref(ind))
            Stats.pref = Stats.pref(ind);
        else
            Stats.pref = ind;
        end
        
        % Percent of cells with firing rates >25% over baseline
        Stats.broadnessP = mean(stats.tCurveCorr > max(stats.tCurveCorr)*.25);
        
        % Store the statistics in this cell's structure
        if contains(stimuli.stimType{s}, 'Spat')
            stimType = 'Spatial';
        elseif contains(stimuli.stimType{s}, 'Temp')
            stimType = 'Temporal';
        elseif contains(stimuli.stimType{s}, 'Aper')
            stimType = 'Aperture';
        elseif contains(stimuli.stimType{s}, 'Ori')
            stimType = 'Orientation';
        elseif contains(stimuli.stimType{s}, 'Cont')
            stimType = 'Contrast';
        elseif contains(stimuli.stimType{s}, 'Cen')
            stimType = 'CenterSurround';
        elseif contains(stimuli.stimType{s}, 'Lat') || ...
                contains(stimuli.stimType{s}, 'spon')
            stimType = 'Latency';
        else
            stimType = strrep(stimuli.stimType{s}, '-', '_');
        end
        if ~isfield(Statistics, stimType)
            Statistics.(stimType) = Stats;
        else
            Statistics.(stimType) = [Statistics.(stimType); Stats];
        end
    end
    
end

% Plot scatters
stimTypes = fieldnames(Statistics);
for i = 1:length(stimTypes)
    
    stim = Statistics.(stimTypes{i});
    
    n = size(stim,1);
    stim = stim([stim.ttest] <  0.05);
    
    figure(i);
    scatter([stim.pref], [stim.si]);
    title(stimTypes{i}, 'Interpreter', 'none');
    xlabel('preference');
    ylabel('selectivity index');
    xlim auto
    ylim([0 1]);
    
    dim = [.2 .5 .3 .3];
    str = sprintf('%d/%d cells responding (p > 0.05)', size(stim, 1), n);
    annotation('textbox',dim,'String',str,'FitBoxToText','on');
    
end
