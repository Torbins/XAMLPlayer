type
  [ComponentPlatformsAttribute(pfidWindows)]
  TXAMLMediaPlayer = class(TXAMLHost)
  private
    FPlayerWrapper: TXAMLPlayerWrapper;
    function GetControlsVisible: Boolean;
    function GetErrorEvent: TPlayerErrorEvent;
    function GetFileName: string;
    function GetIsMuted: Boolean;
    function GetLoopPlayback: Boolean;
    function GetPlaybackPosition: TTime;
    function GetStateEvent: TPlayerStateEvent;
    function GetStretch: TVideoStretch;
    procedure SetControlsVisible(const Value: Boolean);
    procedure SetErrorEvent(const Value: TPlayerErrorEvent);
    procedure SetFileName(const Value: string);
    procedure SetIsMuted(const Value: Boolean);
    procedure SetLoopPlayback(const Value: Boolean);
    procedure SetPlaybackPosition(const Value: TTime);
    procedure SetStateEvent(const Value: TPlayerStateEvent);
    procedure SetStretch(const Value: TVideoStretch);
  public
    constructor Create(AOwner: TComponent); override;
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
    property FileName: string read GetFileName write SetFileName;
    property IsMuted: Boolean read GetIsMuted write SetIsMuted default False;
    property LoopPlayback: Boolean read GetLoopPlayback write SetLoopPlayback default False;
    property Stretch: TVideoStretch read GetStretch write SetStretch default vsFit;
    property OnError: TPlayerErrorEvent read GetErrorEvent write SetErrorEvent;
    property OnStateChange: TPlayerStateEvent read GetStateEvent write SetStateEvent;
  end;

procedure Register;

implementation

{ TXAMLMediaPlayer }

constructor TXAMLMediaPlayer.Create(AOwner: TComponent);
begin
  inherited;

  FPlayerWrapper := TXAMLPlayerWrapper.Create(FIsland);
end;

destructor TXAMLMediaPlayer.Destroy;
begin
  FPlayerWrapper.Stop;
  FPlayerWrapper.Free;

  inherited;
end;

function TXAMLMediaPlayer.GetControlsVisible: Boolean;
begin
  Result := FPlayerWrapper.ControlsVisible;
end;

function TXAMLMediaPlayer.GetCurrentMedia_Duration: TTime;
begin
  Result := FPlayerWrapper.GetCurrentMedia_Duration;
end;

function TXAMLMediaPlayer.GetCurrentMedia_NumInPlaylist: Integer;
begin
  Result := FPlayerWrapper.GetCurrentMedia_NumInPlaylist;
end;

function TXAMLMediaPlayer.GetCurrentMedia_Title: String;
begin
  Result := FPlayerWrapper.GetCurrentMedia_Title;
end;

function TXAMLMediaPlayer.GetErrorEvent: TPlayerErrorEvent;
begin
  Result := FPlayerWrapper.OnError;
end;

function TXAMLMediaPlayer.GetFileName: string;
begin
  Result := FPlayerWrapper.FileName;
end;

function TXAMLMediaPlayer.GetIsMuted: Boolean;
begin
  Result := FPlayerWrapper.IsMuted;
end;

function TXAMLMediaPlayer.GetLoopPlayback: Boolean;
begin
  Result := FPlayerWrapper.LoopPlayback;
end;

function TXAMLMediaPlayer.GetPlaybackPosition: TTime;
begin
  Result := FPlayerWrapper.PlaybackPosition;
end;

function TXAMLMediaPlayer.GetPlayListSize: Integer;
begin
  Result := FPlayerWrapper.GetPlayListSize;
end;

function TXAMLMediaPlayer.GetStateEvent: TPlayerStateEvent;
begin
  Result := FPlayerWrapper.OnStateChange;
end;

function TXAMLMediaPlayer.GetStretch: TVideoStretch;
begin
  Result := FPlayerWrapper.Stretch;
end;

function TXAMLMediaPlayer.IsPaused: Boolean;
begin
  Result := FPlayerWrapper.IsPaused;
end;

function TXAMLMediaPlayer.IsPlaying: Boolean;
begin
  Result := FPlayerWrapper.IsPlaying;
end;

procedure TXAMLMediaPlayer.Next;
begin
  FPlayerWrapper.Next;
end;

procedure TXAMLMediaPlayer.Pause;
begin
  FPlayerWrapper.Pause;
end;

procedure TXAMLMediaPlayer.Play;
begin
  FPlayerWrapper.Play;
end;

procedure TXAMLMediaPlayer.PlayDirectory(ADirectory, AFileMask: String);
begin
  FPlayerWrapper.PlayDirectory(ADirectory, AFileMask);
end;

procedure TXAMLMediaPlayer.Previous;
begin
  FPlayerWrapper.Previous;
end;

procedure TXAMLMediaPlayer.SetControlsVisible(const Value: Boolean);
begin
  FPlayerWrapper.ControlsVisible := Value;
end;

procedure TXAMLMediaPlayer.SetErrorEvent(const Value: TPlayerErrorEvent);
begin
  FPlayerWrapper.OnError := Value;
end;

procedure TXAMLMediaPlayer.SetFileName(const Value: string);
begin
  FPlayerWrapper.FileName := Value;
end;

procedure TXAMLMediaPlayer.SetIsMuted(const Value: Boolean);
begin
  FPlayerWrapper.IsMuted := Value;
end;

procedure TXAMLMediaPlayer.SetLoopPlayback(const Value: Boolean);
begin
  FPlayerWrapper.LoopPlayback := Value;
end;

procedure TXAMLMediaPlayer.SetPlaybackPosition(const Value: TTime);
begin
  FPlayerWrapper.PlaybackPosition := Value;
end;

procedure TXAMLMediaPlayer.SetStateEvent(const Value: TPlayerStateEvent);
begin
  FPlayerWrapper.OnStateChange := Value;
end;

procedure TXAMLMediaPlayer.SetStretch(const Value: TVideoStretch);
begin
  FPlayerWrapper.Stretch := Value;
end;

procedure TXAMLMediaPlayer.Stop;
begin
  FPlayerWrapper.Stop;
end;

procedure Register;
begin
  RegisterComponents('Media', [TXAMLMediaPlayer]);
end;
