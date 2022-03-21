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

for ($num = 1 ; $num -le $loops ; $num++){
    Start-BitsTransfer -Source http://speedtest-sgp1.digitalocean.com/5gb.test -Destination d:\$num.bin
}

Start-Job -ScriptBlock `
{
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
