function result = processLfpData(data, fs, time, electrodeid, ...
    ex, path, filename, plotFun, varargin)
%processLfpData Plot lfp data with the given list of plotting functions

p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.parse(varargin{:});
offset = p.Results.offset;

if ~iscell(plotFun)
    plotFun = {plotFun};
end

result = struct;
result.electrodeid = electrodeid;

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

dur = nanmean(diff(ex.CondTest.CondOn));
stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
samples = ceil(dur*fs*ex.secondperunit);
x = linspace(-offset, dur-offset, samples);
lfp = zeros(length(ex.CondTest.CondIndex), samples);
for t = 1:length(ex.CondTest.CondIndex)
    t0 = ex.CondTest.CondOn(t) - offset;
    t1 = t0 + dur;
    if isnan(t0)
        continue;
    end
    sub = subvec(data, t0*ex.secondperunit, t1*ex.secondperunit, fs, time);
    lfp(t,1:min(length(sub),samples)) = sub(1:min(length(sub),samples))';
end
events = [-offset stimDur dur-offset];

% Organize MFR into proper conditions
lfpMean = nan(size(groupingValues,1), size(lfp,2), size(conditions,3));
for l = 1:size(conditions,3)
    for i = 1:size(conditions,1)
        lfpMean(i,:,l) = mean(lfp(conditions(i,:,l),:),1);
    end
    % Save optimal condition at each level
    [~, i] = max(max(abs(lfpMean(:,:,l)),[],2));
    result.(['maxDelta',strrep(levelNames{l},'.','_')]) = groupingValues(i,:);
end

for f = 1:length(plotFun)
    switch plotFun{f}
        case 'plotLfp'
            for l = 1:size(conditions,3)
                
                nf = NeuroFig(ex.ID, electrodeid, [], levelNames{l});
                plotLfp(x, lfpMean(:,:,l), events, labels);
                nf.suffix = 'lfp';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
        case 'plotLfpPowers'
            nf = NeuroFig(ex.ID, electrodeid, []);
            plotLfpPowers(data, fs);
            nf.suffix = 'lfp_power';
            nf.dress();
            nf.print(path, filename);
            nf.close();
        otherwise
            continue;
    end
end