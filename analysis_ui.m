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

% Last Modified by GUIDE v2.5 25-Jun-2018 16:10:52

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

% UIWAIT makes analysis_ui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Load preferences
global uiPrefsList
uiPrefsList = {'ParallelCheck', 'DataDirBox', 'FiguresDirBox', ...
    'SortingDirBox', 'SuffixBox', 'SourceFormatMenu', 'RawDataBox', ...
    'ActionList'};
loadPrefs(handles);

% Set the title
set(hObject, 'Name', 'analysis UI')

% Hide the sorting buttons
SourceFormatMenu_Callback(hObject, eventdata, handles)

% Set up the plot function list
handles.plots = [1];

% Update handles structure
guidata(hObject, handles);

% Populate file table
RefreshButton_Callback(hObject, eventdata, handles);


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

% Save Preferences
savePrefs(handles);

% Close the figure
delete(hObject);


function SearchStringBox_Callback(hObject, eventdata, handles)
% hObject    handle to SearchStringBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SearchStringBox as text
%        str2double(get(hObject,'String')) returns contents of SearchStringBox as a double
strs = regexp(get(handles.SearchStringBox, 'String'),'\s?,\s?', 'split');
mt = handles.mt;
set(handles.FileList, 'Value', []);
if isempty(mt.Tests)
    return;
elseif mod(length(strs),2) == 0
    query = mt.query(strs{:});
    set(handles.FileList, 'String', {query.Tests.filename} );
    set(handles.FileList, 'UserData', query.Tests);
elseif length(strs) == 1
    files = {mt.Tests.filename};
    match = cellfun(@(x)contains(x,strs{1},'IgnoreCase',true),files);
    set(handles.FileList, 'String', files(match));
    set(handles.FileList, 'UserData', mt.Tests(match));
else
    set(handles.FileList, 'String', {mt.Tests.filename});
    set(handles.FileList, 'UserData', mt.Tests);
end


% --- Executes on button press in SelectNone.
function SelectNone_Callback(hObject, eventdata, handles)
% hObject    handle to SelectNone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.FileList, 'Value', []);


% --- Executes on button press in SelectAll.
function SelectAll_Callback(hObject, eventdata, handles)
% hObject    handle to SelectAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
files = get(handles.FileList, 'String');
set(handles.FileList, 'Value', 1:length(files));


% --- Executes on button press in RefreshButton.
function RefreshButton_Callback(hObject, eventdata, handles)
% hObject    handle to RefreshButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
metafile = fullfile(get(handles.DataDirBox, 'String'),'metadata.mat');
mt = NeuroAnalysis.IO.MetaTable(metafile);
if ~isempty(mt.Tests)
    mt = mt.query('sourceformat', 'Ripple');
end
handles.mt = mt;
SearchStringBox_Callback(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in MakeSortFile.
function MakeSortFile_Callback(hObject, eventdata, handles)
% hObject    handle to MakeSortFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));
sortingDir = get(handles.SortingDirBox, 'String');
sourceFormatMenu = cellstr(get(handles.SourceFormatMenu, 'String'));
sourceFormat = sourceFormatMenu{get(handles.SourceFormatMenu, 'Value')};
switch sourceFormat
    case 'Plexon'
        dataDir = get(handles.RawDataBox, 'String');
        setStatus(handles, 'generating files...');
        makeFilesForSortingOld(dataDir, sortingDir, animalID, unitNo, 'bin');
        setStatus(handles, '');
    otherwise
        setStatus(handles, ['no sorting method for ', sourceFormat]);
        return;
end

% --- Executes on button press in DoneSorting.
function DoneSorting_Callback(hObject, eventdata, handles)
% hObject    handle to DoneSorting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));
dataDir = get(handles.DataDirBox, 'String');
sortingDir = get(handles.SortingDirBox, 'String');
suffix = get(handles.SuffixBox, 'String');

setStatus(handles, 'converting sorted files...');
convertPlexonSpikes(sortingDir, dataDir, animalID, unitNo, suffix);
setStatus(handles, '');


% --- Executes on button press in DoneSorting.
function AutomaticSorting_Callback(hObject, eventdata, handles)
% hObject    handle to DoneSorting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
animalID = get(handles.AnimalIDBox, 'String');
unitNo = eval(get(handles.UnitNoBox, 'String'));
fileNo = eval(get(handles.FileNoBox, 'String'));
searchString = get(handles.SearchStringBox, 'String'); % TODO

