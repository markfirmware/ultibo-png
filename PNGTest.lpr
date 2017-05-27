program PNGTest;
{$mode objfpc}{$H+}
{$define use_tftp}

uses
 {$ifdef CONTROLLER_QEMUVPB}             QEMUVersatilePB,PlatformQemuVpb,VersatilePB, {$endif}
 {$ifdef CONTROLLER_RPI_INCLUDING_RPI0}  BCM2835,BCM2708,PlatformRPi,                 {$endif}
 {$ifdef CONTROLLER_RPI2_INCLUDING_RPI3} BCM2836,BCM2709,PlatformRPi2,                {$endif}
 {$ifdef CONTROLLER_RPI3}                BCM2837,BCM2710,PlatformRPi3,                {$endif}
  GlobalConfig, GlobalConst, GlobalTypes, Platform, Threads, SysUtils, Console,
  GraphicsConsole, Classes, uLog, UltiboClasses, Http, FATFS,FileSystem,VirtualDisk,
  FrameBuffer, uFontInfo, freetypeh,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  Ultibo, uCanvas;

const
 Seconds=1;
 MillisecondsPerSecond=1000;

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
{$ifdef use_tftp}
  IPAddress : string;
{$endif}
  FBFormat : LongWord;
  FrameProps : TFrameBufferProperties;
  Canvas : TCanvas;
  DefFrameBuff : PFrameBufferDevice;
  Rect : Ultibo.TRect;
  cRect : TConsoleRect;
  s : string;

procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 ('TFTP - ' + s);
end;

procedure WaitForSDDrive;
begin
  while not DirectoryExists ('C:\') do sleep (500);
end;

procedure PilotCreateRamDisk;
var
 ImageNo:Integer;
 Device:TDiskDevice;
 Volume:TDiskVolume;
 Drive:TDiskDrive;
begin
 ConsoleWriteLn('Create ram disk ...');
 ImageNo:=FileSysDriver.CreateImage(0,'RAM Disk',itMEMORY,mtREMOVABLE,ftUNKNOWN,iaDisk or iaReadable or iaWriteable,512,20480,0,0,0,pidUnused);
 if ImageNo <> 0 then
  begin
   if FileSysDriver.MountImage(ImageNo) then
    begin
     Device:=FileSysDriver.GetDeviceByImage(FileSysDriver.GetImageByNo(ImageNo,False,FILESYS_LOCK_NONE),False,FILESYS_LOCK_NONE);
     if Device <> nil then
      begin
       Volume:=FileSysDriver.GetVolumeByDevice(Device,False,FILESYS_LOCK_NONE);
       if Volume <> nil then
        begin
         if FileSysDriver.FormatVolume(Volume.Name,ftUNKNOWN,fsFAT12) then
          begin
           Drive:=FileSysDriver.GetDriveByVolume(Volume,False,FILESYS_LOCK_NONE);
           if Drive <> nil then
            begin
             ConsoleWriteLn(Format('Virtual disk %s',[Drive.Name]));
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure PilotGitHubFetch(FileNames:array of String);
var
 I:Cardinal;
 FileName,Url:String;
 FileStream:TFileStream;
 Client:THTTPClient;
begin
 for I:=Low(FileNames) to High(FileNames) do
  begin
   Client:=THTTPClient.Create;
   FileName:=FileNames[I];
   FileStream:=TFileStream.Create(FileName,fmCreate);
   try
    Url:=Format('http://45.79.200.166:7000/github.com/markfirmware/ultibo-png/%s',[FileName]);
    if not Client.GetStream(Url,FileStream) then
     raise Exception.Create(Format('Could not fetch %s',[Url]));
   finally
    FileStream.Free;
    Client.Free;
   end;
  end;
end;

{$ifdef use_tftp}
function WaitForIPComplete : string;
var
  TCP : TWinsock2TCPClient;
begin
  TCP := TWinsock2TCPClient.Create;
  Result := TCP.LocalAddress;
  if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
        begin
          sleep (1000);
          Result := TCP.LocalAddress;
        end;
    end;
  TCP.Free;
end;
{$endif}

procedure Main;
begin
  Sleep(3 * 1000);
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := GraphicsWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT);
  SetLogProc (@Log1);
  Log1 ('Animated PNG Test. Uses my own version of TCanvas.');
  {$ifdef CONTROLLER_QEMUVPB}
   PilotCreateRamDisk;
   WaitForIPComplete;
   Log1('Fetching ttf files');
   PilotGitHubFetch(['arial.ttf']);
  {$endif}
  WaitForSDDrive;

{$ifdef use_tftp}
  IPAddress := WaitForIPComplete;
  Log2 ('TFTP - Enabled - Syntax "tftp -i ' + IPAddress + ' PUT kernel7.img"');
  SetOnMsg (@Msg2);
  Log2 ('');
{$endif}

  DefFrameBuff := FramebufferDeviceGetDefault;
  Canvas := TCanvas.Create;
  FrameProps.Size := 0;
  FBFormat := COLOR_FORMAT_UNKNOWN;
  if FramebufferDeviceGetProperties (DefFrameBuff, @FrameProps) = ERROR_SUCCESS then
    begin
      Log ('Buffer Colour Format ' + FrameProps.Format.ToString + ' Depth ' + FrameProps.Depth.ToString + ' Size ' + Frameprops.Size.ToString);
      Log ('Buffer Width ' + FrameProps.PhysicalWidth.ToString + ' Height ' + FrameProps.PhysicalHeight.ToString);
      FBFormat := FrameProps.Format;
    end
  else
    Log ('failed to get props');
  cRect := GraphicsWindowGetRect (Console3);
  Canvas.SetSize (cRect.X2 - cRect.X1, cRect.Y2 - cRect.Y1, FBFormat);

  s := 'In front and behind gears.';

  Log2 ('Commands...');
  Log2 ('  1  Start.');
  Log2 ('  2  Stop.');
  Log2 ('  m  Draw text.');
  Log2 ('');

  ch := #0;
  while true do
    begin
      if ConsoleGetKey (ch, nil) then
       begin
        Log1(Format('key %s',[ch]));
        case (ch) of
          'M', 'm' :
            begin
              Canvas.Fill (COLOR_GREEN);
              Rect := SetRect (30, 0, 30 + 80, 60);
              Canvas.Fill (Rect, COLOR_RED);
              Rect := SetRect (39, 40, 30 + 39, 20 + 40);
              Canvas.Fill (Rect, COLOR_BROWN);
              Canvas.DrawText (20, 20, 'How is it going', 'arial', 24, COLOR_BLUE);
              Log1('Canvas.Draw');
//            Canvas.Draw (DefFrameBuff, (FrameProps.PhysicalWidth div 2) + 2, (FrameProps.PhysicalHeight div 2) + 2);
              GraphicsWindowDrawImage(Console3,0,0,Canvas.Buffer,Canvas.Width,Canvas.Height,Canvas.ColourFormat);
            end;
        end;
      end;
    end;
  ThreadHalt (0);
end;

begin
 try
  Main;
 except on E:Exception do
  begin
   Log2(Format('Exception %s',[E.Message]));
  end;
 end;
end.
