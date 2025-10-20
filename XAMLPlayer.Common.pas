{
MIT No Attribution

Copyright 2025 Mykola Petrivskyi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

unit XAMLPlayer.Common;

interface

uses
  Winapi.Windows, WinAPI.CommonTypes, Winapi.UI.Xaml, Winapi.UI.Xaml.ControlsRT, Winapi.Media, Winapi.WinRT;

type
  TPlayerState = (psPlaying, psPaused, psStopped);
  TPlayerStateEvent = procedure (Sender: TObject; State: TPlayerState) of object;
  THandler = procedure of object;
  TVideoStretch = (vsOriginal, vsFill, vsFit, vsFullFit);
  TErrorType = (etUnknown, etAborted, etNetworkError, etDecodingError, etSourceNotSupported);
  TErrorHandler = procedure (AType: TErrorType; const AMesage: String) of object;
  TPlayerErrorEvent = procedure (Sender: TObject; ErrorType: TErrorType; const ErrorMesage: String) of object;
  TPlayerPositionRequest = procedure(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer) of object;

  TXAMLEngine = class
  private
    class var FHostingEngine: Hosting_IWindowsXamlManager;
    class var FInitialized: Boolean;
    class constructor Create;
    class destructor Destroy;
  public
    class property Initialized: Boolean read FInitialized;
  end;

  TXAMLPlayerEventHolder = class(TNoRefCountObject, TypedEventHandler_2__Playback_IMediaPlayer__IInspectable,
      TypedEventHandler_2__Playback_IMediaPlayer__IInspectable_Delegate_Base)
    FHandler: THandler;
    procedure Invoke(sender: Playback_IMediaPlayer; args: IInspectable); safecall;
  public
    Token: EventRegistrationToken;
    constructor Create(AHandler: THandler);
  end;

  TXAMLPlayerErrorEventHolder = class(TNoRefCountObject,
      TypedEventHandler_2__Playback_IMediaPlayer__Playback_IMediaPlayerFailedEventArgs,
      TypedEventHandler_2__Playback_IMediaPlayer__Playback_IMediaPlayerFailedEventArgs_Delegate_Base)
    FHandler: TErrorHandler;
    procedure Invoke(sender: Playback_IMediaPlayer; args: Playback_IMediaPlayerFailedEventArgs); safecall;
  public
    Token: EventRegistrationToken;
    constructor Create(AHandler: TErrorHandler);
  end;

  TXAMLPlayerIsland = class(TXAMLEngine)
  private
    FControlsVisible: Boolean;
    FErrorEvent: TPlayerErrorEvent;
    FFileName: string;
    FIsMuted: Boolean;
    FLoopPlayback: Boolean;
    FPositionRequest: TPlayerPositionRequest;
    FStateEvent: TPlayerStateEvent;
    FStretch: TVideoStretch;
    FPlayList: Playback_IMediaPlaybackList;
    FInterop: IDesktopWindowXamlSourceNative;
    FHostHandle: HWND;
    FMediaPlayer: Playback_IMediaPlayer;
    FMPElement: IMediaPlayerElement;
    FStateEventHolder: TXAMLPlayerEventHolder;
    FEndedEventHolder: TXAMLPlayerEventHolder;
    FErrorEventHolder: TXAMLPlayerErrorEventHolder;
    function GetControlsVisible: Boolean;
    function GetIsMuted: Boolean;
    function GetLoopPlayback: Boolean;
    function GetPlaybackPosition: TTime;
    function GetStretch: TVideoStretch;
    procedure SetControlsVisible(const Value: Boolean);
    procedure SetFileName(const Value: string);
    procedure SetIsMuted(const Value: Boolean);
    procedure SetLoopPlayback(const Value: Boolean);
    procedure SetPlaybackPosition(const Value: TTime);
    procedure SetStretch(const Value: TVideoStretch);
  protected
    procedure DoStateChange(AState: TPlayerState);
    procedure EndFileHandler;
    procedure ErrorHandler(AType: TErrorType; const AMesage: String);
    procedure StateChangeHandler;
  public
    constructor Create(APositionGetter: TPlayerPositionRequest);
    destructor Destroy; override;
    function GetCurrentMedia_Duration: TTime;
    function GetCurrentMedia_NumInPlaylist: Integer;
    function GetCurrentMedia_Title: String;
    function GetPlayListSize: Integer;
    function IsPaused: Boolean;
    function IsPlaying: Boolean;
    procedure Next;
    procedure Pause;
    procedure Play;
    procedure PlayDirectory(ADirectory: String; AFileMask: String = '*.mp4');
    procedure Previous;
    procedure Stop;
    procedure UpdateParentHandle(AParent, ATopParent: HWND);
    procedure UpdateVisibility;
    property PlaybackPosition: TTime read GetPlaybackPosition write SetPlaybackPosition;
  published
    property ControlsVisible: Boolean read GetControlsVisible write SetControlsVisible default False;
    property FileName: string read FFileName write SetFileName;
    property IsMuted: Boolean read GetIsMuted write SetIsMuted default False;
    property LoopPlayback: Boolean read GetLoopPlayback write SetLoopPlayback default False;
    property Stretch: TVideoStretch read GetStretch write SetStretch default vsFit;
    property OnError: TPlayerErrorEvent read FErrorEvent write FErrorEvent;
    property OnStateChange: TPlayerStateEvent read FStateEvent write FStateEvent;
  end;

resourcestring
  SManifestWarning = 'Application manifest does not contain "maxversiontested" element!';

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils, System.Win.ComObj, System.Win.WinRT, WinAPI.Foundation,
  Winapi.UI.Xaml.Media;

const
  SEngineWindowClass = 'Windows.UI.Core.CoreWindow';
  SEngineWindowName = 'DesktopWindowXamlSource';

{ TXAMLEngine }

class constructor TXAMLEngine.Create;
begin
  if TOSVersion.Check(10) and (TOSVersion.Build >= 18362) then
  begin
    try
      FHostingEngine := THosting_WindowsXamlManager.InitializeForCurrentThread;
      FInitialized := True;
    except
      on e: EOleException do
        FInitialized := False;
    end;
  end
  else
    FInitialized := False;
end;

class destructor TXAMLEngine.Destroy;
begin
  FHostingEngine := nil;
end;

{ TXAMLPlayerEventHolder }

constructor TXAMLPlayerEventHolder.Create(AHandler: THandler);
begin
  FHandler := AHandler;
end;

procedure TXAMLPlayerEventHolder.Invoke(sender: Playback_IMediaPlayer; args: IInspectable);
begin
  FHandler;
end;

{ TXAMLPlayerErrorEventHolder }

constructor TXAMLPlayerErrorEventHolder.Create(AHandler: TErrorHandler);
begin
  FHandler := AHandler;
end;

procedure TXAMLPlayerErrorEventHolder.Invoke(sender: Playback_IMediaPlayer;
  args: Playback_IMediaPlayerFailedEventArgs);
const
  ConvertType: array [Playback_MediaPlayerError] of TErrorType = (etUnknown, etAborted, etNetworkError, etDecodingError,
    etSourceNotSupported);
var
  Msg: String;
begin
  Msg := TWindowsString.HStringToString(args.ErrorMessage);
  if Msg = '' then
    Msg := SysErrorMessage(Cardinal(args.ExtendedErrorCode));
  FHandler(ConvertType[args.Error], Msg);
end;

{ TXAMLPlayerIsland }

constructor TXAMLPlayerIsland.Create(APositionGetter: TPlayerPositionRequest);
begin
  FStretch := vsFit;
  FPositionRequest := APositionGetter;

  if FInitialized then
  begin
    FMPElement := TMediaPlayerElement.Create;
    FMediaPlayer := TPlayback_MediaPlayer.Create;
    FMPElement.SetMediaPlayer(FMediaPlayer);
    FPlayList := TPlayback_MediaPlaybackList.Create;

    FStateEventHolder := TXAMLPlayerEventHolder.Create(StateChangeHandler);
    FStateEventHolder.Token := FMediaPlayer.add_CurrentStateChanged(FStateEventHolder);
    FEndedEventHolder := TXAMLPlayerEventHolder.Create(EndFileHandler);
    FEndedEventHolder.Token := FMediaPlayer.add_MediaEnded(FEndedEventHolder);
    FErrorEventHolder := TXAMLPlayerErrorEventHolder.Create(ErrorHandler);
    FErrorEventHolder.Token := FMediaPlayer.add_MediaFailed(FErrorEventHolder);
  end;
end;

destructor TXAMLPlayerIsland.Destroy;
begin
  Stop;

  if FInitialized then
  begin
    FMediaPlayer.remove_CurrentStateChanged(FStateEventHolder.Token);
    FStateEventHolder.Free;
    FMediaPlayer.remove_MediaEnded(FEndedEventHolder.Token);
    FEndedEventHolder.Free;
    FMediaPlayer.remove_MediaFailed(FErrorEventHolder.Token);
    FErrorEventHolder.Free;
  end;

  FPlayList := nil;
  FMediaPlayer := nil;
  FMPElement := nil;
  FHostHandle := 0;
  if Assigned(FInterop) then
    (FInterop as IClosable).Close;
  FInterop := nil;

  inherited;
end;

procedure TXAMLPlayerIsland.DoStateChange(AState: TPlayerState);
begin
  if Assigned(FStateEvent) then
    FStateEvent(Self, AState);
end;

procedure TXAMLPlayerIsland.EndFileHandler;
begin
  DoStateChange(psStopped);
end;

procedure TXAMLPlayerIsland.ErrorHandler(AType: TErrorType; const AMesage: String);
begin
  if Assigned(FErrorEvent) then
    FErrorEvent(Self, AType, AMesage);
end;

function TXAMLPlayerIsland.GetControlsVisible: Boolean;
begin
  if FInitialized then
    Result := FMPElement.AreTransportControlsEnabled
  else
    Result := FControlsVisible;
end;

function TXAMLPlayerIsland.GetCurrentMedia_Duration: TTime;
begin
  if FInitialized then
    Result := FMediaPlayer.NaturalDuration.Duration / 10000 / MSecsPerDay
  else
    Result := 0;
end;

function TXAMLPlayerIsland.GetCurrentMedia_NumInPlaylist: Integer;
begin
  if FInitialized and (FPlayList.CurrentItemIndex < MaxInt) then
    Result := FPlayList.CurrentItemIndex + 1
  else
    Result := 0;
end;

function TXAMLPlayerIsland.GetCurrentMedia_Title: String;
begin
  if not FInitialized then
    Exit('');

  if not Assigned(FPlayList.CurrentItem) then
    Exit(TPath.GetFileNameWithoutExtension(TWindowsString.HStringToString(
      (FMPElement.Source as Core_IMediaSource4).Uri.Path)));

  Result := TWindowsString.HStringToString(
    (FPlayList.CurrentItem as Playback_IMediaPlaybackItem2).GetDisplayProperties.MusicProperties.Title);
  if Result = '' then
    Result := TWindowsString.HStringToString(
      (FPlayList.CurrentItem as Playback_IMediaPlaybackItem2).GetDisplayProperties.VideoProperties.Title);
  if Result = '' then
    Result := TPath.GetFileNameWithoutExtension(TWindowsString.HStringToString(
      (FPlayList.CurrentItem.Source as Core_IMediaSource4).Uri.Path));
end;

function TXAMLPlayerIsland.GetIsMuted: Boolean;
begin
  if FInitialized then
    Result := FMediaPlayer.IsMuted
  else
    Result := FIsMuted;
end;

function TXAMLPlayerIsland.GetLoopPlayback: Boolean;
begin
  if FInitialized then
    Result := FMediaPlayer.IsLoopingEnabled
  else
    Result := FLoopPlayback;
end;

function TXAMLPlayerIsland.GetPlaybackPosition: TTime;
begin
  if FInitialized then
    Result := FMediaPlayer.Position.Duration / 10000 / MSecsPerDay
  else
    Result := 0;
end;

function TXAMLPlayerIsland.GetPlayListSize: Integer;
begin
  if FInitialized then
    Result := (FPlayList.Items as IVector_1__Playback_IMediaPlaybackItem_Base).Size
  else
    Result := 0;
end;

function TXAMLPlayerIsland.GetStretch: TVideoStretch;
const
  MPElementToFacade: array[Winapi.UI.Xaml.Media.Stretch] of TVideoStretch = (vsOriginal, vsFill, vsFit, vsFullFit);
begin
  if FInitialized then
    Result := MPElementToFacade[FMPElement.Stretch_]
  else
    Result := FStretch;
end;

function TXAMLPlayerIsland.IsPaused: Boolean;
begin
  if FInitialized then
    Result := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Paused
  else
    Result := True;
end;

function TXAMLPlayerIsland.IsPlaying: Boolean;
begin
  if FInitialized then
    Result := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Playing
  else
    Result := False;
end;

procedure TXAMLPlayerIsland.Next;
begin
  if FInitialized and (GetPlayListSize > 0) then
    FPlayList.MoveNext;
end;

procedure TXAMLPlayerIsland.Pause;
begin
  if FInitialized then
    FMediaPlayer.Pause;
end;

procedure TXAMLPlayerIsland.Play;
begin
  if FInitialized then
    FMediaPlayer.Play;
end;

procedure TXAMLPlayerIsland.PlayDirectory(ADirectory, AFileMask: String);
begin
  FFileName := ADirectory + AFileMask;

  if FInitialized then
  begin
    for var FileName in TDirectory.GetFiles(ADirectory, AFileMask) do
    begin
      var Uri: IUriRuntimeClass := TUri.CreateUri(TWindowsString.Create(FileName));
      var Item: Playback_IMediaPlaybackItem := TPlayback_MediaPlaybackItem.Create(TCore_MediaSource.CreateFromUri(Uri));
      (FPlayList.Items as IVector_1__Playback_IMediaPlaybackItem_Base).Append(Item);
    end;

    FMPElement.Source := FPlayList as Playback_IMediaPlaybackSource;
    Play;
  end;
end;

procedure TXAMLPlayerIsland.Previous;
begin
  if FInitialized and (GetPlayListSize > 0) then
    FPlayList.MovePrevious;
end;

procedure TXAMLPlayerIsland.SetControlsVisible(const Value: Boolean);
begin
  if FInitialized then
    FMPElement.AreTransportControlsEnabled := Value
  else
    FControlsVisible := Value;
end;

procedure TXAMLPlayerIsland.SetFileName(const Value: string);
begin
  FFileName := Value;

  if FInitialized then
  begin
    FMPElement.Source := (TCore_MediaSource.CreateFromUri(TUri.CreateUri(TWindowsString.Create(Value))) as
      Playback_IMediaPlaybackSource);
    Play;
  end;
end;

procedure TXAMLPlayerIsland.SetIsMuted(const Value: Boolean);
begin
  if FInitialized then
    FMediaPlayer.IsMuted := Value
  else
    FIsMuted := Value;
end;

procedure TXAMLPlayerIsland.SetLoopPlayback(const Value: Boolean);
begin
  if FInitialized then
    FMediaPlayer.IsLoopingEnabled := Value
  else
    FLoopPlayback := Value;
end;

procedure TXAMLPlayerIsland.SetPlaybackPosition(const Value: TTime);
var
  TS: TimeSpan;
begin
  if FInitialized then
  begin
    TS.Duration := TimeToMilliseconds(Value) * 10000;
    FMediaPlayer.Position := TS;
  end;
end;

procedure TXAMLPlayerIsland.SetStretch(const Value: TVideoStretch);
const
  FacadeToMPElement: array[TVideoStretch] of Winapi.UI.Xaml.Media.Stretch = (Winapi.UI.Xaml.Media.Stretch.None,
    Winapi.UI.Xaml.Media.Stretch.Fill, Winapi.UI.Xaml.Media.Stretch.Uniform, Winapi.UI.Xaml.Media.Stretch.UniformToFill);
begin
  if FInitialized then
    FMPElement.Stretch_ := FacadeToMPElement[Value]
  else
    FStretch := Value;
end;

procedure TXAMLPlayerIsland.StateChangeHandler;
begin
  case FMediaPlayer.CurrentState of
    Playback_MediaPlayerState.Playing: DoStateChange(psPlaying);
    Playback_MediaPlayerState.Paused: DoStateChange(psPaused);
    Playback_MediaPlayerState.Stopped, Playback_MediaPlayerState.Closed: DoStateChange(psStopped);
  end;
end;

procedure TXAMLPlayerIsland.Stop;
begin
  if FInitialized then
  begin
    FMediaPlayer.SetUriSource(nil);
    DoStateChange(psStopped);
  end;
end;

procedure TXAMLPlayerIsland.UpdateParentHandle(AParent, ATopParent: HWND);

  procedure ProtectEngineWindow;
  var
    EW: HWND;
  begin
    if ATopParent <> 0 then
    begin
      EW := FindWindowEx(ATopParent, 0, SEngineWindowClass, SEngineWindowName);
      if EW <> 0 then
        Winapi.Windows.SetParent(EW, GetDesktopWindow);
    end;
  end;

begin
  if Assigned(FInterop) then
  begin
    FHostHandle := 0;
    if Assigned(FInterop) then
      (FInterop as IClosable).Close;
    FInterop := nil;
  end;

  if Initialized and (AParent <> 0) then
  begin
    FInterop := THosting_DesktopWindowXamlSource.Create as IDesktopWindowXamlSourceNative;
    FInterop.AttachToWindow(AParent);
    (FInterop as Hosting_IDesktopWindowXamlSource).Content := (FMPElement as IUIElement);
    FHostHandle := FInterop.get_WindowHandle;

    // After a call to FInterop.AttachToWindow, special engine window will become a child of the parent form window
    // When form handle needs to be recreated (type of border has changed, styles enabled, etc.) engine window will be
    // destroyed and XAML integration broken
    // It is possible to prevent this by turning engine window back into top-level window
    ProtectEngineWindow;

    UpdateVisibility;
  end;
end;

procedure TXAMLPlayerIsland.UpdateVisibility;
var
  Left, Top, Width, Height: Integer;
  Visible: Boolean;
begin
  if FInitialized and (FHostHandle > 0) then
  begin
    Visible := False;
    Left := 0;
    Top := 0;
    Width := 0;
    Height := 0;

    if Assigned(FPositionRequest) then
      FPositionRequest(Visible, Left, Top, Width, Height);

    if Visible then
      SetWindowPos(FHostHandle, 0, Left, Top, Width, Height, SWP_SHOWWINDOW + SWP_NOACTIVATE)
    else
      SetWindowPos(FHostHandle, 0, Left, Top, Width, Height, SWP_HIDEWINDOW + SWP_NOACTIVATE);
  end;
end;

end.
