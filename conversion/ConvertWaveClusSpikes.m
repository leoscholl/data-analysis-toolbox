function ConvertWaveClusSpikes(filename)

[path, name, ~] = fileparts(filename);

load([path,filesep,'times_',name,'-raw.mat']);

dur = length(spikes(:,1));
adc001 = [ones(dur,1), cluster_class(:,2)./1000, cluster_class(:,1), -1*ones(dur,1), spikes];
save([path,filesep,name,'-waveclus-spikes.mat'], 'adc001');

end