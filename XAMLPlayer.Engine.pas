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
  System.SysUtils, System.Classes, System.SyncObjs, Winapi.Windows, Winapi.Messages, Winapi.UI.Xaml, Winapi.SystemRT;

type
  TPositionRequest = procedure(var AVisible: Boolean; var ALeft, ATop, AWidth, AHeight: Integer) of object;
  TRunState = (rsInitializing, rsRunning, rsEnded, rsError);

  TXAMLIsland = class(TThread)
  private
    FController: IDispatcherQueueController;
    FHostingEngine: Hosting_IWindowsXamlManager;
    FPositionRequest: TPositionRequest;
    FInterop: Hosting_IDesktopWindowXamlSource;
    FHostHandle: HWND;
    FIslandHandle: HWND;
    FElement: IUIElement;
    FStarted: TLightweightEvent;
    FState: TRunState;
    FSyncWindow: HWND;
    FErrorMessage: String;
    function GetElement: IUIElement;
    procedure SyncProcedure(var Message: TMessage);
    procedure InternalQueue(const AProc: TProc; ASynchronous: Boolean);
    procedure SetElement(const Value: IUIElement);
    procedure Detach;
  protected
    procedure Execute; override;
  public
    property Element: IUIElement read GetElement write SetElement;
    property ErrorMessage: String read FErrorMessage;
    constructor Create(APositionGetter: TPositionRequest);
    destructor Destroy; override;
    function Initialized: Boolean;
    function XAMLQueue(Proc: TProc): Boolean;
    function XAMLSync(Proc: TProc): Boolean;
    procedure UpdateParentHandle(AParent, ATopParent: HWND);
    procedure UpdateVisibility;
  end;

implementation

uses
  System.Win.ComObj, WinAPI.Foundation, Winapi.WinRT;

const
  SEngineWindowClass = 'Windows.UI.Core.CoreWindow';
  SEngineWindowName = 'DesktopWindowXamlSource';
  UM_QUEUE = WM_USER + 1;
  UM_SYNC = WM_USER + 2;
  SIslandWindowClass = 'XAMLIslandWindow';

resourcestring
  SManifestWarning = 'Application manifest does not contain "maxversiontested" element!';

{ TXAMLIsland }

constructor TXAMLIsland.Create(APositionGetter: TPositionRequest);
begin
  FErrorMessage := SManifestWarning;
  FPositionRequest := APositionGetter;
  FStarted := TLightweightEvent.Create;
  inherited Create;
end;

destructor TXAMLIsland.Destroy;
begin
  XAMLSync(procedure
  begin
    FElement := nil;
  end);
  Detach;

  XAMLSync(procedure
  begin
    if Assigned(FHostingEngine) then
      (FHostingEngine as IClosable).Close;
    FHostingEngine := nil;

    if Assigned(FController) then
      FController.ShutdownQueueAsync.GetResults;
    FController := nil;
  end);

  XAMLQueue(procedure
  begin
    PostQuitMessage(0);
  end);

  ShutdownThread;
  FStarted.Free;
  inherited;
end;

procedure TXAMLIsland.Execute;

  function RegisterHostWindowClass: ATOM;
  var
    WC: WNDCLASS;
  begin
    FillMemory(@WC, SizeOf(WC), 0);

    WC.lpfnWndProc    := @DefWindowProc;
    WC.hInstance      := HInstance;
    WC.hCursor        := LoadCursor(0, IDC_ARROW);
    WC.lpszClassName  := SIslandWindowClass;

    Result := RegisterClass(WC);
  end;

var
  Msg: TMsg;
