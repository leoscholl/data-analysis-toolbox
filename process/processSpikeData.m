function result = processSpikeData(spike, ...
    ex, path, filename, plotFun, varargin)
%processSpikeData Plot spiking data with the given list of plotting functions

p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.addOptional('binSize', 0.02/ex.secondperunit);
p.addOptional('normFun', []);
p.parse(varargin{:});
offset = p.Results.offset;
binSize = p.Results.binSize;
normFun = p.Results.normFun;

if ~iscell(plotFun)
    plotFun = {plotFun};
end

result = struct;
result.electrodeid = spike.electrodeid;

% Grouping
conditionNames = fieldnames(ex.Cond);
% Take 'Final' factors by default, otherwise take the first
gId = find(contains(conditionNames,'Final'),1);
if isempty(gId)
    groupingFactor = conditionNames{1};
else
    groupingFactor = conditionNames{gId};
end
[groupingValues, conditions, levelNames] = ...
    groupConditions(ex, groupingFactor, 'remaining');
result.groupingFactor = groupingFactor;
result.levelNames = levelNames;

% Labels for grouped conditions
labels = cell(1,size(groupingValues,1));
for i = 1:size(groupingValues,1)
    labels{i} = strcat(groupingFactor, ' = ', sprintf(' %g', groupingValues(i,:)));
end

% Prepare annotation parameters
baseParam = {'Ori', 'Diameter', 'Size', 'Color', 'Position', ...
    'Contrast', 'SpatialFreq', 'TemporalFreq', 'GratingType'};
baseParam = NeuroAnalysis.Base.getstructfields(ex.EnvParam, ...
    baseParam);

% Per-electrode figures
for f = 1:length(plotFun)
    switch plotFun{f}
        case 'plotWaveforms'
            nf = NeuroFig(ex.ID, spike.electrodeid, []);
            plotWaveforms(spike);
            nf.dress();
            nf.suffix = 'wf';
            nf.print(path, filename);
            nf.close();
            continue;
    end
end

