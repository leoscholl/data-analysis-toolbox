function varargout = analysis_ui(varargin)
%ANALYSIS_UI MATLAB code file for analysis_ui.fig
%      ANALYSIS_UI, by itself, creates a new ANALYSIS_UI or raises the existing
%      singleton*.
%
%      H = ANALYSIS_UI returns the handle to a new ANALYSIS_UI or the handle to
%      the existing singleton*.
%
%      ANALYSIS_UI('Property','Value',...) creates a new ANALYSIS_UI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to analysis_ui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      ANALYSIS_UI('CALLBACK') and ANALYSIS_UI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in ANALYSIS_UI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help analysis_ui

% Last Modified by GUIDE v2.5 22-Jun-2017 15:48:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analysis_ui_OpeningFcn, ...
                   'gui_OutputFcn',  @analysis_ui_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

global uiPrefsList

% --- Executes just before analysis_ui is made visible.
function analysis_ui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for analysis_ui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes analysis_ui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Load preferences
global uiPrefsList
uiPrefsList = {'PlotLFPCheck', 'ShowFiguresCheck', ...
    'SummaryFigsCheck', 'DataDirBox', 'FiguresDirBox', ...
    'AnimalIDBox', 'UnitNoBox', 'FileNoBox'};
loadPrefs(handles);

% Set the title
set(hObject, 'Name', 'analysis UI')

% Remove the summary panel
state = get(handles.ShowSummary, 'Value');
set(handles.SummaryTable, 'Data', []);
if state
    toggleSummaryVisibility(handles, 0);
    set(handles.ShowSummary, 'Value', 0);
end


% --- Outputs from this function are returned to the command line.
function varargout = analysis_ui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make sure any summary data is exported
if isfield(handles, 's') && isa(handles.s, 'summaryTable')
    disp(['Exporting summary to ', fileName]);
    fileName = handles.s.export();
end

% Save Preferences
global uiPrefsList
disp('Saving preferences...');
savePrefs(handles);

% Close the figure
delete(hObject);


% --- Executes on button press in Recalculate.
function Recalculate_Callback(hObject, eventdata, handles)
% hObject    handle to Recalculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));
fileNo = eval(get(handles.FileNoBox, 'String'));
whichElectrodes = eval(get(handles.ElectrodeNoBox, 'String'));
expTypeMenu = cellstr(get(handles.ExpTypeMenu, 'String'));
expType = expTypeMenu{get(handles.ExpTypeMenu, 'Value')};

plotLFP = get(handles.PlotLFPCheck, 'Value');
showFigures = get(handles.ShowFiguresCheck, 'Value');
summaryFigs = get(handles.SummaryFigsCheck, 'Value');
dataDir = get(handles.DataDirBox, 'String');
figuresDir = get(handles.FiguresDirBox, 'String');

switch expType
    case 'Spikes'
        recalculate(dataDir, figuresDir, animalID, unitNo, fileNo, whichElectrodes, ...
            showFigures, plotLFP, summaryFigs);
    case 'ECoG'
        
end


% --- Helper function for plotting buttons
function plotHelper(handles, figureType)

animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));
fileNo = eval(get(handles.FileNoBox, 'String'));
whichElectrodes = eval(get(handles.ElectrodeNoBox, 'String'));
dataDir = get(handles.DataDirBox, 'String');
figuresDir = get(handles.FiguresDirBox, 'String');

expTypeMenu = cellstr(get(handles.ExpTypeMenu, 'String'));
expType = expTypeMenu{get(handles.ExpTypeMenu, 'Value')};

switch expType
    case 'Spikes'
        plotIndividual(dataDir, figuresDir, animalID, unitNo, fileNo, ...
            whichElectrodes, figureType)
    case 'ECoG'
        
end


% --- Executes on button press in PlotWaveforms.
function PlotWaveforms_Callback(hObject, eventdata, handles)
% hObject    handle to PlotWaveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotHelper(handles, 'waveforms');

% --- Executes on button press in PlotISIs.
function PlotISIs_Callback(hObject, eventdata, handles)
% hObject    handle to PlotISIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotHelper(handles, 'isi');

% --- Executes on button press in PlotRasters.
function PlotRasters_Callback(hObject, eventdata, handles)
% hObject    handle to PlotRasters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotHelper(handles, 'rasters');

