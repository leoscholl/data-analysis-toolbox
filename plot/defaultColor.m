function [ color ] = defaultColor( unitid )
%defaultColor Generates the default color for the given unit id

basicColors = ['k';'b';'g';'c';'r'];
colors = zeros(length(basicColors), 3);
for c = 1:length(basicColors)
    % This little gem from the mathworks forums magically converts each
    % single-letter color code into a RGB value
    colors(c,:) = rem(floor((strfind('kbgcrmyw', basicColors(c)) - 1) * ...
        [0.25 0.5 1]), 2);
end

extraColors = hsv(20);
colors = [colors; extraColors(2:end,:)];

color = colors(unitid+1,:);

end

