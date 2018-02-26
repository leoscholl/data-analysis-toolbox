function hout=supertitle(varargin)
%SUPTITLE puts a title above all subplots.
%
%	SUPTITLE('text') adds text to the top of the figure
%	above all subplots (a "super title"). Use this function
%	after all subplot commands.
%
%   SUPTITLE is a helper function for yeastdemo.

%   Copyright 2003-2014 The MathWorks, Inc.
%   Modified 2017 Leo Scholl

% Warning: If the figure or axis units are non-default, this
% function will temporarily change the units.

args = {};
if nargin == 1
    fig = gcf;
    str = varargin{1};
else
    if isobject(varargin{1}) && ischar(varargin{2})
        fig = varargin{1};
        str = varargin{2};
        if nargin > 2
            args = varargin(3:end);
        end
    else
        fig = gcf;
        str = varargin{1};
        args = varargin(2:end);
    end
end
p = inputParser;
p.addParameter('FontSize', get(fig,'defaultaxesfontsize')+4);
p.addParameter('PlotFontSize', get(fig,'defaultaxesfontsize'));
p.parse(args{:});

% Parameters used to position the supertitle.

% Amount of the figure window devoted to subplots
plotregion = .92;

% Y position of title in normalized coordinates
titleypos  = .95;

% Fontsize for supertitle
fs = p.Results.FontSize;

% Fudge factor to adjust y spacing between subplots
fudge=1;

figunits = get(fig,'units');

% Get the (approximate) difference between full height (plot + title
% + xlabel) and bounding rectangle.

if ~strcmp(figunits,'pixels')
    set(fig,'units','pixels');
    pos = get(fig,'position');
    set(fig,'units',figunits);
else
    pos = get(fig,'position');
end
ff = (p.Results.PlotFontSize)*1.27*5/pos(4)*fudge;

% The 5 here reflects about 3 characters of height below
% an axis and 2 above. 1.27 is pixels per point.

% Determine the bounding rectangle for all the plots

h = findobj(fig,'Type','axes');

% Just use a regular title if there is only one axis
if length(h) == 1
    title(h(1), str, 'FontSize', fs, 'FontWeight', 'normal');
    return;
end

oldUnits = get(h, {'Units'});
if ~all(strcmp(oldUnits, 'normalized'))
    % This code is based on normalized units, so we need to temporarily
    % change the axes to normalized units.
    set(h, 'Units', 'normalized');
    cleanup = onCleanup(@()resetUnits(h, oldUnits));
end

max_y=0;
min_y=1;
oldtitle = [];
numAxes = length(h);
thePositions = zeros(numAxes,4);
for i=1:numAxes
    pos=get(h(i),'pos');
    thePositions(i,:) = pos;
    if ~strcmp(get(h(i),'Tag'),'suptitle')
        if pos(2) < min_y
            min_y=pos(2)-ff/5*3;
        end
        if pos(4)+pos(2) > max_y
            max_y=pos(4)+pos(2)+ff/5*2;
        end
    else
        oldtitle = h(i);
    end
end

if max_y > plotregion
    scale = (plotregion-min_y)/(max_y-min_y);
    for i=1:numAxes
        pos = thePositions(i,:);
        pos(2) = (pos(2)-min_y)*scale+min_y;
        pos(4) = pos(4)*scale-(1-scale)*ff/5*3;
        set(h(i),'position',pos);
    end
end

np = get(fig,'nextplot');
set(fig,'nextplot','add');
if ~isempty(oldtitle)
    delete(oldtitle);
end
axes('pos',[0 1 1 1],'visible','off','Tag','suptitle');
ht=text(.5,titleypos-1,str, 'Interpreter', 'none');
set(ht,'horizontalalignment','center','fontsize',fs);
set(fig,'nextplot',np);
% axes(haold);
if nargout
    hout=ht;
end
end

function resetUnits(h, oldUnits)
    % Reset units on axes object. Note that one of these objects could have
    % been an old supertitle that has since been deleted.
    valid = isgraphics(h);
    set(h(valid), {'Units'}, oldUnits(valid));
end