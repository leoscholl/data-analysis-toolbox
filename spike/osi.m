function [OSI,DSI] = osi(response, theta)
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here
response = reshape(response, length(response), 1);
theta = reshape(theta, length(theta), 1);
[~, prefInd] = max(response);
prefTheta = theta(prefInd);
theta_ = mod(theta - prefTheta + pi/2, 2*pi);
left = 0 <= theta_ &...
    theta_ < pi;
OSI = abs(sum(response(left).*exp(2.1i*theta(left)))/sum(response(left)));
DSI = abs(sum(response.*exp(1i*theta))/sum(response));
end

