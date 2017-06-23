function plotAllResults(figuresPath, fileName, Params, Results,...
                        whichElectrodes, plotTCs, plotBars, plotRasters,...
                        plotMaps, summaryFig, plotLFP, showFigures, ...
                        clumpRasters)
%plotAllResults Function plotting Tuning Curves for different stimuli

% Check arguments
narginchk(5,13);
if isempty(Results)
    warning('Cannot plot results without results...');
    return; % Can't do anything. 
end

if nargin < 13 || isempty(clumpRasters)
    clumpRasters = 0;
end
if nargin < 12 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 11 || isempty(plotLFP)
    plotLFP = 0;
end
if nargin < 10 || isempty(summaryFig)
    summaryFig = 0;
end
if nargin < 9 || isempty(plotMaps)
    plotMaps = 0;
end
if nargin < 8 || isempty(plotRasters)
    plotRasters = 0;
end
if nargin < 7 || isempty(plotBars)
    plotBars = 0;
end
if nargin < 6 || isempty(plotTCs)
    plotTCs = 0;
end
if nargin < 5 || isempty(whichElectrodes)
    whichElectrodes = Results.Electrodes.number;
end
if showFigures; showFigures = 'on'; else; showFigures = 'off'; end

% Set up results
SpikeDataAll = Results.SpikeDataAll;
StatisticsAll = Results.StatisticsAll;

% Set up colors
nCells = cellfun(@(x) length(unique(x.cell)), SpikeDataAll);
cellColors = makeDefaultColors(nCells);

% If summary figures are requested, then cannot run in parallel
if summaryFig
    poolobj = gcp('nocreate');
    delete(poolobj);
end

% Go through each electrode
parfor i = 1:length(whichElectrodes)
    elecNo = whichElectrodes(i);

    SpikeData = SpikeDataAll{elecNo};
    Statistics = StatisticsAll{elecNo};
    cells = unique(SpikeData.cell);
    
    % Plotting Figures
    elecDir = sprintf('Ch%02d',elecNo);
    if ~isdir(fullfile(figuresPath,elecDir))
        mkdir(fullfile(figuresPath,elecDir))
    end
    
    for j = 1:length(cells)
        u = cells(j);
        
        % TC plots
        figBaseName = [fileName,'_',num2str(u),'El',num2str(elecNo)];
        
        tmpParams = Params;

        StatsUnit = Statistics(Statistics.cell == u,:);
        tCurve = StatsUnit.tCurve(StatsUnit.conditionNo); % sort properly
        
        SpikeDataUnit = SpikeData(SpikeData.cell == u,:);
        
        % Plot tuning curves
        if plotTCs
            
            % Basic tuning curve
            [tCurveFig, OSI, DI] = plotTCurve(StatsUnit, ...
                tmpParams, showFigures, elecNo, u);
            
            % Set the x-scale
            if ~isempty(strfind(tmpParams.stimType,'Looming')) || ...
                    ~isempty(strfind(tmpParams.stimType,'velocity'))
                set(gca,'xscale','log');
            end
            
            % File saving
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_tc']),...
%                 '-png', '-nocrop', '-m2', TCurveFig);
            saveas(tCurveFig,fullfile(figuresPath,elecDir,[figBaseName,'_tc.png']));
            %saveas(TCurveFig,fullfile(ResultsPath,ElecDir,[FigBaseName,'_tc']),'fig');
            
            % velocity tunning curves for preffered spatial and temporal
            % frequencies
            if ~(isempty(findstr(fileName,'R')) || ...
                    isempty(findstr(tmpParams.stimType,'Temporal')) && ...
                    isempty(findstr(tmpParams.stimType,'Spatial'))) %#ok<*FSTR>
                
                % Take velocities from the params file
                velParams = tmpParams;
                velConditions = unique(tmpParams.Data.velocity);
                velConditionNo = zeros(length(velConditions),1);
                for k = 1:length(velConditions)
                    velConditionNo(k) = ...
                        unique(tmpParams.Data.conditionNo(tmpParams.Data.velocity == ...
                        velConditions(k))); % should only be one!
                end
                velParams.Conditions.condition = velConditions;
                velParams.Conditions.conditionNo = velConditionNo;
                StatsUnit.conditionNo = velConditionNo;
                
                % Plot a figure
                velCurveFig = plotTCurve(StatsUnit, ...
                    velParams, showFigures, elecNo, u);
                set(gca,'xscale','log'); % use log scale
                
