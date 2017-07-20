function animalIDs = findAnimals(baseDir, searchString)
%findUnits returns a cell array of units

narginchk(1,2);

if nargin < 2 || isempty(searchString)
    searchString = '*';
end

animals = dir(fullfile(baseDir,searchString));
animals = animals(vertcat(animals.isdir));
animals = {animals.name};
animalIDs = cellfun(@animalIdFromText, animals, 'UniformOutput', false);

% Remove any incorrectly formatted animalIDs
valid = ~cellfun(@isempty, animalIDs);
animalIDs = animalIDs(valid);

% Sort animals
animalNos = cellfun(@(x)sscanf(x, '%*c%d'), animalIDs);
[~, idx] = sort(animalNos);
animalIDs = {animalIDs{idx}};

end

function animalID = animalIdFromText(text)
[nums, c] = sscanf(text, '%c%d*');
if c == 2
    animalID = [char(nums(1)), int2str(nums(2))];
else
    animalID = '';
end
end