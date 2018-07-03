function result = processSpikeData(spike, ex, groups, path, filename, actions, varargin)
%processSpikeData Plot spiking data with the given list of plotting functions

p = inputParser;
p.addParameter('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.addParameter('binSize', 0.02/ex.secondperunit);
p.addParameter('normFun', []);
p.addParameter('ignoreNonResponsive', false);
p.addParameter('groupTuningCurves', true);
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
    param = struct;

    % Calculate MFR and F1
    pre = nan(length(ex.CondTest.CondIndex), 1);
    f0 = pre; f1 = pre; sp = pre;
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
        sp(t) = length(spikeTimes(spikes, t0, t1));
    end
    
    % Fix time units
    if ex.secondperunit ~= 1
        pre = pre/ex.secondperunit;
        f0 = f0/ex.secondperunit;
        f1 = f1/ex.secondperunit;
    end
    
    % Organize MFR into proper conditions
    mF0 = nan(size(groupingValues,1), size(conditions,3));
    mPre = nan(size(groupingValues,1), size(conditions,3));
    fano = nan(size(groupingValues,1), size(conditions,3));
    response = false(size(groupingValues,1), size(conditions,3));
    data = [];
    for l = 1:size(conditions,3)
        for i = 1:size(groupingValues,1)
            data.f0{i,:,l} = f0(conditions(i,:,l))';
            data.f1{i,:,l} = f1(conditions(i,:,l))';
            data.pre{i,:,l} = pre(conditions(i,:,l))';
            mF0(i,l) = nanmean(f0(conditions(i,:,l)));
            mPre(i,l) = nanmean(pre(conditions(i,:,l)));
            fano(i,l) = nanvar(sp(conditions(i,:,l)))/nanmean(sp(conditions(i,:,l)));
            response(i,l) = isresponsive(pre(conditions(i,:,l)),f0(conditions(i,:,l)));
        end
        
        % Save optimal condition at each level
        [~, i] = max(mF0(:,l));
        param(l).maxF0 = groupingValues(i,:);
        test.maxF0{l} = groupingValues(i,:);
    end
    
    % Do a basic test of responsiveness
    if ignoreNonResponsive && ~any(response(:))
        unit{j} = [];
        continue;
    end
    
    % Store mfr data
    test.data = data;
    test.data.fano = fano;
    
    % Calculate OSI and DSI for orientation stimuli
    if contains(ex.ID, 'Ori') && contains(groupingFactor, 'Ori')
        theta = cellfun(@deg2rad, ex.CondTestCond.(groupingFactor));
        for l = 1:size(conditions,3)
            level = any(conditions(:,:,l),1);
            [OSI, DSI] = osi(f0(level), theta(level));
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
                if groupTuningCurves                    
                    nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j));
                    if size(conditions,3) > 1
                        data = rmfield(data, {'f1', 'pre'});
                    end
                    plotTuningCurve(groupingValues, data, groupingFactor, levelNames);
                    nf.suffix = 'tc';
                    nf.dress('Params', baseParam);
                    nf.print(path, filename);
                    nf.close();
                else
                    for l = 1:size(conditions,3)
                        nf = NeuroFig(ex.ID, spike.electrodeid, uuid(j), levelNames{l});
                        leveldata = struct;
                        fields = fieldnames(data);
                        for k = 1:length(fields)
                            leveldata.(fields{k}) = data.(fields{k})(:,:,l);
                        end
                        plotTuningCurve(groupingValues, leveldata, groupingFactor, []);
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
                    v = mF0(:,l) - mPre(:,l);
                    test.map.v(:,l) = v;
                    
                    % Plot
                    clim = max(abs(v));
                    plotMap(x,y,v,groupingFactor,'image', [-clim clim]);
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