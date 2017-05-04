function plotWaveforms(resultsPath, fileName, Electrodes)
%PlotWaveforms plots mean waveform for each unit

for ch = 1:size(Electrodes,1)
    
    elecNo = Electrodes.number(ch);
    elecDir = sprintf('Ch%02d', elecNo);
       
    % Waveforms could be empty for this channel
    wf = Electrodes.waveforms{ch};
    if isempty(wf)
        disp(['No waveforms in ch ',elecNo]);
    end
    
    units = unique(wf(:,2));
    
    colors = hsv(max(10,length(units)));
    fig1 = figure(10);hold on;
    set(gcf,'Visible','off');
    for t = 1:length(units)
        wf_unit = wf(wf(:,2) == units(t),3:end);
        wf_mean = mean(wf_unit);
        wf_std = std(wf_unit);
        plot(1/30000:1/30000:(1/30000)*size(wf_unit,2),wf_mean,...
            'Color',colors(t,:),'LineWidth',1.5);
        plot(1/30000:1/30000:(1/30000)*size(wf_unit,2),wf_mean+wf_std,...
            'LineSpec','--','Color',colors(t,:),'LineWidth',1);
        plot(1/30000:1/30000:(1/30000)*size(wf_unit,2),wf_mean-wf_std,...
            'LineSpec','--','Color',colors(t,:),'LineWidth',1);
    end
    if ~isdir([resultsPath,'Ch',ElecNo])
        mkdir([resultsPath,'Ch',ElecNo]);
    end
    legend({num2str(units)});
    title([fileName,' El', ElecNo],'FontSize',6);
    axis tight;
    figureName = fullfile(resultsPath,elecDir,[fileName, '_','El', elecNo,'-waveforms']);
    print(fig1,figureName,'-dpng');
    hgsave(fig1,figureName);
    close;
    disp(['Waveforms saved for ch ', ElecNo]);
end

end