dataDir = get(handles.DataDirBox, 'String');
sortingDir = get(handles.SortingDirBox, 'String');
sourceFormatMenu = cellstr(get(handles.SourceFormatMenu, 'String'));
sourceFormat = sourceFormatMenu{get(handles.SourceFormatMenu, 'Value')};
switch sourceFormat
    case 'WaveClus'
        if isempty(fileNo)
            setStatus(handles, 'generating files...');
            makeFilesForSorting(dataDir, sortingDir, animalID, unitNo, 'spikes');

            setStatus(handles, 'sorting...');
            sortWithWaveclus(sortingDir, animalID, unitNo);

            setStatus(handles, 'splitting files...');
            convertWavSpikes(dataDir, sortingDir, animalID, unitNo);
            setStatus(handles, '');
        else
            setStatus(handles, 'sorting...');
            sortWaveclusSingle(dataDir, sortingDir, animalID, unitNo, fileNo);
            setStatus(handles, '');
        end
    otherwise
        setStatus(handles, ['no sorting method for ', sourceFormat]);
        return;
end


% --- Executes on button press in LoadDatasets.
function LoadDatasets_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDatasets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tests = get(handles.FileList, 'UserData');
selected = get(handles.FileList, 'Value');
tests = tests(selected);
files = arrayfun(@(x)x.files{1}, tests, 'UniformOutput', 0);

sourceFormatMenu = cellstr(get(handles.SourceFormatMenu, 'String'));
sourceFormat = sourceFormatMenu{get(handles.SourceFormatMenu, 'Value')};
dataDir = get(handles.DataDirBox, 'String');

datasets = cell(1,length(files));
for f = 1:length(files)
    filepath = fullfile(dataDir, files{f});
    datasets{f} = loadDataset(filepath, sourceFormat);   
end
assignin('base','datasets',datasets);
pause(0.1);

% --- Executes on button press in LoadFilenames.
function LoadFilenames_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFilenames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tests = get(handles.FileList, 'UserData');
selected = get(handles.FileList, 'Value');
tests = tests(selected);
dataDir = get(handles.DataDirBox, 'String');
files = arrayfun(@(x)fullfile(dataDir, x.files{1}), tests, 'UniformOutput', 0);
assignin('base','files',files);
pause(0.1);

% --- Executes on button press in AddAction.
function AddAction_Callback(hObject, eventdata, handles)
% hObject    handle to AddAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
actionsList = get(handles.ActionList, 'String');
actions = get(handles.AddActionBox, 'String');
actionsList{end + 1} = actions;
set(handles.ActionList, 'String', actionsList);

% --- Executes on button press in DelAction.
function DelAction_Callback(hObject, eventdata, handles)
% hObject    handle to DelAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
actionsList = get(handles.ActionList, 'String');
actions = actionsList(get(handles.ActionList, 'Value'));
actionsList = setdiff(actionsList, actions);
set(handles.ActionList, 'String', actionsList);
set(handles.ActionList, 'Value', []);

% --- Executes on button press in PlotFigures.
function PlotFigures_Callback(hObject, eventdata, handles)
% hObject    handle to PlotFigures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tests = get(handles.FileList, 'UserData');
selected = get(handles.FileList, 'Value');
tests = tests(selected);
files = arrayfun(@(x)x.files{1}, tests, 'UniformOutput', 0);
dataDir = get(handles.DataDirBox, 'String');
files = cellfun(@(x)fullfile(dataDir, x(3:end)), files, 'UniformOutput', 0);

figuresPath = get(handles.FiguresDirBox, 'String');
sourceFormatMenu = cellstr(get(handles.SourceFormatMenu, 'String'));
sourceFormat = sourceFormatMenu{get(handles.SourceFormatMenu, 'Value')};
isParallel = logical(get(handles.ParallelCheck, 'Value'));

actionList = get(handles.ActionList, 'String');
actions = actionList(get(handles.ActionList, 'Value'));
actions = actions(~cellfun(@isempty, actions));
args = strsplit(handles.Args.String, {', '}, 'CollapseDelimiters', true);
args = args(1:floor(length(args)/2)*2); % only allow name-value pairs
for i = 1:length(args)
    try
        args{i} = eval(args{i});
        fprintf('arg %d: %s', i, evalc('disp(args{i})'));
    catch
    end