% --- Executes on button press in PlotLFP.
function PlotLFP_Callback(hObject, eventdata, handles)
% hObject    handle to PlotLFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotHelper(handles, 'lfp');

% --- Executes on button press in PlotExtras.
function PlotExtras_Callback(hObject, eventdata, handles)
% hObject    handle to PlotExtras (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotHelper(handles, 'extras');


% --- Executes on button press in SummaryPrev.
function SummaryPrev_Callback(hObject, eventdata, handles)
% hObject    handle to SummaryPrev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isa(handles.s, 'summaryTable')
    handles.s.prevUnit();
    handles.s.showUnit();
    set(handles.UnitNoBox, 'String', num2str(handles.s.unitNo));
end

% --- Executes on button press in SummaryNext.
function SummaryNext_Callback(hObject, eventdata, handles)
% hObject    handle to SummaryNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isa(handles.s, 'summaryTable')
    handles.s.nextUnit();
    handles.s.showUnit();
    set(handles.UnitNoBox, 'String', num2str(handles.s.unitNo));
end

% --- Executes on button press in SummaryFinish.
function SummaryFinish_Callback(hObject, eventdata, handles)
% hObject    handle to SummaryFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isa(handles.s, 'summaryTable')
    fileName = handles.s.export();
    handles.s = [];
    guidata(hObject, handles);
    set(handles.UnitNoBox, 'String', '[]');
    set(handles.ShowSummary, 'Value', 0);
    toggleSummaryVisibility(handles, 0);
    disp(['Exported summary data to ', fileName]);
end

% --- Executes on button press in SummaryStart.
function SummaryStart_Callback(hObject, eventdata, handles)
% hObject    handle to SummaryStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dataDir = get(handles.DataDirBox, 'String');
animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));

% Set up the summary object
if isfield(handles, 's') && isa(handles.s, 'summaryTable')
    warning('Already started');
    return;
end

% Show the summary panel
state = get(handles.ShowSummary, 'Value');
if ~state
    set(handles.ShowSummary, 'Value', 1);
    toggleSummaryVisibility(handles, 1);
end
drawnow
disp('Preparing summary...');
s = summaryTable( dataDir, animalID, unitNo, handles );
s.showUnit();
handles.s = s;
guidata(hObject,handles);


% Update the unit number
set(handles.UnitNoBox, 'String', num2str(handles.s.unitNo));

