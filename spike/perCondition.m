function [m, s, per] = perCondition(fr, conditions)
% Organize MFR into proper conditions
m = nan(size(conditions,1), size(conditions,3));
s = m;
per = cell(size(conditions,1), size(conditions,3));
for l = 1:size(conditions,3)
    for i = 1:size(conditions,1)
        m(i,l) = nanmean(fr(conditions(i,:,l)));
        s(i,l) = sem(fr(conditions(i,:,l)));
        if nargout > 2
            per{i,l} = fr(conditions(i,:,l));
        end
    end
end
