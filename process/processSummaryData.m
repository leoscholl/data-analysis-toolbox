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
            for l = 1:length(groups.levelNames)
                nf = NeuroFig(ex.ID, [], [], 'summary', groups.levelNames{l});
                label = {};
                hold on
                electrodes = [result.spike.electrodeid];
                uelectrodes = unique(electrodes);
                hue = linspace(0,1,length(uelectrodes)+1); % hue for each elec
                
                v = zeros(length(result.spike(1).(ex.ID){1}.map.v), length(result.spike));
                for u = 1:length(result.spike)
                    v(:,u) = result.spike(u).(ex.ID){1}.map.v(:,l);
                end
                
                for u = 1:length(result.spike)
                    electrodeid = result.spike(u).electrodeid;
                    uid = result.spike(u).uid;
                    map = result.spike(u).(ex.ID){1}.map;
  
                    m = mean(v(:,u));
                    s = std(v(:,u));
                    localThr = m+s;
                    contours = [localThr, localThr];
                    
                    % Saturation reflects relative strength of response
                    saturation = sum(abs(v(:,u)))/max(sum(abs(v),1)); 
                    color = hsv2rgb([hue(electrodeid==uelectrodes) saturation 1]);
                    label{end+1} = sprintf('elec %d unit %d',...
                        electrodeid, uid);
                    plotMap(map.x, map.y, v(:,u), ...
                        groups.factor, 'outline', ...
                        contours, color);

                end
                legend(label);
                nf.suffix = 'map';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
    end
end