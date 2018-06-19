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
        if length(varargin) == 1
            clims = varargin{1};
        else
            clims = [-max(abs(v)) max(abs(v))];
        end
        colorbar; colormap('jet'); caxis(clims);
    case 'outline'
        yrange = varargin{1};
        color = varargin{2};
        contour(xq,yq,vq,yrange,'ShowText','off','Color',color);
    otherwise
        error('Unknown style, use ''image'' or ''outline''');
end
xlabel(sprintf('%s X [deg]',factorName), 'Interpreter', 'none');
ylabel(sprintf('%s Y [deg]',factorName), 'Interpreter', 'none');
axis tight;
box off;

