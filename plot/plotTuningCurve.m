function plotTuningCurve(cond, data, groupingFactor, levelNames)
%plotTuningCurve draws tuning curve figure

hold on;
legendItems = {};

% Plot data with SEMs
nLevels = size(data.mF0,2);
colors = jet(nLevels);
if nLevels == 1
    errorbar(cond(:,1),data.mF0,data.semF0,'k','LineWidth',1);
    if any(~isnan(data.mF1) | ~isnan(data.semF1))
        errorbar(cond(:,1),data.mF1,data.semF1,'r');
        legendItems = {'F0';'F1';'PreICI'};
    else
        legendItems = {'F0';'PreICI'};
    end
    errorbar(cond(:,1),data.mPre,data.semPre,'Color',[0.5 0.5 0.5]);
else
    for l = 1:nLevels
        errorbar(cond(:,1),data.mF0(:,l),data.semF0(:,l),'Color',colors(l,:));
        legendItems = [legendItems; {['F0_',levelNames{l}]}];
    end
end

% Configure axes, legend, title
axis tight;
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

