function plotISIs(resultsPath, fileName, Results)
%PlotWaveforms plots mean waveform for each unit

Electrodes = Results.Electrodes;

centers = 0:0.0005:0.1;
nUnits = cellfun(@(x) length(unique(x.u)), Results.SpikeDataAll);
colors = makeDefaultColors(nUnits);

for ch = 1:size(Electrodes,1)
    
    elecNo = Electrodes.number(ch);
    elecDir = sprintf('Ch%02d', elecNo);
    
    SpikeData = Results.SpikeDataAll{elecNo};
       
    % ISIs
    figure('Visible','off');
    units = unique(SpikeData.u);
    for u = 1:length(units)
        unit = units(u);
        subplot(ceil(length(units)/2),2,u)
        isi = SpikeData(SpikeData.u == unit,:).isi;
        isi = vertcat(isi{:});
        histogram(isi,centers,'FaceColor',colors(u,:),'EdgeColor','none');
        xlim([0,0.05]);
        ylim('auto');
        xticks((0:0.01:0.1));
        xticklabels(1000*(0:0.01:0.1));
        xlabel('inter-spike interval (ms)');
        ylabel('number of invervals');
        set(gca,'FontSize',6);
        title(sprintf('Unit %d', unit));
    end
  

    figureName = fullfile(resultsPath,elecDir,[fileName, '_','El', num2str(elecNo),'-isi']);
    print(gcf,figureName,'-dpng');
    hgsave(gcf,figureName);
    close;
    disp(['ISIs saved for ', elecDir]);
end

end

