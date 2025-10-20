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
  TXAMLMediaPlayer = class(TCustomControl)
  private
    FIsland: TXAMLPlayerIsland;
    procedure SetFileName(const Value: string);
    function GetLoopPlayback: Boolean;
    procedure SetLoopPlayback(const Value: Boolean);
    function GetIsMuted: Boolean;
    procedure SetIsMuted(const Value: Boolean);
    function GetControlsVisible: Boolean;
    procedure SetControlsVisible(const Value: Boolean);
    function GetStretch: TVideoStretch;
    procedure SetStretch(const Value: TVideoStretch);
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    function GetPlaybackPosition: TTime;
    procedure SetPlaybackPosition(const Value: TTime);
    function GetErrorEvent: TPlayerErrorEvent;
    function GetStateEvent: TPlayerStateEvent;
    procedure SetErrorEvent(const Value: TPlayerErrorEvent);
    procedure SetStateEvent(const Value: TPlayerStateEvent);
    function GetFileName: string;
  protected
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
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
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Visible;
    property OnCanResize;
    property OnResize;
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

function TXAMLMediaPlayer.GetPlayListSize: Integer;
begin
  Result := FIsland.GetPlayListSize;
end;

function TXAMLMediaPlayer.GetStateEvent: TPlayerStateEvent;
begin
  Result := FIsland.OnStateChange;
end;

function TXAMLMediaPlayer.GetStretch: TVideoStretch;
begin
  Result := FIsland.Stretch;
end;

function TXAMLMediaPlayer.IsPaused: Boolean;
begin
  Result := FIsland.IsPaused;
end;

function TXAMLMediaPlayer.IsPlaying: Boolean;
begin
  Result := FIsland.IsPlaying;
end;

procedure TXAMLMediaPlayer.Next;
begin
  FIsland.Next;
end;

procedure TXAMLMediaPlayer.CMVisibleChanged(var Message: TMessage);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

constructor TXAMLMediaPlayer.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csOpaque];

  FIsland := TXAMLPlayerIsland.Create(ReqPosition);
end;

procedure TXAMLMediaPlayer.CreateWnd;
begin
  inherited;

  FIsland.UpdateParentHandle(WindowHandle, GetTopParentHandle);
end;

destructor TXAMLMediaPlayer.Destroy;
begin
  FIsland.Stop;
  FIsland.Free;

  inherited;
end;

function TXAMLMediaPlayer.GetControlsVisible: Boolean;
begin
  Result := FIsland.ControlsVisible;
end;

function TXAMLMediaPlayer.GetCurrentMedia_Duration: TTime;
begin
  Result := FIsland.GetCurrentMedia_Duration;
end;

function TXAMLMediaPlayer.GetCurrentMedia_NumInPlaylist: Integer;
begin
  Result := FIsland.GetCurrentMedia_NumInPlaylist;
end;

function TXAMLMediaPlayer.GetCurrentMedia_Title: String;
begin
  Result := FIsland.GetCurrentMedia_Title;
end;

function TXAMLMediaPlayer.GetErrorEvent: TPlayerErrorEvent;
begin
  Result := FIsland.OnError;
end;

function TXAMLMediaPlayer.GetFileName: string;
begin
  Result := FIsland.FileName;
end;

function TXAMLMediaPlayer.GetIsMuted: Boolean;
begin
  Result := FIsland.IsMuted;
end;

function TXAMLMediaPlayer.GetLoopPlayback: Boolean;
begin
  Result := FIsland.LoopPlayback;
end;

function TXAMLMediaPlayer.GetPlaybackPosition: TTime;
begin
  Result := FIsland.PlaybackPosition;
end;

procedure TXAMLMediaPlayer.Paint;
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

procedure TXAMLMediaPlayer.Pause;
begin
  FIsland.Pause;
end;

procedure TXAMLMediaPlayer.Play;
begin
  FIsland.Play;
end;

procedure TXAMLMediaPlayer.PlayDirectory(ADirectory, AFileMask: String);
begin
  FIsland.PlayDirectory(ADirectory, AFileMask);
end;

procedure TXAMLMediaPlayer.Previous;
begin
  FIsland.Previous;
end;

procedure TXAMLMediaPlayer.ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
begin
  AVisible := Visible;

  ALeft := 0;
  ATop := 0;
  AWidth := Width;
  AHeight := Height;
end;

procedure TXAMLMediaPlayer.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLMediaPlayer.SetControlsVisible(const Value: Boolean);
begin
  FIsland.ControlsVisible := Value;
end;

procedure TXAMLMediaPlayer.SetErrorEvent(const Value: TPlayerErrorEvent);
begin
  FIsland.OnError := Value;
end;

procedure TXAMLMediaPlayer.SetFileName(const Value: string);
begin
  FIsland.FileName := Value;
end;

procedure TXAMLMediaPlayer.SetIsMuted(const Value: Boolean);
begin
  FIsland.IsMuted := Value;
end;

procedure TXAMLMediaPlayer.SetLoopPlayback(const Value: Boolean);
begin
  FIsland.LoopPlayback := Value;
end;

procedure TXAMLMediaPlayer.SetPlaybackPosition(const Value: TTime);
begin
  FIsland.PlaybackPosition := Value;
end;

procedure TXAMLMediaPlayer.SetStateEvent(const Value: TPlayerStateEvent);
begin
  FIsland.OnStateChange := Value;
end;

procedure TXAMLMediaPlayer.SetStretch(const Value: TVideoStretch);
begin
  FIsland.Stretch := Value;
end;

procedure TXAMLMediaPlayer.Stop;
begin
  FIsland.Stop;
end;

procedure Register;
begin
  RegisterComponents('Media', [TXAMLMediaPlayer]);
end;

end.
