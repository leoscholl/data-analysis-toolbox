function [Results] = analyze(dataset, whichElectrodes, verbose, isparallel)
%analyze Function making PSTH, rasters, and ISIs for data in Electrodes

Results = struct;
Results.status = 0;
Results.error = '';
if isempty(dataset) || ~isfield(dataset, 'spike') || isempty(dataset.spike)
    Results.error = 'No spike data';
    return; % not enough data for this file
end

if nargin < 2 || isempty(whichElectrodes)
    whichElectrodes = [dataset.spike.electrodeid];
end
if nargin < 3 || isempty(verbose)
    verbose = false;
end
if nargin < 4 || isempty(isparallel)
    isparallel = true;
end

% Parameters
Params = loadParameters(dataset.ex);
if isempty(Params) || ~isfield(Params, 'Data') || isempty(Params.Data)
    Results.error = 'Empty parameters structure';
    return;
end
Params.blankPeriod = 0.5; % how much time to consider blank (only if
% stimInterval >= blankPeriod)
Params.responseLag = 0.1; % delay between stimulus and response (ms)

% Which electrodes to processes
Params.nElectrodes = length([dataset.spike.electrodeid]);
Params.whichElectrodes = whichElectrodes;

% Load all possible stim times
Events = loadDigitalEvents(dataset);
Events = adjustStimTimes2(Params, Events);
StimTimes = Events.StimTimes;

% Replace the old stim times with these new ones
nStims = size(Params.Data,1);
Params.Data.stimTime = StimTimes.on(1:nStims);
Params.Data.stimOffTime = StimTimes.off(1:nStims);
Params.Data.stimDiffTime = [StimTimes.on(2:nStims); NaN] - StimTimes.on(1:nStims);

% Add stimulus offsets to Data table
nTrials = Params.nTrials;
if nTrials < 2
    Results.Params = Params;
    Results.StimTimes = StimTimes;
    Results.error = 'Not enough trials\n';
    return;
end

% Generate a condition table
Params.ConditionTable = conditionTable(Params);

% Make a gaussian filter for later
sigma = 1;
sz = 10;    % length of gaussFilter vector
x = linspace(-sz / 2, sz / 2, sz);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

% All electrodes
rawSpikes = dataset.spike(ismember([dataset.spike.electrodeid], whichElectrodes));
if isfield(dataset, 'lfp')
    rawLFP = dataset.lfp.data;
    fsLFP = dataset.lfp.fs;
    elecLFP = dataset.lfp.electrodeid;
else
    rawLFP = zeros(0,2);
    fsLFP = [];
    elecLFP = [dataset.spike.electrodeid];
end
if verbose
    nUnits = arrayfun(@(x)length(unique(x.unitid)), rawSpikes);
    fprintf('%d electrodes (out of %d) with %s units\n', ...
        length(whichElectrodes), Params.nElectrodes, mat2str(nUnits));
end
spike = struct;
lfp = struct;

if isparallel
    if isempty(gcp('nocreate')) && isempty(getCurrentTask())
        parpool; % start the parallel pool
    end
    parfor i = 1:length(whichElectrodes)
        elecNo = rawSpikes(i).electrodeid;
        if elecNo == 0 && ~ismember(elecNo, whichElectrodes)
            continue;
        end

        % Collect spike times for this electrode  
        if isempty(rawSpikes(i))
            fprintf(2, 'No spikes for electrode %d...', elecNo);
            continue;
        end
        [SpikeData, Statistics] = ...
            analyzeElectrode(Params, rawSpikes(i), gaussFilter);

        % Save everything
        spike(i).Data = SpikeData;
        spike(i).Statistics = Statistics;
        spike(i).electrodeid = elecNo;

    end % Electrodes loop
