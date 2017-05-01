function PlotWaveforms(ResultsPath, FileName, Waveforms, ElectrodeNames)
%PlotWaveforms plots mean waveform for each unit

for ch = 1:length(ElectrodeNames)
    
    Elec = ElectrodeNames{ch};
    ElecNo = Elec(strfind(Elec,'c')+1:end);
    ElecDir = ['Ch',ElecNo'];
       
    % Waveforms could be empty for this channel
    wf_ch =  Waveforms(Waveforms(:,1) == ch, :);
    if isempty(wf_ch)
        disp(['No waveforms in ch ',ElecNo]);
    end
    
    Temps = unique(wf_ch(:,2));
    
    colors = hsv(max(10,length(Temps)));
    fig1 = figure(10);hold on;
    set(gcf,'Visible','off');
    for t = 1:length(Temps)
        wf = wf_ch(wf_ch(:,1) == ch & wf_ch(:,2) == Temps(t),3:end);
        plot(1/30000:1/30000:(1/30000)*size(wf,2),mean(wf),...
            'Color',colors(t,:),'LineWidth',1.5);
    end
    if ~isdir([ResultsPath,'Ch',ElecNo])
        mkdir([ResultsPath,'Ch',ElecNo]);
    end
    legend({num2str(Temps)});
    title([FileName,' El', ElecNo],'FontSize',6);axis tight;
    FigureName = fullfile(ResultsPath,ElecDir,[FileName, '_','El', ElecNo,'-waveforms']);
    print(fig1,FigureName,'-dpng');
    hgsave(fig1,FigureName);
    close;
    disp(['Waveforms saved for ch ', ElecNo]);
end

end

