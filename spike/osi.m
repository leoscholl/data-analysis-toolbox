function [OSI,DSI] = osi(response, theta)
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here
theta(isnan(response)) = [];
response(isnan(response)) = [];
OSI = abs(sum(response(:).*exp(2i*mod(theta(:), pi)))/sum(response(:)));
DSI = abs(sum(response(:).*exp(1i*theta(:)))/sum(response(:)));
end

