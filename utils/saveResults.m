function saveResults( Results )
%saveResults writes the analysis to mat file

% Save to mat file
[dataPath, fileName, ~] = fileparts(Results.source);
if ~exist(dataPath,'dir')
    mkdir(dataPath);
end
oldResultsFile = fullfile(dataPath,[fileName,'.mat']);
resultsFile = fullfile(dataPath,[fileName,'-analysis.mat']);

if exist(resultsFile, 'file')
    try
        r = load(resultsFile);
    catch e
        warning(getReport(e));
        r = [];
    end
else 
    r = [];
end
if isfield(r, 'analysis') 
    if ~isempty(setdiff(fieldnames(Results),fieldnames(r.analysis)))
        r.analysis = Results;
        save(resultsFile, '-struct', 'r', '-v7.3');
        return;
    end
    ind = find(strcmp({r.analysis.sourceFormat}, Results.sourceFormat));
    if isempty(ind) || ind == 0
        r.analysis(end+1) = Results;
    else
        r.analysis(ind) = Results;
    end
    save(resultsFile, '-struct', 'r', '-v7.3');
else
    r.analysis = Results;
    save(resultsFile, '-struct', 'r', '-v7.3');
end

end

