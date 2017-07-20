function saveResults( Results )
%saveResults writes the analysis to mat file

% Save to mat file
[dataPath, fileName, ~] = fileparts(Results.source);
if ~exist(dataPath,'dir')
    mkdir(dataPath);
end
resultsFile = fullfile(dataPath,[fileName,'.mat']);
r = matfile(resultsFile, 'Writable', true);
varNames = who(r);
if ismember('analysis', varNames)
    analysis = r.analysis;
    ind = find(strcmp({analysis.sourceFormat}, Results.sourceFormat));
    if isempty(ind) || ind == 0
        analysis(end+1) = Results;
    else
        analysis(ind) = Results;
    end
    r.analysis = analysis;
else
    r.analysis = Results;
end

end

