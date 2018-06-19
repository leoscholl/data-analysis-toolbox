function [sub, subTime] = subvec(vec, t0, samples, fs)
%SUBVEC returns sub-vector in given range
%   Detailed explanation goes here
sub = nan(samples,1);
i0 = floor(t0*fs)+1;
i1 = min(i0 + samples, length(vec));
if i0 < 1
    sub((1-i0):end) = vec(1:i1);
else
    sub = vec(i0:i1);
end
subTime = [i0/fs, i1/fs];
end

