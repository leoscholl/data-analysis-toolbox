function [sub, subTime] = subvec(vec, t0, t1, fs, time)
%SUBVEC returns sub-vector in given range
%   Detailed explanation goes here
i0 = floor(t0*fs)+1;
i1 = min(length(vec), floor(t1*fs)+1);
sub = vec(i0:i1);
subTime = [i0/fs, i1/fs];
end

