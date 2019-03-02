function plotPsth(time, histograms, events, labels, color, style, markers)
%plotPsth Draws a PSTH
% time: x axis (1 x nTimepoints) array
% histograms: y axis (nConditions x nTimepoints) array
% events: [trialStart stimOff trialEnd]
% labels: (1 x nConditions) cell string
% color: matlab plot color
% style: 'line' or 'bar' plot
% markers: boolean to draw a box around the stimulus duration

if ~exist('style', 'var') || isempty(style)
    style = 'bar';
end

if ~exist('markers', 'var') || isempty(markers)
    markers = false;
end

hold on;
maxY = max([1; histograms(:)]);
tickDistance = max(0.1, round((events(3)-events(1))/10, 1, 'significant')); % maximum 20 ticks
for i = 1:size(histograms,1)
    
    % Make a two-column subplot
    if size(histograms,1) > 1
        ax = subplot(ceil(size(histograms,1)/2),2,i);
    else
        ax = gca;
    end
    
    % Plot histogram
    switch style
        case 'bar'
            b = bar(ax,time,histograms(i,:),'hist');
            set(b, 'FaceColor',color,...
                'EdgeColor',color);
        case 'line'
            plot(ax, time, histograms(i,:), 'color', color);
        otherwise
            error('Unknown style ''%s'', please choose either ''bar'' or ''line''', style);
    end
    axis(ax,[events(1) events(3) 0 maxY]);
    
    % XTick
    box(ax,'off');
    tick = 0:-tickDistance:events(1); % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:events(3)];
    set(ax,'XTick',tick);
    
    % Mark stim duration
    if markers
        v = [0 0; events(2) 0; ...
            events(2) maxY; 0 maxY];
        f = [1 2 3 4];
        patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
            'FaceAlpha',0.1,'EdgeColor','none');
    end
    
    % For subplots, only label the bottommost axes
    if i == size(histograms,1) || i == size(histograms,1) - 1
        if i == size(histograms,1) || mod(size(histograms,1),2) == 0
            if any(events >= 500) xlabel(ax, 'Time [ms]'), else xlabel(ax, 'Time [s]'), end;
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'spikes/s');
    
    if size(histograms,1) > 1
        title(ax, labels{i}, 'FontWeight','Normal', 'Interpreter', 'none');
    end
    
    
    
end
hold off;