%                 export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_vel_tc']),...
%                     '-png', '-nocrop', '-m2', VelCurveFig);
                saveas(velCurveFig,fullfile(figuresPath,elecDir,[figBaseName,'_vel_tc.png']));
                close(velCurveFig);
            end
            
            % Making subplots of TC's for all electrodes
            if summaryFig == 1 && tmpParams.nElectrodes>1
                
                % Bring up a figure for this unit, separate from the tuning
                % curve figure that is open
                if ~ishandle(100+u)
                    figure(100+u);
                    set(gcf,'Visible',showFigures);
                    set(gcf,'Color','White');
                    set(gcf, 'UserData', 'summary');
                else
                    set(0,'CurrentFigure', 100+u);
                end
                
                % Set up subplots
                if tmpParams.nElectrodes==2
                    sub = subplot(1,2,i);
                elseif tmpParams.nElectrodes==3 || tmpParams.nElectrodes==4
                    sub = subplot(2,2,i);
                else
                    sub = subplot(ceil((tmpParams.nElectrodes)/4),4,i);
                end
                
                % Copy the tuning curve figure axis
                tCurveAxis = findobj('Parent',tCurveFig,'Type','axes');
                copyobj(get(tCurveAxis(1),'Children'),sub);
                
                % Title, axes, etc.
                titleStr = sprintf('Ch%d', elecNo);
                title(titleStr,'FontSize',3,'FontWeight','Normal');
                set(sub,'FontSize',3);
                if strfind(tmpParams.stimType, 'Ori')
                    set(sub,'XTick',[tmpParams.Conditions.condition; 360]);
                else
                    set(sub,'XTick',tmpParams.Conditions.condition);
                end
                box off;
                axis tight;
                
                % Set the x-scale
                switch tmpParams.stimType
                    case {'velocity', 'VelocityConstantCycles', ...
                            'VelocityConstantCyclesBar',...
                            'Looming'}
                        set(gca,'xscale','log');
                end
            end
            
            % Now we can close the tuning curve figure
            close(tCurveFig);
        end
        
        % Plot bar graphs
        if plotBars
            
            % Basic tuning curve
            barFig = plotBarGraph(StatsUnit, ...
                tmpParams, cellColors(j,:), showFigures, elecNo, u);
            
            % File saving
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_bar']),...
%                 '-png', '-nocrop', '-m2', BarFig);
            saveas(barFig,fullfile(figuresPath,elecDir,[figBaseName,'_bar.png']));

        end
        
        % Plotting rasters and histograms
        if plotRasters && size(Params.Conditions,1) <= 20 && ~clumpRasters
            
            [hRaster, hPSTH] = plotRastergrams( SpikeDataUnit, tmpParams, ...
                cellColors(j,:), showFigures, elecNo, u);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_raster']),...
%                 '-png', '-m3', '-p0.05', hRaster);
            saveas(hRaster,fullfile(figuresPath,elecDir,[figBaseName,'_raster.png']));

            close(hRaster);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_PSTHs']), ...
