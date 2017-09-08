function [ Scatter, UCells ] = statsSummary( Cells )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

Scatter = struct;
UCells = struct('id', [], 'electrodeid', [], 'session', [], 'sessionid', [], ...
    'subject', [], 'subjectid', [], 'track', [], 'cell', [], 'response', [], ...
    'location', []);

cells = unique(Cells.id);

Locations = struct;
load('C:\Users\leo\Google Drive\Matlab\manual analysis\locations.mat');

uniqueCells = {};
for c = 1:length(cells)
    uniqueCells{c} = Cells(Cells.id == cells(c),:);
end
Cells = [];

parfor c = 1:length(cells)
    
    % Only look a trials for this cell
    cell = struct;
    stimuli = uniqueCells{c};
    cell.id = stimuli.id(1);
    cell.session = stimuli.session{1};
    cell.sessionid = stimuli.sessionid(1);
    cell.subject = stimuli.subject{1};
    cell.subjectid = stimuli.subjectid(1);
    cell.track = stimuli.track{1};
    cell.electrodeid = stimuli.electrodeid(1);

    cell.cell = stimuli.cell(1);
    cell.response = struct;
    
    % Collect location information if there is any
    map = Locations.(cell.subject).(cell.session);
    if isKey(map, cell.electrodeid)
        cell.location = map(cell.electrodeid);
    else
        cell.location = '';
    end

    for s = 1:size(stimuli,1)
        
        % Calculate statistics for each stim type
        stats = stimuli.Statistics{s};
        Stats = cell;
        
        % Remove cells with low firing rates
        if stimuli.meanSpikes(s) < 1 || stimuli.maxSpikes(s) < 10
            continue;
        end

        % Group the trials by condition number
        corr = cellfun(@(x, y)x - y, {stats.meanTrials}, {stats.blankTrials}, ...
            'UniformOutput', false);
        groups = arrayfun(@(x,y)repmat(x,1,y), [stats.conditionNo], ...
            cellfun(@length, corr), 'UniformOutput', false);
        
        % Run ANOVA
        Stats.anova = anova1([corr{:}], [groups{:}], 'off');
        
        try
            % Wilcoxon rank-sum for each condition
            Stats.ranksum = cellfun(@ranksum, {stats.meanTrials}, {stats.blankTrials});
            Stats.broadnessW = mean(Stats.ranksum < 0.01);

            % All trials vs all blank trials
            [~, Stats.ttest] = ttest([stats.meanTrials], [stats.blankTrials]);
        catch e
            % Not enough blank trials, usually
            Stats.ttest = NaN;
            Stats.ranksum = [];
            Stats.broadnessW = NaN;
        end
        
        % Rank surprise
        Stats.surprise = cellfun(@mean,{stats.surpriseInd});
        Stats.bursts = cellfun(@(x)mean(x(:,1)),{stats.nBursts});
        
        % Selectivity
        nConds = length([stats.conditionNo]);
        rMax = max([stats.tCurve]);
        rMin = min([stats.tCurve]);
        Stats.baseline = mean([stats.blank]);
        Stats.dos = (nConds - sum(arrayfun(@(x)x/rMax,[stats.tCurve])))/(nConds - 1);
        rNorm = ([stats.tCurve] - rMin)/(rMax - rMin);
        Stats.breadth = 1 - median(rNorm);
        Stats.si = (rMax - rMin)/(rMax + rMin);
        
        % Preferred stimulus
        dimensions = fieldnames(stimuli.Conditions{s});
        levels = stimuli.Conditions{s}.(dimensions{1});
        [~, ind] = max(rNorm);
        if isnumeric(levels(ind))
            Stats.pref = levels(ind);
        else
            Stats.pref = ind;
        end
        
        % Percent of cells with firing rates >25% over baseline
        Stats.broadnessP = mean([stats.tCurveCorr] > max([stats.tCurveCorr])*.25);
        
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
        elseif contains(stimuli.stimType{s}, 'Velocity')
            stimType = 'Velocity';
        elseif contains(stimuli.stimType{s}, 'RF')
            stimType = 'RFMap';
        elseif contains(stimuli.stimType{s}, 'Annulus')
            stimType = 'Annulus';
        else
            stimType = strrep(stimuli.stimType{s}, '-', '_');
        end
          
        % OSI
        if strcmp(stimType, 'Orientation')
            valid = levels >= 0;
            theta = deg2rad(levels(valid));
            response = [stats.tCurve]';
            response = response(valid);
            Stats.dsi = abs(sum(response.*exp(1i*theta))/sum(response));
            Stats.osi = abs(sum(response.*exp(2.1i*theta))/sum(response));
        end
        
        % Latency
        if strcmp(stimType, 'Latency')
            Stats.latency = stats.latency;
        end
        
        % Scatter plot structure
%         if ~isfield(Scatter, stimType)
%             Scatter.(stimType) = Stats;
%         else
%             Scatter.(stimType) = [Scatter.(stimType); Stats];
%         end
        
        % Group responses per cell
        cell.response.(stimType) = rmfield(Stats, {'id', ...
            'electrodeid', 'session', 'sessionid', 'subject', 'subjectid',...
            'track', 'cell', 'response', 'location'});
    end % for each stimuli

    UCells(c,:) = cell;

    
end % for each cell


