function result = processSpikeData(spike, ex, groups, path, filename, actions, varargin)
%processSpikeData Plot spiking data with the given list of plotting functions

p = inputParser;
p.addParameter('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.addParameter('latency', 0.05/ex.secondperunit);
p.addParameter('binSize', 0.02/ex.secondperunit);
p.addParameter('normFun', []);
p.addParameter('ignoreNonResponsive', false);
p.addParameter('groupTuningCurves', false);
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
latency = p.Results.latency;
binSize = p.Results.binSize;
normFun = p.Results.normFun;
ignoreNonResponsive = strcmp('true', p.Results.ignoreNonResponsive) || ...
    (islogical(p.Results.ignoreNonResponsive) && p.Results.ignoreNonResponsive);
groupTuningCurves = strcmp('true', p.Results.groupTuningCurves) || ...
    (islogical(p.Results.groupTuningCurves) && p.Results.groupTuningCurves);

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
    peri = pre;
    for t = 1:nct
        
        % Pre-stimulus
        t1 = ex.CondTest.CondOn(t) + latency;
        t0 = t1 - offset;
        pre{t} = spikeTimes(spikes, t0, t1).*ex.secondperunit;
        
        % Peri-stimulus
        t0 =  ex.CondTest.CondOn(t) + latency;
        t1 = ex.CondTest.CondOff(t) + latency;
        peri{t} = spikeTimes(spikes, t0, t1).*ex.secondperunit;
    end
    unit{j}.pre = pre;
    unit{j}.peri = peri;

    % Calculate F0 and F1 for pre- and peri-stimulus intervals
    if isfield(ex.CondTestCond, 'TemporalFreq')
        tf = cell2mat(ex.CondTestCond.TemporalFreq);
    elseif isfield(baseParam, 'TemporalFreq')
        tf = repmat(baseParam.TemporalFreq, 1, nct);
    else
        tf = nan(1, nct);
    end
    ts = ones(length(pre),1)*offset*ex.secondperunit;
    pref0 = f0f1(pre, ts, tf);
    ts = (ex.CondTest.CondOff-ex.CondTest.CondOn).*ex.secondperunit;
    [perif0, perif1] = f0f1(peri, ts, tf);
    unit{j}.pref0 = pref0;
    unit{j}.perif0 = perif0;
    unit{j}.perif1 = perif1;
    
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
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j));
                    data.F0 = perif0;
                    plotTuningCurve(cond, data, conditions, factor, levelNames);
                    nf.suffix = 'tc';
                    nf.dress('Params', baseParam);
                    nf.print(path, filename);
                    nf.close();
                else
                    for l = 1:size(conditions,3)
                        nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
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
                    
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
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
                    valid = ~cellfun(@isempty,rasters);
                    events = [-offset stimDur dur-offset];
                    
                    plotRastergram(rasters(valid), events, labels(valid), defaultColor(uuid(j)));
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
                    valid = all(~isnan(hists),2);
                    
                    edges = -offset:dur/(nBins):dur-offset;
                    centers = edges(1:end-1) + diff(edges)/2;
                    events = [-offset stimDur dur-offset];
                    
                    plotPsth(centers, hists(valid,:), events, labels(valid), defaultColor(uuid(j)))
                    nf.suffix = 'psth';
                    nf.dress();
                    nf.print(path, filename);
                    nf.close();
                end
                
            case 'plotPolar'
                for l = 1:size(conditions,3)
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
                    plotPolar(groupingValues, data.f0(:,:,l));
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