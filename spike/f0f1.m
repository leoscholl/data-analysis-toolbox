function [f0,f1] = f0f1(varargin)
%F0F1 calculates F0 and F1 at a given frequency for given spike trains 
% [f0, f1] = f0f1(spikes, ts, tf)
%   spikes - (n x 1) cell array of peri-stimulus spike trains
%   ts - (n x 1) vector of durations for each spike train
%   tf - (n x 1) vector of temporal frequencies for each spike train 
%
% [f0, f1] = f0f1(spikes, t0, t1, tf)
%   spikes - (m x 1) vector of spike times
%   t0 - start time
%   t1 - end time
%   tf - temporal frequency
%
if iscell(varargin{1}) && nargin == 3
    spikes = varargin{1};
    t = varargin{2};
    tf = varargin{3};
    f0 = nan(length(spikes), 1);
    f1 = f0;
    for i = 1:length(spikes)
        [f0(i), f1(i)] = if0f1(spikes{i}, 0, t(i), tf(i));
    end
elseif nargin == 4
    [f0, f1] = if0f1(varargin{:});
else
    error('Incorrectly formatted input');
end
end

function [f0,f1] = if0f1(spikes, t0, t1, tf)
f1 = NaN;
T = t1 - t0;
N = max(1, ceil(tf/T));
x = psth(spikes, t0, t1, N);
ifr = x./(T/N);
Y = abs(fft(ifr))/N;
f0 = Y(:,1);
if N >= 2
    f1 = Y(:,2);
end
end

