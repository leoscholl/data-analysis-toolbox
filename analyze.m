function [Params, Results] = analyze(resultsPath, fileName, ...
    Params, StimTimes, Electrodes, whichElectrodes)
%analyze Function making PSTH, rasters, and ISIs for data in Electrodes

if nargin < 7
    whichElectrodes = Electrodes.number;
end

% Parameters
Params.BlankPeriod = 0.5; % how much time to consider blank (only if
% StimInterval >= BlankPeriod)
Params.ResponseLag = 0.1; % delay between stimulus and response (ms)

% Which electrodes to processes
Params.NoOfElectrodes = length(whichElectrodes);
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
Params.Data.StimTime = StimTimes.on(1:nStims);
Params.Data.StimOffTime = StimTimes.off(1:nStims);
Params.Data.StimDiffTime = [StimTimes.on(2:nStims); NaN] - StimTimes.on(1:nStims);

% Determine conditions
Conditions = unique(Params.Data.Condition(1:nStims,:),'rows');
Conditions = reshape(Conditions, nConds, size(Params.Data.Condition,2));

% Make corrections to the conditions
if strcmp(Params.StimType,'CatApertureSmall') && Conditions(end) == 30
    Conditions(end) = 15; % fixing cat aperture
end
if strcmp(Params.AnimalID,'C1504') && strcmp(Params.StimType,'Contrast')
    Conditions = [19.45,34.10,46.82,62.90,73.50,81.82,92.52,97.26];
end
if strcmp(Params.StimType,'CenterSurround') || strcmp(Params.StimType,'OriDomains')
    Conditions(Conditions<0) = Conditions(Conditions<0)*10;
end

% Determine condition numbers and sort conditions properly
ConditionNo = zeros(length(Conditions),1);
for i = 1:length(Conditions)
    ConditionNo(i) = unique(Params.Data.ConditionNo(sum(Params.Data.Condition == ...
        Conditions(i,:),2) == size(Params.Data.Condition,2))); % should only be one!
end
Params.Conditions = table([],[],[],[],[],[],[],[],cell(0),cell(0));
Params.Conditions.Properties.VariableNames = ...
    {'CondNo','Cond','StimDuration','StimInterval','StimDiffTime',...
    'numbins','binsize','TimeFrom','Time','Centers'};

% Determine per-condition parameters
for i = 1:length(ConditionNo)
    c = ConditionNo(i);
    
    Stimuli = Params.Data(Params.Data.ConditionNo == c,:);
    
    % Variable bin size or number of bins
    switch Params.BinType
        case 'number'
            StimDiffTime = min(Stimuli.StimDiffTime); % This cond
            numbins = 200;
            binsize = StimDiffTime/numbins;
        case 'size'
            StimDiffTime = min(Stimuli.StimDiffTime); % This cond
%             StimDiffTime = min(Params.Data.StimDiffTime); % All stimuli
            binsize = 0.01;
            numbins = floor(StimDiffTime/binsize);
    end
    
    % Pick out the peri-stimulus times and bin centers
    StimDuration = min(Stimuli.StimDuration);
    StimInterval = min(Stimuli.StimInterval);
    TimeFrom = min(StimInterval/2, Params.BlankPeriod);
    Time = -TimeFrom:binsize:StimDiffTime-TimeFrom;
    Centers = Time(1:end-1) + diff(Time)/2;
    
    % Save everything to a table
    Params.Conditions = [Params.Conditions; ...
        {c, Conditions(c,:), StimDuration, StimInterval, StimDiffTime,...
        numbins, binsize, TimeFrom, Time, Centers}];
end

clear StimDiffTime StimDuration StimInterval TimeFrom Time Centers ...
    numbins binsize