% --- Executes on button press in ShowSummary.
function ShowSummary_Callback(hObject, eventdata, handles)
% hObject    handle to ShowSummary (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowSummary
state = get(hObject, 'Value');
toggleSummaryVisibility(handles, state);


% --- Helper to toggle visibility of summary panel
function toggleSummaryVisibility(handles, state)
figurePos = get(handles.figure1, 'Position');
summaryPos = get(handles.SummaryPanel, 'Position');
panelPos(1,:) = get(handles.SettingsPanel, 'Position');
panelPos(2,:) = get(handles.RecalculatePanel, 'Position');
panelPos(3,:) = get(handles.SummaryControlPanel, 'Position');
if state
    set(handles.SummaryPanel, 'Visible', 'on');
    figurePos(4) = figurePos(4) + summaryPos(4);
    figurePos(2) = figurePos(2) - summaryPos(4);
    panelPos(:,2) = panelPos(:,2) + summaryPos(4);
else
    set(handles.SummaryPanel, 'Visible', 'off');
    figurePos(4) = figurePos(4) - summaryPos(4);
    figurePos(2) = figurePos(2) + summaryPos(4);
    panelPos(:,2) = panelPos(:,2) - summaryPos(4);
end
set(handles.figure1, 'Position', figurePos);
set(handles.SettingsPanel, 'Position', panelPos(1,:));
set(handles.RecalculatePanel, 'Position', panelPos(2,:));
set(handles.SummaryControlPanel, 'Position', panelPos(3,:));



% --- Loads preferences.
function loadPrefs(handles)
global uiPrefsList
for i = 1:length(uiPrefsList)
    prfname = uiPrefsList{i};
    if ispref('data_analysis_toolbox',prfname) %pref exists
        if isfield(handles, prfname) %ui widget exists
            myhandle = handles.(prfname);
            prf = getpref('data_analysis_toolbox',prfname);
            uiType = get(myhandle,'Style');
            switch uiType
                case 'edit'
                    if ischar(prf)
                        set(myhandle, 'String', prf);
                    else
                        set(myhandle, 'String', num2str(prf));
                    end
                case 'checkbox'
                    if islogical(prf) || isnumeric(prf)
                        set(myhandle, 'Value', prf);
                    end
                case 'popupmenu'
                    str = get(myhandle,'String');
                    if isnumeric(prf) && prf <= length(str)
                        set(myhandle, 'Value', prf);
                    end
            end
        end
    end
end
drawnow

% --- Stores preferences.
function savePrefs(handles)
global uiPrefsList
for i = 1:length(uiPrefsList)
    prfname = uiPrefsList{i};
    myhandle = handles.(prfname);
    uiType = get(myhandle,'Style');
    switch uiType
        case 'edit'
            prf = get(myhandle, 'String');
            setpref('data_analysis_toolbox', prfname, prf);
        case 'checkbox'
            prf = get(myhandle, 'Value');
            if ~islogical(prf); prf=logical(prf);end
            setpref('data_analysis_toolbox', prfname, prf);
        case 'popupmenu'
            prf = get(myhandle, 'Value');
            setpref('data_analysis_toolbox', prfname, prf);
    end
end



% --- Executes on button press in PlotRastersCheck.
function PlotRastersCheck_Callback(hObject, eventdata, handles)
% hObject    handle to PlotRastersCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotRastersCheck


% --- Executes on button press in PlotLFPCheck.
function PlotLFPCheck_Callback(hObject, eventdata, handles)
% hObject    handle to PlotLFPCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotLFPCheck


% --- Executes on button press in PlotWaveformsCheck.
function PlotWaveformsCheck_Callback(hObject, eventdata, handles)
% hObject    handle to PlotWaveformsCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotWaveformsCheck


% --- Executes on button press in ShowFiguresCheck.
function ShowFiguresCheck_Callback(hObject, eventdata, handles)
% hObject    handle to ShowFiguresCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowFiguresCheck


% --- Executes on selection change in ExpTypeMenu.
function ExpTypeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ExpTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExpTypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExpTypeMenu


% --- Executes during object creation, after setting all properties.
function ExpTypeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExpTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AnimalIDBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnimalIDBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AnimalIDBox as text
%        str2double(get(hObject,'String')) returns contents of AnimalIDBox as a double


% --- Executes during object creation, after setting all properties.
function AnimalIDBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AnimalIDBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function UnitNoBox_Callback(hObject, eventdata, handles)
% hObject    handle to UnitNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of UnitNoBox as text
%        str2double(get(hObject,'String')) returns contents of UnitNoBox as a double


% --- Executes during object creation, after setting all properties.
function UnitNoBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UnitNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FileNoBox_Callback(hObject, eventdata, handles)
% hObject    handle to FileNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FileNoBox as text
%        str2double(get(hObject,'String')) returns contents of FileNoBox as a double


% --- Executes during object creation, after setting all properties.
function FileNoBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function DataDirBox_Callback(hObject, eventdata, handles)
% hObject    handle to DataDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DataDirBox as text
%        str2double(get(hObject,'String')) returns contents of DataDirBox as a double


% --- Executes during object creation, after setting all properties.
function DataDirBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DataDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FiguresDirBox_Callback(hObject, eventdata, handles)
% hObject    handle to FiguresDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FiguresDirBox as text
%        str2double(get(hObject,'String')) returns contents of FiguresDirBox as a double


% --- Executes during object creation, after setting all properties.
function FiguresDirBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FiguresDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SummaryFigsCheck.
function SummaryFigsCheck_Callback(hObject, eventdata, handles)
% hObject    handle to SummaryFigsCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SummaryFigsCheck



function ElectrodeNoBox_Callback(hObject, eventdata, handles)
% hObject    handle to ElectrodeNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ElectrodeNoBox as text
%        str2double(get(hObject,'String')) returns contents of ElectrodeNoBox as a double


% --- Executes during object creation, after setting all properties.
function ElectrodeNoBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ElectrodeNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CaseNotes_Callback(hObject, eventdata, handles)
% hObject    handle to CaseNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CaseNotes as text
%        str2double(get(hObject,'String')) returns contents of CaseNotes as a double


% --- Executes during object creation, after setting all properties.
function CaseNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CaseNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
