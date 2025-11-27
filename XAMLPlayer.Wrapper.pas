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

unit XAMLPlayer.Wrapper;

interface

uses
  WinAPI.CommonTypes, Winapi.UI.Xaml.ControlsRT, Winapi.Media, Winapi.WinRT, XAMLPlayer.Engine;

type
  TPlayerState = (psPlaying, psPaused, psStopped);
  TPlayerStateEvent = procedure (Sender: TObject; State: TPlayerState) of object;
  THandler = procedure of object;
  TVideoStretch = (vsOriginal, vsFill, vsFit, vsFullFit);
  TErrorType = (etUnknown, etAborted, etNetworkError, etDecodingError, etSourceNotSupported);
  TErrorHandler = procedure (AType: TErrorType; const AMesage: String) of object;
  TPlayerErrorEvent = procedure (Sender: TObject; ErrorType: TErrorType; const ErrorMesage: String) of object;

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

  TXAMLPlayerWrapper = class(TXAMLEngine)
  private
    FControlsVisible: Boolean;
    FErrorEvent: TPlayerErrorEvent;
    FFileName: string;
    FIsMuted: Boolean;
    FLoopPlayback: Boolean;
    FStateEvent: TPlayerStateEvent;
    FStretch: TVideoStretch;
    FPlayList: Playback_IMediaPlaybackList;
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
    constructor Create(AIsland: TXAMLIsland);
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

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils, System.Win.WinRT, WinAPI.Foundation, Winapi.UI.Xaml.Media;

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

{ TXAMLPlayerWrapper }

constructor TXAMLPlayerWrapper.Create(AIsland: TXAMLIsland);
begin
  FStretch := vsFit;

  if Initialized then
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

    AIsland.Element := FMPElement as IUIElement;
  end;
end;

destructor TXAMLPlayerWrapper.Destroy;
begin
  Stop;

  if Initialized then
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

  inherited;
end;

procedure TXAMLPlayerWrapper.DoStateChange(AState: TPlayerState);
begin
  if Assigned(FStateEvent) then
    FStateEvent(Self, AState);
end;

procedure TXAMLPlayerWrapper.EndFileHandler;
begin
  DoStateChange(psStopped);
end;

procedure TXAMLPlayerWrapper.ErrorHandler(AType: TErrorType; const AMesage: String);
begin
  if Assigned(FErrorEvent) then
    FErrorEvent(Self, AType, AMesage);
end;

function TXAMLPlayerWrapper.GetControlsVisible: Boolean;
begin
  if Initialized then
    Result := FMPElement.AreTransportControlsEnabled
  else
    Result := FControlsVisible;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_Duration: TTime;
begin
  if Initialized then
    Result := FMediaPlayer.NaturalDuration.Duration / 10000 / MSecsPerDay
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_NumInPlaylist: Integer;
begin
  if Initialized and (FPlayList.CurrentItemIndex < MaxInt) then
    Result := FPlayList.CurrentItemIndex + 1
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_Title: String;
begin
  if not Initialized then
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

function TXAMLPlayerWrapper.GetIsMuted: Boolean;
begin
  if Initialized then
    Result := FMediaPlayer.IsMuted
  else
    Result := FIsMuted;
end;

function TXAMLPlayerWrapper.GetLoopPlayback: Boolean;
begin
  if Initialized then
    Result := FMediaPlayer.IsLoopingEnabled
  else
    Result := FLoopPlayback;
end;

function TXAMLPlayerWrapper.GetPlaybackPosition: TTime;
begin
  if Initialized then
    Result := FMediaPlayer.Position.Duration / 10000 / MSecsPerDay
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetPlayListSize: Integer;
begin
  if Initialized then
    Result := (FPlayList.Items as IVector_1__Playback_IMediaPlaybackItem_Base).Size
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetStretch: TVideoStretch;
const
  MPElementToFacade: array[Winapi.UI.Xaml.Media.Stretch] of TVideoStretch = (vsOriginal, vsFill, vsFit, vsFullFit);
