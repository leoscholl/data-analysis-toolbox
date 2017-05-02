function plotResults(resultsPath, fileName, stimType, ...
    Params, StimTimes, Electrodes, ...
    plotTCs, plotBars, plotRasters, plotMaps, summaryFig, ...
    plotLFP, showFigures)
%PlotResults Function plotting Tuning Curves for different stimuli

% Parameters
Params.BlankPeriod = 0.5; % how much time to consider blank (only if
% StimInterval >= BlankPeriod)
Params.ResponseLag = 0.03; % delay between stimulus and response (ms)

if showFigures; showFigures = 'on'; else showFigures = 'off'; end
sumFigs = [];

% Set up colors
colors = ['k';'b';'g';'c';'r'];
for c = 1:length(colors)
    unitColors(c,:) = rem(floor((strfind('kbgcrmyw', colors(c)) - 1) * [0.25 0.5 1]), 2);
end

Params.NoOfElectrodes = size(Electrodes,1);

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
if strcmp(Params.AnimalID,'C1504') && strcmp(stimType,'Contrast')
    Conditions = [19.45,34.10,46.82,62.90,73.50,81.82,92.52,97.26];
end
if strcmp(stimType,'CenterSurround') || strcmp(stimType,'OriDomains')
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
for el = 1:Params.NoOfElectrodes
    
    % Collect spike times for this electrode
    elecNo = Electrodes.number(el);
    SpikeTimes = Electrodes.spikes{elecNo};
    
    ElectrodeName = Electrodes.name{elecNo};
    fprintf('%s',ElectrodeName);
    
    if isempty(SpikeTimes)
        fprintf(2, 'No spikes for %s...');
        continue;
    end
    
    Units = unique(SpikeTimes(:,2));
    
    % Initialize the data structures
    SpikeDataAll = table([],[],[],cell(0),cell(0),cell(0));
    SpikeDataAll.Properties.VariableNames = ...
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
    for i = 1:length(ConditionNo)
        
        c = ConditionNo(i);
        Stimuli = Params.Data(Params.Data.ConditionNo == c,:);
        Condition = Params.Conditions(Params.Conditions.CondNo == c,:);
        binsize = Condition.binsize;
        
        % Pick out the pre-stimulus and peri-stimulus times
        Centers = cell2mat(Condition.Centers);
        Which = Centers>=0 & Centers < Condition.StimDuration+Params.ResponseLag;
        WhichBlank = Centers<0;
        
        for u = 1:length(Units)
            Unit = Units(u);
            
            % Make Rasters and Histograms
            for t = 1:size(Stimuli,1) % how many trials for this condition
                
                % Raster plots, histograms and ISIs
                StimTime = Stimuli.StimTime(t);
                StimOffTime = Stimuli.StimOffTime(t);
                Spikes = SpikeTimes(SpikeTimes(:,2) == Unit & ...
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
                
                SpikeDataAll = [SpikeDataAll; ...
                    {c,t,u,Raster,Hist',ISIs}];
            end
            
            % Prepare Trials x Centers matrix for histogram
            Hists = cell2mat(SpikeDataAll.Hist(SpikeDataAll.c == c ...
                & SpikeDataAll.u == u)');
            ISIs = SpikeDataAll.ISIs(SpikeDataAll.c == c ...
                & SpikeDataAll.u == u);
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
            MeanTrials{c,u} = NumCounts./(binsize*size(PSTH,1)); % average over time
            BlankTrials{c,u} = NumCountsBlank./(binsize*size(PreStimulus,1)); % average over time
            TCurveAll(c,u) = mean(MeanTrials{c,u}); % average over time and trials
            BlankAll(c,u) = mean(BlankTrials{c,u}); % average over time and trials
            
            % SEMs
            TCurveSEMAll(c,u) = std(MeanTrials{c,u})/sqrt(nTrials); % average over time and STD over trials
            BlankSEMAll(c,u) = std(BlankTrials{c,u})/sqrt(nTrials);% average over time and STD over trials
            
            % Corrected mean firing rates
            TCurveCorrAll(c,u) = TCurveAll(c,u)-BlankAll(c,u);
            TCurveCorrSEMAll(c,u) = std(MeanTrials{c,u}-BlankTrials{c,u})/sqrt(nTrials);
            
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
                
                F1RepAll(c,u) = mean(F1);
                F1RepSDAll(c,u) = std(F1)/sqrt(nTrials);
            else
                F1RepAll(c,u) = NaN;
                F1RepSDAll(c,u) = NaN;
            end
        end
    end
    
    % Merge all statistics into a table
    [c,u] = meshgrid(ConditionNo,Units);
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
    
    %% Plotting Figures
    ElecNo = ElectrodeName(findstr(ElectrodeName,'c')+1:end);
    ElecDir = sprintf('Ch%02d',str2num(ElecNo));
    SummaryDir = 'Summary';
    if ~isdir(fullfile(resultsPath,ElecDir))
        mkdir(fullfile(resultsPath,ElecDir))
    end
    
    for u = 1:length(Units)
        
        % TC plots
        FigBaseName = [fileName,'_',num2str(Units(u)),'El',ElecNo];
        Params.Unit = Units(u);
        Params.UnitNo = u;
        Params.ElecNo = el;
        
        TCurve = TCurveAll(:,u);
        TCurveSEM = TCurveSEMAll(:,u);
        Blank = BlankAll(:,u);
        BlankSEM = BlankSEMAll(:,u);
        TCurveCorr = TCurveCorrAll(:,u);
        TCurveCorrSEM = TCurveCorrSEMAll(:,u);
        if ~(isempty(F1RepAll) || isempty(F1RepSDAll))
            F1Rep = F1RepAll(:,u);
            F1RepSD = F1RepSDAll(:,u);
        else
            F1Rep = [];
            F1RepSD = [];
        end
        
        SpikeData = SpikeDataAll(SpikeDataAll.u == u,:);
        
        % Plot tuning curves
        if plotTCs
            
            % Basic tuning curve
            [TCurveFig, OSI, DI] = PlotTCurve(TCurve, TCurveSEM, Blank, ...
                BlankSEM, F1Rep, F1RepSD, TCurveCorr, TCurveCorrSEM, ...
                Params, showFigures);
            
            % Set the x-scale
            if ~isempty(strfind(Params.StimType,'Looming')) || ...
                    ~isempty(strfind(Params.StimType,'Velocity'))
                set(gca,'xscale','log');
            end
            
            % File saving
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_tc']),...
%                 '-png', '-nocrop', '-m2', TCurveFig);
            saveas(TCurveFig,fullfile(resultsPath,ElecDir,[FigBaseName,'_tc.png']));
            %saveas(TCurveFig,fullfile(ResultsPath,ElecDir,[FigBaseName,'_tc']),'fig');
            
            % Velocity tunning curves for preffered spatial and temporal
            % frequencies
            if 0
            %if ~(isempty(findstr(FileName,'R')) || isempty(findstr(StimType,'Temporal')) && isempty(findstr(StimType,'Spatial'))) %#ok<*FSTR>
                
                % Take velocities from the params file
                VelParams = Params;
                VelConditions = unique(Params.Data.Velocity);
                VelConditionNo = zeros(length(Conditions),1);
                for i = 1:length(Conditions)
                    VelConditionNo(i) = ...
                        unique(Params.Data.ConditionNo(Params.Data.Velocity == ...
                        VelConditions(i))); % should only be one!
                end
                VelParams.Conditions.Cond = VelConditions;
                VelParams.Conditions.CondNo = VelConditionNo;
                
                % Plot a figure
                VelCurveFig = PlotTCurve(TCurve, TCurveSEM, Blank, BlankSEM, ...
                    F1Rep, F1RepSD, TCurveCorr, TCurveCorrSEM, ...
                    VelParams, ShowFigures);
                set(gca,'xscale','log'); % use log scale
                
%                 export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_vel_tc']),...
%                     '-png', '-nocrop', '-m2', VelCurveFig);
                saveas(VelCurveFig,fullfile(ResultsPath,ElecDir,[FigBaseName,'_vel_tc.png']));
                close(VelCurveFig);
            end
            
            % Making subplots of TC's for all electrodes
            if summaryFig == 1 && Params.NoOfElectrodes>1
                
                % Bring up a figure for this unit, separate from the tuning
                % curve figure that is open
                if u>length(sumFigs)
                    sumFigs(u) = figure(100+u);
                    set(sumFigs(u),'Visible',showFigures);
                    set(sumFigs(u),'Color','White');
                else
                    set(0,'CurrentFigure', sumFigs(u));
                end
                SummaryUnits(u) = Units(u);
                
                % Set up subplots
                if Params.NoOfElectrodes==2
                    sub = subplot(1,2,el);
                elseif Params.NoOfElectrodes==3 || Params.NoOfElectrodes==4
                    sub = subplot(2,2,el);
                else
                    sub = subplot(ceil((Params.NoOfElectrodes)/4),4,el);
                end
                
                % Copy the tuning curve figure axis
                TCurveAxis = findobj('Parent',TCurveFig,'Type','axes');
                copyobj(get(TCurveAxis(1),'Children'),sub);
                
                % Title, axes, etc.
                Title = sprintf('Ch%d', Params.ElecNo);
                title(Title,'FontSize',3,'FontWeight','Normal');
                set(sub,'FontSize',3);
                set(sub,'XTick',Params.Conditions);
                box off;
                axis tight;
                
                % Set the x-scale
                switch Params.StimType
                    case {'Velocity', 'VelocityConstantCycles', ...
                            'VelocityConstantCyclesBar',...
                            'Looming'}
                        set(gca,'xscale','log');
                end
            end
            
            % Now we can close the tuning curve figure
            close(TCurveFig);
        end
        
        % Plot bar graphs
        if plotBars
            
            % Basic tuning curve
            BarFig = PlotBarGraph(TCurve, TCurveSEM, Blank, BlankSEM, ...
                Params, showFigures);
            
            % File saving
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_bar']),...
%                 '-png', '-nocrop', '-m2', BarFig);
            saveas(BarFig,fullfile(resultsPath,ElecDir,[FigBaseName,'_bar.png']));

        end
        
        % Plotting rasters and histograms
        if plotRasters && length(ConditionNo) <= 20
            
            [hRaster, hPSTH] = PlotRastergrams( SpikeData, Params, ...
                [unitColors; hsv(length(Units) - 5)], showFigures );
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_raster']),...
%                 '-png', '-m3', '-p0.05', hRaster);
            saveas(hRaster,fullfile(resultsPath,ElecDir,[FigBaseName,'_raster.png']));

            close(hRaster);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_PSTHs']), ...
