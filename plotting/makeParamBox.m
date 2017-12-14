function [paramStr] = makeParamBox(Params, OSI, DSI)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


constants = struct('Name', '', 'Value', NaN);

ps = {'sf', 'spatial', 'tf', 'velocity', 'ap', 'ori', 'contrast', ...
    'duration', 'interval'};

for p = 1:length(ps)
    
    varPos = contains(Params.Data.Properties.VariableNames, ps{p}, 'IgnoreCase', true);
    varNames = Params.Data.Properties.VariableNames(varPos);
    for i = 1:length(varNames)
        if length(unique(Params.Data.(varNames{i}))) == 1

            % This is a constant parameter. Add it to the list
            constants = [constants; struct('Name', ...
                varNames{i}, ...
                'Value', ...
                Params.Data.(varNames{i})(1))];
        end
    end
            
end

if nargin > 2 && ~isempty(OSI) && ~isempty(DSI)
    constants = [constants; ...
        struct('Name', 'OSI', 'Value', OSI); ...
        struct('Name', 'DSI', 'Value', DSI)];
end

cellData = struct2cell(constants(2:end));   
paramStr = sprintf('%15s: %0.3f\n',cellData{:});

end

