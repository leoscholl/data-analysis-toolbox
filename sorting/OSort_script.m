%
% OSort_script.m

function [results_filenames, original_filename] = OSort_script (DataDir, AnimalID, UnitNo)
%% which files to sort
paths=[];

Unit = deblank(['Unit',num2str(UnitNo)]);

paths.basePath=[DataDir,AnimalID,'\',Unit];
paths.pathOut=[paths.basePath,filesep,'results'];
paths.pathRaw=[paths.basePath,filesep,'osort',filesep];
paths.pathFigs=[paths.basePath,filesep,'figs'];
paths.timestampspath=[paths.basePath,filesep,'osort',filesep];             % if a timestampsInclude.txt file is found in this directory, only the range(s) of timestamps specified will be processed. 

paths.patientID=[AnimalID,' ',Unit]; % label in plots

% check the files
rawFiles = dir([paths.pathRaw,'*.bin']);
if ~isempty(rawFiles)
    
    % How many channels
    Channels = 1:length(rawFiles);
    
    %Block size
    Filesize = rawFiles(1).bytes;
    Blocksize = Filesize/4 + 2;
    Blocksize = min(Blocksize, 10000000); %10,000,000
else
    warning('No files to sort.');
    original_filename = [];
    results_filenames = [];
    return;
end

filesToProcess = Channels;  %which channels to detect/sort
noiseChannels  = [   ]; % which channels to ignore

groundChannels=[]; %which channels are ground (ignore)

doGroundNormalization=0;
normalizeOnly=[]; %which channels to use for normalization

if exist('groundChannels') && ~doGroundNormalization
  filesToProcess=setdiff(filesToProcess, groundChannels);
end

%default align is mixed, unless listed below as max or min.
filesAlignMax=[ ];
filesAlignMin=[ ];


%% global settings
paramsIn=[];

paramsIn.rawFilePrefix=[AnimalID,Unit,'-'];        % some systems use CSC instead of A
paramsIn.processedFilePrefix=[AnimalID,Unit,'-'];

paramsIn.rawFileVersion = 4; %1 is analog cheetah, 2 is digital cheetah (NCS), 3 is txt file.  determines sampling freq&dynamic range.
paramsIn.samplingFreq = 30000; %only used if rawFileVersion==3

%which tasks to execute
paramsIn.blocksize = Blocksize;
paramsIn.tillBlocks = 999;  %how many blocks to process (each ~20s). 0=no limit.
paramsIn.doDetection = 1;
paramsIn.doSorting = 1;
paramsIn.doFigures = 1;
paramsIn.noProjectionTest = 1;
paramsIn.doRawGraphs = 1;
paramsIn.doGroundNormalization=doGroundNormalization;

paramsIn.displayFigures = 0 ;  %1 yes (keep open), 0 no (export and close immediately); for production use, use 0 

paramsIn.minNrSpikes=100; %min nr spikes assigned to a cluster for it to be valid
                                                                                                                         
%params
[runs, ~] = determineBlocks( Filesize/2 + 1, Blocksize );
paramsIn.blockNrRawFig=[ runs ];
paramsIn.outputFormat='png';
paramsIn.thresholdMethod=1; %1=approx, 2=exact
paramsIn.prewhiten=0; %0=no, 1=yes,whiten raw signal (dont)
paramsIn.defaultAlignMethod=2;  %only used if peak finding method is "findPeak". 1=max, 2=min, 3=mixed
paramsIn.peakAlignMethod=1; %1 find Peak, 2 none, 3 peak of power, 4 MTEO peak
                        
%for wavelet detection method
%paramsIn.detectionMethod=5; %1 power, 2 T pos, 3 T min, 4 T abs, 5 wavelet
%dp.scalesRange = [0.2 1.0]; %in ms
%dp.waveletName='bior1.5'; 
%paramsIn.detectionParams=dp;
%extractionThreshold=0.1; %for wavelet method

%for power detection method
paramsIn.detectionMethod=1; %1 power, 2 T pos, 3 T min, 3 T abs, 4 wavelet
dp.kernelSize=18; 
paramsIn.detectionParams=dp;
extractionThreshold = 5;  % extraction threshold

thres         = [repmat(extractionThreshold, 1, length(filesToProcess))];

%% execute
[normalizationChannels,paramsIn] = StandaloneGUI_prepare(noiseChannels,doGroundNormalization,paramsIn,filesToProcess,filesAlignMax, filesAlignMin);
StandaloneGUI(paths, filesToProcess, thres, normalizationChannels, paramsIn);

for i=1:length(Channels)
    results_filenames{i} = [paths.pathOut,filesep,deblank(num2str(extractionThreshold)),...
        filesep,paramsIn.processedFilePrefix,deblank(num2str(i)),'_sorted_new.mat'];
end
original_filename = [paths.basePath,filesep,AnimalID,Unit];
save(fullfile(paths.pathOut,deblank(num2str(extractionThreshold)),...
    [paramsIn.processedFilePrefix,deblank(num2str(i)),'filenames.mat']),...
    'results_filenames', 'original_filename');

end