begin
  if Initialized then
    Result := MPElementToFacade[FMPElement.Stretch_]
  else
    Result := FStretch;
end;

function TXAMLPlayerWrapper.IsPaused: Boolean;
begin
  if Initialized then
    Result := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Paused
  else
    Result := True;
end;

function TXAMLPlayerWrapper.IsPlaying: Boolean;
begin
  if Initialized then
    Result := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Playing
  else
    Result := False;
end;

procedure TXAMLPlayerWrapper.Next;
begin
  if Initialized and (GetPlayListSize > 0) then
    FPlayList.MoveNext;
end;

procedure TXAMLPlayerWrapper.Pause;
begin
  if Initialized then
    FMediaPlayer.Pause;
end;

procedure TXAMLPlayerWrapper.Play;
begin
  if Initialized then
    FMediaPlayer.Play;
end;

procedure TXAMLPlayerWrapper.PlayDirectory(ADirectory, AFileMask: String);
begin
  FFileName := ADirectory + AFileMask;

  if Initialized then
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

procedure TXAMLPlayerWrapper.Previous;
begin
  if Initialized and (GetPlayListSize > 0) then
    FPlayList.MovePrevious;
end;

procedure TXAMLPlayerWrapper.SetControlsVisible(const Value: Boolean);
begin
  if Initialized then
    FMPElement.AreTransportControlsEnabled := Value
  else
    FControlsVisible := Value;
end;

procedure TXAMLPlayerWrapper.SetFileName(const Value: string);
begin
  FFileName := TPath.GetFullPath(Value);

  if Initialized then
  begin
    FMPElement.Source := (TCore_MediaSource.CreateFromUri(TUri.CreateUri(TWindowsString.Create(FFileName))) as
      Playback_IMediaPlaybackSource);
    Play;
  end;
end;

procedure TXAMLPlayerWrapper.SetIsMuted(const Value: Boolean);
begin
  if Initialized then
    FMediaPlayer.IsMuted := Value
  else
    FIsMuted := Value;
end;

procedure TXAMLPlayerWrapper.SetLoopPlayback(const Value: Boolean);
begin
  if Initialized then
    FMediaPlayer.IsLoopingEnabled := Value
  else
    FLoopPlayback := Value;
end;

procedure TXAMLPlayerWrapper.SetPlaybackPosition(const Value: TTime);
var
  TS: TimeSpan;
begin
  if Initialized then
  begin
    TS.Duration := TimeToMilliseconds(Value) * 10000;
    FMediaPlayer.Position := TS;
  end;
end;

procedure TXAMLPlayerWrapper.SetStretch(const Value: TVideoStretch);
const
  FacadeToMPElement: array[TVideoStretch] of Winapi.UI.Xaml.Media.Stretch = (Winapi.UI.Xaml.Media.Stretch.None,
    Winapi.UI.Xaml.Media.Stretch.Fill, Winapi.UI.Xaml.Media.Stretch.Uniform, Winapi.UI.Xaml.Media.Stretch.UniformToFill);
begin
  if Initialized then
    FMPElement.Stretch_ := FacadeToMPElement[Value]
  else
    FStretch := Value;
end;

procedure TXAMLPlayerWrapper.StateChangeHandler;
begin
  case FMediaPlayer.CurrentState of
    Playback_MediaPlayerState.Playing: DoStateChange(psPlaying);
    Playback_MediaPlayerState.Paused: DoStateChange(psPaused);
    Playback_MediaPlayerState.Stopped, Playback_MediaPlayerState.Closed: DoStateChange(psStopped);
  end;
end;

procedure TXAMLPlayerWrapper.Stop;
begin
  if Initialized then
  begin
    FMediaPlayer.SetUriSource(nil);
    DoStateChange(psStopped);
  end;
end;

end.
