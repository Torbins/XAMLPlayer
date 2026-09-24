unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.ExtCtrls,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, XAMLPlayer.VCLHost, XAMLPlayer.VCLPlayer, XAMLPlayer.Wrapper,
  Vcl.ComCtrls;

type
  TfMain = class(TForm)
    pButtons: TPanel;
    XAMLMediaPlayer: TXAMLMediaPlayer;
    bOpen: TButton;
    bPlay: TButton;
    bPause: TButton;
    OpenDialog: TOpenDialog;
    bStop: TButton;
    bMute: TButton;
    tbPosition: TTrackBar;
    lTime: TLabel;
    tTimeUpdate: TTimer;
    tAction: TTimer;
    procedure bMuteClick(Sender: TObject);
    procedure bOpenClick(Sender: TObject);
    procedure bPauseClick(Sender: TObject);
    procedure bPlayClick(Sender: TObject);
    procedure bStopClick(Sender: TObject);
    procedure CheckParams(Sender: TObject);
    procedure EnableUpdateTimer(Sender: TObject);
    procedure tbPositionTracking(Sender: TObject);
    procedure tTimeUpdateTimer(Sender: TObject);
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

procedure TfMain.bMuteClick(Sender: TObject);
begin
  if XAMLMediaPlayer.IsMuted then
  begin
    bMute.Caption := '🔇';
    XAMLMediaPlayer.IsMuted := False;
  end
  else
  begin
    bMute.Caption := '🔉';
    XAMLMediaPlayer.IsMuted := True;
  end;
end;

procedure TfMain.bOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    XAMLMediaPlayer.FileName := OpenDialog.FileName;
end;

procedure TfMain.bPauseClick(Sender: TObject);
begin
  XAMLMediaPlayer.Pause;
end;

procedure TfMain.bPlayClick(Sender: TObject);
begin
  XAMLMediaPlayer.Play;
end;

procedure TfMain.bStopClick(Sender: TObject);
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
        bPause.Enabled := True;
        bStop.Enabled := True;
        bMute.Enabled := True;
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
        bPause.Enabled := False;
        bStop.Enabled := False;
        bMute.Enabled := False;
      end;
  end;
end;

end.
