function [Results] = analyze(dataPath, fileName, sourceFormat, ...
    Params, StimTimes, Electrodes, whichElectrodes, verbose)
%analyze Function making PSTH, rasters, and ISIs for data in Electrodes

if nargin < 8 || isempty(whichElectrodes)
    whichElectrodes = Electrodes.number;
end

if nargin < 9 || isempty(verbose)
    verbose = false;
end

% Parameters
Params.blankPeriod = 0.5; % how much time to consider blank (only if
% stimInterval >= blankPeriod)
Params.responseLag = 0.1; % delay between stimulus and response (ms)

% Which electrodes to processes
Params.nElectrodes = size(Electrodes,1);
Params.whichElectrodes = whichElectrodes;
Results = [];

% Add stimulus offsets to Data table
nTrials = Params.nTrials;
if nTrials < 2
    fprintf(2, 'Not enough trials\n');
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
if verbose
    spikes = Electrodes.spikes(ismember(Electrodes.number, whichElectrodes));
    nUnits = cellfun(@countUnits, spikes)';
    fprintf('%d electrodes (out of %d) with %s units\n', ...
        length(whichElectrodes), Params.nElectrodes, mat2str(nUnits));
end
SpikeDataAll = cell(1,length(whichElectrodes));
StatisticsAll = cell(1,length(whichElectrodes));
parfor i = 1:length(whichElectrodes)
    elecNo = whichElectrodes(i);
    if elecNo == 0
        continue;
    end
    
    % Collect spike times for this electrode
    spikeTimes = Electrodes.spikes{Electrodes.number == elecNo};
    
    electrodeName = Electrodes.name{Electrodes.number == elecNo};
    
    if isempty(spikeTimes)
        fprintf(2, 'No spikes for %s...', electrodeName);
        continue;
    end
    
    cells = unique(spikeTimes(:,2));
    
    % Initialize the data structures
    SpikeData = table([],[],[],cell(0),cell(0),cell(0),[]);
    SpikeData.Properties.VariableNames = ...
        {'conditionNo','trial','cell','raster','hist','isi', 'stimTime'};
    Statistics = nan(length(conditionNo)*length(cells),11);
    Statistics = array2table(Statistics);
    Statistics.Properties.VariableNames = ...
        {'conditionNo','cell',...
        'tCurve','tCurveSEM','blank','blankSEM',...
        'tCurveCorr','tCurveCorrSEM','f1Rep','f1RepSD', ...
        'latency'};
    meanTrials = cell(length(conditionNo),length(cells));
    blankTrials = cell(length(conditionNo),length(cells));
    tCurveAll = zeros(length(conditionNo),length(cells));
    tCurveSEMAll = zeros(length(conditionNo),length(cells));
    blankAll = zeros(length(conditionNo),length(cells));
    blankSEMAll = zeros(length(conditionNo),length(cells));
    tCurveCorrAll = zeros(length(conditionNo),length(cells));
    tCurveCorrSEMAll = zeros(length(conditionNo),length(cells));
    f1RepAll = nan(length(conditionNo),length(cells));
    f1RepSDAll = nan(length(conditionNo),length(cells));
    
    %% Analysis
    for j = 1:length(conditionNo)
        
        c = conditionNo(j);
        Stimuli = Params.Data(Params.Data.conditionNo == c,:);
        Condition = Params.Conditions(Params.Conditions.conditionNo == c,:);
        binSize = Condition.binSize;
        
        % Pick out the pre-stimulus and peri-stimulus times
        centers = cell2mat(Condition.centers);
        which = centers>=0 & centers < Condition.stimDuration+Params.responseLag;
        whichBlank = centers<0;
        
        for k = 1:length(cells)
            u = cells(k);
            
            % Make Rasters and Histograms
            for t = 1:size(Stimuli,1) % how many trials for this condition
                
                % Raster plots, histograms and ISIs
                stimTime = Stimuli.stimTime(t);
                stimOffTime = Stimuli.stimOffTime(t);
                spikes = spikeTimes(spikeTimes(:,2) == u & ...
                    spikeTimes(:,1) >= stimTime-Condition.timeFrom & ...
                    spikeTimes(:,1) < stimTime+Condition.stimDiffTime);
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
            if isempty(latency); latency = NaN; end;
            
            % Calculate mean firing
            meanTrials{j,k} = numCounts./(binSize*size(psth,1)); % average over time
            blankTrials{j,k} = numCountsBlank./(binSize*size(preStimulus,1)); % average over time
            tCurveAll(j,k) = mean(meanTrials{j,k}); % average over time and trials
            blankAll(j,k) = mean(blankTrials{j,k}); % average over time and trials
            
            % SEMs
            tCurveSEMAll(j,k) = std(meanTrials{j,k})/sqrt(nTrials); % average over time and STD over trials
            blankSEMAll(j,k) = std(blankTrials{j,k})/sqrt(nTrials);% average over time and STD over trials
            
            % Corrected mean firing rates
            tCurveCorrAll(j,k) = tCurveAll(j,k)-blankAll(j,k);
            tCurveCorrSEMAll(j,k) = std(meanTrials{j,k}-blankTrials{j,k})/sqrt(nTrials);
            
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
                f1RepAll(j,k) = mean(f1);
                f1RepSDAll(j,k) = std(f1)/sqrt(nTrials);
            else
                f1RepAll(j,k) = NaN;
                f1RepSDAll(j,k) = NaN;
            end
            
            Statistics((j-1)*length(cells)+k,:) = ...
                {c, u, ...
                tCurveAll(j,k),tCurveSEMAll(j,k), ...
                blankAll(j,k),blankSEMAll(j,k), ...
                tCurveCorrAll(j,k),tCurveCorrSEMAll(j,k), ...
                f1RepAll(j,k),f1RepSDAll(j,k), ...
                latency};
        end
    end
        
    % Merge all statistics into a table (faster to do like this at the end)
