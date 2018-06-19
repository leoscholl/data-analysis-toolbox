function plotTimeFreq(time, freq, data, events, labels, zlabel)
%plotTimeFreq

tickDistance = max(0.1, round((events(3)-events(1))/10, 1, 'significant')); % maximum 20 ticks

hold on;
maxC = max([1; data(:)]);

for i = 1:length(labels)
    
    % Make a two-column subplot
    if length(labels) > 1
        ax = subplot(ceil(length(labels)/2),2,i);
    else
        ax = gca;
    end

    imagesc(time, freq, data(:,:,i));
    set(gca, 'ydir', 'normal')
    ylim([min(freq) max(freq)]);
    colormap jet; caxis([0 maxC]); 
    c = colorbar;
    if exist('zlabel', 'var') && ~isempty(zlabel)
        c.Label.String = zlabel;
    end
    
    % XTick
    xlim([events(1) events(3)]);
    box(ax,'off');
    tick = 0:-tickDistance:events(1); % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:events(3)];
    set(ax,'XTick',tick);

    % For subplots, only label the bottommost axes
    if i == length(labels) || i == length(labels) - 1
        if i == length(labels) || mod(length(labels),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'Freq [Hz]');
    
    if length(labels) > 1 
        title(ax, labels{i}, ...
            'FontWeight','Normal', 'Interpreter', 'none');
    end
   
    
end
hold off;

end