end

setStatus(handles, 'plotting...');
% mt = NeuroAnalysis.IO.MetaTable('temp');
results = batch_process(files, figuresPath, [], isParallel, ...
    sourceFormat, actions, true, args{:});
assignin('base','results',results);
%assignin('base','mt',mt);
pause(0.2);

setStatus(handles, '');

% --- Executes on selection change in SourceFormatMenu.
function SourceFormatMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SourceFormatMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SourceFormatMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SourceFormatMenu
contents = cellstr(get(handles.SourceFormatMenu,'String'));
sourceFormat = contents{get(handles.SourceFormatMenu,'Value')};

switch sourceFormat
    case 'Ripple'
        set(handles.MakeSortFile, 'Visible', 'off');
        set(handles.DoneSorting, 'Visible', 'off');
    case 'Plexon'
        set(handles.MakeSortFile, 'String', 'Make bin file');
        set(handles.MakeSortFile, 'Callback', ...
            @(hObject,eventdata)analysis_ui('MakeSortFile_Callback',...
            hObject,eventdata,guidata(hObject)));
        set(handles.DoneSorting, 'String', 'Done Sorting');
        set(handles.DoneSorting, 'Callback', ...
            @(hObject,eventdata)analysis_ui('DoneSorting_Callback',...
            hObject,eventdata,guidata(hObject)));
        set(handles.MakeSortFile, 'Visible', 'on');
        set(handles.DoneSorting, 'Visible', 'on');
    case 'WaveClus'
        set(handles.DoneSorting, 'String', 'Do Sorting');
        set(handles.DoneSorting, 'Callback', ...
            @(hObject,eventdata)analysis_ui('AutomaticSorting_Callback',...
            hObject,eventdata,guidata(hObject)));
        set(handles.MakeSortFile, 'Visible', 'off');
        set(handles.DoneSorting, 'Visible', 'on');
    otherwise
        set(handles.MakeSortFile, 'Visible', 'off');
        set(handles.DoneSorting, 'Visible', 'off');
end

% --- Sets the title with a status indication
function setStatus(handles, text)
if isempty(text)
    set(handles.figure1, 'Name', 'analysis UI');
else
    set(handles.figure1, 'Name', ['analysis UI - ', text]);
end
drawnow;

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
                case 'listbox'
                    if iscellstr(prf) || ischar(prf)
                        set(myhandle, 'String', prf);
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
        case 'listbox'
            prf = get(myhandle, 'String');
            setpref('data_analysis_toolbox', prfname, prf);
    end
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


% --- Executes on button press in ParallelCheck.
function ParallelCheck_Callback(hObject, eventdata, handles)
% hObject    handle to ParallelCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ParallelCheck


% --- Executes during object creation, after setting all properties.
function SearchStringBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SearchStringBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function SortingDirBox_Callback(hObject, eventdata, handles)
% hObject    handle to SortingDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SortingDirBox as text
%        str2double(get(hObject,'String')) returns contents of SortingDirBox as a double


% --- Executes during object creation, after setting all properties.
function SortingDirBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SortingDirBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function SuffixBox_Callback(hObject, eventdata, handles)
% hObject    handle to SuffixBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SuffixBox as text
%        str2double(get(hObject,'String')) returns contents of SuffixBox as a double


% --- Executes during object creation, after setting all properties.
function SuffixBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SuffixBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function RawDataBox_Callback(hObject, eventdata, handles)
% hObject    handle to RawDataBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RawDataBox as text
%        str2double(get(hObject,'String')) returns contents of RawDataBox as a double


% --- Executes during object creation, after setting all properties.
function RawDataBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RawDataBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function SourceFormatMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SourceFormatMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FileList.
function FileList_Callback(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FileList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FileList


% --- Executes during object creation, after setting all properties.
function FileList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function ActionList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ActionList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function AddActionBox_Callback(hObject, eventdata, handles)
% hObject    handle to AddActionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AddActionBox as text
%        str2double(get(hObject,'String')) returns contents of AddActionBox as a double


% --- Executes during object creation, after setting all properties.
function AddActionBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AddActionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Args_Callback(hObject, eventdata, handles)
% hObject    handle to Args (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Args as text
%        str2double(get(hObject,'String')) returns contents of Args as a double


% --- Executes during object creation, after setting all properties.
function Args_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Args (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
