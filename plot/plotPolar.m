function plotPolar(groupingValues, f0, conditions)
theta = deg2rad([groupingValues; groupingValues(1)]);
response = perCondition(f0, conditions);
response = [response; response(1)];
polarplot(theta, response, '-ok');

end
