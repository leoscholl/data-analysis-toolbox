function plotTuningCurve(cond, data, conditions, groupingFactor, levelNames)
%plotTuningCurve draws tuning curve figure

hold on;
legendItems = {};

% Prepare colors
items = fieldnames(data);
nLevels = size(conditions,3);
if nLevels == 1 && length(items) == 3
    colors(1,:,1) = [0 0 0];
    colors(1,:,2) = [1 0 0];
    colors(1,:,3) = [0.5 0.5 0.5];
elseif nLevels == 1
    colors = reshape(distinguishable_colors(length(items)), 1, 3, length(items));
else
    colors = repmat(distinguishable_colors(nLevels), 1, 1, length(items));
end

% Plot data with SEMs
for i = 1:length(items)
    pop = data.(items{i});
    for l = 1:nLevels
        [m, s] = perCondition(pop, conditions(:,:,l));
        errorbar(cond,m,s,'Color',colors(l,:,i),'LineWidth',1);
        if isempty(levelNames) || isempty(levelNames{l})
            legendItems = [legendItems; items{i}];
        else
            legendItems = [legendItems; ...
            {strcat(items{i},sprintf('_%s',levelNames{l}))}];
        end
    end
end

% Configure axes, legend, title
axis tight;
lim = axis;
ylim([0 lim(4)]);
legend(legendItems,'Location','NorthEast','Interpreter','none');
legend('boxoff');

xlabel(groupingFactor, 'Interpreter', 'none');
ylabel('Rate [spikes/s]');
if issorted(cond, 'strictmonotonic') 
    set(gca,'XTick',cond);
else
    x = unique(cond,'rows');
    set(gca,'XTick',x(:,1));
end
box off;


hold off;

end

