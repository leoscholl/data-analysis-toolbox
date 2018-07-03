function plotRastergram(rasters, events, labels, color)
%plotRastergram Draws raster plot
% rasters: (1 x nConditions) cell of (1 x nTrials) cells
% events: [trialStart stimOff trialEnd]
% labels: (1 x nConditions) cell string
% color: matlab plot color

if ~exist('color', 'var')
    color = 'k';
end

hold on;

tickDistance = max(0.1, round((events(3)-events(1))/10, 1, 'significant')); % maximum 20 ticks
for i = 1:length(rasters)
    
    % Make a two-column subplot
    if length(rasters) > 1
        ax = subplot(ceil(length(rasters)/2),2,i);
    else
        ax = subplot(1,1,1);
    end
    
    % Plot vertical lines
    spikesCond = rasters{i};
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
        plot(ax, xx, yy, 'Color', color)
    end

    % XTick
    box(ax,'off');
    axis(ax, [events(1) events(3) 0 ...
        length(spikesCond)+1]);
    tick = 0:-tickDistance:events(1); % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:events(3)];
    set(ax,'XTick',tick);

    % Mark stim duration
    v = [0 0; events(2) 0; ...
        events(2) length(spikesCond)+1; 0 length(spikesCond)+1];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    if i == length(rasters) || i == length(rasters) - 1
        if i == length(rasters) || mod(length(rasters),2) == 0
            if any(events >= 500) xlabel(ax, 'Time [ms]'), else xlabel(ax, 'Time [s]'), end;
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'Trial');
    
    if length(rasters) > 1 
        title(ax, labels{i}, 'FontWeight','Normal', 'Interpreter', 'none');
    end
    
end
hold off;
