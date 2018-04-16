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

% Prepare annotation parameters
baseParam = {'Ori', 'Diameter', 'Size', 'Color', 'Position', ...
            'Contrast', 'SpatialFreq', 'TemporalFreq', 'GratingType'};
params = NeuroAnalysis.Base.getstructfields(ex.EnvParam, ...
    baseParam);

% Organize conditions into groups
conditionNames = fieldnames(ex.Cond);
xConditionName = conditionNames{1};
xConditions = ex.Cond.(xConditionName);
xConditions = reshape(xConditions, length(xConditions), 1);
xCond = unique(cell2mat(xConditions),'rows');
dim = size(xCond, 2);
x = xCond(:,1);

hold on;
legendItems = {};
if length(conditionNames) == 1
    
    mF0 = nan(1, size(xCond,1)); semF0 = mF0; mPre = mF0; semPre = mF0;
    mF1 = mF0; semF1 = mF0;
    for i = 1:size(xCond, 1)
        group = cellfun(@(x)isequal(x,xCond(i,:)), ex.CondTestCond.(xConditionName));
        mF0(i) = nanmean(f0(group));
        semF0(i) = sem(f0(group)); 
        mPre(i) = nanmean(pre(group));
        semPre(i) = sem(pre(group));
        mF1(i) = nanmean(f1(group)); 
        semF1(i) = sem(f1(group));   
    end

    % Plot data with SEMs
    errorbar(x,mF0,semF0,'k','LineWidth',1);
    if any(~isnan(mF1) | ~isnan(semF1))
        errorbar(x,mF1,semF1,'r');
        legendItems = {'F0';'F1';'PreICI'};
    else
        legendItems = {'F0';'PreICI'};
    end
    errorbar(x,mPre,semPre,'Color',[0.5 0.5 0.5]);
    
    if contains(ex.ID, 'Ori')
        baseline = mean(mF0);
        valid = x >= 0;
        theta = deg2rad(x(valid));
        response = mF0(valid) - baseline;
        response(response < 0) = 0;
        [OSI, DSI] = osi(response, theta);
        params.OSI = OSI;
        params.DSI = DSI;
    end

else
    conditionNames = conditionNames(2:end);
    remainingCond = [];
    dim = [];
    for f = 1:length(conditionNames)
        factor = conditionNames{f};
        conditions = ex.Cond.(factor);
        conditions = reshape(conditions, length(conditions), 1);
        remainingCond = [remainingCond conditions];
        dim = [dim size(conditions,2)];
    end
    cond = unique(cell2mat(remainingCond),'rows');
    cond = mat2cell(cond, ones(1,size(cond,1)), dim);
    condString = cellfun(@(x)sprintf('%0.3f_',x),cond,'UniformOutput', false);
    condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);

    colors = jet(size(cond,1));
    
    for l = 1:size(cond,1)
        
        group = zeros(length(ex.CondTest.CondIndex),1);
        for f = 1:length(conditionNames)
            group(cellfun(@(x)isequal(x, cond{l,f}), ...
                ex.CondTestCond.(conditionNames{f}))) = 1;
        end
        levelName = [conditionNames'; condString(l,:)];
        levelName = sprintf('%s_%s_', levelName{:});
        levelName = levelName(1:end-1);

        mF0 = nan(1, size(xCond,1)); semF0 = mF0; mPre = mF0; semPre = mF0;
        mF1 = mF0; semF1 = mF0;
        for i = 1:size(xCond, 1)
            condition = cellfun(@(x,y)isequal(x,xCond(i,:)),...
                ex.CondTestCond.(xConditionName));
            condition = reshape(condition, length(condition), 1);
            mF0(i) = nanmean(f0(condition & group));
            semF0(i) = sem(f0(condition & group)); 
            mPre(i) = nanmean(pre(condition & group));
            semPre(i) = sem(pre(condition & group));
            mF1(i) = nanmean(f1(condition & group)); 
            semF1(i) = sem(f1(condition & group));   
        end

        % Plot data with SEMs
        errorbar(x,mF0,semF0,'Color',colors(l,:));
        legendItems = [legendItems; {['F0_',levelName]}];

        if contains(ex.ID, 'Ori')
            baseline = mean(mF0);
            valid = x >= 0;
            theta = deg2rad(x(valid));
            response = mF0(valid) - baseline;
            response(response < 0) = 0;
            [OSI, DSI] = osi(response, theta);
            params.(['OSI_',num2str(l)]) = OSI;
            params.(['DSI_',num2str(l)]) = DSI;
        end
    end
end

% Configure axes, legend, title
axis tight;
legend(legendItems,'Location','NorthEast','Interpreter','none');
legend('boxoff');

xlabel(xConditionName, 'Interpreter', 'none');
ylabel('Rate [spikes/s]');
if issorted(x, 'strictmonotonic') 
    set(gca,'XTick',x);
else
    set(gca,'XTick',unique(x));
end
box off;

% Dress the figure with title etc
nf.suffix = 'tc';
nf.dress('Params', params);
hold off;

end

