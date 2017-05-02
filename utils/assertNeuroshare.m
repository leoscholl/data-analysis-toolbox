function assertNeuroshare( )
%assertNeuroshare Check to make sure neuroshare functions are in the MATLAB 
% path
if ~exist('ns_CloseFile.m', 'file')
    disp('WARNING => the neuroshare functions were not found in your MATLAB path.');
    disp('looking in directory ../');
    path(path, '../');
    
    if exist('ns_CloseFile.m', 'file')
        disp('This script found the neuroshare functions in ../');
    else
        disp('In a standard Trellis installation these functions are located in:');
        disp('   <trellis_install_dir>/Tools/matlab/neuroshare>');
    end
    
    % add the path as it is in SVN
    path(path, '..');
    
    if ~exist('ns_CloseFile.m', 'file')
        return;
    end
    
end

end