% Per-cell figures
uuid = spike.uuid;
unit = cell(1, length(uuid));
for j = 1:length(uuid)
    spikes = spike.time(spike.unitid == uuid(j));
    unit{j}.uuid = uuid(j);
    if isempty(spikes)
        continue;
    end
    
    % Calculate MFR and F1
    pre = nan(length(ex.CondTest.CondIndex), 1);
    f0 = pre; f1 = pre;
    for t = 1:length(ex.CondTest.CondIndex)
        
        % Pre-stimulus
        t1 = ex.CondTest.CondOn(t);
        t0 = t1 - offset;
        pre(t) = f0f1(spikes, t0, t1, NaN);
        
        % Peri-stimulus
        if isfield(ex.CondTestCond, 'TemporalFreq')
            tf = ex.CondTestCond.TemporalFreq{t};
        elseif isfield(ex.EnvParam, 'TemporalFreq')
            tf = ex.EnvParam.TemporalFreq;
        else
            tf = NaN;
        end
        t0 = t1;
        t1 = ex.CondTest.CondOff(t);
        [f0(t), f1(t)] = f0f1(spikes, t0, t1, tf/ex.secondperunit);
    end
    
    % Fix time units
    if ex.secondperunit ~= 1
        pre = pre/ex.secondperunit;
        f0 = f0/ex.secondperunit;
        f1 = f1/ex.secondperunit;
    end
    
    % Organize MFR into proper conditions
    mF0 = nan(size(groupingValues,1), size(conditions,3));
    semF0 = mF0; mPre = mF0; semPre = mF0; mF1 = mF0; semF1 = mF0;
    for l = 1:size(conditions,3)
        for i = 1:size(groupingValues,1)
            mF0(i,l) = nanmean(f0(conditions(i,:,l)));
            semF0(i,l) = sem(f0(conditions(i,:,l)));
            mPre(i,l) = nanmean(pre(conditions(i,:,l)));
            semPre(i,l) = sem(pre(conditions(i,:,l)));
            mF1(i,l) = nanmean(f1(conditions(i,:,l)));
            semF1(i,l) = sem(f1(conditions(i,:,l)));
        end
        
        % Save optimal condition at each level
        [~, i] = max(mF0(:,l));
        unit{j}.(['maxF1',strrep(levelNames{l},'.','_')]) = groupingValues(i,:);
    end
    data.mF0 = mF0; data.semF0 = semF0; data.mPre = mPre;
    data.semPre = semPre; data.mF1 = mF1; data.semF1 = semF1;
    
    
    % Calculate OSI and DSI for orientation stimuli
    if contains(ex.ID, 'Ori')
        for l = 1:size(conditions,3)
            baseline = mean(mF0(:,l));
            valid = groupingValues(:,1) >= 0;
            theta = deg2rad(groupingValues(valid,1));
            response = mF0(valid) - baseline;
            response(response < 0) = 0;
            [OSI, DSI] = osi(response, theta);
            unit{j}.(['OSI',strrep(levelNames{l},'.','_')]) = OSI;
            unit{j}.(['DSI',strrep(levelNames{l},'.','_')]) = DSI;
        end
    end
    m = [fieldnames(baseParam)' fieldnames(unit{j})'; ...
        struct2cell(baseParam)' struct2cell(unit{j})'];
    mergedParam = struct(m{:});
    
    
    for f = 1:length(plotFun)
        
        switch plotFun{f}
            case 'plotTuningCurve'
                nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j));
                plotTuningCurve(groupingValues, data, groupingFactor, levelNames);
                nf.suffix = 'tc';
                nf.dress('Params', mergedParam);
                nf.print(path, filename);
                nf.close();
                
            case 'plotMap'
                if ~contains(groupingFactor, 'position', 'IgnoreCase', true)
                    error('No position data for RF mapping');
                end
                x = groupingValues(:,1);
                y = groupingValues(:,2);
                unit{j}.map.x = x;
                unit{j}.map.y = y;
                unit{j}.map.v = zeros(length(x),size(conditions,3));
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
                    v = mF0(:,l) - mPre(:,l);
                    unit{j}.map.v(:,l) = v;
                    
                    % Plot
                    plotMap(x,y,v,groupingFactor,'image');
                    nf.suffix = 'map';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            case 'plotRastergram'
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
                    
                    % Collect rasters
                    dur = nanmean(diff(ex.CondTest.CondOn));
                    stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
                    rasters = cell(1,size(conditions,1));
                    for c = 1:size(conditions,1)
                        t0 = ex.CondTest.CondOn(conditions(c,:,l)) - offset;
                        t1 = t0 + dur;
                        trials = cell(1,length(t0));
                        for t = 1:length(t0)
                            trials{t} = spikeTimes(spikes, t0(t), t1(t)) - offset;
                        end
                        rasters{c} = trials;
                    end
                    events = [-offset stimDur dur-offset];
                    
                    plotRastergram(rasters, events, labels, defaultColor(uuid(j)));
                    nf.suffix = 'raster';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            case 'plotPsth'
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
                    
                    % Collect histograms
                    dur = nanmean(diff(ex.CondTest.CondOn));
                    stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
                    nBins = round(dur/binSize);
                    hists = zeros(size(conditions,1),nBins);
                    for c = 1:size(conditions,1)
                        t0 = ex.CondTest.CondOn(conditions(c,:,l)) - offset;
                        t1 = t0 + dur;
                        trials = zeros(length(t0), nBins);
                        for t = 1:length(t0)
                            trials(t, :) = psth(spikes, t0(t), t1(t), nBins, normFun);
                        end
                        hists(c,:) = mean(trials,1)./binSize/ex.secondperunit;
                    end
                    
                    edges = -offset:dur/(nBins):dur-offset;
                    centers = edges(1:end-1) + diff(edges)/2;
                    events = [-offset stimDur dur-offset];
                    
                    plotPsth(centers, hists, events, labels, defaultColor(uuid(j)))
                    nf.suffix = 'psth';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            otherwise
                continue;
        end
        
        
    end
    
end

result.unit = [unit{:}];

end