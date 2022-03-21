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
Add-Content -Path D:\AntesDeScript.txt -Value "Someone was here"
Start-Job -ScriptBlock `
{
    Add-Content -Path D:\DentroDeStartJob.txt -Value "Someone was here"
    while ((Get-BitLockerVolume -MountPoint D:).VolumeStatus -eq "FullyDecrypted")
    {
    }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ((Get-BitLockerVolume -MountPoint D:).VolumeStatus -eq "FullyEncrypted")
    {
    }
    $sw.Stop()
    $sw.Elapsed
    $loops=5
    Add-Content -Path D:\Results.txt -Value "Total time elapsed to encrypt a disk with $($loops*5)GB in seconds: $($sw.Elapsed)"
}
