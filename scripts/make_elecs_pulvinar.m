animalID = 'R1702';

unit = [1:9]';

medial = {[4];
          [4];
          [3 4];
          [3 4];
          [3 4];
          [3 4];
          [2 3 4];
          [2 3 4];
          [2 3 4]};
      
lateral = {[1 2 3];
           [1 2 3];
           [1 2];
           [1 2];
           [1 2];
           [1 2];
           [1];
           [1];
           [1]};
       
Elecs = table(unit, medial, lateral);

save(['C:\Users\leo\Google Drive\Matlab\data-analysis\manual analysis\',...
    animalID,'-locations.mat'],'Elecs');