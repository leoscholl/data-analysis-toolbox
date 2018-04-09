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
v = nan(length(uPos),1);
for i = 1:length(uPos)
    mapPeri = mean(peri(iPos == i));
    mapPre = mean(pre(iPos == i));
    v(i) =  mapPeri - mapPre;    
end

% Interpolate
x = uPos(:,1);
y = uPos(:,2);
[xq,yq] = meshgrid(min(x):max(x), ...
    min(y):max(y));
vq = griddata(x,y,v,xq,yq);

% Plot
s = surf(xq,yq,vq);
s.EdgeColor = 'none';
colormap('jet');
xlabel('X [deg]');
ylabel('Y [deg]');
colorbar;
axis tight;
box off;
view(0,90);


nf.suffix = 'map';
nf.dress();

end