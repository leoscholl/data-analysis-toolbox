function [f0,f1] = f0f1(spikes, t0, t1, tf)
%F0F1 Summary of this function goes here
%   Detailed explanation goes here

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

