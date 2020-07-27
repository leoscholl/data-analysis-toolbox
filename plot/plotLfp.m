function plotLfp(time, lfp, events, labels)
%plotLfp Draw a per-condition plot of LFP data

minY = min(lfp(:));
maxY = max(lfp(:));
tickDistance = max(0.1, round((events(3)-events(1))/10, 1, 'significant')); % maximum 20 ticks

hold on;

for i = 1:length(labels)
    
    % Make a two-column subplot
    if length(labels) > 1
        ax = subplot(ceil(length(labels)/2),2,i);
    else
        ax = subplot(1,1,1);
    end

    plot(time, lfp(i,:,:));
    hold on;
    
    % XTick
    box(ax,'off');
    axis(ax, [events(1) events(3) minY ...
        maxY]);
    tick = 0:-tickDistance:events(1); % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:events(3)];
    set(ax,'XTick',tick);

    % Mark stim duration
    v = [0 minY; events(2) minY; events(2) maxY; 0 maxY];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    if i == length(labels) || i == length(labels) - 1
        if i == length(labels) || mod(length(labels),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'Voltage [mV]');
    
    if length(labels) > 1 
        title(ax, labels{i}, ...
            'FontWeight','Normal', 'Interpreter', 'none');
    end
   
    
end
hold off;

end