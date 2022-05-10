# Directory where my powershell scripts are stored.
$psdir="C:\Users\rubin\Dropbox\Source\RAAF\scripts\power"

# Load the windows search helper function.
. $psdir\get-indexedItem.ps1

Get-IndexedItem $Args[0] | % { Write-Host $_.FullName }
