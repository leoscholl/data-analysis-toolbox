function plotAllResults(figuresPath, fileName, Results,...
                        whichElectrodes, plotTCs, plotBars, plotRasters,...
                        plotMaps, summaryFig, plotLFP, showFigures)
%plotAllResults Function plotting Tuning Curves for different stimuli

% Check arguments
narginchk(4,12);
if isempty(Results)
    warning('Cannot plot results without results...');
    return; % Can't do anything. 
end

if nargin < 11 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 10 || isempty(plotLFP)
    plotLFP = 0;
end
if nargin < 9 || isempty(summaryFig)
    summaryFig = 0;
end
if nargin < 8 || isempty(plotMaps)
    plotMaps = 0;
end
if nargin < 7 || isempty(plotRasters)
    plotRasters = 0;
end
if nargin < 6 || isempty(plotBars)
    plotBars = 0;
end
if nargin < 5 || isempty(plotTCs)
    plotTCs = 0;
end
if nargin < 4 || isempty(whichElectrodes)
    whichElectrodes = [Results.spike.electrodeid];
end
if showFigures; showFigures = 'on'; else; showFigures = 'off'; end

% Set up broadcast variables
Params = Results.Params;
spike = Results.spike;

% If summary figures are requested, then cannot run in parallel
if summaryFig
    poolobj = gcp('nocreate');
    delete(poolobj);
end

% Go through each electrode
parfor i = 1:length(whichElectrodes)
    elecNo = spike(i).electrodeid;

    SpikeData = spike(i).Data;
    Statistics = spike(i).Statistics;
    
    if isempty(SpikeData) || isempty(Statistics)
        continue;
    end
    cells = unique(SpikeData.cell);
    cellColors = makeDefaultColors(cells);
    
    % Plotting Figures
    elecDir = sprintf('Ch%02d',elecNo);
    if ~isdir(fullfile(figuresPath,elecDir))
        mkdir(fullfile(figuresPath,elecDir))
    end
    
    for j = 1:length(cells)
        u = cells(j);
        
        % TC plots
        figBaseName = [fileName,'_',num2str(u),'El',num2str(elecNo)];
        
        StatsUnit = Statistics(Statistics.cell == u,:);
        SpikeDataUnit = SpikeData(SpikeData.cell == u,:);
        
        % Plot tuning curves
        if plotTCs
            
            % Basic tuning curve
            [tCurveFig, OSI, DI] = plotTCurve(StatsUnit, ...
                Params, showFigures, elecNo, u);
            
            % Set the x-scale
            if ~isempty(strfind(Params.stimType,'Looming')) || ...
                    contains(lower(Params.stimType),'velocity')
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
                    isempty(findstr(Params.stimType,'Temporal')) && ...
                    isempty(findstr(Params.stimType,'Spatial'))) %#ok<*FSTR>
                
                % Take velocities from the params file
                velParams = Params;
                velConditions = unique(Params.Data.velocity);
                velConditionNo = zeros(length(velConditions),1);
                for k = 1:length(velConditions)
                    velConditionNo(k) = ...
                        unique(Params.Data.conditionNo(Params.Data.velocity == ...
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
            if summaryFig == 1 && Params.nElectrodes>1
                
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
                if Params.nElectrodes==2
                    sub = subplot(1,2,i);
                elseif Params.nElectrodes==3 || Params.nElectrodes==4
                    sub = subplot(2,2,i);
                else
                    sub = subplot(ceil((Params.nElectrodes)/4),4,i);
                end
                
                % Copy the tuning curve figure axis
                tCurveAxis = findobj('Parent',tCurveFig,'Type','axes');
                copyobj(get(tCurveAxis(1),'Children'),sub);
                
                % Title, axes, etc.
                titleStr = sprintf('Ch%d', elecNo);
                title(titleStr,'FontSize',3,'FontWeight','Normal');
                set(sub,'FontSize',3);
                if strfind(Params.stimType, 'Ori')
                    set(sub,'XTick',[Params.Conditions.condition; 360]);
                else
                    set(sub,'XTick',Params.Conditions.condition);
                end
                box off;
                axis tight;
                
                % Set the x-scale
                switch Params.stimType
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
                Params, cellColors(j,:), showFigures, elecNo, u);
            
            % File saving
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_bar']),...
%                 '-png', '-nocrop', '-m2', BarFig);
            saveas(barFig,fullfile(figuresPath,elecDir,[figBaseName,'_bar.png']));

        end
        
        % Plotting rasters and histograms
        if plotRasters == 1 % one raster per condition
            
            [hRaster, hPSTH] = plotRastergrams( SpikeDataUnit, Params, ...
                cellColors(j,:), showFigures, elecNo, u);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_raster']),...
%                 '-png', '-m3', '-p0.05', hRaster);
            saveas(hRaster,fullfile(figuresPath,elecDir,[figBaseName,'_raster.png']));

            close(hRaster);
            
%             export_fig(fullfile(ResultsPath,ElecDir,[FigBaseName,'_PSTHs']), ...
%                 '-png', '-m3', '-p0.05', hPSTH);
            saveas(hPSTH,fullfile(figuresPath,elecDir,[figBaseName,'_PSTHs.png']));
            close(hPSTH);
            
        elseif plotRasters == 2 % clump all conditions into one raster
            
            % Lump conditions together for stimuli with many conditions
           [hRaster, hPSTH] = plotRastersAll( SpikeDataUnit, Params, ...
                cellColors(j,:), showFigures, elecNo, u );

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
            
            if strfind(Params.stimType, 'BackProject')
                
                % Use the back-projection method to plot an RF map
                binSize = min(Params.Conditions.binSize);
    
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
                hMap = plotBackProjection(bestMap, Params, showFigures);
                
            else
                hMap = plotMap(StatsUnit, Params, showFigures, elecNo, u);
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

end