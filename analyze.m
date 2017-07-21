function [Results] = analyze(dataset, whichElectrodes, verbose)
%analyze Function making PSTH, rasters, and ISIs for data in Electrodes

Results = struct;
Results.status = 0;
Results.error = '';
if isempty(dataset) || ~isfield(dataset, 'spike') || isempty(dataset.spike)
    Results.error = 'No spike data';
    return; % not enough data for this file
elseif ~isfield(dataset, 'ex') || isempty(dataset.ex) || ...
        ~isfield(dataset.ex, 'Data') || isempty(dataset.ex.Data)
    Results.error = 'Empty parameters structure';
    return;
end

if nargin < 2 || isempty(whichElectrodes)
    whichElectrodes = [dataset.spike.electrodeid];
end
if nargin < 3 || isempty(verbose)
    verbose = false;
end

% Parameters
Params = dataset.ex;
Params.blankPeriod = 0.5; % how much time to consider blank (only if
% stimInterval >= blankPeriod)
Params.responseLag = 0.1; % delay between stimulus and response (ms)

% Which electrodes to processes
Params.nElectrodes = length(dataset.spike);
Params.whichElectrodes = whichElectrodes;
Params.unitNo = sscanf(Params.unit, 'Unit%d');

% Load all possible stim times
Events = loadDigitalEvents(dataset);
if ~isempty(Events)
    StimTimes = Events.StimTimes;
end
StimTimes.matlab = Params.Data.stimTime;

[stimOnTimes, stimOffTimes, source, latency, variation, hasError, msg] = ...
    adjustStimTimes(Params, Events);

StimTimes.on = stimOnTimes;
StimTimes.off = stimOffTimes;
StimTimes.latency = latency;
StimTimes.variation = variation;
StimTimes.source = source;
StimTimes.hasError = hasError;
StimTimes.msg = msg;

% Add stimulus offsets to Data table
nTrials = Params.nTrials;
if nTrials < 2
    Results.error = 'Not enough trials\n';
    return;
end
nConds = Params.nConds;
nStims = size(Params.Data,1);
Params.Data.stimTime = StimTimes.on(1:nStims);
Params.Data.stimOffTime = StimTimes.off(1:nStims);
Params.Data.stimDiffTime = [StimTimes.on(2:nStims); NaN] - StimTimes.on(1:nStims);

% Determine conditions
conditions = unique(Params.Data.condition(1:nStims,:),'rows');
conditions = reshape(conditions, nConds, size(Params.Data.condition,2));

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

% Determine condition numbers and sort conditions properly
conditionNo = zeros(length(conditions),1);
for i = 1:length(conditions)
    isThisCond = Params.Data.condition == conditions(i,:);
    condIndex = sum(isThisCond,2) == size(Params.Data.condition,2);
    condNo = unique(Params.Data.conditionNo(condIndex)); % should only be one!
    assert(length(condNo) == 1); 
    conditionNo(i) = condNo;
end
Params.Conditions = table([],[],[],[],[],[],[],[],cell(0),cell(0));
Params.Conditions.Properties.VariableNames = ...
    {'conditionNo','condition','stimDuration','stimInterval','stimDiffTime',...
    'numBins','binSize','timeFrom','time','centers'};

% Determine per-condition parameters
for i = 1:length(conditionNo)
    c = conditionNo(i);
    
    Stimuli = Params.Data(Params.Data.conditionNo == c,:);
    
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
    stimDuration = min(Stimuli.stimDuration);
    stimInterval = min(Stimuli.stimInterval);
    timeFrom = min(stimInterval/2, Params.blankPeriod);
    time = -timeFrom:binSize:stimDiffTime-timeFrom;
    centers = time(1:end-1) + diff(time)/2;
    
    % Save everything to a table
    Params.Conditions = [Params.Conditions; ...
        {c, conditions(c,:), stimDuration, stimInterval, stimDiffTime,...
        numBins, binSize, timeFrom, time, centers}];
end

clear stimDiffTime stimDuration stimInterval TimeFrom Time Centers ...
    numBins binSize

% Make a gaussian filter for later
sigma = 5;
sz = 30;    % length of gaussFilter vector
x = linspace(-sz / 2, sz / 2, sz);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

% All electrodes
rawSpikes = dataset.spike(ismember([dataset.spike.electrodeid], whichElectrodes));
if verbose
    nUnits = arrayfun(@(x)length(unique(x.unitid)), rawSpikes);
    fprintf('%d electrodes (out of %d) with %s units\n', ...
        length(whichElectrodes), Params.nElectrodes, mat2str(nUnits));
