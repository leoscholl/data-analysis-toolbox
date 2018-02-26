function [ nf ] = plotWaveforms(ex, spike)
%PlotWaveforms plots mean waveform for each unit

fs = 30000;

% helper function to fill std error
fill_between_lines = @(X,Y1,Y2,C) patch( [X fliplr(X)],  [Y1 fliplr(Y2)], ...
    1, 'FaceColor', C, 'EdgeColor', 'none');

suffix = 'wf';
nf = NeuroFig(ex.ID, spike.electrodeid, [], suffix);

if isempty(spike.data)
    error(['No waveforms in ch ',num2str(spike.electrodeid)]);
end

numSpikes = [];

% Plot the waveforms
lines = [];

hold on;
for u = 1:length(spike.uuid)
    wf_unit = spike.data(:,spike.unitid == spike.uuid(u))';
    numSpikes(u) = size(wf_unit,1);
    x = 1000*(1/fs:1/fs:size(wf_unit,2)/fs);
    wf_mean = mean(wf_unit,1);
    wf_std = std(wf_unit,0,1);
    wf_sem = wf_std/sqrt(size(wf_unit,1));
    
    h = plot(x,wf_mean, 'Color',defaultColor(spike.uuid(u)),'LineWidth',1.5);
    lines = [lines; h];
    
    %fill_between_lines(x, wf_mean-wf_sem, wf_mean+wf_sem, defaultColor(spike.uuid(u)));
    fill_between_lines(x, wf_mean-wf_std, wf_mean+wf_std, defaultColor(spike.uuid(u)));
end
hold off;
alpha(0.15); % add transparency
legend(lines,arrayfun( ...
    @(x)sprintf('unit %d (%d spks)', spike.uuid(x), numSpikes(x)), ...
    1:length(spike.uuid), 'Un', 0));
legend boxoff;
axis tight;
xlabel('Time (ms)')
ylabel('Voltage (uV)')

nf.dress();

end

