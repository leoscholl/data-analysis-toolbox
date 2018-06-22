function result = processLfpData(data, fs, time, electrodeid, ...
    ex, groups, path, filename, actions, varargin)
%processLfpData Plot lfp data with the given list of plotting functions

p = inputParser;
p.addParameter('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.parse(varargin{:});
offset = p.Results.offset;

if ~iscell(actions)
    actions = {actions};
end

% Unpack inputs
groupingFactor = groups.groupingFactor;
groupingValues = groups.groupingValues;
conditions = groups.conditions;
levelNames = groups.levelNames;
labels = groups.labels;

result = struct;
result.electrodeid = electrodeid;

dur = nanmean(diff(ex.CondTest.CondOn));
stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
samples = ceil(dur*fs*ex.secondperunit);
x = linspace(-offset, dur-offset, samples);
lfp = zeros(length(ex.CondTest.CondIndex), samples);
for t = 1:length(ex.CondTest.CondIndex)
    t0 = ex.CondTest.CondOn(t) - offset;
    if isnan(t0)
        continue;
    end
    sub = subvec(data, t0*ex.secondperunit, samples, fs);
    lfp(t,1:min(length(sub),samples)) = sub(1:min(length(sub),samples))';
end
events = [-offset stimDur dur-offset];

% Organize MFR into proper conditions
lfpMean = nan(size(groupingValues,1), size(lfp,2), size(conditions,3));
for l = 1:size(conditions,3)
    for i = 1:size(conditions,1)
        lfpMean(i,:,l) = mean(lfp(conditions(i,:,l),:),1);
    end
    % Save optimal condition at each level
    [~, i] = max(max(abs(lfpMean(:,:,l)),[],2));
    result.(['maxDelta',strrep(levelNames{l},'.','_')]) = groupingValues(i,:);
end

for f = 1:length(actions)
    switch actions{f}
        case 'plotLfp'
            for l = 1:size(conditions,3)
                
                nf = NeuroFig(ex.ID, electrodeid, [], levelNames{l});
                plotLfp(x, lfpMean(:,:,l), events, labels);
                nf.suffix = 'lfp';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
        case 'plotLfpPowers'
            nf = NeuroFig(ex.ID, electrodeid, []);
            plotLfpPowers(data, fs);
            nf.suffix = 'lfp_power';
            nf.dress();
            nf.print(path, filename);
            nf.close();
        case 'plotCwt'

            % Wavelet convolution of whole dataset
            wTime = -1:(1/fs):1; % time vector for wavelet
            wFreq = 4:60; % vector of wavelet frequencies
            n = 6; % number of wavelet cycles
            wLength = length(wTime); % length of the wavelet
            % Initialize a matrix for the convolution results
            wavelet_conv = zeros(length(wFreq),length(data));
            % Transform data into frequency domain
            nfft = length(data) + wLength - 1;
            df = fft(data', nfft);
            for i=1:length(wFreq) % Loop through every frequency
                % Create the wavelet
                fr = wFreq(i);
                s = n/(2*pi*fr);
                A = 1/sqrt(s*sqrt(pi));
                wavelet = A*exp(1i*2*pi*fr*wTime).*exp(-(wTime.^2)/(2*s^2));
                % Do the convolution
                full = ifft(df.*fft(wavelet,nfft));
                wavelet_conv(i,:) = full((1+(wLength-1)/2):(length(full)-(wLength-1)/2));
            end

            cwt = nan(length(wFreq), samples, length(ex.CondTest.CondIndex));
            for t = 1:length(ex.CondTest.CondIndex)
                t0 = ex.CondTest.CondOn(t) - offset;
                ind1 = round(t0*ex.secondperunit*fs+1);
                ind2 = ind1+samples-1;
                if isnan(t0) || ind1 < 1 || ind2 > size(wavelet_conv,2)
                    continue;
                end
                cwt(:,:,t) = abs(wavelet_conv(:, ind1:ind2));
            end

            % Organize per condition per group
            cwtMean = nan(size(cwt,1), size(cwt,2), size(groupingValues,1), size(conditions,3));
            for l = 1:size(conditions,3)
                for i = 1:size(conditions,1)
                    cwtMean(:,:,i,l) = nanmean(abs(cwt(:,:,conditions(i,:,l))),3);
                end
            end

            % Plot CWT
            for l = 1:size(conditions,3)
                nf = NeuroFig(ex.ID, electrodeid, [], levelNames{l});
                plotTimeFreq(x, wFreq, cwtMean(:,:,:,l), events, labels)
                nf.suffix = 'cwt';
                nf.dress();
                nf.print(path, filename);
                nf.close();
            end
            
        otherwise
            continue;
    end
end
end