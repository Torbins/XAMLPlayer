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

unit XAMLPlayer.VCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Controls, XAMLPlayer.Common;

type
  TXAMLHost = class(TCustomControl)
  private
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    FIsland: TXAMLIsland;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Visible;
    property OnCanResize;
    property OnResize;
  end;

  TXAMLMediaPlayer = class(TXAMLHost)
  private
    FPlayerWrapper: TXAMLPlayerWrapper;
    procedure SetFileName(const Value: string);
    function GetLoopPlayback: Boolean;
    procedure SetLoopPlayback(const Value: Boolean);
    function GetIsMuted: Boolean;
    procedure SetIsMuted(const Value: Boolean);
    function GetControlsVisible: Boolean;
    procedure SetControlsVisible(const Value: Boolean);
    function GetStretch: TVideoStretch;
    procedure SetStretch(const Value: TVideoStretch);
    function GetPlaybackPosition: TTime;
    procedure SetPlaybackPosition(const Value: TTime);
    function GetErrorEvent: TPlayerErrorEvent;
    function GetStateEvent: TPlayerStateEvent;
    procedure SetErrorEvent(const Value: TPlayerErrorEvent);
    procedure SetStateEvent(const Value: TPlayerStateEvent);
    function GetFileName: string;
  public
    property PlaybackPosition: TTime read GetPlaybackPosition write SetPlaybackPosition;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetCurrentMedia_Duration: TTime;
    procedure Play;
    procedure Pause;
    procedure Stop;
    procedure Next;
    procedure Previous;
    function GetCurrentMedia_NumInPlaylist: Integer;
    function GetCurrentMedia_Title: String;
    function GetPlayListSize: Integer;
    function IsPlaying: Boolean;
    function IsPaused: Boolean;
    procedure PlayDirectory(ADirectory: String; AFileMask: String = '*.mp4');
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

uses
  Vcl.Graphics;

{ TXAMLHost }

constructor TXAMLHost.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csOpaque];

  FIsland := TXAMLIsland.Create(ReqPosition);
end;

destructor TXAMLHost.Destroy;
begin
  FIsland.Free;

  inherited;
end;

procedure TXAMLHost.CMVisibleChanged(var Message: TMessage);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLHost.CreateWnd;
begin
  inherited;

  FIsland.UpdateParentHandle(WindowHandle, GetTopParentHandle);
end;

procedure TXAMLHost.Paint;
var
  TempStr: String;
  TempRect: TRect;
begin
  inherited;

  Canvas.Brush.Color := clDkGray;
  Canvas.Rectangle(ClientRect);
  Canvas.Font.Color := clWhite;
  Canvas.Font.Size := 12;
  TempRect := ClientRect;
  TempStr := SManifestWarning;
  Canvas.TextRect(TempRect, TempStr, [tfCenter, tfVerticalCenter, tfWordBreak]);
end;

procedure TXAMLHost.ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
begin
  AVisible := Visible;

  ALeft := 0;
  ATop := 0;
  AWidth := Width;
  AHeight := Height;
end;

procedure TXAMLHost.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

{ TXAMLMediaPlayer }

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

end.
