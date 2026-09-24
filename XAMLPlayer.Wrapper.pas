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

  TXAMLPlayerEventHolder = class(TNoRefCountObject, TypedEventHandler_2__Playback_IMediaPlayer__IInspectable
      {$IF CompilerVersion <= 36.0}, TypedEventHandler_2__Playback_IMediaPlayer__IInspectable_Delegate_Base{$IFEND})
    FHandler: THandler;
    procedure Invoke(sender: Playback_IMediaPlayer; args: IInspectable); safecall;
  public
    Token: EventRegistrationToken;
    constructor Create(AHandler: THandler);
  end;

  TXAMLPlayerErrorEventHolder = class(TNoRefCountObject,
      TypedEventHandler_2__Playback_IMediaPlayer__Playback_IMediaPlayerFailedEventArgs{$IF CompilerVersion <= 36.0},
      TypedEventHandler_2__Playback_IMediaPlayer__Playback_IMediaPlayerFailedEventArgs_Delegate_Base{$IFEND})
    FHandler: TErrorHandler;
    procedure Invoke(sender: Playback_IMediaPlayer; args: Playback_IMediaPlayerFailedEventArgs); safecall;
  public
    Token: EventRegistrationToken;
    constructor Create(AHandler: TErrorHandler);
  end;

  TXAMLPlayerWrapper = class
  private
    FIsland: TXAMLIsland;
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
    FDestroying: Boolean;
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
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils, System.Win.WinRT, WinAPI.Foundation,
  Winapi.UI.Xaml.Media;

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
  FIsland := AIsland;

  FIsland.BlockingSync(procedure
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

    FIsland.Element := FMPElement as IUIElement;
  end);
end;

destructor TXAMLPlayerWrapper.Destroy;
begin
  FDestroying := True;
  Stop;

  FIsland.LazySync(procedure
  begin
    FMediaPlayer.remove_CurrentStateChanged(FStateEventHolder.Token);
    FStateEventHolder.Free;
    FMediaPlayer.remove_MediaEnded(FEndedEventHolder.Token);
    FEndedEventHolder.Free;
    FMediaPlayer.remove_MediaFailed(FErrorEventHolder.Token);
    FErrorEventHolder.Free;

    FPlayList := nil;
    FMediaPlayer := nil;
    FMPElement := nil;
  end);

  inherited;
end;

procedure TXAMLPlayerWrapper.DoStateChange(AState: TPlayerState);
begin
  if Assigned(FStateEvent) and not FDestroying then
    TThread.Queue(nil, procedure
    begin
      FStateEvent(Self, AState);
    end);
end;

procedure TXAMLPlayerWrapper.EndFileHandler;
begin
  DoStateChange(psStopped);
end;

procedure TXAMLPlayerWrapper.ErrorHandler(AType: TErrorType; const AMesage: String);
begin
  if Assigned(FErrorEvent) and not FDestroying then
    TThread.Queue(nil, procedure
    begin
      FErrorEvent(Self, AType, AMesage);
    end);
end;

function TXAMLPlayerWrapper.GetControlsVisible: Boolean;
var
  Res: Boolean;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMPElement.AreTransportControlsEnabled;
    end)
  then
    Result := Res
  else
    Result := FControlsVisible;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_Duration: TTime;
var
  Res: TTime;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.NaturalDuration.Duration / 10000 / MSecsPerDay;
    end)
  then
    Result := Res
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_NumInPlaylist: Integer;
var
  Res: Integer;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FPlayList.CurrentItemIndex + 1;
    end)
  then
    Result := Res
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetCurrentMedia_Title: String;
var
  Res: String;
begin
  if FIsland.LazySync(procedure
    begin
      if not Assigned(FPlayList.CurrentItem) then
      begin
        Res := (TPath.GetFileNameWithoutExtension(TWindowsString.HStringToString(
          (FMPElement.Source as Core_IMediaSource4).Uri.Path)));
        Exit;
      end;

      Res := TWindowsString.HStringToString(
        (FPlayList.CurrentItem as Playback_IMediaPlaybackItem2).GetDisplayProperties.MusicProperties.Title);
      if Res = '' then
        Res := TWindowsString.HStringToString(
          (FPlayList.CurrentItem as Playback_IMediaPlaybackItem2).GetDisplayProperties.VideoProperties.Title);
      if Res = '' then
        Res := TPath.GetFileNameWithoutExtension(TWindowsString.HStringToString(
          (FPlayList.CurrentItem.Source as Core_IMediaSource4).Uri.Path));
    end)
  then
    Result := Res
  else
    Result := '';
end;

function TXAMLPlayerWrapper.GetIsMuted: Boolean;
var
  Res: Boolean;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.IsMuted;
    end)
  then
    Result := Res
  else
    Result := FIsMuted;
end;

function TXAMLPlayerWrapper.GetLoopPlayback: Boolean;
var
  Res: Boolean;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.IsLoopingEnabled;
    end)
  then
    Result := Res
  else
    Result := FLoopPlayback;
end;

function TXAMLPlayerWrapper.GetPlaybackPosition: TTime;
var
  Res: TTime;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.Position.Duration / 10000 / MSecsPerDay;
    end)
  then
    Result := Res
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetPlayListSize: Integer;
var
  Res: Integer;