end
spike = struct;
parfor i = 1:length(whichElectrodes)
    elecNo = rawSpikes(i).electrodeid;
    if elecNo == 0
        continue;
    end
    
    % Collect spike times for this electrode  
    
    if isempty(rawSpikes(i))
        fprintf(2, 'No spikes for electrode %d...', elecNo);
        continue;
    end
    
    cells = unique(rawSpikes(i).unitid);
    
    % Initialize the data structures
    SpikeData = table([],[],[],cell(0),cell(0),cell(0),[]);
    SpikeData.Properties.VariableNames = ...
        {'conditionNo','trial','cell','raster','hist','isi', 'stimTime'};
    Statistics = table([],[],[],[],[],[],[],[],[],[],[],cell(0),cell(0));
    Statistics.Properties.VariableNames = ...
        {'conditionNo','cell',...
        'tCurve','tCurveSEM','blank','blankSEM',...
        'tCurveCorr','tCurveCorrSEM','f1Rep','f1RepSD', ...
        'latency', 'meanTrials', 'blankTrials', };
    
    %% Analysis
    for j = 1:length(conditionNo)
        
        c = conditionNo(j);
        Stimuli = Params.Data(Params.Data.conditionNo == c,:);
        Condition = Params.Conditions(Params.Conditions.conditionNo == c,:);
        binSize = Condition.binSize;
        nTrials = size(Stimuli,1);
        
        % Pick out the pre-stimulus and peri-stimulus times
        centers = cell2mat(Condition.centers);
        which = centers>=0 & centers < Condition.stimDuration+Params.responseLag;
        whichBlank = centers<0;
        
        for k = 1:length(cells)
            u = cells(k);
            
            % Make Rasters and Histograms
            for t = 1:nTrials % how many trials for this condition
                
                % Raster plots, histograms and ISIs
                stimTime = Stimuli.stimTime(t);
                stimOffTime = Stimuli.stimOffTime(t);
                whichSpikes = rawSpikes(i).unitid == u & ...
                    rawSpikes(i).time  >= stimTime-Condition.timeFrom & ...
                    rawSpikes(i).time < stimTime+Condition.stimDiffTime;
                spikes = rawSpikes(i).time(whichSpikes)';
                if ~isempty(spikes)
                    raster = spikes - stimTime;
                    hist = histcounts(raster,cell2mat(Condition.time));
                    if length(spikes) > 1
                        isi = diff(raster);
                    else
                        isi = [];
                    end
                else
                    raster = [];
                    hist = zeros(1,length(centers));
                    isi = [];
                end
                
                SpikeData = [SpikeData; ...
                    {c,t,u,raster,hist',isi, stimTime}];
            end
            
            % Prepare Trials x Centers matrix for histogram
            hists = cell2mat(SpikeData.hist(SpikeData.conditionNo == c ...
                & SpikeData.cell == u)');
            
            % Statistics
            psth = hists(which,:);
            preStimulus = hists(whichBlank,:);
            numCounts = sum(psth,1);
            numCountsBlank = sum(preStimulus,1);
            
            % Calculate confidence interval for blank firing rate
            histFilt = conv (sum(hists, 2), gaussFilter, 'same');
            [~, ~, CI, ~] = normfit(histFilt(whichBlank));
            
            % Find bins where firing rate is outside of CI
            binCounts = histFilt(centers >= 0);
            latencyBin = find(binCounts > CI(2),1);
            latency = latencyBin * binSize;
            if isempty(latency); latency = NaN; end
            
            % Calculate mean firing
            meanTrials = numCounts./(binSize*size(psth,1)); % average over time
            blankTrials = numCountsBlank./(binSize*size(preStimulus,1)); % average over time
            tCurve = mean(meanTrials); % average over time and trials
            blank = mean(blankTrials); % average over time and trials
            
            % SEMs
            tCurveSEM = std(meanTrials)/sqrt(nTrials); % average over time and STD over trials
            blankSEM = std(blankTrials)/sqrt(nTrials);% average over time and STD over trials
            
            % Corrected mean firing rates
            tCurveCorr = tCurve-blank;
            tCurveCorrSEM = std(meanTrials-blankTrials)/sqrt(nTrials);
            
            % FFT analysis
            if ismember('tf', Params.Data.Properties.VariableNames)
                %                 T = 0.5;
                %                 N = floor(T/binSize);
                % Pad with zeros to get a better idea of Y at f=TF
                N = max(size(psth,1), floor(1/binSize/min(Stimuli.tf)));
                psthPad = [psth; zeros(N - size(psth,1), size(psth,2))];
                T = N*binSize;
                Y = fft(psthPad(1:N,:)./binSize,[],1);
                psthSpectra = abs(Y(1:floor(N/2),:))/floor(N/2);
                specFreq = 0:1/T:floor((N-1)/T/2);
                f1 = psthSpectra(find(specFreq>=min(Stimuli.tf)-0.05,1),:);
                if isempty(f1); f1 = NaN; end
                f1Rep = mean(f1);
                f1RepSD = std(f1)/sqrt(nTrials);
            else
                f1Rep = NaN;
                f1RepSD = NaN;
            end
            
            Statistics((j-1)*length(cells)+k,:) = ...
                {c, u, ...
                tCurve,tCurveSEM, ...
                blank,blankSEM, ...
                tCurveCorr,tCurveCorrSEM, ...
                f1Rep,f1RepSD, ...
                latency, {meanTrials}, {blankTrials}};
        end
    end
        
    % Save everything
    spike(i).Data = SpikeData;
    spike(i).Statistics = Statistics;
    spike(i).electrodeid = elecNo;

end % Electrodes loop

% Accumulate results
Results.spike = spike;
Results.StimTimes = StimTimes;
Results.Params = Params;
Results.status = 1;
Results.source = dataset.source;
Results.sourceFormat = dataset.sourceformat;

end