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

unit XAMLPlayer.VCLHost;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Controls, XAMLPlayer.Engine;

type
  [ComponentPlatformsAttribute(pfidWindows)]
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

end.