else
    for elecNo = whichElectrodes
        i = find([rawSpikes.electrodeid] == elecNo);
        if isempty(i)
            continue;
        end
        
        % Collect spike times for this electrode  
        if isempty(rawSpikes(i))
            fprintf(2, 'No spikes for electrode %d...', elecNo);
            continue;
        end
        
        [SpikeData, Statistics] = ...
            analyzeElectrode(Params, rawSpikes(i), gaussFilter);

        % Save everything
        spike(i).Data = SpikeData;
        spike(i).Statistics = Statistics;
        spike(i).electrodeid = elecNo;
    end
end

% LFP analysis (needs to be done separately from spike)
% for elecNo = whichElectrodes
%         i = find([rawSpikes.electrodeid] == elecNo);
%         if isempty(i)
%             continue;
%         end
%         
%         % Collect spike times for this electrode  
%         if isempty(rawSpikes(i))
%             fprintf(2, 'No spikes for electrode %d...', elecNo);
%             continue;
%         end
%         if ~ismember(elecNo, elecLFP)
%             lfpSlice = [];
%         else
%             lfpSlice = rawLFP(:,i);
%         end
%         [SpikeData, LFPData, Statistics] = ...
%             analyzeElectrode(Params, rawSpikes(i), gaussFilter, lfpSlice, fsLFP);
% 
%         % Save everything
%         if size(SpikeData,1) > 0 && size(Statistics,1) > 0
%             spike(i).Data = SpikeData;
%             spike(i).Statistics = Statistics;
%             spike(i).electrodeid = elecNo;
%         end
%         if ismember(elecNo, elecLFP)
%             lfp(i).Data = LFPData;
%             lfp(i).electrodeid = elecLFP(i);
%             lfp(i).fs = fsLFP;
%         end
%     end

% Accumulate results
Results.lfp = lfp;
Results.spike = spike;
Results.StimTimes = StimTimes;
Results.Params = Params;
Results.status = 1;
Results.source = dataset.source;
Results.sourceFormat = dataset.sourceformat;

end

function [SpikeData, Statistics] = ...
    analyzeElectrode(Params, rawSpikes, gaussFilter)

% Initialize the data structures
    SpikeData = table([],[],[],cell(0),cell(0),cell(0),[]);
    SpikeData.Properties.VariableNames = ...
        {'conditionNo','trial','cell','raster','hist','isi', 'stimTime'};
%     LFPData = table([],cell(0),cell(0),cell(0),cell(0));
%     LFPData.Properties.VariableNames = ...
%         {'conditionNo', 'time', 'mean', 'std', 'trials'};
    Statistics = table([],[],[],[],[],[],[],[],[],[],[],[],...
        cell(0),cell(0),cell(0), cell(0), cell(0), cell(0), cell(0));
    Statistics.Properties.VariableNames = ...
        {'conditionNo','cell',...
        'tCurve','tCurveSEM','blank','blankSEM',...
        'tCurveCorr','tCurveCorrSEM','f0','f1','f1SD', ...
        'latency', 'cv', 'meanTrials', 'blankTrials', 'histFilt', ...
        'surpriseInd', 'bursts', 'nBursts'};
    
    %% Analysis
    conditionNo = Params.ConditionTable.conditionNo;
    cells = unique(rawSpikes.unitid);
    for j = 1:length(conditionNo)
        
        c = conditionNo(j);
        Stimuli = Params.Data(Params.Data.conditionNo == c,:);
        Condition = table2struct(Params.ConditionTable(...
            Params.ConditionTable.conditionNo == c,:));
        binSize = Condition.binSize;
        nTrials = size(Stimuli,1);
        
        % Pick out the pre-stimulus and peri-stimulus times
        time = Condition.time;
        centers = Condition.centers;
        which = centers>=0 & centers < Condition.stimDuration+Params.responseLag;
        whichBlank = centers<0;
        assert(any(which)); % Need at least one trial bin
        assert(any(whichBlank)); % Need at least one blank bin
        
        for k = 1:length(cells)
            u = cells(k);
            
            % Make Rasters and Histograms
            histFilt = zeros(length(centers), nTrials);
            cv = cell(length(time)-1,1);
            surpInd = zeros(nTrials, 1);
            burst = nan(nTrials, 2);
            nBursts = zeros(nTrials, 2); % how many bursts during and outside of stim
            
            for t = 1:nTrials % how many trials for this condition
                
                % Raster plots, histograms and ISIs
                stimTime = Stimuli.stimTime(t);
                stimOffTime = Stimuli.stimOffTime(t);
                whichSpikes = rawSpikes.unitid == u & ...
                    rawSpikes.time  >= stimTime-Condition.timeFrom & ...
                    rawSpikes.time < stimTime+Condition.stimDiffTime;
                spikes = rawSpikes.time(whichSpikes)';
                if ~isempty(spikes)
                    raster = spikes - stimTime;
                    hist = histcounts(raster,time);
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
                
                histFilt(:,t) = conv (hist, gaussFilter, 'same')';
                
                % Coefficient of variation - doesn't really work
