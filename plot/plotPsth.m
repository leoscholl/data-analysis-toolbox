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

% Grouping
if isempty(ex.Cond)
    histogram = mean(hists,1)./binSize;
    maxY = max(histogram);
    labels = {};
else
    conditionNames = fieldnames(ex.Cond);
    conditionName = conditionNames{1}; % Take the first one for now
    conditions = ex.Cond.(conditionName);
    conditions = reshape(conditions, length(conditions), 1);
    cond = unique(cell2mat(conditions),'rows');

    maxY = 0;
    histogram = [];
    for i = 1:length(cond)
        group = cellfun(@(x)isequal(x,cond(i,:)), ex.CondTestCond.(conditionName));
        h = hists(group,:);
        h = mean(h,1)./binSize; % spike density
        histogram(i,:) = h;
        maxY = max([maxY h]);
        if isnumeric(cond)
            labels{i} = sprintf('%s = %.3f', conditionName, cond(i,:));
        elseif iscellstr(cond)
            labels{i} = cond(i,:);
        end
    end
end

hold on;

for i = 1:size(histogram,1)
    
    % Make a two-column subplot
    if size(histogram,1) > 1
        ax = subplot(ceil(size(histogram,1)/2),2,i);
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
    if i == size(histogram,1) || i == size(histogram,1) - 1
        if i == size(histogram,1) || mod(size(histogram,1),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'spikes/s');
    
    if size(histogram,1) > 1 
        title(ax, labels{i}, 'FontWeight','Normal', 'Interpreter', 'none');
    end
    
    
    
end
hold off;
nf.suffix = 'psth';
nf.dress();
