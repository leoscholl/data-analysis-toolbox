function nf = plotLfp(nf, ex, data, fs, time, varargin)
%plotLfp Draw a per-condition plot of LFP data

% Parse optional inputs
p = inputParser;
p.addOptional('offset', min(0.5/ex.secondperunit, (ex.PreICI + ex.SufICI)/2));
p.parse(varargin{:});
offset = p.Results.offset;

% Collect rasters
dur = nanmean(diff(ex.CondTest.CondOn));
tickDistance = max(0.1, round(dur/10, 1, 'significant')); % maximum 20 ticks
stimDur = nanmean(ex.CondTest.CondOff - ex.CondTest.CondOn);
samples = ceil(dur*fs*ex.secondperunit);
x = linspace(-offset, dur-offset, samples);
lfp = zeros(length(ex.CondTest.CondIndex), samples);
for t = 1:length(ex.CondTest.CondIndex)
    t0 = ex.CondTest.CondOn(t) - offset;
    t1 = t0 + dur;
    if isnan(t0)
        continue;
    end
    sub = subvec(data, t0*ex.secondperunit, t1*ex.secondperunit, fs, time);
    lfp(t,1:min(length(sub),samples)) = sub(1:min(length(sub),samples))';
end

% Gather conditions
conditionNames = fieldnames(ex.Cond);
conditionName = conditionNames{1}; % Take the first one for now
conditions = ex.Cond.(conditionName);
if iscell(conditions)
    conditions = cell2mat(conditions);
end

% Group conditions
idx = unique(ex.CondTest.CondIndex);
lfpMean = zeros(length(idx), samples);
for i = 1:length(idx)
    lfpMean(i,:) = mean(lfp(ex.CondTest.CondIndex == idx(i),:),1);
end

minY = min(lfpMean(:));
maxY = max(lfpMean(:));

hold on;

for i = 1:length(idx)
    
    % Make a two-column subplot
    if length(idx) > 1
        ax = subplot(ceil(length(idx)/2),2,i);
    else
        ax = subplot(1,1,1);
    end

    plot(x, lfpMean(i,:), 'b');

    axis(ax,[-offset dur-offset minY maxY]);
    
    % XTick
    box(ax,'off');
    axis(ax, [-offset dur-offset minY ...
        maxY]);
    tick = 0:-tickDistance:-offset; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:dur-offset];
    
    % Mark stim duration
    set(ax,'XTick',tick);
    v = [0 minY; stimDur minY; stimDur maxY; 0 maxY];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    if i == length(idx) || i == length(idx) - 1
        if i == length(idx) || mod(length(idx),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    ylabel(ax, 'Voltage [mV]');
    
    if length(idx) > 1 
        if isnumeric(conditions)
            title(ax, sprintf('%s = %.3f', conditionName, conditions(idx(i))), ...
                'FontWeight','Normal', 'Interpreter', 'none');
        elseif iscellstr(conditions)
            title(ax, sprintf('%s', conditions{idx(i)}), ...
                'FontWeight','Normal', 'Interpreter', 'none');
        end
    end
   
    
end
hold off;
nf.suffix = 'lfp';
nf.dress();
end