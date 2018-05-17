function result = processSummaryData(spikeResult, lfpResult, ...
    ex, path, filename, plotFun)
%processSummaryData

if ~iscell(plotFun)
    plotFun = {plotFun};
end

result.spike = [spikeResult{:}];
result.lfp = [lfpResult{:}];
if isempty(result.lfp)
    result = rmfield(result, 'lfp');
end
if isempty(result.spike)
    result = rmfield(result, 'spike');
    return;
end

for f = 1:length(plotFun)
    switch plotFun{f}
        case 'plotMap'
            for l = 1:length(result.spike(1).levelNames)
                nf = NeuroFig(ex.ID, [], [], 'summary', result.spike(1).levelNames{l});
                hold on
                colors = jet(sum(arrayfun(@(x)length(x.unit),result.spike)));
                c = 1;
                for e = 1:length(result.spike)
                    unit = result.spike(e).unit;
                    for u = 1:length(unit)
                        map = unit(u).map;
                        yrange = [8 16 32]; % arbitrary
                        label = sprintf('e%du%d',result.spike(e).electrodeid, ...
                            unit(u).uuid);
                        plotMap(map.x, map.y, map.v(:,l), ...
                            result.spike(e).groupingFactor, 'outline', ...
                            yrange, label, colors(c,:));
                        c = c + 1;
                    end
                end
                nf.suffix = 'map';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
    end
end

