unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.ExtCtrls,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, XAMLPlayer.VCLHost, XAMLPlayer.VCLPlayer, XAMLPlayer.Wrapper,
  Vcl.ComCtrls, System.Types, Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls, System.Actions, Vcl.ActnList, Vcl.ActnMan,
  Vcl.ActnPopup, Vcl.StdActns;

type
  TfMain = class(TForm)
    pButtons: TPanel;
    XAMLMediaPlayer: TXAMLMediaPlayer;
    bOpen: TButton;
    bPlay: TButton;
    bPause: TButton;
    bStop: TButton;
    bMute: TButton;
    tbPosition: TTrackBar;
    lTime: TLabel;
    tTimeUpdate: TTimer;
    tAction: TTimer;
    ActionManager: TActionManager;
    FileOpen: TFileOpen;
    FileExit: TFileExit;
    aPlay: TAction;
    aPause: TAction;
    aStop: TAction;
    aMute: TAction;
    PopupActionBar: TPopupActionBar;
    Open1: TMenuItem;
    Play1: TMenuItem;
    Pause1: TMenuItem;
    Stop1: TMenuItem;
    Mute1: TMenuItem;
    Exit1: TMenuItem;
    procedure aMuteClick(Sender: TObject);
    procedure FileOpenClick(Sender: TObject);
    procedure aPauseClick(Sender: TObject);
    procedure aPlayClick(Sender: TObject);
    procedure aStopClick(Sender: TObject);
    procedure CheckParams(Sender: TObject);
    procedure EnableUpdateTimer(Sender: TObject);
    procedure tbPositionTracking(Sender: TObject);
    procedure tTimeUpdateTimer(Sender: TObject);
    procedure XAMLMediaPlayerClick(Sender: TObject);
    procedure XAMLMediaPlayerContextPopup(Sender: TObject; Position: TPointF; var Handled: Boolean);
    procedure XAMLMediaPlayerStateChange(Sender: TObject; State: TPlayerState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

uses
  System.Math;

procedure TfMain.aMuteClick(Sender: TObject);
begin
  if XAMLMediaPlayer.IsMuted then
  begin
    aMute.Caption := '🔇 Mute';
    bMute.Caption := '🔇';
    XAMLMediaPlayer.IsMuted := False;
  end
  else
  begin
    aMute.Caption := '🔉 Unmute';
    bMute.Caption := '🔉';
    XAMLMediaPlayer.IsMuted := True;
  end;
end;

procedure TfMain.FileOpenClick(Sender: TObject);
begin
  XAMLMediaPlayer.FileName := FileOpen.Dialog.FileName;
end;

procedure TfMain.aPauseClick(Sender: TObject);
begin
  XAMLMediaPlayer.Pause;
end;

procedure TfMain.aPlayClick(Sender: TObject);
begin
  XAMLMediaPlayer.Play;
end;

procedure TfMain.aStopClick(Sender: TObject);
begin
  XAMLMediaPlayer.Stop;
end;

procedure TfMain.CheckParams(Sender: TObject);
begin
  tAction.Enabled := False;
  if ParamCount > 0 then
    XAMLMediaPlayer.FileName := ParamStr(1);
end;

procedure TfMain.EnableUpdateTimer(Sender: TObject);
begin
  tAction.Enabled := False;
  tTimeUpdate.Enabled := True;
end;

procedure TfMain.tbPositionTracking(Sender: TObject);
begin
  tTimeUpdate.Enabled := False;

  XAMLMediaPlayer.PlaybackPosition := XAMLMediaPlayer.GetCurrentMedia_Duration * tbPosition.Position / tbPosition.Max;

  tAction.Enabled := False;
  tAction.OnTimer := EnableUpdateTimer;
  tAction.Enabled := True;
end;

procedure TfMain.tTimeUpdateTimer(Sender: TObject);
begin
  lTime.Caption := TimeToStr(XAMLMediaPlayer.PlaybackPosition) + '/' + sLineBreak +
    TimeToStr(XAMLMediaPlayer.GetCurrentMedia_Duration);

  if XAMLMediaPlayer.GetCurrentMedia_Duration > 0 then
    tbPosition.Position := Min(Trunc(XAMLMediaPlayer.PlaybackPosition * tbPosition.Max /
      XAMLMediaPlayer.GetCurrentMedia_Duration), tbPosition.Max)
  else
    tbPosition.Position := 0;
end;

procedure TfMain.XAMLMediaPlayerClick(Sender: TObject);
begin
  if XAMLMediaPlayer.IsPlaying then
    XAMLMediaPlayer.Pause
  else
    XAMLMediaPlayer.Play;
end;

procedure TfMain.XAMLMediaPlayerContextPopup(Sender: TObject; Position: TPointF; var Handled: Boolean);
var
  ScreenPoint: TPoint;
begin
  ScreenPoint := Point(Round(Position.X), Round(Position.Y));
  ScreenPoint := XAMLMediaPlayer.ClientToScreen(ScaleValue(ScreenPoint));
  PopupActionBar.Popup(ScreenPoint.X, ScreenPoint.Y);
  Handled := True;
end;

procedure TfMain.XAMLMediaPlayerStateChange(Sender: TObject; State: TPlayerState);
begin
  Caption := XAMLMediaPlayer.GetCurrentMedia_Title;
  if Caption <> '' then
    Caption := Caption + ' - ';
  case State of
    psPlaying:
      begin
        Caption := Caption + 'Playing';
        tTimeUpdate.Enabled := True;
        tbPosition.Enabled := True;
        aPause.Enabled := True;
        aStop.Enabled := True;
        aMute.Enabled := True;
      end;
    psPaused:
      begin
        Caption := Caption + 'Paused';
        tTimeUpdate.Enabled := False;
      end;
    psStopped:
      begin
        Caption := Caption + 'Stopped';
        tTimeUpdate.Enabled := False;
        lTime.Caption := '';
        tbPosition.Position := 0;
        tbPosition.Enabled := False;
        aPause.Enabled := False;
        aStop.Enabled := False;
        aMute.Enabled := False;
      end;
  end;
end;

end.
