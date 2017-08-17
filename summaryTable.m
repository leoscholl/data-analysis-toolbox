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

            if nargin < 3 || isempty(columnNames)
                Summary = obj.Cells(obj.Cells.selected, :);
            else
                Summary = obj.Cells(obj.Cells.selected, columnNames);
            end
            
            if isempty(Summary)
                csvFile = 'empty summary table';
                return;
            end
            
            % Export
            exportFile = fullfile(obj.dataDir, obj.animalID, 'summary.mat');
            save(exportFile, 'Summary', 'notes');
            
            % Also export a csvFile for excel
            firstRow = table2cell(Summary(1,:));
            valid = cellfun(@isnumeric, firstRow(1,:)) | ...
                cellfun(@islogical, firstRow(1,:)) | ...
                cellfun(@ischar, firstRow(1,:));

            csvFile = fullfile(obj.dataDir, obj.animalID, 'summary.csv');
            csvFile = obj.incrementFileName(csvFile);
            writetable(Summary(:,valid),csvFile,'WriteRowNames',true,'QuoteStrings',true);
            
        end
        
        % --- Automatically select certain files using specified function
        function autoSelect(obj, selectionMethod)
            
            % Chooses the last (most recent) test for each stimulus type
            function best = lastStim(stimuli)
                best = max(stimuli.fileNo);
            end
            
            % Chooses the test with the greatest maximum corrected response
            function best = maxResponse(Stimuli)
                [~, ind] = max(cellfun(@(x)max([x.tCurveCorr]), Stimuli.Statistics));
                best = Stimuli.fileNo(ind);
            end
            
            switch selectionMethod
                case 'LastStim'
                    selectionFun = @lastStim;
                case 'MaxResponse'
                    selectionFun = @maxResponse;
                otherwise
                    selectionFun = @lastStim;
            end
            
            % Go through the table and select the "best" of each stim type
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
            
            [~, ~, Files] = findFiles(dataDir, animalID, [], '*.mat');
            nFiles = size(Files,1);
            
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
                        cell.Statistics = table2struct(Stats(Stats.cell == cells(j),:));
                        cell.SpikeData = table2struct(SpikeData(SpikeData.cell == cells(j),:));
                        cell.Conditions = Conditions;
                        cell.fileNo = Files.fileNo(f);
                        cell.stimType = Files.stimType{f};
                        cell.notes = {};
                        cell.selected = false;
                        cell.sessionid = sum(double(cell.session).* ...
                            (10.^(0:length(cell.session)-1)));
                        cell.animalid = sum(double(animalID).* ...
                            (10.^(0:length(animalID)-1)));
                        cell.id = str2double(sprintf('%d%d%d', ...
                            cell.electrodeid + 1, cell.cell + 1, ...
                            cell.sessionid + cell.animalid * 100));

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
