function saveResults( Results )
%saveResults writes the analysis to mat file

% Save to mat file
[dataPath, fileName, ~] = fileparts(Results.source);
if ~exist(dataPath,'dir')
    mkdir(dataPath);
end
resultsFile = fullfile(dataPath,[fileName,'.mat']);
% r = matfile(resultsFile, 'Writable', true);
r = load(resultsFile);
if isfield(r, 'analysis') 
    if ~isempty(setdiff(fieldnames(Results),fieldnames(r.analysis)))
        analysis = Results;
        save(resultsFile, 'analysis', '-append');
        return;
    end
    ind = find(strcmp({r.analysis.sourceFormat}, Results.sourceFormat));
    if isempty(ind) || ind == 0
        r.analysis(end+1) = Results;
    else
        r.analysis(ind) = Results;
    end
    analysis = r.analysis;
    save(resultsFile, 'analysis', '-append');
else
    analysis = Results;
    save(resultsFile, 'analysis', '-append');
end

end

