function sortWithWaveclus( sortingDir, animalID, whichUnits )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

for unitNo = whichUnits
    
    sortingPath = fullfile(sortingDir, animalID); 
    fileName = [animalID, 'Unit', num2str(unitNo)];


    files = dir(fullfile(sortingPath,[fileName, '*ch.mat']));
    files = files(~vertcat(files.isdir)); % just for good measure
    files = {files.name};
    files = unique(files);

    parallel = true;

    Get_spikes(files, 'parallel', parallel);
    par = struct;
    par.min_clus = 100;
    par.max_spk = 50000;
    par.maxtemp = 0.251;                                                                                     
    Do_clustering(files, 'par', par, 'parallel', parallel);
end

end