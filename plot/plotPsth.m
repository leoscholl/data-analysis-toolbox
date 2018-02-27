function [ nf ] = plotPsth(nf, ex, spikes, uid, varargin)
%PlotRasters opens and draws raster plot

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.addOptional('binSize', 0.02/ex.secondperunit);
p.addOptional('normFun', []);
p.parse(varargin{:});
offset = p.Results.offset;
binSize = p.Results.binSize;
normFun = p.Results.normFun;

% Make psth
dur = nanmean(diff(ex.CondTest.CondOn));
stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
nBins = round(dur/binSize);
for t = 1:length(ex.CondTest.CondIndex)
    t0 = ex.CondTest.CondOn(t) - offset;
    t1 = t0 + dur;
    hists(t, :) = psth(spikes, t0, t1, nBins, normFun);
end
edges = -offset:dur/(nBins):dur-offset;
centers = edges(1:end-1) + diff(edges)/2;
tickDistance = max(0.1, round(dur/10, 1, ...
    'significant')); % maximum 20 ticks

% Gather conditions
conditionNames = fieldnames(ex.Cond);
conditionName = conditionNames{1}; % Take the first one for now
conditions = ex.Cond.(conditionName);
if iscell(conditions)
    conditions = cell2mat(conditions);
end

hold on;

% Group according to condition index
idx = unique(ex.CondTest.CondIndex);
maxY = 1;
histogram = [];
for i = 1:length(idx)
    h = hists(ex.CondTest.CondIndex == idx(i),:);
    h = mean(h,1)./binSize; % spike density
    histogram(i,:) = h;
    maxY = max([maxY h]);
end
 
for i = 1:length(idx)
    
    % Make a two-column subplot
    if length(idx) > 1
        ax = subplot(ceil(length(idx)/2),2,i);
    else
        ax = subplot(1,1,1);
    end
    
    % Plot histogram
    b = bar(ax,centers,histogram(i,:),'hist');
    set(b, 'FaceColor',defaultColor(uid),...
        'EdgeColor',defaultColor(uid));
    axis(ax,[-offset dur-offset 0 maxY]);

    % XTick
    box(ax,'off');
    tick = 0:-tickDistance:-offset; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:dur-offset];
    
    % Mark stim duration in red
    set(ax,'XTick',tick);
    v = [0 0; stimDur 0; ...
        stimDur maxY; 0 maxY];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    if i == length(idx) || i == length(idx) - 1
        if i == length(idx) || mod(length(idx),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'spikes/s');
    
    if length(idx) > 1 
        if isnumeric(conditions)
            title(ax, sprintf('%s = %.3f', conditionName, conditions(idx(i))), ...
                'FontWeight','Normal', 'Interpreter', 'none');
        elseif iscellstr(conditions)
            title(ax, sprintf('%s', conditions{idx(i)}), ...
                'FontWeight','Normal', 'Interpreter', 'none');
        end
    end
    
    
    
end
hold off;
nf.suffix = 'psth';
nf.dress();
