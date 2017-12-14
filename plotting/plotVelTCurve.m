function [ handle, suffix ] = plotVelTCurve(Statistics, SpikeData, ...
    Params, color, showFigure, elecNo, cell)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Take velocities from the params file
velParams = Params;
velConditions = unique(Params.Data.velocity);
velConditionNo = zeros(length(velConditions),1);
for k = 1:length(velConditionNo)
    velConditionNo(k) = ...
        unique(Params.Data.conditionNo(Params.Data.velocity == ...
        velConditions(k))); % should only be one!
end
velParams.ConditionTable.condition = velConditions(velConditionNo);
velParams.Conditions.Velocity = velConditions(velConditionNo);
velStatistics = Statistics;
velStatistics.conditionNo = velConditionNo;

[ handle ] = plotTCurve(velStatistics, SpikeData, ...
    velParams, color, showFigure, elecNo, cell);
set(gca,'xscale','log'); % use log scale
suffix = 'vel_tc';

end

