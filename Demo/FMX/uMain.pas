unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls,
  XAMLPlayer.FMXHost, XAMLPlayer.FMXPlayer;

type
  TfMain = class(TForm)
    XAMLMediaPlayer: TXAMLMediaPlayer;
    bOpen: TButton;
    OpenDialog: TOpenDialog;
    lWarning: TLabel;
    procedure bOpenClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.fmx}

procedure TfMain.bOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    XAMLMediaPlayer.FileName := OpenDialog.FileName;
end;

end.
