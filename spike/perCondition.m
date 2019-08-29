function [m, s] = perCondition(fr, conditions)
% Organize MFR into proper conditions
m = nan(size(conditions,1), size(conditions,3));
s = m;
for l = 1:size(conditions,3)
    for i = 1:size(conditions,1)
        m(i,l) = nanmean(fr(conditions(i,:,l)));
        s(i,l) = sem(fr(conditions(i,:,l)));
        
    end
end
