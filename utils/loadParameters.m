function Params = loadParameters(ex)
%loadParameters either loads directly or converts from VLab the parameters

if isempty(ex)
    return;
end

Params = ex;

% Directly load parameters if possible
if isfield(Params, 'Data') && ~isempty(Params.Data)
    return;
elseif isfield(Params, 'Data')
    return; % empty Data field means no trials
end

% Attempt to convert from VLab format
return;
stimType = fieldnames(Params.Cond);
conditions = Params.(stimType);
Params.nConds = length(conditions);

conditionNo = Params.CondTest.CondIndex';
trialNo = Params.CondTest.CondRepeat';
nStims = length(conditionNo);
stimNo = [1:nStims]';
times = Params.CondTest.CONDSTATE;
stimTime = nan(nStims, 1);
stimOffTime = nan(nStims, 1);

for i = 1:length(times)
    states = cellfun(@fieldnames,times{i}, 'UniformOutput', false);
    condState = find(strcmp(states, 'COND'));
    sufState = find(strcmp(states, 'SUFICI'));
    stimTime(i) = times{i}{condState}.COND;
    stimOffTime(i) = times{i}{sufState}.SUFICI;
    condition(i) = conditions(conditionNo(i));
end

Params.Data = table(stimNo, stimTime, stimOffTime, trialNo, conditionNo, condition);


end