begin
  if FIsland.LazySync(procedure
    begin
      Res := (FPlayList.Items as {$IF CompilerVersion <= 36.0}IVector_1__Playback_IMediaPlaybackItem_Base{$ELSE}
        IVector_1__Playback_IMediaPlaybackItem{$IFEND}).Size;
    end)
  then
    Result := Res
  else
    Result := 0;
end;

function TXAMLPlayerWrapper.GetStretch: TVideoStretch;
const
  MPElementToFacade: array[Winapi.UI.Xaml.Media.Stretch] of TVideoStretch = (vsOriginal, vsFill, vsFit, vsFullFit);
var
  Res: TVideoStretch;
begin
  if FIsland.LazySync(procedure
    begin
      Res := MPElementToFacade[FMPElement.Stretch_];
    end)
  then
    Result := Res
  else
    Result := FStretch;
end;

function TXAMLPlayerWrapper.IsPaused: Boolean;
var
  Res: Boolean;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Paused;
    end)
  then
    Result := Res
  else
    Result := True;
end;

function TXAMLPlayerWrapper.IsPlaying: Boolean;
var
  Res: Boolean;
begin
  if FIsland.LazySync(procedure
    begin
      Res := FMediaPlayer.CurrentState = Playback_MediaPlayerState.Playing;
    end)
  then
    Result := Res
  else
    Result := False;
end;

procedure TXAMLPlayerWrapper.Next;
begin
  if GetPlayListSize > 0 then
    FIsland.LazyQueue(procedure
    begin
      FPlayList.MoveNext;
    end);
end;

procedure TXAMLPlayerWrapper.Pause;
begin
  FIsland.LazyQueue(procedure
  begin
    FMediaPlayer.Pause;
  end);
end;

procedure TXAMLPlayerWrapper.Play;
begin
  FIsland.LazyQueue(procedure
  begin
    FMediaPlayer.Play;
  end);
end;

procedure TXAMLPlayerWrapper.PlayDirectory(ADirectory, AFileMask: String);
begin
  FFileName := ADirectory + AFileMask;

  FIsland.LazyQueue(procedure
  begin
    for var FileName in TDirectory.GetFiles(ADirectory, AFileMask) do
    begin
      var Uri: IUriRuntimeClass := TUri.CreateUri(TWindowsString.Create(FileName));
      var Item: Playback_IMediaPlaybackItem := TPlayback_MediaPlaybackItem.Create(TCore_MediaSource.CreateFromUri(Uri));
      (FPlayList.Items as {$IF CompilerVersion <= 36.0}IVector_1__Playback_IMediaPlaybackItem_Base{$ELSE}
        IVector_1__Playback_IMediaPlaybackItem{$IFEND}).Append(Item);
    end;

    FMPElement.Source := FPlayList as Playback_IMediaPlaybackSource;
  end);

  Play;
end;

procedure TXAMLPlayerWrapper.Previous;
begin
  if GetPlayListSize > 0 then
    FIsland.LazyQueue(procedure
    begin
      FPlayList.MovePrevious;
    end);
end;

procedure TXAMLPlayerWrapper.SetControlsVisible(const Value: Boolean);
begin
  if not FIsland.LazySync(procedure
    begin
      FMPElement.AreTransportControlsEnabled := Value;
    end)
  then
    FControlsVisible := Value;
end;

procedure TXAMLPlayerWrapper.SetFileName(const Value: string);
begin
  if Value <> '' then
  begin
    FFileName := TPath.GetFullPath(Value);

    FIsland.LazyQueue(procedure
    begin
      FMPElement.Source := (TCore_MediaSource.CreateFromUri(TUri.CreateUri(TWindowsString.Create(FFileName))) as
        Playback_IMediaPlaybackSource);
    end);
    Play;
  end
  else
  begin
    FFileName := '';
    Stop;
  end;
end;

procedure TXAMLPlayerWrapper.SetIsMuted(const Value: Boolean);
begin
  if not FIsland.LazySync(procedure
    begin
      FMediaPlayer.IsMuted := Value;
    end)
  then
    FIsMuted := Value;
end;

procedure TXAMLPlayerWrapper.SetLoopPlayback(const Value: Boolean);
begin
  if not FIsland.LazySync(procedure
    begin
      FMediaPlayer.IsLoopingEnabled := Value;
    end)
  then
    FLoopPlayback := Value;
end;

procedure TXAMLPlayerWrapper.SetPlaybackPosition(const Value: TTime);
var
  TS: TimeSpan;
begin
  TS.Duration := TimeToMilliseconds(Value) * 10000;

  FIsland.LazySync(procedure
  begin
    FMediaPlayer.Position := TS;
  end);
end;

procedure TXAMLPlayerWrapper.SetStretch(const Value: TVideoStretch);
const
  FacadeToMPElement: array[TVideoStretch] of Winapi.UI.Xaml.Media.Stretch = (Winapi.UI.Xaml.Media.Stretch.None,
    Winapi.UI.Xaml.Media.Stretch.Fill, Winapi.UI.Xaml.Media.Stretch.Uniform, Winapi.UI.Xaml.Media.Stretch.UniformToFill);
begin
  if not FIsland.LazySync(procedure
    begin
      FMPElement.Stretch_ := FacadeToMPElement[Value];
    end)
  then
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
  FIsland.LazySync(procedure
  begin
    FMediaPlayer.SetUriSource(nil);
    DoStateChange(psStopped);
  end);
end;

end.
