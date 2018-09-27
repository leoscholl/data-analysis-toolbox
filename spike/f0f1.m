function [f0,f1] = f0f1(varargin)
%F0F1 Summary of this function goes here
%   Detailed explanation goes here
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

