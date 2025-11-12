#Specify a path to the ISO file:
$imagePath = $(Write-Host -NoNewLine) + $(Write-Host "`n`rPath to the source ISO file: " -ForegroundColor Green -NoNewLine; Read-Host)
$imagePath = $imagePath.Trim('"')

#Mount the ISO image:
$Report = @()
Mount-DiskImage -ImagePath $imagePath | Out-Null
$iSOImage = Get-DiskImage -ImagePath $imagePath | Get-Volume
$iSODrive = "$([string]$iSOImage.DriveLetter):"

#Then get the information about Windows versions in install.wim or install.esd:
$winImages = Get-windowsimage -ImagePath "$iSODrive\sources\install.wim”
Foreach ($winImage in $winImages) {
    $curImage=Get-WindowsImage -ImagePath "$iSODrive\sources\install.wim” -Index $WinImage.ImageIndex
    $objImage = [PSCustomObject]@{
        ImageIndex = $curImage.ImageIndex
        ImageName = $curImage.ImageName
        Version = $curImage.Version
        Languages=$curImage.Languages
        Architecture =$curImage.Architecture
    }
$Report += $objImage
}

#Unmount the ISO image:
Dismount-DiskImage -ImagePath $imagePath | Out-Null

#You can display the result in the Out-GridView table:
$Report | Format-Table
#$Report  | Out-GridView