%                 '-png', '-m3', '-p0.05', hPSTH);
            saveas(hPSTH,fullfile(resultsPath,ElecDir,[FigBaseName,'_PSTHs.png']));
            close(hPSTH);
            
        elseif plotRasters
            
            % Lump conditions together for stimuli with many conditions
            rParams = Params;
            rSpikeData = SpikeData;
            unpadded = rSpikeData.Hist;
            minSize = min(cellfun('length',unpadded));
            Hists = [];
            for j = 1:size(unpadded,1)
                Hists{j,1} = unpadded{j}(1:minSize);
            end
            rSpikeData.Hist = Hists;
            
            rParams.Conditions = ...
                Params.Conditions(find(Params.Conditions.numbins == minSize,1),:);
            rParams.Conditions.Cond = NaN;
            rParams.Conditions.CondNo = 1;
            
            rSpikeData.c = ones(size(rSpikeData,1),1);
            [~, ix] = sort(SpikeData.c); % sort by condition
            rSpikeData.t = [1:size(rSpikeData,1)]';
            rSpikeData = rSpikeData(ix,:);
            
            [hRaster, hPSTH] = PlotRastergrams( rSpikeData, rParams, ...
                [unitColors; hsv(length(Units) - 5)], showFigures );
            
            % draw lines between the condition boundaries
            rCondNo = SpikeData(ix,:).c;
            rTrialNo = rSpikeData.t;
            minX = min(rParams.Conditions.Centers{:});
            maxX = max(rParams.Conditions.Centers{:});
            set(0,'CurrentFigure',hRaster);
            hold on;
            for i = 1:length(rCondNo)-1
                if rCondNo(i) ~= rCondNo(i+1)
                    plot([minX maxX],[rSpikeData.t(i) rSpikeData.t(i)],'k:');
                end
            end
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_raster']),...
%                 '-png', '-m3', '-p0.05', hRaster);
            saveas(hRaster,fullfile(resultsPath,ElecDir,[FigBaseName,'_raster.png']));

            close(hRaster);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_PSTHs']), ...
