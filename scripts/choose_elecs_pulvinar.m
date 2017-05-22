function whichElectrodes = choose_elecs_pulvinar(animalID, unit, location)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

load(['C:\Users\leo\Google Drive\Matlab\data-analysis\manual analysis\',...
    animalID,'-locations.mat']);
switch location
    case 'medial'
        whichElectrodes = Elecs.medial{Elecs.unit == unit};
    case 'lateral'
        whichElectrodes = Elecs.lateral{Elecs.unit == unit};
    otherwise
        whichElectrodes = [];
end

end

