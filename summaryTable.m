classdef summaryTable < handle
    
    properties
        dataDir % where to locate results files
        animalID
        unitNo
        Units % Storage of all the information about each unit
        Electrodes % how many electrodes and what are their names
        handles % handles for gui
        columns = {'file', 'stimulus', 'electrode', 'cell', ...
            'pref', 'f1pref', 'corrpref', 'lat', ...
            'ori', 'sf', 'tf', 'apt', 'velocity', 'latency', 'other', 'notes'};
    end
    
    methods
        
        % --- Constructor
        function obj = summaryTable( dataDir, animalID, unitNo, handles )
            
            obj.handles = handles;
            obj.animalID = animalID;
            obj.dataDir = dataDir;
            [~, obj.Units] = findUnits(dataDir, animalID);
            
            if size(obj.Units,1) < 1
                error(['No units found for ', animalID]);
            end
            
             % Set the first unit number
            if ~isempty(unitNo) && ismember(unitNo, obj.Units.number)
                obj.unitNo = unitNo;
            else
                obj.unitNo = obj.Units.number(1);
            end
            
            % Generate tables for all units
            obj.Units.data = repmat({{}}, size(obj.Units,1), 1);
            for i = 1:size(obj.Units,1)
                unitNo = obj.Units.number(i);
                [summary, Electrodes] = obj.generateUnit(dataDir, animalID, unitNo);
                obj.Electrodes = Electrodes;
                obj.Units.data{i} = summary;
            end 
        end
        
        
        % --- Move to the next unit
        function nextUnit(obj)
            if ~isempty(obj.unitNo)
                obj.collectUnit(); % save the current unit summary
            end
            i = find(obj.Units.number == obj.unitNo);
            if size(obj.Units,1) >= i + 1
                obj.unitNo = obj.Units.number(i+1);
            else
                fprintf(2, 'No more units');
            end
        end
        
        
        % --- Move to the previous unit
        function prevUnit(obj)
            if ~isempty(obj.unitNo)
                obj.collectUnit(); % save the current unit summary
            end
            i = find(obj.Units.number == obj.unitNo);
            if i > 1
                obj.unitNo = obj.Units.number(i-1);
            else
                fprintf(2, 'No previous units');
            end
        end
        
        
        % --- Display the summary for a unit on the table
        function showUnit(obj)
            
            % Get the summary data
            Sum = obj.Units.data{obj.Units.number == obj.unitNo};
            
            % display the summary for this unit, allow choice of files for each
            % stimulus
            set(obj.handles.SummaryTable, 'Data', Sum);
            obj.handles.SummaryTable.ColumnName = obj.columns;
            obj.handles.SummaryTable.ColumnWidth = {30, 70, 30, 30, ...
                30, 30, 30, 40, ...
                30, 30, 30, 30, 30, 30, 30, 97};
            obj.handles.SummaryTable.RowName = [];
            obj.handles.SummaryTable.ColumnEditable = [false false false false ...
                true true true false ...
                true true true true true true true true];
            obj.handles.SummaryTable.ColumnFormat = {'numeric', 'char', 'numeric', 'numeric', ...
                'numeric', 'numeric', 'numeric', 'numeric', ...
                'logical', 'logical', 'logical', 'logical', 'logical', 'logical', ...
                'logical', 'char'};
            
        end

        
        % --- Store the data for the current unit
        function collectUnit(obj)
            
            data = get(obj.handles.SummaryTable, 'Data');
            if isempty(data)
                return;
            end
            obj.Units.data{obj.Units.number == obj.unitNo} = data;
            
        end
        
        
        % --- Save all data to file in a single table
        function csvFile = export(obj)
            
            obj.collectUnit(); % just in case
            
            Summary = obj.summarize();
            notes = get(obj.handles.CaseNotes, 'String');
            
            % Export
            exportFile = fullfile(obj.dataDir, obj.animalID, 'summary.mat');
            save(exportFile, 'Summary', 'notes');
            
            % Also export a csvFile for excel
            csvFile = fullfile(obj.dataDir, obj.animalID, 'summary.csv');
            csvFile = obj.incrementFileName(csvFile);
            writetable(Summary,csvFile,'WriteRowNames',true,'QuoteStrings',true);
            
        end
        
        
        % --- collect all the summary data into a single table
        function Summary = summarize(obj)
            
            Summary = {};
            
            for i = 1:size(obj.Units,1)
                
                i = find(obj.Units.number == obj.unitNo);
                data = obj.Units.data{i};
                
                Sum = cell2table(data);
                Sum.Properties.VariableNames = obj.columns;
                set(obj.handles.SummaryTable, 'Data', []);
                
                nElectrodes = size(obj.Electrodes, 1);
                
                for e = 1:nElectrodes
                    cells = unique(Sum.cell);
                    for c = 1:length(cells)
                        track = [];
                        obj.unitNo;
                        electrode = obj.Electrodes.number(e);
                        cell = cells(c);
                        CellSum = Sum(Sum.cell == cell & Sum.electrode == electrode,:);
                        ori = obj.pref(CellSum(CellSum.ori,{'pref', 'f1pref','corrpref'}));
                        sf = obj.pref(CellSum(CellSum.sf,{'pref', 'f1pref','corrpref'}));
                        tf = obj.pref(CellSum(CellSum.tf,{'pref', 'f1pref','corrpref'}));
                        apt = obj.pref(CellSum(CellSum.apt,{'pref', 'f1pref','corrpref'}));
                        velocity = obj.pref(CellSum(CellSum.velocity,{'pref', 'f1pref','corrpref'}));
                        latency = obj.pref(CellSum(CellSum.latency, {'pref', 'lat'}));
                        other = obj.pref(CellSum(CellSum.other,{'pref', 'f1pref','corrpref'}));
                        notes = table2cell(CellSum(~cellfun(@isempty,CellSum.notes),{'stimulus','file','notes'}));
                        
                        % Add osi for the file that ori is selected
                        if sum(CellSum.ori) == 1
                            oriFileNo = CellSum.file(CellSum.ori);
                            oriCell = CellSum.cell(CellSum.ori);
                            oriElec = CellSum.electrode(CellSum.ori);
                            [Params, Results] = loadResults(obj.dataDir, ...
                                obj.animalID, obj.unitNo, oriFileNo);
                            Statistics = Results.StatisticsAll{oriElec};
                            Statistics = Statistics(Statistics.cell == oriCell,:);
                            [ osi, di ] = calculateOsi(Statistics, Params);
                        else
                            osi = [];
                            di = [];
                        end
                        
                        Summary = [Summary; {track, obj.Units.number(i), ...
                            electrode, cell, ...
                            ori, osi, di, sf, tf, apt, velocity, ...
                            latency, other, notes}];
                    end % cells loop
                end % Electrodes loop
            end % Units loop
            
            Summary = cell2table(Summary);
            Summary.Properties.VariableNames = {'track', 'unit', 'cell', 'electrode', ...
                'ori', 'osi', 'di', 'sf', 'tf', 'apt', 'velocity', 'latency', ...
                'other', 'notes'};
            
        end
        
    end
    
    methods (Static)
        
        % --- Choose the preferred condition based on priorities
        function r = pref(T)
            if ~isempty(T.pref)
                r = T.pref;
            elseif ismember('f1pref',T.Properties.VariableNames) && ...
                    ~isempty(T.f1pref) && ~isnan(T.f1pref)
                r = T.f1pref;
            elseif ismember('corrpref',T.Properties.VariableNames) && ...
                    ~isempty(T.corrpref) && ~isnan(T.corrpref)
                r = T.corrpref;
            elseif ismember('lat',T.Properties.VariableNames) && ...
                    ~isempty(T.lat) && ~isnan(T.lat)
                r = T.lat;
            else
                r = [];
            end
        end
        
        
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

        
        % --- Generate a summary table for a given unit
        function [summary, Electrodes] = generateUnit(dataDir, animalID, unitNo)
            summary = {};
            Electrodes = table;
            
            % Generate from files if it doesn't already exist
            [~, ~, Files] = findFiles(dataDir, animalID, ...
                unitNo, '*-export.mat');
            
            for f=1:size(Files,1)
                
                fileName = Files.fileName{f};
                filePath = fullfile(dataDir, animalID, ...
                    Files.unit{f}, [fileName, '-export.mat']);
                if exist(filePath,'file')
                    load(filePath);
                end
                
                if ~isfield(Params, 'nElectrodes')
                    continue;
                end
                nElectrodes = Params.nElectrodes;
                Electrodes = Results.Electrodes(:,{'name', 'number'});
                cells = {};
                
                for i=1:nElectrodes
                    Stats = Results.StatisticsAll{i};
                    cells{i} = unique(Stats.cell);
                    
                    for j = 1:length(cells{i})
                        StatsCell = Stats(Stats.cell == cells{i}(j),:);
                        [maxCorr, maxCorrInd] = max(StatsCell.tCurveCorr);
                        [maxF1, maxF1Ind] = max(StatsCell.f1Rep);
                        if ~isnan(maxCorr)
                            maxCorrCN = StatsCell.conditionNo(maxCorrInd);
                            maxCorrCond = Params.Conditions.condition(...
                                Params.Conditions.conditionNo == maxCorrCN);
                        else
                            maxCorrCond = NaN;
                        end
                        if ~isnan(maxF1)
                            maxF1CN = StatsCell.conditionNo(maxF1Ind);
                            maxF1Cond = Params.Conditions.condition(...
                                Params.Conditions.conditionNo == maxF1CN);
                        else
                            maxF1Cond = NaN;
                        end
                        latencies = StatsCell.latency(~isnan(StatsCell.latency));
                        latency = mean(latencies);
                        
                        
                        summary = [summary; {Files.fileNo(f), Files.stimType{f}, ...
                            Results.Electrodes.number(i), cells{i}(j), ...
                            [], maxF1Cond, maxCorrCond, latency}];
                    end
                end
            end

            if isempty(summary)
                fprintf(2, ['No data for unit ', num2str(unitNo)]);
                return;
            end
            
            summary = sortrows(summary, [3, 1]); % organize by electrode
            summary(:,9:15) = {false};
            summary(:,16) = {''};
        end
        
    end
    
end