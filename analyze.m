function [Params, Results] = analyze(resultsPath, fileName, ...
    Params, StimTimes, Electrodes, whichElectrodes)
%analyze Function making PSTH, rasters, and ISIs for data in Electrodes

if nargin < 7
    whichElectrodes = Electrodes.number;
end

% Parameters
Params.blankPeriod = 0.5; % how much time to consider blank (only if
% stimInterval >= blankPeriod)
Params.responseLag = 0.1; % delay between stimulus and response (ms)

% Which electrodes to processes
Params.nElectrodes = length(whichElectrodes);
Params.whichElectrodes = whichElectrodes;
Results = [];

% Add stimulus offsets to Data table
nTrials = Params.nTrials;
if nTrials < 2
    warning('Not enough trials');
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
    conditionNo(i) = unique(Params.Data.conditionNo(sum(Params.Data.condition == ...
        conditions(i,:),2) == size(Params.Data.condition,2))); % should only be one!
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
            numBins = 200;
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

% All electrodes
nUnits = cellfun(@(x) length(unique(x(:,2))), Electrodes.spikes)';
fprintf('%d electrodes with %s units (analyzing %d)\n', Params.nElectrodes, ...
    mat2str(nUnits), length(whichElectrodes));
for i = 1:length(whichElectrodes)
    elecNo = whichElectrodes(i);
    
    % Collect spike times for this electrode
    spikeTimes = Electrodes.spikes{elecNo};
    
    electrodeName = Electrodes.name{elecNo};
    
    if isempty(spikeTimes)
        fprintf(2, 'No spikes for %s...');
        continue;
    end
    
    units = unique(spikeTimes(:,2));
    
    % Initialize the data structures
    SpikeData = table([],[],[],cell(0),cell(0),cell(0));
    SpikeData.Properties.VariableNames = ...
        {'c','t','u','raster','hist','isi'};
    Statistics = nan(length(conditionNo)*length(units),10);
    Statistics = array2table(Statistics);
    Statistics.Properties.VariableNames = ...
        {'conditionNo','unit',...
        'tCurve','tCurveSEM','blank','blankSEM',...
        'tCurveCorr','tCurveCorrSEM','f1Rep','f1RepSD'};
    meanTrials = cell(length(conditionNo),length(units));
    blankTrials = cell(length(conditionNo),length(units));
    tCurveAll = zeros(length(conditionNo),length(units));
    tCurveSEMAll = zeros(length(conditionNo),length(units));
    blankAll = zeros(length(conditionNo),length(units));
    blankSEMAll = zeros(length(conditionNo),length(units));
    tCurveCorrAll = zeros(length(conditionNo),length(units));
    tCurveCorrSEMAll = zeros(length(conditionNo),length(units));
    f1RepAll = nan(length(conditionNo),length(units));
    f1RepSDAll = nan(length(conditionNo),length(units));
    
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
        
        for k = 1:length(units)
            u = units(k);
            
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
                    {c,t,u,raster,hist',isi}];
            end
            
            % Prepare Trials x Centers matrix for histogram
            hists = cell2mat(SpikeData.hist(SpikeData.c == c ...
                & SpikeData.u == u)');
            
            % Statistics
            psth = hists(which,:);
            preStimulus = hists(whichBlank,:);
            numCounts = sum(psth,1);
            numCountsBlank = sum(preStimulus,1);
            
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
            if ismember('TF', Params.Data.Properties.VariableNames)
                %                 T = 0.5;
                %                 N = floor(T/binSize);
                % Pad with zeros to get a better idea of Y at f=TF
                N = max(size(psth,1), floor(1/binSize/min(Stimuli.TF)));
                psthPad = [psth; zeros(N - size(psth,1), size(psth,2))];
                T = N*binSize;
                Y = fft(psthPad(1:N,:)./binSize,[],1);
                psthSpectra = abs(Y(1:floor(N/2),:))/floor(N/2);
                specFreq = 0:1/T:floor((N-1)/T/2);
                f1 = psthSpectra(find(specFreq>=min(Stimuli.TF)-0.05,1),:);
                
                f1RepAll(j,k) = mean(f1);
                f1RepSDAll(j,k) = std(f1)/sqrt(nTrials);
            else
                f1RepAll(j,k) = NaN;
                f1RepSDAll(j,k) = NaN;
            end
            
            Statistics((j-1)*length(units)+k,:) = ...
                {c, u, ...
                tCurveAll(j,k),tCurveSEMAll(j,k), ...
                blankAll(j,k),blankSEMAll(j,k), ...
                tCurveCorrAll(j,k),tCurveCorrSEMAll(j,k), ...
                f1RepAll(j,k),f1RepSDAll(j,k)};
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
    Results.Electrodes = Electrodes;
    Results.SpikeDataAll{elecNo} = SpikeData;
    Results.StatisticsAll{elecNo} = Statistics;
    Results.StimTimes = StimTimes;

end; % Electrodes loop

if ~exist(resultsPath,'dir')
    mkdir(resultsPath);
end
save(fullfile(resultsPath,[fileName,'-results.mat']),...
        'Params','Results');

end