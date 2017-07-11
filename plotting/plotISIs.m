function plotISIs(figuresPath, fileName, Results)
%PlotWaveforms plots mean waveform for each unit

Electrodes = Results.Electrodes;

centers = 0:0.0002:0.1;
nCells = cellfun(@countUnits, Results.SpikeDataAll);
colors = makeDefaultColors(nCells);

for ch = 1:size(Electrodes,1)
    
    elecNo = Electrodes.number(ch);
    elecDir = sprintf('Ch%02d', elecNo);
    
    SpikeData = Results.SpikeDataAll{elecNo};
    if isempty(SpikeData)
        continue;
    end
       
    % ISIs
    fig = figure('Visible','off');
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
    print(fig,figureName,'-dpng');
    hgsave(fig,figureName);
    close(fig);
end

end


function count = countUnits(spikes)
if isempty(spikes)
    count = 0;
else
    count = length(unique(spikes.cell));
end
end
