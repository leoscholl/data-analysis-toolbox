% EditCaseFiles

DataDir = 'I:\Data\';

Animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
    'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629'};
FullUnits = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
    [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13]};

for i = 1:length(Animals)
    
    AnimalID = Animals{i};
    WhichUnits = FullUnits{i};
    
%     switch AnimalID
%         case {'null'}
%             continue;
%         otherwise

            % Reset the case file
            SortedUnits = [];
            CaseFile = fullfile(DataDir, AnimalID, [AnimalID,'.mat']);
            save(CaseFile,'SortedUnits','-append');
% %     end

end