%                 '-png', '-m3', '-p0.05', hPSTH);
            saveas(hPSTH,fullfile(resultsPath,ElecDir,[FigBaseName,'_PSTHs.png']));
            close(hPSTH);
        end
        
        % Plot maps
        if plotMaps
            
            hMap = PlotMap(TCurve, Params, showFigures);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_RFMap']), ...
%                 '-png', '-m2', '-p0.05', hMap);
            saveas(hMap,fullfile(resultsPath,ElecDir,[FigBaseName,'_RFMap.png']));
            close(hMap);
            
        end
        
        fprintf('.'); % status update
        
    end % Units loop
    
    % Save everything
    Results(el).Electrodes = Electrodes;
    Results(el).SpikeData = SpikeDataAll;
    Results(el).Statistics = Statistics;

end; % Electrodes loop

save(fullfile(resultsPath,[fileName,'-results.mat']),...
        'Params','Results');
    
% Save summary figures if any are open
if summaryFig
    if ~isdir(fullfile(resultsPath,SummaryDir))
        mkdir(fullfile(resultsPath,SummaryDir))
    end
    for u = 1:length(sumFigs)
        Unit = SummaryUnits(u);
        FigBaseName = [fileName,'_',num2str(Units(u))];
        
        set(0,'CurrentFigure',sumFigs(u));
        suptitle(sprintf('%d[%s] C %d summary', Params.ExpNo,...
            Params.StimType, Unit));
%         export_fig(fullfile(ResultsPath,SummaryDir,[FigBaseName,'_summary']),...
%             '-png', '-m3', '-nocrop', SumFigs(u));
        saveas(sumFigs(u),fullfile(resultsPath,SummaryDir,[FigBaseName,'_summary.png']));
        close(sumFigs(u));
    end
end

disp('...done');

end