function plotMap(x,y,v,factorName,style,varargin)
%PlotMaps Plot RF maps with 3x interpolation

% Interpolate
pixelSize = mean(diff(unique(x)))/3;
[xq,yq] = meshgrid(min(x):pixelSize:max(x), ...
    min(y):pixelSize:max(y));
vq = griddata(x,y,v,xq,yq);

% Plot
switch style
    case 'image'
        imagesc(unique(x), unique(y), vq);
        set(gca, 'ydir', 'normal');
        colorbar; colormap('jet');
    case 'outline'
        yrange = varargin{1};
        label = varargin{2};
        color = varargin{3};
        [C,h] = contour(xq,yq,vq,yrange,'ShowText','off','Color',color);
        t = clabel(C);
        for i = 2:2:length(t)
            t(i).String = label;
        end
end
xlabel(sprintf('%s X [deg]',factorName), 'Interpreter', 'none');
ylabel(sprintf('%s Y [deg]',factorName), 'Interpreter', 'none');
axis tight;
box off;

