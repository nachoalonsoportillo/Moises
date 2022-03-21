param (
    [int]$loops
)

$CdRomDriveLetter = "F:"
$CdRomCurrentLetter = (Get-WmiObject -Class Win32_CDROMDrive).Drive
$CdRomVolumeName = mountvol $CdRomCurrentLetter /l
$CdRomVolumeName = $CdRomVolumeName.Trim()
mountvol $CdRomCurrentLetter /d
mountvol $CdRomDriveLetter $CdRomVolumeName

$PartitionStyle = (Get-Disk | Where Number -eq 1).PartitionStyle
if ($PartitionStyle -ne "MBR"){
    Get-Disk |
    Where Number -eq 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -AssignDriveLetter -UseMaximumSize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data Drive" -Confirm:$false    
}

if ($loops -ge 1){
    Start-BitsTransfer -Source http://speedtest-sgp1.digitalocean.com/5gb.test -Destination d:\1.bin
}

for ($num = 2 ; $num -le $loops ; $num++){
    Copy-Item -Path d:\1.bin -Destination d:\$num.bin
}

$LogonScript = @'
    Start-Transcript -Path D:\StartupScript.log
    while ((Get-BitLockerVolume -MountPoint D:).VolumeStatus -eq "FullyDecrypted")
    {
    }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ((Get-BitLockerVolume -MountPoint D:).VolumeStatus -ne "FullyEncrypted")
    {
    }
    $sw.Stop()
    Add-Content -Path D:\Results.txt -Value "Total time elapsed to encrypt the data disk in seconds: $($sw.Elapsed)"

    Unregister-ScheduledTask -TaskName "StartupScript" -Confirm:$False
'@ > D:\StartupScript.ps1

$Trigger = New-ScheduledTaskTrigger -AtStartup
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument 'D:\StartupScript.ps1'
Register-ScheduledTask -TaskName "StartupScript" -Trigger $Trigger -User "NT AUTHORITY\SYSTEM" -Action $Action -RunLevel "Highest" -Force
