function [ ConditionTable ] = conditionTable( Params )
%conditionTable Generate a table describing all conditions tested


conditionNames = fieldnames(Params.Conditions);

for i = 1:length(conditionNames)
    conditions(:,i) = Params.Conditions.(conditionNames{i});
end

% Make corrections to the conditions
if strcmp(Params.stimType,'CatApertureSmall') && conditions(end) == 30
    conditions(end) = 15; % fixing cat aperture
end
if strcmp(Params.animalID,'C1504') && strcmp(Params.stimType,'Contrast')
    conditions = [19.45,34.10,46.82,62.90,73.50,81.82,92.52,97.26];
end
if strcmp(Params.stimType,'CenterSurround') || strcmp(Params.stimType,'OriDomains')
    conditions(conditions<0) = conditions(conditions<0)*10;
end

ConditionTable = table([],[],[],[],[],[],[],[],cell(0),cell(0));
ConditionTable.Properties.VariableNames = ...
    {'conditionNo','condition','stimDuration','stimInterval','stimDiffTime',...
    'numBins','binSize','timeFrom','time','centers'};

% Determine per-condition parameters
for c = 1:length(conditions)
    
    Stimuli = Params.Data(Params.Data.conditionNo == c,:);
    
    if isempty(Stimuli)
        error('Some condition has no trials');
    end
    
    % Variable bin size or number of bins
    switch Params.binType
        case 'number'
            stimDiffTime = min(Stimuli.stimDiffTime); % This condition
            numBins = 100;
            binSize = stimDiffTime/numBins;
        case 'size'
            stimDiffTime = min(Stimuli.stimDiffTime); % This condition
%             stimDiffTime = min(Params.Data.stimDiffTime); % All stimuli
            binSize = 0.01;
            numBins = floor(stimDiffTime/binSize);
    end
    
    % Pick out the peri-stimulus times and bin centers
    stimDuration = min(Stimuli.stimOffTime - Stimuli.stimTime);
    stimInterval = min(Stimuli.stimDiffTime - ...
        (Stimuli.stimOffTime - Stimuli.stimTime));
    timeFrom = min(stimInterval/2, Params.blankPeriod);
    time = -timeFrom:binSize:stimDiffTime-timeFrom;
    centers = time(1:end-1) + diff(time)/2;
    
    % Save everything to a table
    ConditionTable = [ConditionTable; ...
        {c, conditions(c,:), stimDuration, stimInterval, stimDiffTime,...
        numBins, binSize, timeFrom, {time}, {centers}}];
end

end

