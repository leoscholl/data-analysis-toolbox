%
%
%main interface to automatic sorting (but manual classification of good/bad
%cells).
%
%
function sortingTextGUI


AnimalID = 'R1518';
Unit = 'Unit1';
Channel = '1';
extraction_thr = '5';

basepath=['I:\Data\',AnimalID,filesep,Unit,filesep,'results',filesep,extraction_thr,filesep];
filenameIn=[AnimalID,Unit,'-',Channel];
label=[ filenameIn ]; %label is channel/patient/session


%--------------------------------

%do all sorting
% automaticSort(basepath, filenameIn);


%-------------
%classify (manually)

if ~exist([basepath filenameIn '_spikes_sorted.mat'],'file')
    copyfile([basepath filenameIn '_sorted_new.mat'], ...
    [basepath filenameIn '_spikes_sorted.mat']);
end

load([basepath filenameIn '_spikes_sorted.mat']);

for j=1:2
    assigned=[];
    spikes=[];
    timestamps=[];
    
    if j==1
        %positive
        assigned=assignedPositive;
        spikes=newSpikesPositive;
        timestamps=newTimestampsPositive;
    else
        %negative
        assigned=assignedNegative;
        spikes=newSpikesNegative;
        timestamps=newTimestampsNegative;
    end
    
    clusters = unique(assigned);
    nrClusters = length(unique(assigned));
    colors = jet(nrClusters);
    
    for i=1:nrClusters
        if clusters(i) > 1
            figure(j*100+i);
            plotSingleCluster(spikes, timestamps, assigned, label, clusters(i), colors(i,:));
        end
    end
end

%%
%--------if necessary -- check some raw waveforms (manual and optional)


% figure(99)
% spikes=newSpikesPositive;
% timestamps=newTimestampsPositive;
% assigned=assignedPositive;
% plot(1:256, spikes(find(assigned==999) ,:)','g', 1:256, spikes( find(assigned==1) ,:)','r');
% figure(98)
% plot(1:256, mean(spikes(find(assigned==999) ,:))','g', 1:256, mean(spikes( find(assigned==2) ,:))','r');


%set this manually based on plots
usePositive=[1 2];
useNegative=[2 3];

%store figures
for j=1:2
    stat='';
    if j==1
        use=usePositive;
        stat='P';
    else
        use=useNegative;
        stat='N';
    end
    
    for i=1:length(use)
        figure(j*100+use(i));
        eval(['print -djpeg ' basepath filenameIn '_fig_' stat '_' num2str(use(i))]);
    end
end
'store'
save([basepath filenameIn '_spikes_sorted.mat'], 'newSpikesPositive', 'newSpikesNegative', 'newTimestampsPositive', 'newTimestampsNegative','assignedPositive','assignedNegative', 'usePositive', 'useNegative');

clear all;