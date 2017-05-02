function [ Params ] = loadParams( dataPath, fileName )
%loadParams loads the parameters structure for the specified file

% Load parameters from file if they exist already
if ~isempty(whos(fullfile(dataPath,fileName), 'Params'))
    load(fullfile(dataPath,fileName),'Params')
end

% Otherwise convert from old format
if ~exist('Params','var') || ~isfield(Params,'Data')
    % These are not the params you're looking for
    Params = convertLogMat( dataPath, fileName );
end
end

