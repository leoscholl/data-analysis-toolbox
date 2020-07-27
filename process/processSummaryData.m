function result = processSummaryData(spikeResult, lfpResult, ...
    ex, groups, path, filename, actions, varargin)
%processSummaryData

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('mappingThreshold', 10); % minimum firing rate
p.addParameter('electrodeMap', []);
p.addParameter('ignoreElectrodes', []);
p.parse(varargin{:});
thr = p.Results.mappingThreshold;

if ~iscell(actions)
    actions = {actions};
end

result.ex = ex;
result.pre = repmat(ex.PreICI, 1, length(ex.CondTest.CondIndex)).*ex.secondperunit;
result.peri = reshape(ex.CondTest.CondOff-ex.CondTest.CondOn, 1, length(ex.CondTest.CondIndex)).*ex.secondperunit;
result.post = repmat(ex.SufICI, 1, length(ex.CondTest.CondIndex)).*ex.secondperunit;
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

                % Remove any units with firing rates below threshold
                spike = [];
                for u = 1:length(result.spike)
                    s = max(result.spike(u).(ex.ID){1}.map.v(:,l));
                    if s > thr
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
            
                        
        case 'CSD'
            
            if isempty(result.lfp)
                continue;
            end
            if isempty(p.Results.electrodeMap)
                warning('No electrode map given');
                continue;
            end
            depth = p.Results.electrodeMap(str2double(ex.RecordSite), double([result.lfp.electrodeid]));
            trash = ismember([result.lfp.electrodeid],p.Results.ignoreElectrodes);
            depth = depth(~trash);
            
            % Inverse delta current source density estimation of mean lfp
            b0 = 0.54;
            b1 = 0.23;
            diam = 0.5*1e-3;
            cond = 0.3;
            cond_top = 0.3;
            for c=1:size(groups.conditions,1)
                for l=1:size(groups.conditions,3)
                    data = [];
                    for e=1:length(result.lfp)
                        data(e,:) = result.lfp(e).mean(c,:,l);
                    end
                    
                    CSD = F_delta(depth,diam,cond,cond_top)^-1*data(~trash,:);
                    [n1,n2]=size(CSD);
                    CSD_add = [];
                    CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
                    CSD_add(n1+2,:)=zeros(1,n2);
                    CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
                    CSD = S_general(n1+2,b0,b1)*CSD_add; % CSD has n1 rows
                    for e=1:size(CSD,1)
                        result.lfp([result.lfp.electrodeid] == e).csd(c,:,l) = CSD(e,:);
                    end
                end
            end
    end
end