%                 for bin = 1:length(time)-1
%                     spikes = find(raster >= time(bin) & ...
%                         raster < time(bin+1) & ...
%                         logical([ones(length(raster)-1, 1); 0])); % don't include last spike
%                     cv{bin} = [cv{bin}; raster(spikes+1) - raster(spikes)];
%                 end

                % Rank Surprise analysis
                if length(raster) > 2
                    limit = []; % default is 75th percentile of ISIs
                    RSalpha = -log(0.05); % Significance cutoff
                    [RS,burst_length,burst_start]=rank_surprise(raster,limit,RSalpha);
                    stimOn = burst_start > find(raster > 0, 1) & ...
                        burst_start + burst_length - 1 < find(raster > Condition.stimDuration, 1);
                    stimBurst = find(stimOn);
                    blankBurst = find(~stimOn);
                    nBursts(t,:) = [length(stimBurst),length(blankBurst)];
                    nStimBurst = length(stimBurst);
                    if nStimBurst > 0
                        surpInd(t) = RS(stimBurst(1));
                        burst(t,:) = [burst_start(stimBurst(1)), ...
                            burst_start(stimBurst(1)) + burst_length(stimBurst(1)) - 1];
                        burst(t,1) = raster(burst(t,1));
                        burst(t,2) = raster(burst(t,2));
                    end
                end
                
            end
            
            % Prepare Trials x Centers matrix for histogram
            hists = cell2mat(SpikeData.hist(SpikeData.conditionNo == c ...
                & SpikeData.cell == u)');
            
            % Statistics
            psth = hists(which,:);
            preStimulus = hists(whichBlank,:);
            numCounts = sum(psth,1);
            numCountsBlank = sum(preStimulus,1);
            
            % Latency
            histFilt = mean(histFilt,2);
            baseline = mean(histFilt(whichBlank));
            histCorrected = histFilt - baseline;
            histStd = std(histCorrected);
            latencyBin = find(which' & ...
                abs(histCorrected) > 2*histStd, 1);
            latency = latencyBin * binSize - Condition.timeFrom;
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
                f1Trials = psthSpectra(find(specFreq>=min(Stimuli.tf)-0.05,1),:);
                if isempty(f1Trials); f1Trials = NaN; end
                f0 = mean(psthSpectra(1,:));
                f1 = mean(f1Trials);
                f1SD = std(f1Trials)/sqrt(nTrials);
            else
                f0 = NaN;
                f1 = NaN;
                f1SD = NaN;
            end
            
            % Coefficient of variation
%             cv = cellfun(@(bin)std(bin)/mean(bin),cv);

            
            
            
            % Poisson analysis
%             maxIsi = 0.1; % 100 ms gap is too much of a gap
%             surpInd = nan(nTrials, 1);
%             burst = nan(nTrials, 2);
%             for t = 1:nTrials
%                 spikes = SpikeData.raster{SpikeData.conditionNo == c ...
%                 & SpikeData.cell == u & SpikeData.trial == t};
%             
%                 stimTime = find(spikes >= 0, 1);
%                 stimOffTime = find(spikes < Condition.stimDuration + ...
%                     Params.responseLag, 1, 'last');
%                 if isempty(stimOffTime)
%                     stimOffTime = length(spikes);
%                 end
%             
%                 if isempty(stimTime) || stimOffTime - stimTime < 2
%                     burst(t,:) = NaN;
%                     surpInd(t) = NaN;
%                     continue;
%                 end
%                 
%                 % Mean firing rate for this trial
%                 r = length(spikes) / ...
%                     (Condition.timeFrom + Condition.stimDiffTime);
%                 
%                 spikes = spikes(stimTime:stimOffTime);
%                 T = [];
%                 n = 2;
%                 
%                 % Find the first pair of spikes with instantaneous firing
%                 % rate >= mean firing rate
%                 startInd = find(spikes(1:end-1) >= 0 & ...
%                     n./diff(spikes) >= r, 1);
%                 if isempty(startInd)
%                     burst(t,:) = NaN;
%                     surpInd(t) = NaN;
%                     continue;
%                 end
%                 ind = startInd + 1;
%                 T = spikes(ind) - spikes(ind-1);
%                 isi = T;
%                 
%                 % Find end of burst by iterating suprise index forwards
%                 SI = zeros(length(spikes),2);
%                 while ind <= length(spikes) && isi < maxIsi
%                     p = poisscdf(n, r*T);
%                     SI(ind,1) = -log(p);
%                     
%                     if ind ~= length(spikes)
%                         isi = spikes(ind+1) - spikes(ind);
%                         n = n + 1;
%                         T = T + isi;
%                     end
%                     ind = ind + 1;
%                 end
%                 [~, burst(t,2)] = max(SI(:,1));
%                 
%                 % Find beginning of burst by removing spikes from the
%                 % beginning until SI is maximized
%                 ind = startInd;
%                 n = burst(t,2) - ind;
%                 T = spikes(burst(t,2)) - spikes(ind);
%                 while n > 1
%                     p = poisscdf(n, r*T);
%                     SI(ind,2) = -log(p);
%                     
%                     ind = ind + 1;
%                     n = n - 1;
%                     T = spikes(burst(t,2)) - spikes(ind);
%                 end
%                 [~, burst(t,1)] = max(SI(:,2));
%                 
%                 % Calculate the final surprise index
%                 n = burst(t,2) - burst(t,1);
%                 T = spikes(burst(t,2)) - spikes(burst(t,1));
%                 p = poisscdf(n, r*T);
%                 surpInd(t) = -log(p);
%                 
%                 % Convert burst indices into timestamps
%                 burst(t,1) = spikes(burst(t,1));
%                 burst(t,2) = spikes(burst(t,2));
%             end
            
            
            Statistics((j-1)*length(cells)+k,:) = ...
                {c, u, ...
                tCurve,tCurveSEM, ...
                blank,blankSEM, ...
                tCurveCorr,tCurveCorrSEM, ...
                f0,f1,f1SD, ...
                latency, cv, {meanTrials}, {blankTrials}, {histFilt}, ...
                {surpInd}, {burst}, {nBursts}};
            
        end
        
        % LFP binning
%         if ~isempty(rawLFP)
%             time = -Condition.timeFrom:1/fsLFP:Condition.stimDiffTime;
%             lfpTrials = zeros(nTrials,length(time));
%             for t = 1:nTrials
%                 stimTime = Stimuli.stimTime(t);
%                 stimOffTime = Stimuli.stimOffTime(t);
%                 ind = ceil(fsLFP*(stimTime+time));
%                 ind(ind>length(rawLFP)) = length(rawLFP);
%                 lfpTrials(t,:) = rawLFP(ind);
%             end
%             LFPData(j,:) = {c, {time}, {mean(lfpTrials)}, {std(lfpTrials)}, {lfpTrials}};
%         end
    end 
end

    