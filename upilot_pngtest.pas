unit uPilot_pngtest;
{$mode objfpc}{$h+}

interface
procedure PilotRestoreHostKernel;
procedure PilotCreateRamDisk;
procedure PilotGitHubFetch(FileNames:array of String);

implementation
uses
 {$ifdef CONTROLLER_QEMUVPB}               QEMUVersatilePB, {$endif}
 {$ifdef CONTROLLER_RPI_INCLUDING_RPI0}    RaspberryPi,     {$endif}
 {$ifdef CONTROLLER_RPI2_INCLUDING_RPI3}   RaspberryPi2,    {$endif}
 {$ifdef CONTROLLER_RPI3}                  RaspberryPi3,    {$endif}
 Classes,Console,GlobalConfig,GlobalConst,GlobalTypes,
 FATFS,FileSystem,Http,Platform,
 SysUtils,Threads,UltiboClasses,Ultibo,VirtualDisk;

const
 Seconds=1;
 MillisecondsPerSecond=1000;

procedure RenameFile2(Old,New:String);
begin
 if not RenameFile(Old,New) then
  begin
   WriteLn(Format('Could not rename %s to %s',[Old,New]));
   ThreadHalt(0);
  end;
end;

const
 KernelName='kernel.img';

procedure PilotRestoreHostKernel;
begin
 {$ifndef CONTROLLER_QEMUVPB}
  while not DirectoryExists('c:\') do
   Sleep(Round(0.1 * Seconds * MillisecondsPerSecond));
  DeleteFile(PChar(Format('c:\%s',[KernelName])));
  RenameFile2(Format('c:\%s.host',[KernelName]),Format('c:\%s',[KernelName]));
 {$endif}
end;

procedure PilotCreateRamDisk;
var
 ImageNo:Integer;
 Device:TDiskDevice;
 Volume:TDiskVolume;
// Drive:TDiskDrive;
begin
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
           FileSysDriver.GetDriveByVolume(Volume,False,FILESYS_LOCK_NONE);
//         if Drive <> nil then
//          begin
//           Log2(Format('Virtual disk %s',[Drive.Name]));
//          end;
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

end.
