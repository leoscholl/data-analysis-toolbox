classdef summaryTable < handle
% summaryTable generates a summary for each unit in a given dataset
    
    properties
        dataDir % where to locate results files
        animalID
        Cells % Storage of all the information about each cell
        columns = {'file', 'stimulus', 'electrode', 'cell', 'notes'};
    end
    
    methods
        
        % --- Constructor
        function obj = summaryTable( dataDir, animalID, sourceFormat )
            
            obj.animalID = animalID;
            obj.dataDir = dataDir;

            % Gather data
            obj.Cells = obj.gatherData(dataDir, animalID, sourceFormat);
        end
        
        % --- Fetch a unit summary table
        function Unit = getUnit(obj, session)
            Unit = obj.Cells(strcmp(obj.Cells.session, session),:);
        end
        
        % --- Store a Unit table
        function putUnit(obj, session, Unit)
            if ~isempty(Unit)
                obj.Cells(strcmp(obj.Cells.session, session), ...
                    Unit.Properties.VariableNames) = Unit;
            end
        end
        
        % --- Save all data to file in a single table
        function [csvFile, Summary] = export(obj, notes, columnNames)

            UCells = obj.uniqueCells(columnNames);
            
            if nargin < 2
                notes = '';
            end
            
            if isempty(UCells)
                csvFile = 'empty summary table';
                return;
            end
            
            csv = {};
            for c = 1:length(UCells)

                cell = UCells(c);
                animal = cell.subject;
                unit = sscanf(cell.session, 'Unit%d');
                if unit > 100
                    unit = unit/10;
                end
                cellNo = cell.cell;
                elecNo = cell.electrodeid;

                response = any(structfun(@(x)x.ttest < 0.005, cell.response));
            %     surprise = any(structfun(@(x)mean([x.surprise]) > 4, cell.response));
                tuning = any(structfun(@(x)x.anova < 0.005, cell.response));

                osi = [];
                dsi = [];
                sf = [];
                tf = [];
                apt = [];
                con = [];
                lat = [];
                background = []; % baseline

                % Add fields for cells that have them and have significant responses
                if isfield(cell.response, 'Orientation') && cell.response.Orientation.ttest < 0.05
                    osi = cell.response.Orientation.osi;
                    dsi = cell.response.Orientation.dsi;
                end
                if isfield(cell.response, 'Spatial') && cell.response.Spatial.ttest < 0.05
                    sf = cell.response.Spatial.pref;
                end
                if isfield(cell.response, 'Temporal') && cell.response.Temporal.ttest < 0.05
                    tf = cell.response.Temporal.pref;
                end
                if isfield(cell.response, 'Aperture') && cell.response.Aperture.ttest < 0.05
                    apt = cell.response.Aperture.pref;
                end
                if isfield(cell.response, 'Contrast') && cell.response.Contrast.ttest < 0.05
                    con = cell.response.Contrast.pref;
                end
                if isfield(cell.response, 'Latency') && cell.response.Latency.ttest < 0.05
                    lat = cell.response.Latency.latency;
                end

                % Background calculation
                tests = fieldnames(cell.response);
                for s = 1:length(tests)
                    background(s) = cell.response.(tests{s}).baseline;
                end
                background = mean(background);

                % Add to table
                csv(c,:) = {animal, unit, cellNo, elecNo, response, tuning, ...
                    osi, dsi, flatOri, sf, tf, apt, con, lat, background};

            end

            Summary = cell2table(csv);
            Summary.Properties.VariableNames = {'AnimalID', 'Unit', 'Cell', 'Elec', ...
                'Response', 'Tuning', 'OSI', 'DSI', 'FlatOri', 'SF', ...
                'TF', 'Apt', 'Con', 'Latency', 'BG'};

            % Sort
            Summary = sortrows(Summary,{'AnimalID', 'Unit', 'Elec', 'Cell'});
            
            % Export
            exportFile = fullfile(obj.dataDir, obj.animalID, 'summary.mat');
            save(exportFile, 'Summary', 'notes');
            
            % Also export a csvFile for excel
            csvFile = fullfile(obj.dataDir, obj.animalID, 'summary.csv');
            csvFile = obj.incrementFileName(csvFile);
            writetable(Summary,csvFile,'WriteRowNames',true,'QuoteStrings',true);
            
        end
        
        % --- Automatically select certain files using specified function
        function autoSelect(obj, selectionMethod)
            
            if isempty(obj.Cells)
                return;
            end
            
            % Chooses the last (most recent) test for each stimulus type
            function best = lastStim(stimuli)
                best = max(stimuli.fileNo);
            end
            
            % Chooses the test with the greatest maximum corrected response
            function best = maxResponse(Stimuli)
                [~, ind] = max(cellfun(@(x)max([x.tCurveCorr]), Stimuli.Statistics));
                best = Stimuli.fileNo(ind);
            end
            
            % Chooses the test with the greatest number of stimuli bursts
            function best = maxBursts(Stimuli)
                [~, ind] = max(cellfun(@(x)nansum(cellfun(@(y)mean(y(:,1)),{x.nBursts})), Stimuli.Statistics));
                best = Stimuli.fileNo(ind);
            end
            
            switch selectionMethod
                case 'LastStim'
                    selectionFun = @lastStim;
                case 'MaxResponse'
                    selectionFun = @maxResponse;
                case 'MaxBursts'
                    selectionFun = @maxBursts;
                otherwise
                    selectionFun = @lastStim;
            end
            
            % Go through the table and select the "best" of each stim type
            obj.Cells.selected(:) = false;
            sessions = unique(obj.Cells.session);
            for s = 1:length(sessions)
                electrodes = unique(obj.Cells.electrodeid(strcmp(obj.Cells.session, sessions{s})));
                for e = 1:length(electrodes)
                    cells = unique(obj.Cells.cell(strcmp(obj.Cells.session, sessions{s}) & ...
                        obj.Cells.electrodeid == electrodes(e)));
                    for c = 1:length(cells)
                        Stimuli = obj.Cells(strcmp(obj.Cells.session, sessions{s}) & ...
                            obj.Cells.electrodeid == electrodes(e) & ...
                            obj.Cells.cell == cells(c), :);
                        stimTypes = unique(Stimuli.stimType);
                        for stim = 1:length(stimTypes)
                            best = selectionFun(Stimuli(strcmp(stimTypes{stim}, Stimuli.stimType),:));
                            obj.Cells.selected(strcmp(obj.Cells.session, sessions{s}) & ...
                                obj.Cells.electrodeid == electrodes(e) & ...
                                obj.Cells.cell == cells(c) & ...
                                obj.Cells.fileNo == best) = true;
                        end
                    end
                end
            end
        end

        
        % --- Summarize cells by uniqueness and perform basic statistics
        function Summary = uniqueCells(obj, columnNames)
            
            if isempty(obj.Cells)
                Summary = struct;
                return;
            elseif nargin < 2 || isempty(columnNames)
                AllCells = obj.Cells(obj.Cells.selected, :);
            else
                AllCells = obj.Cells(obj.Cells.selected, columnNames);
            end
            
            Summary = struct('cell', [], 'id', [], 'electrodeid', [], 'session', [], 'sessionid', [], ...
                'subject', [], 'subjectid', [], 'track', [], 'response', [], ...
                'location', [], 'spikes', []);

            cellIds = unique(AllCells.id);

            uniqueCells = cell(1, length(cellIds));
            for c = 1:length(cellIds)
                uniqueCells{c} = AllCells(AllCells.id == cellIds(c),:);
            end

            if isempty(gcp('nocreate')) && isempty(getCurrentTask())
                parpool;
            end
            for c = 1:length(cellIds)

                % Only look a trials for this cell
                Stimuli = uniqueCells{c};
                
                % Gather basic information
                thisCell = struct;
                thisCell.cell = Stimuli.cell(1);
                thisCell.id = Stimuli.id(1);
                thisCell.session = Stimuli.session{1};
                thisCell.sessionid = Stimuli.sessionid(1);
                thisCell.subject = Stimuli.subject{1};
                thisCell.subjectid = Stimuli.subjectid(1);
                thisCell.track = Stimuli.track{1};
                thisCell.electrodeid = Stimuli.electrodeid(1);
                thisCell.location = Stimuli.location{1};
                thisCell.spikes = 0;
                
                % Add information for the response to each stimulus
                thisCell.response = struct;
                for s = 1:size(Stimuli,1)

                    % Calculate statistics for each stim type
                    stats = Stimuli.Statistics{s};
                    conds = Stimuli.Conditions{s};
                    Stats = struct;

                    % Don't count stimuli with low firing rates
                    Stats.numSpikes = Stimuli.numSpikes(s);
                    Stats.maxSpikes = Stimuli.maxSpikes(s);
                    Stats.meanSpikes = Stimuli.meanSpikes(s);
                    Stats.stdSpikes = Stimuli.stdSpikes(s);
                    thisCell.spikes = thisCell.spikes + Stats.numSpikes;
                    
                    % Group the trials by condition number
                    corr = cellfun(@(x, y)x - y, {stats.meanTrials}, {stats.blankTrials}, ...
                        'UniformOutput', false);
                    groups = arrayfun(@(x,y)repmat(x,1,y), [stats.conditionNo], ...
                        cellfun(@length, corr), 'UniformOutput', false);

                    % Run ANOVA
                    Stats.anova = anova1([corr{:}], [groups{:}], 'off');

                    try
                        % Wilcoxon rank-sum for each condition
                        Stats.ranksum = cellfun(@ranksum, {stats.meanTrials}, {stats.blankTrials});
                        Stats.broadnessW = mean(Stats.ranksum < 0.01);

                        % All trials vs all blank trials
                        [~, Stats.ttest] = ttest([stats.meanTrials], [stats.blankTrials]);
                    catch e
                        % Not enough blank trials, usually
                        Stats.ttest = NaN;
                        Stats.ranksum = [];
                        Stats.broadnessW = NaN;
                    end

                    % Rank surprise
                    Stats.surprise = cellfun(@mean,{stats.surpriseInd});
                    Stats.bursts = cellfun(@(x)mean(x(:,1)),{stats.nBursts});

                    % Selectivity
                    nConds = length([stats.conditionNo]);
                    rMax = max([stats.tCurve]);
                    rMin = min([stats.tCurve]);
                    Stats.baseline = mean([stats.blank]);
                    Stats.peak = rMax;
                    if isnan(Stats.baseline)
                        Stats.baseline = 0;
                        if ismember(-1, conds)
                            Stats.baseline = stats(conds == -1).tCurve;
                        end
                    end
                    Stats.dos = (nConds - sum(arrayfun(@(x)x/rMax,[stats.tCurve])))/(nConds - 1);
                    rNorm = ([stats.tCurve] - rMin)/(rMax - rMin);
                    Stats.breadth = 1 - median(rNorm);
                    Stats.si = (rMax - rMin)/(rMax + rMin);

                    % Preferred stimulus
                    dimensions = fieldnames(Stimuli.Conditions{s});
                    levels = Stimuli.Conditions{s}.(dimensions{1});
                    [~, ind] = max([stats.tCurveCorr]);
                    if isnumeric(levels(ind))
                        Stats.pref = levels(ind);
                    else
                        Stats.pref = ind;
                    end

                    % Percent of cells with firing rates >25% over baseline
                    Stats.broadnessP = mean([stats.tCurveCorr] > max([stats.tCurveCorr])*.25);

                    % Store the statistics in this cell's structure
                    if contains(Stimuli.stimType{s}, 'Spat')
                        stimType = 'Spatial';
                    elseif contains(Stimuli.stimType{s}, 'Temp')
                        stimType = 'Temporal';
                    elseif contains(Stimuli.stimType{s}, 'Aper')
                        stimType = 'Aperture';
                    elseif contains(Stimuli.stimType{s}, 'Ori')
                        stimType = 'Orientation';
                    elseif contains(Stimuli.stimType{s}, 'Cont')
                        stimType = 'Contrast';
                    elseif contains(Stimuli.stimType{s}, 'Cen')
                        stimType = 'CenterSurround';
                    elseif contains(Stimuli.stimType{s}, 'Lat') || ...
                            contains(Stimuli.stimType{s}, 'spon')
                        stimType = 'Latency';
                    elseif contains(Stimuli.stimType{s}, 'Velocity')
                        stimType = 'Velocity';
                    elseif contains(Stimuli.stimType{s}, 'RF')
                        stimType = 'RFMap';
                    elseif contains(Stimuli.stimType{s}, 'Annulus')
                        stimType = 'Annulus';
                    else
                        stimType = strrep(Stimuli.stimType{s}, '-', '_');
                    end

                    % OSI
                    if strcmp(stimType, 'Orientation')
                        valid = levels >= 0;
                        theta = deg2rad(levels(valid));
                        response = [stats.tCurve]';
                        response = response(valid);
                        Stats.dsi = abs(sum(response.*exp(1i*theta))/sum(response));
                        Stats.osi = abs(sum(response.*exp(2.1i*theta))/sum(response));
                    end

                    % Latency
                    if strcmp(stimType, 'Latency')
                        Stats.latency = stats.latency;
                    end

                    % Group responses per cell
                    thisCell.response.(stimType) = Stats;
                    
                end % for each stimuli

                % Append summary array
                Summary(c,:) = thisCell;
                
            end % for each cell
            
            % Don't count this as a real cell if it has too few spikes
            Summary = Summary(arrayfun(@(x)x.spikes > 100, Summary));
        end
        
    end
    
    methods (Static)
        
        % --- Helper for saving files to keep incrementing the name
        function fileName = incrementFileName(fileName)
            [fPath, fName, fExt] = fileparts(fileName);
            if isempty(fExt)  % no extension, assume '.mat'
                fExt     = '.mat';
                fileName = fullfile(fPath, [fName, fExt]);
            end
            if exist(fileName, 'file')
                % Get number of files:
                fDir     = dir(fullfile(fPath, [fName, '*', fExt]));
                fStr     = lower(sprintf('%s*', fDir.name));
                fNum     = regexpi(fStr, [fName, '(\d*)', fExt, '\*'], 'tokens');
                fNum     = cellfun(@getNum, fNum);
                newNum   = max(fNum) + 1;
                fileName = fullfile(fPath, [fName, sprintf('%d', newNum), fExt]);
            end
            
            function num = getNum(token)
                num = str2double(token{1});
                if isempty(num) || isnan(num)
                    num = 0;
                end
            end
        end

        
        function Cells = gatherData(dataDir, animalID, sourceFormat)
            
            % Which files
            [~, ~, Files] = findFiles(dataDir, animalID, [], '*-analysis.mat');
            nFiles = size(Files,1);
            
            % Location data
            load('C:\Users\leo\Google Drive\Matlab\manual analysis\locations.mat');
            if isempty(Locations) || ~isfield(Locations, animalID)
                error('No recording location data found');
            end

            % Collect all cells into a summary array of structures
            summary = [];
            for f = 1:nFiles
                
                analysis = loadResults(dataDir, animalID, ...
                    Files.fileNo(f), sourceFormat);
                
                if isempty(analysis)
                    continue;
                end
                
                analysis.spike;
                analysis.lfp;
                analysis.Params.unit;
                
                for i=1:length(analysis.spike) % for each electrode
                    
                    electrodeid = analysis.spike(i).electrodeid;
                    
                    Stats = analysis.spike(i).Statistics;
                    SpikeData = analysis.spike(i).Data;
                    Conditions = analysis.Params.Conditions;
                    
                    if isempty(Stats)
                        continue;
                    end
                    cells = unique(Stats.cell);
                    
                    for j = 1:length(cells)
                        
                        cell = struct;
                        cell.cell = cells(j);
                        cell.electrodeid = electrodeid;
                        cell.track = [];
                        cell.session = analysis.Params.unit;
                        cell.subject = analysis.Params.animalID;
                        
                        % Collect location information if there is any
                        cell.location = '';
                        if isfield(Locations.(cell.subject), cell.session)
                            map = Locations.(cell.subject).(cell.session);
                            if isKey(map, cell.electrodeid)
                                cell.location = map(cell.electrodeid);
                            end
                        end
                            

                        % Statistics
                        cell.Statistics = table2struct(Stats(Stats.cell == cells(j),:));
                        
                        % Average number of spikes per trial
                        numSpikes = cellfun(@length, SpikeData.raster(SpikeData.cell == cells(j),:));
                        cell.meanSpikes = mean(numSpikes);
                        cell.stdSpikes = std(numSpikes);
                        cell.maxSpikes = max(numSpikes);
                        cell.numSpikes = sum(numSpikes);
                        
                        cell.Conditions = Conditions;
                        cell.fileNo = Files.fileNo(f);
                        cell.stimType = Files.stimType{f};
                        cell.notes = {};
                        cell.selected = false;
                        cell.sessionid = sum(double(cell.session).* ...
                            (10.^(0:length(cell.session)-1)));
                        cell.subjectid = sum(double(animalID).* ...
                            (10.^(0:length(animalID)-1)));
                        cell.id = str2double(sprintf('%d%d%d', ...
                            cell.electrodeid + 1, cell.cell + 1, ...
                            cell.sessionid + cell.subjectid * 100));

                        summary = [summary; cell];
                    end
                end
            end
       
            % Convert to a single table
            if isempty(summary)
                Cells = table;
            else
                Cells = struct2table(summary);
            end
        end
        
    end
    
end
