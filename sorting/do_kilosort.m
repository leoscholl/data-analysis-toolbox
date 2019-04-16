function [ spike ] = do_kilosort( bin, nChan )

addpath(genpath('C:\Users\LyonLab\Documents\MATLAB\Kilosort2')) % path to kilosort folder
rootH = 'E:\Sorting';

ops.NchanTOT    = nChan; % total number of channels in your recording
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.trange = [0 Inf]; % time range to sort

ops.chanMap = genLinearChanMap(nChan);

%% this block runs all the steps of the algorithm

% is there a channel map file in this folder?
rootZ = fileparts(bin);
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
ops.fbinary = bin;

% load config
kiloConfig;

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);
save(fullfile(rootZ, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

%% Get Sorted spikes
% write to Phy
fprintf('Extracting spikes \n')
%rezToPhy(rez, rootdir);

spike = extractrez(rez);

end


%%

function chanMap = genLinearChanMap(nChan);
chanMap.chanMap = 1:nChan;
chanMap.xcoords = ones(1,nChan);
chanMap.ycoords = 1:nChan;
chanMap.connected = true(1,nChan);
chanMap.kcoords = 1:nChan;
end

function [spike]=extractrez(rez)
% spikeTimes will be in samples, not seconds
rez.W = gather(single(rez.Wphy));
rez.U = gather(single(rez.U));
rez.mu = gather(single(rez.mu));

if size(rez.st3,2)>4
    rez.st3 = rez.st3(:,1:4);
end

[~, isort]   = sort(rez.st3(:,1), 'ascend');
rez.st3      = rez.st3(isort, :);
rez.cProj    = rez.cProj(isort, :);
rez.cProjPC  = rez.cProjPC(isort, :, :);

spikeTimes = uint64(rez.st3(:,1));
% [spikeTimes, ii] = sort(spikeTimes);
spikeTemplates = uint32(rez.st3(:,2));
if size(rez.st3,2)>4
    spikeClusters = uint32(1+rez.st3(:,5));
end
amplitudes = rez.st3(:,3);

Nchan = rez.ops.Nchan;

xcoords     = rez.xcoords(:);
ycoords     = rez.ycoords(:);
chanMap     = rez.ops.chanMap(:);
chanMap0ind = chanMap - 1;

nt0 = size(rez.W,1);
U = rez.U;
W = rez.W;

Nfilt = size(W,2);

templates = zeros(Nchan, nt0, Nfilt, 'single');
for iNN = 1:size(templates,3)
    templates(:,:,iNN) = squeeze(U(:,iNN,:)) * squeeze(W(:,iNN,:))';
end
templates = permute(templates, [3 2 1]); % now it's nTemplates x nSamples x nChannels
templatesInds = repmat([0:size(templates,3)-1], size(templates,1), 1); % we include all channels so this is trivial

templateFeatures = rez.cProj;
templateFeatureInds = uint32(rez.iNeigh);
pcFeatures = rez.cProjPC;
pcFeatureInds = uint32(rez.iNeighPC);

whiteningMatrix = rez.Wrot/rez.ops.scaleproc;
whiteningMatrixInv = whiteningMatrix^-1;

% here we compute the amplitude of every template...

% unwhiten all the templates
tempsUnW = zeros(size(templates));
for t = 1:size(templates,1)
    tempsUnW(t,:,:) = squeeze(templates(t,:,:))*whiteningMatrixInv;
end

% The amplitude on each channel is the positive peak minus the negative
tempChanAmps = squeeze(max(tempsUnW,[],2))-squeeze(min(tempsUnW,[],2));

% The template amplitude is the amplitude of its largest channel
tempAmpsUnscaled = max(tempChanAmps,[],2);

% assign all spikes the amplitude of their template multiplied by their
% scaling amplitudes
spikeAmps = tempAmpsUnscaled(spikeTemplates).*amplitudes;

% take the average of all spike amps to get actual template amps (since
% tempScalingAmps are equal mean for all templates)
ta = clusterAverage(spikeTemplates, spikeAmps);
tids = unique(spikeTemplates);
tempAmps(tids) = ta; % because ta only has entries for templates that had at least one spike
gain = getOr(rez.ops, 'gain', 1);
tempAmps = gain*tempAmps'; % for consistency, make first dimension template number


spike.time = spikeTimes;
spike.templates = uint32(spikeTemplates);


if size(rez.st3,2)>4
    spike.clusters = uint32(spikeClusters);
else
    spike.clusters = spike.templates;
end
spike.amplitudes = amplitudes;
spike.templates_ind = templatesInds;

chanMap0ind = int32(chanMap0ind);

spike.channel_map = chanMap0ind;
spike.channel_positions = [xcoords ycoords];

spike.template_features = templateFeatures;
spike.template_feature_ind = templateFeatureInds';
spike.pc_features = pcFeatures;
spike.pc_feature_ind = pcFeatureInds';

spike.whitening_mat = whiteningMatrix;
spike.whitening_mat_inv = whiteningMatrixInv;

if isfield(rez, 'simScore')
    spike.similar_templates = rez.simScore;
end
spike.sortmethod = 'KiloSort2';
spike.sortparams = rez.ops;

end