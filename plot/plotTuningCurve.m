function [ nf ] = plotTuningCurve(ex, spike, uid, varargin)
%plotTuningCurve opens and draws tuning curve figure
% returns handle to NeuroFig holding the tuning curve

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5, ex.PreICI + ex.SufICI));
p.parse(varargin{:});
offset = p.Results.offset;

% Calculate MFR and F1
spikes = spike.time(spike.unitid == uid);
pre = nan(length(ex.CondTest.CondIndex), 1); 
f0 = pre; f1 = pre;
for t = 1:length(ex.CondTest.CondIndex)
    
    % Pre-stimulus
    t1 = ex.CondTest.CondOn(t);
    t0 = t1 - offset;
    pre(t) = f0f1(spikes, t0, t1, NaN);
    
    % Peri-stimulus
    if isfield(ex.Cond, 'TemporalFreq')
        tf = ex.Cond.TemporalFreq(ex.CondTest.CondIndex(t));
    elseif isfield(ex.EnvParam, 'TemporalFreq')
        tf = ex.EnvParam.TemporalFreq;
    else
        tf = NaN;
    end
    t0 = t1;
    t1 = ex.CondTest.CondOff(t);
    [f0(t), f1(t)] = f0f1(spikes, t0, t1, tf);
end   

% Group according to condition index
idx = unique(ex.CondTest.CondIndex);
mF0 = nan(1, length(idx)); semF0 = mF0; mPre = mF0; semPre = mF0;
mCorr = mF0; semCorr = mF0; mF1 = mF0; semF1 = mF0;
for i = 1:length(idx)
    mF0(i) = mean(f0(ex.CondTest.CondIndex == idx(i)));
    semF0(i) = sem(f0(ex.CondTest.CondIndex == idx(i))); 
    mPre(i) = mean(pre(ex.CondTest.CondIndex == idx(i)));
    semPre(i) = sem(pre(ex.CondTest.CondIndex == idx(i)));
    mCorr(i) = mF0(i) - mPre(i);
    semCorr(i) = sem(f0(ex.CondTest.CondIndex == idx(i)) - ...
        pre(ex.CondTest.CondIndex == idx(i)));
    mF1(i) = mean(f1(ex.CondTest.CondIndex == idx(i))); 
    semF1(i) = sem(f1(ex.CondTest.CondIndex == idx(i)));   
    
end

% Gather conditions
conditionNames = fieldnames(ex.Cond);
conditionName = conditionNames{1}; % Take the first one for now
conditions = ex.Cond.(conditionName);

suffix = 'tc';
nf = NeuroFig(ex.ID, spike.electrodeid, uid, suffix);
hold on;

% Plot data with SEMs
errorbar(conditions,mF0,semF0,'k','LineWidth',1);
if any(~isnan(mF1) | ~isnan(semF1))
    errorbar(conditions,mF1,semF1,'r');
end
errorbar(conditions,mPre,semPre,'Color',[0.5 0.5 0.5]);
errorbar(conditions,mCorr,semCorr,'g');

% Plot baseline
baseline = mean(mPre);
line([conditions(1) conditions(end)],[baseline baseline],'Color','blue');

% Configure axes, legend, title
axis tight;
if any(~isnan(mF1) | ~isnan(semF1))
    legend({'F0';'F1';'PreICI';'F0-PreICI'},'Location','NorthEast');
else
    legend({'F0';'PreICI';'F0-PreICI'},'Location','NorthEast');
end
legend('boxoff');

xlabel(conditionName, 'Interpreter', 'none');
ylabel('Rate [spikes/s]');
if issorted(conditions, 'strictmonotonic') 
    set(gca,'XTick',conditions);
else
    set(gca,'XTick',unique(conditions));
end
box off;

% Dress the figure with title etc
OSI = [];
DSI = [];
if contains(ex.ID, 'Ori')
    valid = conditions >= 0;
    theta = deg2rad(conditions(valid));
    response = mF0(valid) - baseline;
    response(response < 0) = 0;
    [OSI, DSI] = osi(response, theta);
end
nf.dress('EnvParam', ex.EnvParam, 'OSI', OSI, 'DSI', DSI);
hold off;

end

