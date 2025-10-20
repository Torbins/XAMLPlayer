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

unit XAMLPlayer.FMX;

interface

uses
  System.Classes, System.Messaging, FMX.Types, FMX.Controls, FMX.Forms, XAMLPlayer.Common;

type
  [ComponentPlatformsAttribute(pfidWindows)]
  TXAMLMediaPlayer = class(TControl)
  private
    FIsland: TXAMLPlayerIsland;
    function GetControlsVisible: Boolean;
    function GetFileName: string;
    function GetIsMuted: Boolean;
    function GetLoopPlayback: Boolean;
    function GetStretch: TVideoStretch;
    procedure SetControlsVisible(const Value: Boolean);
    procedure SetFileName(const Value: string);
    procedure SetIsMuted(const Value: Boolean);
    procedure SetLoopPlayback(const Value: Boolean);
    procedure SetStretch(const Value: TVideoStretch);
    function GetPlaybackPosition: TTime;
    procedure SetPlaybackPosition(const Value: TTime);
    function GetErrorEvent: TPlayerErrorEvent;
    function GetStateEvent: TPlayerStateEvent;
    procedure SetErrorEvent(const Value: TPlayerErrorEvent);
    procedure SetStateEvent(const Value: TPlayerStateEvent);
  protected
    procedure AncestorParentChanged; override;
    procedure AncestorVisibleChanged(const Visible: Boolean); override;
    procedure CreateFormWnd(const Sender: TObject; const M: TMessage);
    procedure DoAbsoluteChanged; override;
    function GetParentForm: TCommonCustomForm;
    procedure Loaded; override;
    procedure Move; override;
    procedure Paint; override;
    procedure ParentChanged; override;
    procedure Resize; override;
    procedure ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
    procedure UpdateParent;
    procedure VisibleChanged; override;
  public
    property PlaybackPosition: TTime read GetPlaybackPosition write SetPlaybackPosition;
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
  published
    property Align;
    property Anchors;
    property Height;
    property Margins;
    property Position;
    property Size;
    property Visible default True;
    property Width;
    property OnResize;
    property OnResized;
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
  System.UIConsts, System.Types, FMX.Platform.Win;

function TXAMLMediaPlayer.GetParentForm: TCommonCustomForm;
var
  LParent: TFmxObject;
begin
  LParent := Parent;
  while (LParent <> nil) and (not (LParent is TCommonCustomForm)) do
    LParent := LParent.Parent;
  if (LParent is TCommonCustomForm) then
    Result := TCommonCustomForm(LParent)
  else
    Result := nil;
end;

procedure TXAMLMediaPlayer.AncestorParentChanged;
begin
  inherited;

  UpdateParent;
end;

procedure TXAMLMediaPlayer.AncestorVisibleChanged(const Visible: Boolean);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

constructor TXAMLMediaPlayer.Create(AOwner: TComponent);
begin
  inherited;

  FIsland := TXAMLPlayerIsland.Create(ReqPosition);

  if FIsland.Initialized then
    TMessageManager.DefaultManager.SubscribeToMessage(TAfterCreateFormHandle, CreateFormWnd);
end;

procedure TXAMLMediaPlayer.CreateFormWnd(const Sender: TObject; const M: TMessage);
var
  Form: TCommonCustomForm;
begin
  Form := (M as TAfterCreateFormHandle).Value;
  if Form = GetParentForm then
    FIsland.UpdateParentHandle(FmxHandleToHWND(Form.Handle), FmxHandleToHWND(Form.Handle));
end;

destructor TXAMLMediaPlayer.Destroy;
begin
  FIsland.Stop;

  TMessageManager.DefaultManager.Unsubscribe(TAfterCreateFormHandle, CreateFormWnd);

  FIsland.Free;

  inherited;
end;

procedure TXAMLMediaPlayer.DoAbsoluteChanged;
begin
  inherited;

  FIsland.UpdateVisibility;
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

function TXAMLMediaPlayer.GetPlayListSize: Integer;
begin
  Result := FIsland.GetPlayListSize;
end;

function TXAMLMediaPlayer.GetPlaybackPosition: TTime;
begin
  Result := FIsland.PlaybackPosition;
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

procedure TXAMLMediaPlayer.Loaded;
begin
  inherited;

  UpdateParent;
end;

procedure TXAMLMediaPlayer.Move;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLMediaPlayer.Next;
begin
  FIsland.Next;
end;

procedure TXAMLMediaPlayer.Paint;
begin
  inherited;

  Canvas.BeginScene;
  try
    Canvas.Fill.Color := claDarkgray;
    Canvas.FillRect(LocalRect, 1);
    Canvas.Fill.Color := claWhite;
    Canvas.Font.Size := 12;
    Canvas.FillText(LocalRect, SManifestWarning, {WordWrap} True, 1, [], TTextAlign.Center);
  finally
    Canvas.EndScene;
  end;
end;

procedure TXAMLMediaPlayer.ParentChanged;
begin
  inherited;

  UpdateParent;
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

  function ParentVisible: Boolean;
  var
    LParent: TFmxObject;
  begin
    Result := True;

    LParent := Parent;
    while (LParent <> nil) and (not (LParent is TCommonCustomForm)) do
    begin
      if (LParent is TControl) and (not TControl(LParent).Visible) then
        Exit(False);
      LParent := LParent.Parent;
    end;
  end;

var
  RectOnForm: TRectF;
  Form: TCommonCustomForm;
begin
  AVisible := Visible and ParentVisible;

  Form := GetParentForm;
  if not Assigned(Form) then
    Exit;

  RectOnForm := (Form.Handle as TWinWindowHandle).FormToWnd(AbsoluteRect);
  ALeft := Trunc(RectOnForm.Left);
  ATop := Trunc(RectOnForm.Top);
  AWidth := Trunc(RectOnForm.Width);
  AHeight := Trunc(RectOnForm.Height);
end;

procedure TXAMLMediaPlayer.Resize;
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

procedure TXAMLMediaPlayer.UpdateParent;
var
  Form: TCommonCustomForm;
begin
  Form := GetParentForm;
  if Assigned(Form) then
    FIsland.UpdateParentHandle(FmxHandleToHWND(Form.Handle), FmxHandleToHWND(Form.Handle));
end;

procedure TXAMLMediaPlayer.VisibleChanged;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure Register;
begin
  RegisterComponents('Media', [TXAMLMediaPlayer]);
end;

end.
