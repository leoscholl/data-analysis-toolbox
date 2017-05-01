% Helper function for copying multiple files
function CopyFiles (SearchString, DataPath, DestPath)
Files = dir(fullfile(DataPath, SearchString));
for f=1:length(Files)
    FileName = Files(f).name;
    
    % Make sure the file exists
    if ~exist(fullfile(DataPath, FileName),'file')
        fprintf('%s does not exist\n', FileName);
    end
    
    % Make sure the target directory exists
    if ~exist(DestPath,'dir')
        mkdir(DestPath);
    end
    
    % Don't overwrite an existing file
    if ~exist(fullfile(DestPath, FileName),'file')
        [success, msg, msgid] = copyfile(fullfile(DataPath,FileName),...
            fullfile(DestPath,FileName));
        if success
            % Display the filename that was copied
            disp(FileName);
        else
            % Display a helpful error message
            fprintf('%s could not be copied:\n', FileName);
            warning(msgid, msg);
        end
    else
        fprintf('%s already exists\n', FileName);
    end
end
end