%     [u,c] = meshgrid(units,conditionNo);
%     Statistics = table(c(:), u(:),...
%         meanTrials(:),blankTrials(:),tCurveAll(:),tCurveSEMAll(:),...
%         blankAll(:),blankSEMAll(:),tCurveCorrAll(:),tCurveCorrSEMAll(:),...
%         f1RepAll(:),f1RepSDAll(:));
%     Statistics.Properties.VariableNames = ...
%         {'conditionNo','unit',...
%         'meanTrials','blankTrials',...
%         'tCurve','tCurveSEM','blank','blankSEM',...
%         'tCurveCorr','tCurveCorrSEM','f1Rep','f1RepSD'};

    % Save everything
    SpikeDataAll{i} = SpikeData;
    StatisticsAll{i} = Statistics;

end % Electrodes loop

% Accumulate results
for i = 1:length(whichElectrodes)
    elecNo = whichElectrodes(i); 
    Results.SpikeDataAll{elecNo} = SpikeDataAll{i};
    Results.StatisticsAll{elecNo} = StatisticsAll{i};
end
Results.StimTimes = StimTimes;
Results.Electrodes = Electrodes(:,{'name','number'});
Results.Params = Params;
Results.sourceFormat = sourceFormat;
Results.source = fileName;

% Save to mat file
if ~exist(dataPath,'dir')
    mkdir(dataPath);
end
resultsFile = fullfile(dataPath,[fileName,'.mat']);
r = matfile(resultsFile, 'Writable', true);
if isfield(r, 'analysis')
    analysis = r.analysis;
    ind = find(strcmp(analysis.sourceFormat, sourceFormat));
    if isempty(ind) || ind == 0
        analysis(end+1) = Results;
    else
        analysis(ind) = Results;
    end
    r.analysis = analysis;
else
    r.analysis = Results;
end
end

% Helper function for counting number of units for a given electrode
function count = countUnits(spikes)
if isempty(spikes)
    count = 0;
else
    count = length(unique(spikes(:,2)));
end
end