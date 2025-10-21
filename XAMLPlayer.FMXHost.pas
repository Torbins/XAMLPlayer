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

unit XAMLPlayer.FMXHost;

interface

uses
  System.Classes, System.Messaging, FMX.Types, FMX.Controls, FMX.Forms, XAMLPlayer.Engine;

type
  [ComponentPlatformsAttribute(pfidWindows)]
  TXAMLHost = class(TControl)
  protected
    FIsland: TXAMLIsland;
    procedure AncestorParentChanged; override;
    procedure AncestorVisibleChanged(const Visible: Boolean); override;
    procedure CreateFormWnd(const Sender: TObject; const M: TMessage);
    procedure DoAbsoluteChanged; override;
    function GetParentForm: TCommonCustomForm;
    procedure Loaded; override;
    procedure Move; override;
    procedure Paint; override;
    procedure ParentChanged; override;
    procedure ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);
    procedure Resize; override;
    procedure UpdateParent;
    procedure VisibleChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
  end;

implementation

uses
  System.UIConsts, System.Types, FMX.Platform.Win;

{ TXAMLHost }

constructor TXAMLHost.Create(AOwner: TComponent);
begin
  inherited;

  FIsland := TXAMLIsland.Create(ReqPosition);

  if FIsland.Initialized then
    TMessageManager.DefaultManager.SubscribeToMessage(TAfterCreateFormHandle, CreateFormWnd);
end;

destructor TXAMLHost.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TAfterCreateFormHandle, CreateFormWnd);

  FIsland.Free;

  inherited;
end;

procedure TXAMLHost.AncestorParentChanged;
begin
  inherited;

  UpdateParent;
end;

procedure TXAMLHost.AncestorVisibleChanged(const Visible: Boolean);
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLHost.CreateFormWnd(const Sender: TObject; const M: TMessage);
var
  Form: TCommonCustomForm;
begin
  Form := (M as TAfterCreateFormHandle).Value;
  if Form = GetParentForm then
    FIsland.UpdateParentHandle(FmxHandleToHWND(Form.Handle), FmxHandleToHWND(Form.Handle));
end;

procedure TXAMLHost.DoAbsoluteChanged;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

function TXAMLHost.GetParentForm: TCommonCustomForm;
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

procedure TXAMLHost.Loaded;
begin
  inherited;

  UpdateParent;
end;

procedure TXAMLHost.Move;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLHost.Paint;
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

procedure TXAMLHost.ParentChanged;
begin
  inherited;

  UpdateParent;
end;

procedure TXAMLHost.ReqPosition(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer);

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

procedure TXAMLHost.Resize;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

procedure TXAMLHost.UpdateParent;
var
  Form: TCommonCustomForm;
begin
  Form := GetParentForm;
  if Assigned(Form) then
    FIsland.UpdateParentHandle(FmxHandleToHWND(Form.Handle), FmxHandleToHWND(Form.Handle));
end;

procedure TXAMLHost.VisibleChanged;
begin
  inherited;

  FIsland.UpdateVisibility;
end;

end.
