function plotPolar(groupingValues, f0)
theta = deg2rad([groupingValues; groupingValues(1)]);
response = cellfun(@mean, f0);
response = [response; response(1)];
polarplot(theta, response, '-ok');

end
