function [ colors ] = makeDefaultColors( units )
%makeDefaultColors Generates n colors for plotting

basicColors = ['k';'b';'g';'c';'r'];
colors = zeros(length(basicColors), 3);
for c = 1:length(basicColors)
    % This little gem from the mathworks forums magically converts each
    % single-letter color code into a RGB value
    colors(c,:) = rem(floor((strfind('kbgcrmyw', basicColors(c)) - 1) * ...
        [0.25 0.5 1]), 2);
end

valueSet = num2cell([colors; hsv(max(units) - size(colors, 1))], 2);
keySet = 0:length(colors)-1;

map = containers.Map(keySet, valueSet);
map(-1) = colors(1,:);

colors = values(map, num2cell(units));
colors = vertcat(colors{:});

end

