function [e] = sem(x, dim)
%SEM Standard error of mean
%   Detailed explanation goes here
if nargin < 2
    [~, dim] = max(size(x));
end
e = nanstd(x,[],dim)/sqrt(size(x,dim));
end