% All electrodes
fprintf('%d electrodes\n', Params.NoOfElectrodes);
for i = 1:length(whichElectrodes)
    elecNo = whichElectrodes(i);
    
    % Collect spike times for this electrode
    SpikeTimes = Electrodes.spikes{elecNo};
    
    ElectrodeName = Electrodes.name{elecNo};
    fprintf('%s',ElectrodeName);
    
    if isempty(SpikeTimes)
        fprintf(2, 'No spikes for %s...');
        continue;
    end
    
    Units = unique(SpikeTimes(:,2));
    
    % Initialize the data structures
    SpikeData = table([],[],[],cell(0),cell(0),cell(0));
    SpikeData.Properties.VariableNames = ...
        {'c','t','u','Raster','Hist','ISIs'};
    MeanTrials = cell(length(ConditionNo),length(Units));
    BlankTrials = cell(length(ConditionNo),length(Units));
    TCurveAll = zeros(length(ConditionNo),length(Units));
    TCurveSEMAll = zeros(length(ConditionNo),length(Units));
    BlankAll = zeros(length(ConditionNo),length(Units));
    BlankSEMAll = zeros(length(ConditionNo),length(Units));
    TCurveCorrAll = zeros(length(ConditionNo),length(Units));
    TCurveCorrSEMAll = zeros(length(ConditionNo),length(Units));
    F1RepAll = nan(length(ConditionNo),length(Units));
    F1RepSDAll = nan(length(ConditionNo),length(Units));
    
    %% Analysis
    for j = 1:length(ConditionNo)
        
        c = ConditionNo(j);
        Stimuli = Params.Data(Params.Data.ConditionNo == c,:);
        Condition = Params.Conditions(Params.Conditions.CondNo == c,:);
        binsize = Condition.binsize;
        
        % Pick out the pre-stimulus and peri-stimulus times
        Centers = cell2mat(Condition.Centers);
        Which = Centers>=0 & Centers < Condition.StimDuration+Params.ResponseLag;
        WhichBlank = Centers<0;
        
        for k = 1:length(Units)
            u = Units(k);
            
            % Make Rasters and Histograms
            for t = 1:size(Stimuli,1) % how many trials for this condition
                
                % Raster plots, histograms and ISIs
                StimTime = Stimuli.StimTime(t);
                StimOffTime = Stimuli.StimOffTime(t);
                Spikes = SpikeTimes(SpikeTimes(:,2) == u & ...
                    SpikeTimes(:,1) >= StimTime-Condition.TimeFrom & ...
                    SpikeTimes(:,1) < StimTime+Condition.StimDiffTime);
                if ~isempty(Spikes)
                    Raster = Spikes - StimTime;
                    Hist = histcounts(Raster,cell2mat(Condition.Time));
                    if length(Spikes) > 1
                        ISIs = diff(Raster);
                    else
                        ISIs = [];
                    end
                else
                    Raster = [];
                    Hist = zeros(1,length(Centers));
                    ISIs = [];
                end
                
                SpikeData = [SpikeData; ...
                    {c,t,u,Raster,Hist',ISIs}];
            end
            
            % Prepare Trials x Centers matrix for histogram
            Hists = cell2mat(SpikeData.Hist(SpikeData.c == c ...
                & SpikeData.u == u)');
            ISIs = SpikeData.ISIs(SpikeData.c == c ...
                & SpikeData.u == u);
            if ~isempty(ISIs)
                ISIs = vertcat(ISIs{:});
            else
                ISIs = [];
            end
            
            % Statistics
            PSTH = Hists(Which,:);
            PreStimulus = Hists(WhichBlank,:);
            NumCounts = sum(PSTH,1);
            NumCountsBlank = sum(PreStimulus,1);
            
            % Calculate mean firing
            MeanTrials{j,k} = NumCounts./(binsize*size(PSTH,1)); % average over time
            BlankTrials{j,k} = NumCountsBlank./(binsize*size(PreStimulus,1)); % average over time
            TCurveAll(j,k) = mean(MeanTrials{j,k}); % average over time and trials
            BlankAll(j,k) = mean(BlankTrials{j,k}); % average over time and trials
            
            % SEMs
            TCurveSEMAll(j,k) = std(MeanTrials{j,k})/sqrt(nTrials); % average over time and STD over trials
            BlankSEMAll(j,k) = std(BlankTrials{j,k})/sqrt(nTrials);% average over time and STD over trials
            
            % Corrected mean firing rates
            TCurveCorrAll(j,k) = TCurveAll(j,k)-BlankAll(j,k);
            TCurveCorrSEMAll(j,k) = std(MeanTrials{j,k}-BlankTrials{j,k})/sqrt(nTrials);
            
            % FFT analysis
            if ismember('TF', Params.Data.Properties.VariableNames)
                %                 T = 0.5;
                %                 N = floor(T/binsize);
                % Pad with zeros to get a better idea of Y at f=TF
                N = max(size(PSTH,1), floor(1/binsize/min(Stimuli.TF)));
                PSTH_pad = [PSTH; zeros(N - size(PSTH,1), size(PSTH,2))];
                T = N*binsize;
                Y = fft(PSTH_pad(1:N,:)./binsize,[],1);
                PSTHspectra = abs(Y(1:floor(N/2),:))/floor(N/2);
                SpecFreq = 0:1/T:floor((N-1)/T/2);
                F1 = PSTHspectra(find(SpecFreq>=min(Stimuli.TF)-0.05,1),:);
                
                F1RepAll(j,k) = mean(F1);
                F1RepSDAll(j,k) = std(F1)/sqrt(nTrials);
            else
                F1RepAll(j,k) = NaN;
                F1RepSDAll(j,k) = NaN;
            end
        end
    end
    
    fprintf('.');
    
    % Merge all statistics into a table
    [u,c] = meshgrid(Units,ConditionNo);
    Statistics = table(c(:), u(:),...
        MeanTrials(:),BlankTrials(:),TCurveAll(:),TCurveSEMAll(:),...
        BlankAll(:),BlankSEMAll(:),TCurveCorrAll(:),TCurveCorrSEMAll(:),...
        F1RepAll(:),F1RepSDAll(:));
    Statistics.Properties.VariableNames = ...
        {'CondNo','Unit',...
        'MeanTrials','BlankTrials',...
        'TCurve','TCurveSEM','Blank','BlankSEM',...
        'TCurveCorr','TCurveCorrSEM','F1Rep','F1RepSD'};
    
    fprintf('.'); % status update

    % Save everything
    Results.Electrodes = Electrodes;
    Results.SpikeDataAll{elecNo} = SpikeData;
    Results.StatisticsAll{elecNo} = Statistics;

end; % Electrodes loop

if ~exist(resultsPath,'dir')
    mkdir(resultsPath);
end
save(fullfile(resultsPath,[fileName,'-results.mat']),...
        'Params','Results');
disp('...done');

end