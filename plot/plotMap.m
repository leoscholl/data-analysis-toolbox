function [ nf ] = plotMap(nf, ex, spikes, uid, varargin)
%PlotMaps Function plotting RF maps

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.parse(varargin{:});
offset = p.Results.offset;

% Gather conditions
if isfield(ex.CondTestCond, 'Position')
    conditionName = 'Position';
else
    conditionName = 'Position_Final';
end
    
% Calculate MFR and F1
pre = nan(length(ex.CondTest.CondIndex), 1); 
peri = pre; 
pos = repmat(pre, 1, length(ex.CondTestCond.(conditionName){1}));
for t = 1:length(ex.CondTest.CondIndex)
    t1 = ex.CondTest.CondOn(t);
    t0 = t1 - offset;
    pre(t) = mfr(spikes, t0, t1)/ex.secondperunit;
    t0 = t1;
    t1 = ex.CondTest.CondOff(t);
    peri(t) = mfr(spikes, t0, t1)/ex.secondperunit;
    pos(t,:) = ex.CondTestCond.(conditionName){t};
end   

% Group
[uPos, ~, iPos] = unique(pos, 'rows');
v = nan(size(uPos,1),1);
for i = 1:size(uPos,1)
    mapPeri = nanmean(peri(iPos == i));
    mapPre = nanmean(pre(iPos == i));
    v(i) =  mapPeri - mapPre;    
end

% Interpolate
x = uPos(:,1);
y = uPos(:,2);
pixelSize = mean(diff(unique(x)))/3;
[xq,yq] = meshgrid(min(x):pixelSize:max(x), ...
    min(y):pixelSize:max(y));
vq = griddata(x,y,v,xq,yq);

% Plot
imagesc(unique(x), unique(y), vq);
set(gca, 'ydir', 'normal');
colormap('jet');
xlabel(sprintf('%s X [deg]',conditionName), 'Interpreter', 'none');
ylabel(sprintf('%s Y [deg]',conditionName), 'Interpreter', 'none');
colorbar;
axis tight;
box off;

nf.suffix = 'map';
nf.dress();

end