%                 '-png', '-m3', '-p0.05', hPSTH);
            saveas(hPSTH,fullfile(figuresPath,elecDir,[figBaseName,'_PSTHs.png']));
            close(hPSTH);
            
        elseif plotRasters
            
            % Lump conditions together for stimuli with many conditions
            rParams = tmpParams;
            rSpikeData = SpikeDataUnit;
            unpadded = rSpikeData.hist;
            minSize = min(cellfun('length',unpadded));
            hists = [];
            for k = 1:size(unpadded,1)
                hists{k,1} = unpadded{k}(1:minSize);
            end
            rSpikeData.hist = hists;
            
            rParams.Conditions = ...
                tmpParams.Conditions(find(tmpParams.Conditions.numBins == minSize,1),:);
            rParams.Conditions.condition = NaN;
            rParams.Conditions.conditionNo = 1;
            
            rSpikeData.c = ones(size(rSpikeData,1),1);
            [~, ix] = sort(SpikeDataUnit.conditionNo); % sort by condition
            rSpikeData.t = [1:size(rSpikeData,1)]';
            rSpikeData = rSpikeData(ix,:);
            
            [hRaster, hPSTH] = plotRastergrams( rSpikeData, rParams, ...
                cellColors(j,:), showFigures, elecNo, u );
            
            % draw lines between the condition boundaries
            rcondNo = SpikeDataUnit(ix,:).conditionNo;
            rTrialNo = rSpikeData.t;
            minX = min(rParams.Conditions.centers{:});
            maxX = max(rParams.Conditions.centers{:});
            set(0,'CurrentFigure',hRaster);
            hold on;
            for k = 1:length(rcondNo)-1
                if rcondNo(k) ~= rcondNo(k+1)
                    plot([minX maxX],[rSpikeData.t(k) rSpikeData.t(k)],'k:');
                end
            end
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_raster']),...
%                 '-png', '-m3', '-p0.05', hRaster);
            saveas(hRaster,fullfile(figuresPath,elecDir,[figBaseName,'_raster_all.png']));

            close(hRaster);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_PSTHs']), ...
%                 '-png', '-m3', '-p0.05', hPSTH);
            saveas(hPSTH,fullfile(figuresPath,elecDir,[figBaseName,'_PSTHs_all.png']));
            close(hPSTH);
        end
        
        % Plot maps
        if plotMaps
            
            if strfind(tmpParams.stimType, 'BackProject')
                
                % Use the back-projection method to plot an RF map
                binSize = min(tmpParams.Conditions.binSize);
    
                % Get the hists
                histograms = cell2mat(SpikeDataUnit.hist);
                histograms = histograms./binSize; % spike density
                directions = SpikeDataUnit.conditionNo;
                
                % Calculate latency
                latencies = 0.03:0.01:0.2; % 30 - 200 ms
                mapMax = zeros(length(latencies),1);
                maps = cell(size(histograms,2),1);
                for k = 1:length(latencies)
                    lat = latencies(k);
                    data = [];
                    for dir=1:length(directions)
                        
                        % How many bins to shift
                        shift = ceil(lat/binSize*cosd(directions(dir))); 
                        
                        % Shift each histogram
                        if shift < 0
                            data(dir,:) = [histograms(dir,shift:end), zeros(1,shift)];
                        else
                            data(dir,:) = [zeros(1,shift), histograms(dir,1:end-shift)];
                        end
                    end
                    maps{k} = back_project(data, directions);
                    mapMax(k) = max(maps{k});
                end
                
                [~, idx] = max(mapMax);
                bestLatency = latencies(idx);
                fprintf('Latency calculated to %d ms\n', bestLatency*1000);
                bestMap = maps{idx};
                hMap = plotBackProjection(bestMap, tmpParams, showFigures);
                
            else
                hMap = plotMap(tCurve, tmpParams, showFigures, elecNo, u);
            end
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_RFMap']), ...
%                 '-png', '-m2', '-p0.05', hMap);
            saveas(hMap,fullfile(figuresPath,elecDir,[figBaseName,'_RFMap.png']));
            close(hMap);
            
        end
        
    end % Units loop
end % Electrodes loop
    
% Save summary figures if any are open
if summaryFig
    summaryDir = 'Summary';
    if ~isdir(fullfile(figuresPath,summaryDir))
        mkdir(fullfile(figuresPath,summaryDir))
    end
    sumFigs = findall(0,'type','figure', 'UserData', 'summary');
    for u = 1:length(sumFigs)
        unit = sumFigs(u).Number - 100;
        figBaseName = [fileName,'_',num2str(unit)];
        
        set(0,'CurrentFigure',100+unit);
        suptitle(sprintf('%d[%s] C %d summary', Params.expNo,...
            Params.stimType, unit));
%         export_fig(fullfile(ResultsPath,SummaryDir,[FigBaseName,'_summary']),...
%             '-png', '-m3', '-nocrop', gcf);
        saveas(gcf,fullfile(figuresPath,summaryDir,[figBaseName,'_summary.png']));
        close(gcf);
    end
end

disp('...done');

end