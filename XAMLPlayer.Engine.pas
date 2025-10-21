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

unit XAMLPlayer.Engine;

interface

uses
  Winapi.Windows, Winapi.UI.Xaml;

type
  TPositionRequest = procedure(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer) of object;

  TXAMLEngine = class
  private
    class var FHostingEngine: Hosting_IWindowsXamlManager;
    class var FInitialized: Boolean;
    class constructor Create;
    class destructor Destroy;
  public
    class property Initialized: Boolean read FInitialized;
  end;

  TXAMLIsland = class(TXAMLEngine)
  private
    FPositionRequest: TPositionRequest;
    FInterop: IDesktopWindowXamlSourceNative;
    FHostHandle: HWND;
    FElement: IUIElement;
    function GetElement: IUIElement;
    procedure SetElement(const Value: IUIElement);
    procedure Detach;
  public
    property Element: IUIElement read GetElement write SetElement;
    constructor Create(APositionGetter: TPositionRequest);
    destructor Destroy; override;
    procedure UpdateParentHandle(AParent, ATopParent: HWND);
    procedure UpdateVisibility;
  end;

resourcestring
  SManifestWarning = 'Application manifest does not contain "maxversiontested" element!';

implementation

uses
  System.SysUtils, System.Win.ComObj, WinAPI.Foundation;

const
  SEngineWindowClass = 'Windows.UI.Core.CoreWindow';
  SEngineWindowName = 'DesktopWindowXamlSource';

{ TXAMLEngine }

class constructor TXAMLEngine.Create;
begin
  if TOSVersion.Check(10) and (TOSVersion.Build >= 18362) then
  begin
    try
      FHostingEngine := THosting_WindowsXamlManager.InitializeForCurrentThread;
      FInitialized := True;
    except
      on e: EOleException do
        FInitialized := False;
    end;
  end
  else
    FInitialized := False;
end;

class destructor TXAMLEngine.Destroy;
begin
  FHostingEngine := nil;
end;

{ TXAMLIsland }

constructor TXAMLIsland.Create(APositionGetter: TPositionRequest);
begin
  FPositionRequest := APositionGetter;
end;

destructor TXAMLIsland.Destroy;
begin
  Detach;
  FElement := nil;

  inherited;
end;

procedure TXAMLIsland.Detach;
begin
  FHostHandle := 0;
  if Assigned(FInterop) then
    (FInterop as IClosable).Close;
  FInterop := nil;
end;

function TXAMLIsland.GetElement: IUIElement;
begin
  if Assigned(FInterop) then
    Result := (FInterop as Hosting_IDesktopWindowXamlSource).Content
  else
    Result := FElement;
end;

procedure TXAMLIsland.SetElement(const Value: IUIElement);
begin
  FElement := Value;
  if Assigned(FInterop) then
    (FInterop as Hosting_IDesktopWindowXamlSource).Content := Value;
end;

procedure TXAMLIsland.UpdateParentHandle(AParent, ATopParent: HWND);

  procedure ProtectEngineWindow;
  var
    EW: HWND;
  begin
    if ATopParent <> 0 then
    begin
      EW := FindWindowEx(ATopParent, 0, SEngineWindowClass, SEngineWindowName);
      if EW <> 0 then
        Winapi.Windows.SetParent(EW, GetDesktopWindow);
    end;
  end;

begin
  Detach;

  if Initialized and (AParent <> 0) then
  begin
    FInterop := THosting_DesktopWindowXamlSource.Create as IDesktopWindowXamlSourceNative;
    FInterop.AttachToWindow(AParent);
    (FInterop as Hosting_IDesktopWindowXamlSource).Content := FElement;
    FHostHandle := FInterop.get_WindowHandle;

    // After a call to FInterop.AttachToWindow, special engine window will become a child of the parent form window
    // When form handle needs to be recreated (type of border has changed, styles enabled, etc.) engine window will be
    // destroyed and XAML integration broken
    // It is possible to prevent this by turning engine window back into top-level window
    ProtectEngineWindow;

    UpdateVisibility;
  end;
end;

procedure TXAMLIsland.UpdateVisibility;
var
  Left, Top, Width, Height: Integer;
  Visible: Boolean;
begin
  if FInitialized and (FHostHandle > 0) then
  begin
    Visible := False;
    Left := 0;
    Top := 0;
    Width := 0;
    Height := 0;

    if Assigned(FPositionRequest) then
      FPositionRequest(Visible, Left, Top, Width, Height);

    if Visible then
      SetWindowPos(FHostHandle, 0, Left, Top, Width, Height, SWP_SHOWWINDOW + SWP_NOACTIVATE)
    else
      SetWindowPos(FHostHandle, 0, Left, Top, Width, Height, SWP_HIDEWINDOW + SWP_NOACTIVATE);
  end;
end;

end.
