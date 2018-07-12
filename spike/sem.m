function [e] = sem(x, dim)
%SEM Standard error of mean
%   Detailed explanation goes here
if nargin < 2
    [~, dim] = max(size(x));
end
if isempty(x), e = NaN; return, end
e = nanstd(x,[],dim)/sqrt(size(x,dim));
end

