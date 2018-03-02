function [sub, subTime] = subvec(vec, t0, t1, fs, time)
%SUBVEC returns sub-vector in given range
%   Detailed explanation goes here
i0 = floor(t0*fs)+time(1)+1;
i1 = min(time(2), floor(t1*fs)+time(1)+1);
sub = vec(i0:i1);
subTime = [i0/fs, i1/fs];
end

