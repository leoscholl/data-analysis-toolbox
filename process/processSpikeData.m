function result = processSpikeData(spike, ex, groups, path, filename, actions, varargin)
%processSpikeData Plot spiking data with the given list of plotting functions

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('offset', 0.02/ex.secondperunit);
p.addParameter('binSize', 0.02/ex.secondperunit);
p.addParameter('normFun', []);
p.addParameter('ignoreNonResponsive', false);
p.addParameter('groupTuningCurves', false);
p.addParameter('removeOutliers', false);
if isstruct(varargin)
    p.parse(varargin);
else
    p.parse(varargin{:});
end

if ~iscell(actions)
    actions = {actions};
end

% Unpack inputs
groupingFactor = groups.factor;
groupingValues = groups.values;
conditions = groups.conditions;
levelNames = groups.levelNames;
labels = groups.labels;
offset = p.Results.offset;
binSize = p.Results.binSize;
normFun = p.Results.normFun;
ignoreNonResponsive = strcmp('true', p.Results.ignoreNonResponsive) || ...
    (islogical(p.Results.ignoreNonResponsive) && p.Results.ignoreNonResponsive);
groupTuningCurves = strcmp('true', p.Results.groupTuningCurves) || ...
    (islogical(p.Results.groupTuningCurves) && p.Results.groupTuningCurves);
removeOutliers = strcmp('true', p.Results.removeOutliers) || ...
    (islogical(p.Results.removeOutliers) && p.Results.removeOutliers);


result = [];

% Prepare annotation parameters
baseParam = {'Ori', 'Diameter', 'Size', 'Color', 'Position', ...
    'Contrast', 'SpatialFreq', 'TemporalFreq', 'GratingType'};
baseParam = NeuroAnalysis.Base.getstructfields(ex.EnvParam, ...
    baseParam);
if isempty(baseParam)
    baseParam = struct;
end

