function [e] = sem(x, dim)
%SEM Standard error of mean
%   Detailed explanation goes here
if nargin < 2
    dim = 1;
end
e = std(x,dim)/sqrt(size(x,dim));
end