begin
  if TOSVersion.Check(10) and (TOSVersion.Build >= 18362) then
  try
    try
      OleCheck(RoInitialize(RO_INIT_SINGLETHREADED));

      FController := TDispatcherQueueController.CreateOnDedicatedThread;
      FHostingEngine := THosting_WindowsXamlManager.InitializeForCurrentThread;

      RegisterHostWindowClass;

      FSyncWindow := AllocateHWnd(SyncProcedure);
      FState := rsRunning;
      FStarted.SetEvent;

      while GetMessage(Msg, 0, 0, 0) do
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
    finally
      FState := rsEnded;
      if FSyncWindow > 0 then
        DeallocateHWnd(FSyncWindow);
      FSyncWindow := 0;

      RoUninitialize;
    end;
  except
    on e: Exception do
    begin
      FState := rsError;
      FStarted.SetEvent;
      FErrorMessage := FErrorMessage + sLineBreak + e.ClassName + ': ' + e.Message;
    end;
  end;
end;

function TXAMLIsland.Initialized: Boolean;
begin
  Result := FStarted.IsSet and (FState = rsRunning);
end;

function TXAMLIsland.GetElement: IUIElement;
begin
  Result := FElement;
end;

procedure TXAMLIsland.SetElement(const Value: IUIElement);
begin
  FElement := Value;
  if Assigned(FInterop) then
    FInterop.Content := Value;
end;

procedure TXAMLIsland.InternalQueue(const AProc: TProc; ASynchronous: Boolean);
var
  P: TProc;
  Intf: IInterface absolute P;
  ProcParam: WPARAM absolute P;
begin
  P := AProc;

  Intf._AddRef;
  if ASynchronous then
    SendMessage(FSyncWindow, UM_SYNC, ProcParam, 0)
  else
    PostMessage(FSyncWindow, UM_QUEUE, ProcParam, 0);
end;

function TXAMLIsland.XAMLQueue(Proc: TProc): Boolean;
begin
  FStarted.WaitFor;
  Result := FState = rsRunning;
  if Result then
    InternalQueue(Proc, {ASynchronous} False);
end;

function TXAMLIsland.XAMLSync(Proc: TProc): Boolean;
begin
  FStarted.WaitFor;
  Result := FState = rsRunning;
  if Result then
    InternalQueue(Proc, {ASynchronous} True);
end;

procedure TXAMLIsland.SyncProcedure(var Message: TMessage);
var
  Proc: TProc;
  Intf: IInterface absolute Proc;
begin
  if (Message.Msg = UM_QUEUE) or (Message.Msg = UM_SYNC) then
  begin
    Proc  := TProc(Message.WParam);
    Intf._Release;

    Proc;
  end;
end;

procedure TXAMLIsland.Detach;
begin
  XAMLSync(procedure
  begin
    if Assigned(FInterop) then
      FInterop.Content := nil;
    FInterop := nil;

    if FIslandHandle > 0 then
      DestroyWindow(FIslandHandle);
  end);

  FIslandHandle := 0;
  FHostHandle := 0;
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

  if AParent > 0 then
  begin
    XAMLSync(procedure
    var
      WndManager: IDesktopWindowXamlSourceNative;
    begin
      FInterop := THosting_DesktopWindowXamlSource.Create;
      WndManager := FInterop as IDesktopWindowXamlSourceNative;

      FIslandHandle := CreateWindow(SIslandWindowClass, '', WS_CHILD, 0, 0, 10, 10, AParent, 0, HInstance, nil);

      WndManager.AttachToWindow(FIslandHandle);
      FInterop.Content := FElement;
      FHostHandle := WndManager.get_WindowHandle;
    end);

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
  ShowCmd: Cardinal;
begin
  if Initialized and (FHostHandle > 0) then
  begin
    Visible := False;
    Left := 0;
    Top := 0;
    Width := 0;
    Height := 0;

    if Assigned(FPositionRequest) then
      FPositionRequest(Visible, Left, Top, Width, Height);

    if Visible then
      ShowCmd := SWP_SHOWWINDOW
    else
      ShowCmd := SWP_HIDEWINDOW;

    SetWindowPos(FIslandHandle, 0, Left, Top, Width, Height, ShowCmd + SWP_NOACTIVATE);
    SetWindowPos(FHostHandle, 0, 0, 0, Width, Height, ShowCmd + SWP_NOACTIVATE);
  end;
end;

end.
