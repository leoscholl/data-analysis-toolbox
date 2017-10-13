%% Plot scatters for TF vs OSI
close all;

pResponse = 0.005;

% Separate responding cells
Complete = Cells(arrayfun(@(x)isfield(x.response,'Orientation') && ...
    isfield(x.response,'Temporal'), Cells),:);
nComplete = size(Complete, 1);
nCompleteLP = sum(arrayfun(@(x)contains(x.location, 'LP') || ...
    strcmp(x.location, 'Border'), Complete));

Responding = Complete(arrayfun(@(x)x.response.Orientation.ttest < pResponse && ...
    x.response.Temporal.ttest < pResponse, Complete),:);
nResponding = size(Responding, 1);

% Plot Ori vs TF response
V1 = arrayfun(@(x)strcmp(x.location, 'V1'), Responding);
LPMR = arrayfun(@(x)strcmp(x.location, 'LPMR'), Responding);
LPLR = arrayfun(@(x)strcmp(x.location, 'LPLR'), Responding);
Border = arrayfun(@(x)strcmp(x.location, 'Border'), Responding);
LP = LPMR | LPLR | Border;
LGN = arrayfun(@(x)strcmp(x.location, 'LGN'), Responding);

% Separate by location
locationNames = {'V1', 'LP', 'LGN', 'Unknown', 'LPLR', 'LPMR', 'Border'};
locations = {V1, LP, LGN, ~LP & ~LGN & ~V1, LPLR, LPMR, Border};
tf = struct;
osi = struct;
for i = 1:length(locations)
    tf.(locationNames{i}) = arrayfun(@(x)x.response.Temporal.pref, Responding(locations{i}));
    osi.(locationNames{i}) = arrayfun(@(x)x.response.Orientation.osi, Responding(locations{i}));
end

% Scatter plots
figure(1);
hold on
scatter(tf.V1, osi.V1);
scatter(tf.LP, osi.LP);
scatter(tf.LGN, osi.LGN);
scatter(tf.Unknown, osi.Unknown);

title('OSI vs TF');
xlabel('TF preference');
ylabel('OSI');
axis tight
legend({'V1', 'LP', 'LGN', 'Unknown'});

dim = [.2 .5 .3 .3];
str = sprintf('%d/%d cells responding (p < %g)', nResponding, nComplete, pResponse);
annotation('textbox',dim,'String',str,'FitBoxToText','on');
hold off;

figure(2);
hold on
scatter(tf.LPLR, osi.LPLR);
scatter(tf.LPMR, osi.LPMR);
scatter(tf.Border, osi.Border);

title('OSI vs TF');
xlabel('TF selectivity');
ylabel('OSI');
axis tight
legend({'LPLR', 'LPMR', 'Border'});

dim = [.2 .5 .3 .3];
str = sprintf('%d/%d cells responding (p < %g)', size(Responding(LP), 1), nCompleteLP, pResponse);
annotation('textbox',dim,'String',str,'FitBoxToText','on');
hold off;


% Bar plots
figure(3)
tf_ = rmfield(tf, {'LPMR', 'LPLR', 'Border'});
osi_ = rmfield(osi, {'LPMR', 'LPLR', 'Border'});
bar([1 1 1 1; 2 2 2 2], [structfun(@mean, tf_)'; structfun(@mean, osi_)']);
xticklabels({'TF selectivity', 'OSI'});
legend(fieldnames(tf_), 'Location', 'BestOutside');
hold off

figure(4)
tf_ = rmfield(tf, {'LP', 'V1', 'LGN', 'Unknown'});
osi_ = rmfield(osi, {'LP', 'V1', 'LGN', 'Unknown'});

bar([1 1 1; 2 2 2], [structfun(@mean, tf_)'; structfun(@mean, osi_)']);
xticklabels({'TF selectivity', 'OSI'});
legend(fieldnames(tf_), 'Location', 'BestOutside');
hold off

% ANOVA for TF
tf_ = rmfield(tf, {'LPMR', 'LPLR', 'Border'});
osi_ = rmfield(osi, {'LPMR', 'LPLR', 'Border'});
locs = fieldnames(tf_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [tf_.(locs{i}) repmat(i, length(tf_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

tf_ = rmfield(tf, {'LP', 'V1', 'LGN', 'Unknown'});
osi_ = rmfield(osi, {'LP', 'V1', 'LGN', 'Unknown'});
locs = fieldnames(tf_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [tf_.(locs{i}) repmat(i, length(tf_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

%% Plot Latency
close all;

pResponse = 0.01;

% Separate responding cells
Complete = Cells(arrayfun(@(x)isfield(x.response,'Latency'), Cells),:);
nComplete = size(Complete, 1);

Responding = Complete(arrayfun(@(x)any(structfun(...
    @(y)y.ttest < pResponse, x.response)), Complete),:);
nResponding = size(Responding, 1);

% Collect each ROI
V1 = arrayfun(@(x)strcmp(x.location, 'V1'), Responding);
LPMR = arrayfun(@(x)strcmp(x.location, 'LPMR'), Responding);
LPLR = arrayfun(@(x)strcmp(x.location, 'LPLR'), Responding);
Border = arrayfun(@(x)strcmp(x.location, 'Border'), Responding);
LP = LPMR | LPLR | Border;
LGN = arrayfun(@(x)strcmp(x.location, 'LGN'), Responding);

% Separate by location
locationNames = {'V1', 'LP', 'LGN', 'Unknown', 'LPLR', 'LPMR', 'Border'};
locations = {V1, LP, LGN, ~LP & ~LGN & ~V1, LPLR, LPMR, Border};
latency = struct;
for i = 1:length(locations)
    latency.(locationNames{i}) = arrayfun(@(x)x.response.Latency.latency, Responding(locations{i}));
end

% Bar plots
figure(3)
latency_ = rmfield(latency, {'LPMR', 'LPLR', 'Border'});

bar(structfun(@nanmean, latency_));
xticklabels(fieldnames(latency_));
hold off

figure(4)
latency_ = rmfield(latency, {'LP', 'V1', 'LGN', 'Unknown'});
bar(structfun(@nanmean, latency_));
xticklabels(fieldnames(latency_));
hold off


% ANOVA
latency_ = rmfield(latency, {'LPMR', 'LPLR', 'Border'});
locs = fieldnames(latency_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [latency_.(locs{i}) repmat(i, length(latency_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

latency_ = rmfield(latency, {'LP', 'V1', 'LGN', 'Unknown'});
locs = fieldnames(latency_);

flat = [];
for i = 1:length(locs)
    flat = [flat; [latency_.(locs{i}) repmat(i, length(latency_.(locs{i})), 1)]];
end
anova1(flat(:,1), flat(:,2));

% PCA
% nCells = size(UCells, 1);
% CompleteCells = UCells(arrayfun(@(x)length(fieldnames(x.response)) == ...
%     length(desiredStims),UCells));
% data = nan(length(CompleteCells), length(desiredStims)*6);
% for c = 1:length(CompleteCells)
%     for s = 1:length(desiredStims)
%         stim = desiredStims{s};
%         names = fieldnames(CompleteCells(c).response.(stim));
%         for i = 1:length(names)
%             data(c,(s-1)*6 + i) = CompleteCells(c).response.(stim).(names{i});
%         end
%     end
% end
% 
% [coeff,score,latent,tsquared,explained,mu] = pca(data);
% plot3(score(:,1), score(:,2), score(:,3),'+');
% xlabel('PCA 1');
% ylabel('PCA 2');
% zlabel('PCA 3');
% 
% 