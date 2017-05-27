program PNGTest; {$mode objfpc}{$H+}

uses QEMUVersatilePB,PlatformQemuVpb,VersatilePB,
 GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,SysUtils,Console,
 GraphicsConsole,FrameBuffer,uCanvas;

var Console1,Console2:TWindowHandle;FrameProps:TFrameBufferProperties;Canvas:TCanvas;cRect:TConsoleRect;

/////////////////////////////////////////////////////////////////////////
procedure TestFillAndDraw;
begin
 ConsoleWindowWriteLn(Console1,'test QEMU uCanvas.pas TCanvas.Fill and TCanvas.Draw');
 ConsoleWindowWriteLn(Console1,'right window should be filled with green');
 cRect:=GraphicsWindowGetRect(Console2);
 Canvas.SetSize(cRect.X2 - cRect.X1,cRect.Y2 - cRect.Y1,FrameProps.Format);
 Canvas.Fill(COLOR_GREEN);
// Canvas.Draw(FramebufferDeviceGetDefault,(FrameProps.PhysicalWidth div 2) + 2,(FrameProps.PhysicalHeight div 2) + 2);
 GraphicsWindowDrawImage(Console2,0,0,Canvas.Buffer,Canvas.Width,Canvas.Height,Canvas.ColourFormat);
end;
/////////////////////////////////////////////////////////////////////////

procedure Main;
begin
  Console1:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_LEFT,True);
  Console2:=GraphicsWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_RIGHT);
  ConsoleWindowWriteLn(Console1,'program start');
  Canvas:=TCanvas.Create;
  FramebufferDeviceGetProperties(FramebufferDeviceGetDefault,@FrameProps);
  ConsoleWindowWriteLn(Console1,'Buffer Colour Format ' + FrameProps.Format.ToString + ' Depth ' + FrameProps.Depth.ToString + ' Size ' + Frameprops.Size.ToString);
  ConsoleWindowWriteLn(Console1,'Buffer Width ' + FrameProps.PhysicalWidth.ToString + ' Height ' + FrameProps.PhysicalHeight.ToString);
  TestFillAndDraw;
  ConsoleWindowWriteLn(Console1,'program stop');
  ThreadHalt(0);
end;

begin try Main; except on E:Exception do ConsoleWindowWriteLn(Console1,Format('Exception %s',[E.Message])); end;
end.
