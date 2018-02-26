function [ nf ] = plotMap(ex, spike, uid, varargin)
%PlotMaps Function plotting RF maps

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5, ex.PreICI + ex.SufICI));
p.parse(varargin{:});
offset = p.Results.offset;

% Calculate MFR and F1
spikes = spike.time(spike.unitid == uid);
pre = nan(length(ex.CondTest.CondIndex), 1); 
peri = pre;
for t = 1:length(ex.CondTest.CondIndex)
    t1 = ex.CondTest.CondOn(t);
    t0 = t1 - offset;
    pre(t) = mfr(spikes, t0, t1);
    t0 = t1;
    t1 = ex.CondTest.CondOff(t);
    peri(t) = mfr(spikes, t0, t1);
end   

% Gather conditions
conditionNames = fieldnames(ex.Cond);
X = unique(ex.Cond.(conditionNames{1}));
Y = unique(ex.Cond.(conditionNames{2}));

% Group according to condition index
idx = unique(ex.CondTest.CondIndex);
mapPeri = nan(length(Y), length(X)); mapPre = mapPeri; mapCorr = mapPeri;
for i = 1:length(idx)
    x = ex.Cond.(conditionNames{1})(idx(i));
    y = ex.Cond.(conditionNames{2})(idx(i));
    ix = find(X == x);
    iy = find(Y == y);
    mapPeri(iy,ix) = mean(peri(ex.CondTest.CondIndex == idx(i)));
    mapPre(iy,ix) = mean(pre(ex.CondTest.CondIndex == idx(i)));
    mapCorr(iy,ix) =  mapPeri(iy,ix) - mapPre(iy,ix);    
    idx(iy,ix) = i; % for testing
end

suffix = 'map';
[~, filename, ~] = fileparts(ex.DataPath);
nf = NeuroFig(filename, spike.electrodeid, uid, suffix);
hold on;

contour(X,Y,mapCorr,'ShowText','on');
colormap('jet');

% Axes, legends, etc.
xlabel(sprintf('%s [deg]', conditionNames{1}),'Interpreter', 'none');
ylabel(sprintf('%s [deg]', conditionNames{2}),'Interpreter', 'none');
axis tight;
box off;
hold off;

nf.dress();

end