$adapter="*"
 # you can specify what type of adapter you want to make changes to like Wireless or Wired
 # depending on adapter name or use * for all
 $adapters = Get-NetAdapter -name $adapter
 Write-Host "Found $($adapters.Length) adapters"
 foreach ($adapter in $adapters){
     $adName = $adapter.Name
     Write-Host "Working on: $adName"
     $adBindings = Get-NetAdapterBinding -name $adName
     foreach ($adbind in $adBindings){
        Write-Host $adbind.ComponentID
        if ($adbind.ComponentID -eq "ms_tcpip6" -and $adbind.Enabled -eq $true){
           Write-Host "Disabling IPv6 on $adName"
           Set-NetAdapterBinding -Name $adName -ComponentID ms_tcpip6 -Enabled $false
        }
     }
 }