% Per-electrode figures
for f = 1:length(actions)
    switch actions{f}
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
    if isempty(spikes)
        continue;
    end
    
    unit{j}.Subject_ID = ex.Subject_ID;
    unit{j}.RecordSession = ex.RecordSession;
    unit{j}.RecordSite = ex.RecordSite;
    unit{j}.electrodeid = spike.electrodeid;
    unit{j}.uid = uuid(j);
    
    test = struct;
    clearvars param
    for l = 1:size(conditions,3)
        param(l) = struct;
    end
    
    % Extract spikes
    nct = length(ex.CondTest.CondIndex);
    pre = cell(nct, 1);
    peri = pre; post = pre; rasters = pre;
    for t = 1:nct
        
        % Pre-stimulus
        t1 = ex.CondTest.CondOn(t) + offset;
        t0 = t1 - ex.PreICI;
        pre{t} = spikeTimes(spikes, t0, t1).*ex.secondperunit;
        
        % Peri-stimulus
        t0 = ex.CondTest.CondOn(t) + offset;
        t1 = ex.CondTest.CondOff(t) + offset;
        peri{t} = spikeTimes(spikes, t0, t1).*ex.secondperunit;
        
        % Post-stimulus
        t0 = ex.CondTest.CondOff(t) + offset;
        t1 = t0 + ex.SufICI;
        post{t} = spikeTimes(spikes, t0, t1).*ex.secondperunit;
        
        % Raster
        t0 = ex.CondTest.CondOn(t) - ex.PreICI;
        t1 = ex.CondTest.CondOff(t) + ex.SufICI;
        rasters{t} = (spikeTimes(spikes, t0, t1) - ex.PreICI).*ex.secondperunit;
        
    end
    
    outliers = false(nct,1);
    conditions = groups.conditions;
    if removeOutliers
        spk = cellfun(@length, rasters);
        if median(spk) == 0
            outliers = isoutlier(spk, 'mean');
        else
            outliers = isoutlier(spk, 'median');
        end
        nct = sum(~outliers);
        conditions = conditions(:,~outliers,:);
        pre = pre(~outliers);
        peri = peri(~outliers);
        post = post(~outliers);
        rasters = rasters(~outliers);
    end
    
    unit{j}.outliers = outliers;
    unit{j}.pre = pre;
    unit{j}.peri = peri;
    unit{j}.post = post;
    unit{j}.rasters = rasters;
    unit{j}.offset = offset*ex.secondperunit;

    % Calculate F0 and F1 for pre- and peri-stimulus intervals
    if isfield(ex.CondTestCond, 'TemporalFreq')
        tf = cell2mat(ex.CondTestCond.TemporalFreq);
    elseif isfield(baseParam, 'TemporalFreq')
        tf = repmat(baseParam.TemporalFreq, 1, nct);
    else
        tf = nan(1, nct);
    end
    ts = ones(length(pre),1)*ex.PreICI*ex.secondperunit;
    pref0 = f0f1(pre, ts, tf);
    ts = (ex.CondTest.CondOff-ex.CondTest.CondOn).*ex.secondperunit;
    [perif0, perif1] = f0f1(peri, ts, tf);
    ts = ones(length(pre),1)*ex.SufICI*ex.secondperunit;
    postf0 = f0f1(post, ts, tf);
    unit{j}.pref0 = pref0;
    unit{j}.perif0 = perif0;
    unit{j}.perif1 = perif1;
    unit{j}.postf0 = postf0;
    
    % Calculate OSI and DSI for orientation stimuli
    if contains(ex.ID, 'Ori') && ischar(groupingFactor) && ...
            contains(groupingFactor, 'Ori')
        theta = cellfun(@deg2rad, ex.CondTestCond.(groupingFactor));
        for l = 1:size(conditions,3)
            level = any(conditions(:,:,l),1);
            [OSI, DSI] = osi(perif0(level), theta(level));
            param(l).OSI = OSI;
            param(l).DSI = DSI;
            test.osi(1,l) = OSI;
            test.dsi(1,l) = DSI;
        end
    end
    
    % Make a more readable title
    title = ex.ID;
    if contains(title, 'Laser') && isfield(ex, 'Param')
        if isfield(ex.Param, 'Laser'); title = [title, ' ', ex.Param.Laser]; end
        if isfield(ex.Param, 'Laser2'); title = [title, ' ', ex.Param.Laser2]; end
    end

    % Plotting
    for f = 1:length(actions)
        
        switch actions{f}
            case 'plotTuningCurve'
                data = [];
                if iscell(groupingValues) || size(groupingValues,2) > 1
                    cond = 1:size(groupingValues,1);
                    factor = 'condition';
                else
                    cond = groupingValues;
                    factor = groupingFactor;
                end
                if size(conditions,3) > 1 && groupTuningCurves
                    nf = NeuroFig(title, spike.electrodeid, uuid(j));
                    data.F0 = perif0;
                    plotTuningCurve(cond, data, conditions, factor, levelNames);
                    nf.suffix = 'tc';
                    nf.dress('Params', baseParam);
                    nf.print(path, filename);
                    nf.close();
                else
                    for l = 1:size(conditions,3)
                        nf = NeuroFig(title, spike.electrodeid, uuid(j), levelNames{l});
                        data.F0 = perif0;
                        data.F1 = perif1;
                        data.pre = pref0;
                        plotTuningCurve(cond, data, conditions(:,:,l), factor, []);
                        nf.suffix = 'tc';
                        m = [fieldnames(baseParam)' fieldnames(param(l))'; ...
                            struct2cell(baseParam)' struct2cell(param(l))'];
                        mergedParam = struct(m{:});
                        nf.dress('Params', mergedParam);
                        nf.print(path, filename);
                        nf.close();
                    end
                end
                
            case 'plotMap'
                if ~contains(groupingFactor, 'position', 'IgnoreCase', true)
                    error('No position data for RF mapping');
                end
                x = groupingValues(:,1);
                y = groupingValues(:,2);
                test.map.x = x;
                test.map.y = y;
                test.map.v = zeros(length(x),size(conditions,3));
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(title, spike.electrodeid, uuid(j), levelNames{l});
                    test.map.v(:,l) = perCondition(perif0 - pref0, conditions(:,:,l));
                    
                    % Plot
                    clim = max(abs(test.map.v(:,l)));
                    plotMap(x,y,test.map.v(:,l),groupingFactor,'image', [-clim clim]);
                    nf.suffix = 'map';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                    
                    

                end
                
            case 'plotRastergram'
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(title, spike.electrodeid, uuid(j), levelNames{l});

                    % Group rasters
                    stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
                    rasterGroups = cell(1,size(conditions,1));
                    for c = 1:size(conditions,1)
                        rasterGroups{c} = rasters(conditions(c,:,l));
                    end

                    valid = ~cellfun(@isempty,rasterGroups);
                    events = [-ex.PreICI stimDur stimDur+ex.SufICI]*ex.secondperunit;
                    
                    plotRastergram(rasterGroups(valid), events, labels(valid), defaultColor(uuid(j)));
                    nf.suffix = 'raster';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            case 'plotPsth'
                for l = 1:size(conditions,3)
                    
                    nf = NeuroFig(title, spike.electrodeid, uuid(j), levelNames{l});
                    
                    % Collect histograms with fixed duration
                    stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
                    dur = ex.PreICI + stimDur + ex.SufICI;
                    nBins = round(dur/binSize);
                    hists = zeros(size(conditions,1),nBins);
                    for c = 1:size(conditions,1)
                        co = ex.CondTest.CondOn(~outliers);
                        t0 = co(conditions(c,:,l)) - ex.PreICI;
                        t1 = t0 + dur;
                        trials = zeros(length(t0), nBins);
                        for t = 1:length(t0)
                            trials(t, :) = psth(spikes, t0(t), t1(t), nBins, normFun);
                        end
                        hists(c,:) = mean(trials,1)./binSize/ex.secondperunit;
                    end
                    valid = all(~isnan(hists),2);
                    
                    edges = -ex.PreICI:dur/(nBins):dur-ex.PreICI;
                    centers = (edges(1:end-1) + diff(edges)/2)*ex.secondperunit;
                    events = [-ex.PreICI stimDur dur-ex.PreICI]*ex.secondperunit;
                    
                    plotPsth(centers, hists(valid,:), events, labels(valid), defaultColor(uuid(j)), 'line')
                    nf.suffix = 'psth';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            case 'plotPolar'
                for l = 1:size(conditions,3)
                    nf = NeuroFig(title, spike.electrodeid, uuid(j), levelNames{l});
                    plotPolar(groupingValues, perif0, conditions(:,:,l));
                    nf.suffix = 'polar';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            otherwise
                continue;
        end
        
        
    end
    
    unit{j}.(ex.ID) = {test};
    
end

result = [unit{:}];

end

function h = isresponsive(pre, post, alpha)

if ~exist('alpha', 'var') || isempty(alpha)
    alpha = 0.01;
end

h = 0;
valid = ~isnan(pre) & ~isnan(post);
pre = pre(valid);
post = post(valid);
if ~isempty(pre) && ~isempty(post)
    h = ttest(pre, post, 'alpha', alpha);
    if isnan(h)
        h = 0;
    end
end
end