% Helper function for copying multiple files
function copyFiles (searchString, dataPath, destPath)
files = dir(fullfile(dataPath, searchString));
for f=1:length(files)
    fileName = files(f).name;
    
    % Make sure the file exists
    if ~exist(fullfile(dataPath, fileName),'file')
        fprintf('%s does not exist\n', fileName);
    end
    
    % Make sure the target directory exists
    if ~exist(destPath,'dir')
        mkdir(destPath);
    end
    
    % Don't overwrite an existing file
    if ~exist(fullfile(destPath, fileName),'file')
        [success, msg, msgid] = copyfile(fullfile(dataPath,fileName),...
            fullfile(destPath,fileName));
        if success
            % Display the filename that was copied
            disp(fileName);
        else
            % Display a helpful error message
            fprintf('%s could not be copied:\n', fileName);
            warning(msgid, msg);
        end
    else
        fprintf('%s already exists\n', fileName);
    end
end
end