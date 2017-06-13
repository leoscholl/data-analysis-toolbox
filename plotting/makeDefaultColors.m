function [ colors ] = makeDefaultColors( nColors )
%makeDefaultColors Generates n colors for plotting

basicColors = ['k';'b';'g';'c';'r'];
colors = zeros(length(basicColors), 3);
for c = 1:length(basicColors)
    % This little gem from the mathworks forums magically converts each
    % single-letter color code into a RGB value
    colors(c,:) = rem(floor((strfind('kbgcrmyw', basicColors(c)) - 1) * ...
        [0.25 0.5 1]), 2);
end

colors = [colors; hsv(max(nColors) - size(colors, 1))];

end

