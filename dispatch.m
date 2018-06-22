function [result] = dispatch(dataset, figuresPath, isParallel, varargin)
%dispatch Send dataset to the appropriate plotting/analysis functions

if nargin < 3 || isempty(isParallel)
    isParallel = false;
end

% Pick default actions
actions = defaultActions(dataset.ex);

% Dispatch to plotting functions
result = processData(dataset, figuresPath, actions, isParallel, varargin{:});

end
