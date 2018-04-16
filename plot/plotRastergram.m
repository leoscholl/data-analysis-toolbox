function [ nf ] = plotRastergram(nf, ex, spikes, uid, varargin)
%PlotRasters opens and draws raster plot

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.parse(varargin{:});
offset = p.Results.offset;

% Collect rasters
dur = nanmean(diff(ex.CondTest.CondOn));
tickDistance = max(0.1, round(dur/10, 1, 'significant')); % maximum 20 ticks
stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
for t = 1:length(ex.CondTest.CondIndex)
    t0 = ex.CondTest.CondOn(t) - offset;
    t1 = t0 + dur;
    raster{t} = spikeTimes(spikes, t0, t1) - offset;
end

% Grouping
if isempty(ex.Cond)
    groups = true(1,length(ex.CondTest.CondIndex));
    labels = {};
else
    conditionNames = fieldnames(ex.Cond);
    conditionName = conditionNames{1}; % Take the first one for now
    conditions = ex.Cond.(conditionName);
    conditions = reshape(conditions, length(conditions), 1);
    cond = unique(cell2mat(conditions),'rows');

    groups = false(size(cond,1),length(ex.CondTest.CondIndex));
    for i = 1:size(cond,1)
        group = cellfun(@(x)isequal(x,cond(i,:)), ex.CondTestCond.(conditionName));
        groups(i,:) = group';
        if isnumeric(cond)
            labels{i} = sprintf('%s = %.3f', conditionName, cond(i,:));
        elseif iscellstr(cond)
            labels{i} = cond(i,:);
        end
    end
end
    

hold on;

for i = 1:size(groups,1)
    
    % Make a two-column subplot
    if size(groups,1) > 1
        ax = subplot(ceil(size(groups,1)/2),2,i);
    else
        ax = subplot(1,1,1);
    end
    
    % Plot vertical lines
    spikesCond = raster(groups(i,:));
    allTrials = [];
    allSpikes = [];
    for r=1:length(spikesCond)
        allSpikes = [allSpikes spikesCond{r}];
        allTrials = [allTrials repmat(r, 1, length(spikesCond{r}))];
    end
    nSpikes = length(allSpikes);
    xx=ones(3*nSpikes,1)*nan;
    yy=ones(3*nSpikes,1)*nan;
    if ~isempty(allSpikes)
        yy(1:3:3*nSpikes)=allTrials;
        yy(2:3:3*nSpikes)=allTrials+1;
        
        %scale the time axis to ms
        xx(1:3:3*nSpikes)=allSpikes;
        xx(2:3:3*nSpikes)=allSpikes;
        plot(ax, xx, yy, 'Color', defaultColor( uid ))
    end

    % XTick
    box(ax,'off');
    axis(ax, [-offset dur-offset 0 ...
        length(spikesCond)+1]);
    tick = 0:-tickDistance:-offset; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:dur-offset];
    
    % Mark stim duration
    set(ax,'XTick',tick);
    v = [0 0; stimDur 0; ...
        stimDur length(spikesCond)+1; 0 length(spikesCond)+1];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    if i == size(groups,1) || i == size(groups,1) - 1
        if i == size(groups,1) || mod(size(groups,1),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'Trial');
    
    if size(groups,1) > 1 
        title(ax, labels{i}, 'FontWeight','Normal', 'Interpreter', 'none');
        
    end
    
    
    
end
hold off;
nf.suffix = 'raster';
nf.dress();
