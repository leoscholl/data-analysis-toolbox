function plotISIs(figuresPath, fileName, Results)
%PlotWaveforms plots mean waveform for each unit

Electrodes = Results.Electrodes;

centers = 0:0.0005:0.1;
nCells = cellfun(@(x) length(unique(x.cell)), Results.SpikeDataAll);
colors = makeDefaultColors(nCells);

for ch = 1:size(Electrodes,1)
    
    elecNo = Electrodes.number(ch);
    elecDir = sprintf('Ch%02d', elecNo);
    
    SpikeData = Results.SpikeDataAll{elecNo};
       
    % ISIs
    figure('Visible','off');
    cells = unique(SpikeData.cell);
    for u = 1:length(cells)
        unit = cells(u);
        h = subplot(ceil(length(cells)/2),2,u);
        hold on;
        isi = SpikeData(SpikeData.cell == unit,:).isi;
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
        
        % minimum refractory period
        str = sprintf('min isi = %3.1fms\nmean isi = %3.1fms', ...
            min(isi)*1000, mean(isi)*1000);
        xl = xlim(h);
        xPos = xl(1) + diff(xl)/2;
        yl = ylim(h);
        yPos = yl(2) - diff(yl)/4;
        t = text(xPos, yPos, str, 'Parent', h);
        set(t, 'FontSize', 6);
        hold off;
    end
  

    figureName = fullfile(figuresPath,elecDir,[fileName, '_','El', num2str(elecNo),'-isi']);
    print(gcf,figureName,'-dpng');
    hgsave(gcf,figureName);
    close;
    disp(['ISIs saved for ', elecDir]);
end

end

