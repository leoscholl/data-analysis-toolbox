function result = processSummaryData(spikeResult, lfpResult, ...
    ex, groups, path, filename, actions, varargin)
%processSummaryData

if ~iscell(actions)
    actions = {actions};
end

result.groups = groups;
result.actions = actions;
result.spike = [spikeResult{:}];
result.lfp = [lfpResult{:}];
if isempty(result.lfp)
    result = rmfield(result, 'lfp');
end
if isempty(result.spike)
    result = rmfield(result, 'spike');
    return;
end

for f = 1:length(actions)
    switch actions{f}
        case 'plotMap'
            thr = 10; % minimum firing rate (spikes/s)
            for l = 1:length(result.spike(1).levelNames)
                nf = NeuroFig(ex.ID, [], [], 'summary', result.spike(1).levelNames{l});
                label = {};
                hold on
                for e = 1:length(result.spike)
                    unit = result.spike(e).unit;
                    uu = 1; x = []; y = []; v = []; uid = [];
                    for u = 1:length(unit)
                        map = unit(u).map;
                        if max(map.v(:,l) > thr)
                            uid(uu) = unit(u).uuid;
                            x(:,uu) = map.x;
                            y(:,uu) = map.y;
                            v(:,uu) = map.v(:,l);
                            uu = uu + 1;
                        end
                    end
                    hue = rand;
                    for u = 1:length(uid)
                        m = mean(v(:,u));
                        s = std(v(:,u));
                        localThr = m+s;
                        contours = [localThr, localThr];
                        saturation = max(0.1, max(v(:,u))/max(v(:)));
                        color = hsv2rgb([hue saturation 1]);
                        label{end+1} = sprintf('elec %d unit %d',...
                            result.spike(e).electrodeid, uid(u));
                        plotMap(x(:,u), y(:,u), v(:,u), ...
                            result.spike(e).groupingFactor, 'outline', ...
                            contours, color);
                    end
                end
                legend(label);
                nf.suffix = 'map';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
    end
end