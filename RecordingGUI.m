function varargout = RecordingGUI(varargin)
% RECORDINGGUI MATLAB code for RecordingGUI.fig
%      RECORDINGGUI, by itself, creates a new RECORDINGGUI or raises the existing
%      singleton*.
%
%      H = RECORDINGGUI returns the handle to a new RECORDINGGUI or the handle to
%      the existing singleton*.
%
%      RECORDINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECORDINGGUI.M with the given input arguments.
%
%      RECORDINGGUI('Property','Value',...) creates a new RECORDINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RecordingGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RecordingGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RecordingGUI

% Last Modified by GUIDE v2.5 06-Apr-2017 15:23:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RecordingGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RecordingGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
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


% --- Executes just before RecordingGUI is made visible.
function RecordingGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RecordingGUI (see VARARGIN)

% Choose default command line output for RecordingGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RecordingGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RecordingGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in StopListenButton.
function StopListenButton_Callback(hObject, eventdata, handles)
% hObject    handle to StopListenButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in StartListenButton.
function StartListenButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartListenButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in StartHeartrateButton.
function StartHeartrateButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartHeartrateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in RecalculateButton.
function RecalculateButton_Callback(hObject, eventdata, handles)
% hObject    handle to RecalculateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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



function AnimalIDBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnimalIDBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AnimalIDBox as text
%        str2double(get(hObject,'String')) returns contents of AnimalIDBox as a double

function UnitNoBox_Callback(hObject, eventdata, handles)
% hObject    handle to UnitNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of UnitNoBox as text
%        str2double(get(hObject,'String')) returns contents of UnitNoBox as a double

function FileNoBox_Callback(hObject, eventdata, handles)
% hObject    handle to FileNoBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FileNoBox as text
%        str2double(get(hObject,'String')) returns contents of FileNoBox as a double
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
