function plotWaveforms(figuresPath, fileName, Electrodes)
%PlotWaveforms plots mean waveform for each unit

% helper function to fill std error
fill_between_lines = @(X,Y1,Y2,C) patch( [X fliplr(X)],  [Y1 fliplr(Y2)], ...
    1, 'FaceColor', C, 'EdgeColor', 'none');

nUnits = cellfun(@(x) length(unique(x(:,2))), Electrodes.waveforms);
colors = makeDefaultColors(nUnits);

for ch = 1:size(Electrodes,1)
    
    elecNo = Electrodes.number(ch);
    elecDir = sprintf('Ch%02d', elecNo);
    
    % Waveforms could be empty for this channel
    wf = Electrodes.waveforms{ch};
    if isempty(wf)
        disp(['No waveforms in ch ',num2str(elecNo)]);
        continue;
    end
    
    units = unique(wf(:,2));
    numSpikes = [];
    
    % Plot the waveforms
    lines = [];
    
    fig1 = figure('Visible','off');hold on;
    for t = 1:length(units)
        wf_unit = wf(wf(:,2) == units(t),3:end);
        numSpikes(t) = size(wf_unit,1);
        x = 1/30000:1/30000:(1/30000)*size(wf_unit,2);
        wf_mean = mean(wf_unit,1);
        wf_std = std(wf_unit,0,1);
        wf_sem = wf_std/sqrt(size(wf_unit,1));

        h = plot(x,wf_mean, 'Color',colors(t,:),'LineWidth',1.5);
        lines = [lines; h];

        x = 1/30000:1/30000:(1/30000)*size(wf_unit,2);
        %fill_between_lines(x, wf_mean-wf_sem, wf_mean+wf_sem, colors(t,:));
        fill_between_lines(x, wf_mean-wf_std, wf_mean+wf_std, colors(t,:));
    end

    alpha(0.2); % add transparency

    % Save the figure
    if ~isdir(fullfile(figuresPath,elecDir))
        mkdir(fullfile(figuresPath,elecDir));
    end
    legend(lines,arrayfun( ...
        @(x)sprintf('cell %d - %d spks', units(x), numSpikes(x)), ...
        1:length(units), 'Un', 0));
    title([fileName,' El', num2str(elecNo)],'FontSize',6);
    axis tight;
    figureName = fullfile(figuresPath,elecDir, ...
        [fileName, '_','El', num2str(elecNo),'-waveforms']);
    print(fig1,figureName,'-dpng');
    hgsave(fig1,figureName);
    close(fig1);
    disp(['Waveforms saved for ch ', num2str(elecNo)]);
end

end