function [ nf ] = plotTuningCurve(nf, ex, spikes, uid, varargin)
%plotTuningCurve opens and draws tuning curve figure
% returns handle to NeuroFig holding the tuning curve

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, ex.PreICI + ex.SufICI));
p.parse(varargin{:});
offset = p.Results.offset;

% Calculate MFR and F1
pre = nan(length(ex.CondTest.CondIndex), 1); 
f0 = pre; f1 = pre;
for t = 1:length(ex.CondTest.CondIndex)
    
    % Pre-stimulus
    t1 = ex.CondTest.CondOn(t);
    t0 = t1 - offset;
    pre(t) = f0f1(spikes, t0, t1, NaN);
    
    % Peri-stimulus
    if isfield(ex.CondTestCond, 'TemporalFreq')
        tf = ex.CondTestCond.TemporalFreq{t};
    elseif isfield(ex.EnvParam, 'TemporalFreq')
        tf = ex.EnvParam.TemporalFreq;
    else
        tf = NaN;
    end
    t0 = t1;
    t1 = ex.CondTest.CondOff(t);
    [f0(t), f1(t)] = f0f1(spikes, t0, t1, tf/ex.secondperunit);
end   

if ex.secondperunit ~= 1
    pre = pre/ex.secondperunit;
    f0 = f0/ex.secondperunit;
    f1 = f1/ex.secondperunit;
end

% Gather conditions
conditionNames = fieldnames(ex.Cond);
conditionName = conditionNames{1}; % Take the first one for now
conditions = ex.Cond.(conditionName);
conditions = reshape(conditions, length(conditions), 1);
cond = unique(cell2mat(conditions),'rows');
dim = size(cond, 2);

% Group according to this condition
mF0 = nan(1, length(cond)); semF0 = mF0; mPre = mF0; semPre = mF0;
mCorr = mF0; semCorr = mF0; mF1 = mF0; semF1 = mF0;
for i = 1:length(cond)
    group = cellfun(@(x)isequal(x,cond(i,:)), ex.CondTestCond.(conditionName));
    mF0(i) = mean(f0(group));
    semF0(i) = sem(f0(group)); 
    mPre(i) = mean(pre(group));
    semPre(i) = sem(pre(group));
    mCorr(i) = mF0(i) - mPre(i);
    semCorr(i) = sem(f0(group) - ...
        pre(group));
    mF1(i) = mean(f1(group)); 
    semF1(i) = sem(f1(group));   
end

hold on;

% Plot data with SEMs
errorbar(cond,mF0,semF0,'k','LineWidth',1);
if any(~isnan(mF1) | ~isnan(semF1))
    errorbar(cond,mF1,semF1,'r');
end
errorbar(cond,mPre,semPre,'Color',[0.5 0.5 0.5]);
errorbar(cond,mCorr,semCorr,'g');

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
if issorted(cond, 'strictmonotonic') 
    set(gca,'XTick',cond);
else
    set(gca,'XTick',unique(cond));
end
box off;

% Dress the figure with title etc
OSI = [];
DSI = [];
if contains(ex.ID, 'Ori')
    valid = cond >= 0;
    theta = deg2rad(cond(valid));
    response = mF0(valid) - baseline;
    response(response < 0) = 0;
    [OSI, DSI] = osi(response, theta);
end
nf.suffix = 'tc';
nf.dress('EnvParam', ex.EnvParam, 'OSI', OSI, 'DSI', DSI);
hold off;

end

