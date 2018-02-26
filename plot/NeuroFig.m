classdef NeuroFig < handle
    %NeuroFig Wrapper for figure that handles titles and saving
    %   Detailed explanation goes here
    
    properties
        handle      % Figure handle
        test        % Test name
        electrode   % Electrode number
        unit        % Unit number
        suffix      % to append on filename
        
        % Defaults
        font = 'Helvetica';
        fontSize = 6;
        titleSize = 18;
        params = {'Ori', 'Diameter', 'Size', 'Color', 'Position', ...
            'Contrast', 'SpatialFreq', 'TemporalFreq', 'GratingType'};
    end
    
    properties (Access = private)
    end
    
    methods
        function obj = NeuroFig(test, electrode, unit, suffix)
            %NeuroFig Construct an instance of this class
            %   Detailed explanation goes here
            obj.test = test;
            obj.electrode = electrode;
            obj.unit = unit;
            obj.suffix = suffix;
            
            % Set up a new figure
            obj.handle = figure('Visible','off','Color','White');
        end
        
        function dress(obj, varargin)
            %dress Add (optionally) a title and/or an annotation to the
            %figure
            
            p = inputParser;
            p.addParameter('Title', '', @ischar);
            p.addParameter('EnvParam', struct([]), @isstruct);
            p.addParameter('OSI', [], @isnumeric);
            p.addParameter('DSI', [], @isnumeric);
            p.parse(varargin{:});
                       
            % Apply default annotation
            params = NeuroAnalysis.Base.getstructfields(p.Results.EnvParam, ...
                obj.params);
            if ~isempty(p.Results.OSI) && ~isempty(p.Results.DSI)
                params.OSI = p.Results.OSI;
                params.DSI = p.Results.DSI;
            end
            str = obj.prepareAnnotation(params);
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
            if isempty(title)
                title = obj.defaultTitle();
            end
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
        
        function print(obj, path, filename, format)
            %print Print to file
            if nargin < 3 || isempty(format)
                format = 'png';
            end
            set(obj.handle,'renderer','painters');
            [~, filename, ~] = fileparts(filename);
            fullname = sprintf('%s_Elec-%d_Unit-%d_%s.%s', filename, ...
                obj.electrode, obj.unit, obj.suffix, format);
            saveas(obj.handle, fullfile(path, fullname));
        end
        
        
    end
    
    methods (Access = private)
        
        function title = defaultTitle(obj)
            %makeTitle makes a title
            if isempty(obj.unit)
                title = sprintf('%s   Elec %d', obj.test, obj.electrode);
            else
                title = sprintf('%s   Elec %d   Unit %d', obj.test, ...
                    obj.electrode, obj.unit);    
            end
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
                elseif isnumeric(x)
                    c = horzcat(sprintf('%.3f ',x));
                else
                    c = '?';
                end
            end
        end
        
    end
    
end

