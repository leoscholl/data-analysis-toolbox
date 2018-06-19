classdef NeuroFig < handle
    %NeuroFig Wrapper for figure that handles titles and saving
    %   Detailed explanation goes here
    
    properties
        handle      % Figure handle
        test        % Test name
        electrode   % Electrode number
        unit        % Unit number
        info        % Other title information
        suffix      % to append on filename
        
        % Defaults
        font = 'Helvetica';
        fontSize = 10;
        titleSize = 28;
    end
    
    properties (Access = private)
    end
    
    methods
        function obj = NeuroFig(test, electrode, unit, varargin)
            %NeuroFig Construct an instance of this class
            %   Detailed explanation goes here
            
            if exist('test', 'var') && ~isempty(test)
                obj.test = test;
            end
            if exist('electrode', 'var') && ~isempty(electrode)
                obj.electrode = electrode;
            end
            if exist('unit', 'var') && ~isempty(unit)
                obj.unit = unit;
            end
            if ~isempty(varargin)
                obj.info = varargin(~cellfun(@isempty,varargin));
            end
            
            % Set up a new figure
            obj.handle = figure('Visible','off','Color','White',...
                'Position', [0 0 900 600], ...
                'PaperUnits', 'inches', ...
                'PaperPositionMode', 'auto');
        end
        
        function dress(obj, varargin)
            %dress Add (optionally) a title and/or an annotation to the
            %figure
                        
            p = inputParser;
            p.addParameter('Title', obj.defaultTitle(), @ischar);
            p.addParameter('Params', []);
            p.parse(varargin{:});
            
            % Apply default annotation
            str = obj.prepareAnnotation(p.Results.Params);
            h = findobj(obj.handle,'Type','axes');
            
            % Only annotate single axes
            if length(h) == 1 && ~isempty(str)
                delete(findall(obj.handle,'Type','annotation'))
                dim = [0.1 0.1 0.1 0.4];
                pos = get(h(1), 'Position');
                dim_ax = [dim(1:2).*pos(1:2) + pos(1:2), 0, 0];
                a = annotation(obj.handle, 'textbox',dim_ax, ...
                    'String',str,'FitBoxToText','on', ...
                    'Interpreter', 'none', 'FontName', 'FixedWidth', ...
                    'FontSize', obj.fontSize);
                
                % Wait for the position to be automatically adjusted
                while dim_ax == get(a, 'Position'); pause(0.01); end
                pos = get(a, 'Position');
                
                % Set the correct position
                set(a, 'Position', [dim_ax(1:2), pos(3:4)]);
            end
            
            % Set font size properly
            for i = 1:length(h)
                set(h(i), 'FontSize', obj.fontSize);
            end
            
            % Apply default title
            title = p.Results.Title;
            supertitle(obj.handle, title, 'FontSize', obj.titleSize, ...
                'PlotFontSize', obj.fontSize);
            
        end
        
        function show(obj)
            %show Displays the figure
            set(obj.handle,'Visible','on');
        end
        
        function hide(obj)
            %hide Turns off the figure
            set(obj.handle,'Visible','off');
        end
        
        function close(obj)
            close(obj.handle);
        end
        
        function print(obj, path, filename, format, pretty)
            %print Print to file
            if nargin < 5 || isempty(pretty)
                pretty = false;
            end
            if nargin < 4 || isempty(format)
                format = 'png';
            end
            [~, filename, ~] = fileparts(filename);
            
            if isempty(obj.electrode)
                electrode = '';
            else
                electrode = sprintf('_Elec_%d', obj.electrode);
            end
            if isempty(obj.unit)
                unit = '';
            else
                unit = sprintf('_Unit_%d', obj.unit);
            end
            if isempty(obj.info)
                info = '';
            else
                info = sprintf('_%s', obj.info{:});
            end
            if isempty(obj.suffix)
                suffix = '_plot';
            else
                suffix = strcat('_',obj.suffix);
            end
            fullname = strcat(filename, electrode, unit, info, suffix, '.', format);
            
            if strcmp(format, 'fig')
                savefig(obj.handle, fullfile(path, fullname), 'compact');
            elseif pretty
                export_fig(obj.handle, fullfile(path, fullname), ...
                    sprintf('-%s', format), '-painters', '-r300', '-m2', ...
                    '-dg576x432', '-p0.02');
            else
                fig_pos = obj.handle.PaperPosition;
                obj.handle.PaperSize = [fig_pos(3) fig_pos(4)];
                frame = getframe(obj.handle);
                [raster, raster_map] = frame2im(frame); % raster is the rasterized image, raster_map is the colormap
                h_crop = 20;
                w_crop = 50;
                raster = raster(1:end-h_crop,w_crop+1:end-w_crop,:);
                if isempty(raster_map)
                    imwrite(raster, fullfile(path, fullname));
                else
                    imwrite(raster, raster_map, fullfile(path, fullname));
                end
            end
        end
        
        
    end
    
    methods (Access = private)
        
        function title = defaultTitle(obj)
            %makeTitle makes a title
            if isempty(obj.info)
                info = '';
            else
                info = sprintf('   %s', obj.info{:});
            end
            if isempty(obj.test)
                obj.test = '';
            end
            if isempty(obj.unit)
                unit = '';
            else
                unit = sprintf('   Unit %d', obj.unit);
            end
            if isempty(obj.electrode)
                electrode = '';
            else
                electrode = sprintf('   Elec %d', obj.electrode);
            end
            title = strcat(obj.test, electrode, unit, info);
        end
        
    end
    
    methods (Static, Access = private)
        
        function annotation = prepareAnnotation(params)
            %addAnnotation Summary of this function goes here
            %   Detailed explanation goes here
            
            if isempty(params)
                annotation = '';
                return
            end
            params = structfun(@convertToChar, params, ...
                'UniformOutput',false);
            fields = fieldnames(params);
            keyvalue = cell(length(fields)*2,1);
            keyvalue(1:2:end) = fields;
            keyvalue(2:2:end) = struct2cell(params);
            annotation = sprintf('%15s: %s\n',keyvalue{:});
            annotation = annotation(1:end-2); % remove trailing newline
            
            function c = convertToChar(x)
                if ischar(x)
                    c = x;
                elseif isinteger(x) || all(round(x) == x)
                    c = horzcat(sprintf('%d ',x));
                elseif isnumeric(x) && x < 0.001
                    c = horzcat(sprintf('%g ',x));
                elseif isnumeric(x)
                    c = horzcat(sprintf('%.3f ',x));
                else
                    c = '?';
                end
            end
        end
        
    end
    
end

