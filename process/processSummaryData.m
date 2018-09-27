function result = processSummaryData(spikeResult, lfpResult, ...
    ex, groups, path, filename, actions, varargin)
%processSummaryData

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('mappingThreshold', 3); % number of standard deviations
p.parse(varargin{:});
thr = p.Results.mappingThreshold;

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

                % Remove any units with low maximum firing rates
                spike = [];
                for u = 1:length(result.spike)
                    if max(result.spike(u).(ex.ID){1}.map.v(:,l)) > thr
                        spike = [spike; result.spike(u)];
                    end
                end
                if isempty(spike)
                    continue;
                end

                % Allocate a hue for each electrode
                electrodes = [spike.electrodeid];
                uelectrodes = unique(electrodes);
                hue = linspace(0,1,length(uelectrodes)+1);
                
                % Plot each unit
                nf = NeuroFig(ex.ID, [], [], 'summary', groups.levelNames{l});
                label = {};
                hold on
                for u = 1:length(spike)
                    electrodeid = spike(u).electrodeid;
                    uid = spike(u).uid;
                    map = spike(u).(ex.ID){1}.map;
  
                    m = mean(map.v(:,l));
                    s = std(map.v(:,l));
                    localThr = m+s;
                    contours = [localThr, localThr];
                    
                    % Value reflects unit number
                    uuid = unique([spike(electrodeid == electrodes).uid]);
                    value = double(uid+1)/double(max(uuid)+1);
                    color = hsv2rgb([hue(electrodeid==uelectrodes) 1 value]);
                    label{end+1} = sprintf('elec %d unit %d',...
                        electrodeid, uid);
                    plotMap(map.x, map.y, map.v(:,l), ...
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