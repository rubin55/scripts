# Before attempting to run this script, review and/or follow the
# following steps.
#
# 0. Make sure you can execute powershell scripts. Start Powershell as an
#    administrator and execute:
#
#      Set-ExecutionPolicy RemoteSigned
#
# 1. Make sure the InterfaceMetric on your VPN/Tun/Tap network devices are lower
#    than the InterfaceMetric on your main Ethernet/WiFi interface, thus making
#    them higher priority. First list your interfaces:
#
#      Get-NetIPInterface -AddressFamily IPv4 | Where-Object ConnectionState -EQ 'Connected' | Where-Object NlMtu -LT 9001
#
#    The first number in the table is the interace's index number. Note the one
#    for your VPN/Tun/Tap adapter and set the metric to something lower (meaning
#    higher priority) than your main ethernet/wi-fi interface, for example:
#
#      Set-NetIPInterface -InterfaceIndex 34 -InterfaceMetric 15
#
# 2. Make sure you disable wsl's broken resolv.conf handler.
#    Create /etc/wsl.conf with the following 2 lines (without the pound signs):
#
#      [network]
#      generateResolvConf = false
#
#    After that, make sure you issue a wsl.exe --shutdown.
#
# 3. Configure your WSL distro name in $WslDistroName below (do wsl -l to
#    see your distro names) and make sure we're pointing at your resolv.conf
#    file in $ResolvConfFile. Also make sure we can write to the resolv.conf
#    file. I had to set permissions pretty broadly at 666 (chmod 666 /etc/resolv.conf).
#
# 4. Schedule this script with Task Scheduler:
#
#      * Click Action –> Create Task…
#      * Give your task a name in the General tab
#      * Click on the Triggers tab and then click New…
#      * In the "Begin the task" menu, choose “On an event.” Then, choose:
#
#          Log: Microsoft-Windows-NetworkProfile/Operational
#          Source: NetworkProfile
#          Event ID: 10000
#
#      * Event ID 10000 is logged when you connect to a network. Add another
#        one when a disconnect would occur (Event ID 10001):
#
#          Log: Microsoft-Windows-NetworkProfile/Operational
#          Source: NetworkProfile
#          Event ID: 10001
#
#      * Go to the Conditions tab. Make sure it runs regardless of AC adapter
#        connected/disconnected, peruse the other options there.
#
#      * Go to the Actions tab. Add a run script action and then:
#
#          Program/script: powershell.exe
#          Arguments: -WindowStyle Hidden -NoProfile -File "c:\where\you\stored\wsl-resolv-handler.ps1"
#

$WslDistroName = "Debian"
$ResolvConfFile = [string]::Format("\\wsl$\{0}\etc\resolv.conf", $WslDistroName)

if(!(Test-Path -Path $ResolvConfFile)) {
  Write-Host "Path not available: $ResolvConfFile"
  Write-Host "Aborting..."
  Exit
}

function Convert-To-UnixLineEndings($path) {
  $oldBytes = [io.file]::ReadAllBytes($path)
  if (!$oldBytes.Length) {
      return;
  }
  [byte[]]$newBytes = @()
  [byte[]]::Resize([ref]$newBytes, $oldBytes.Length)
  $newLength = 0
  for ($i = 0; $i -lt $oldBytes.Length - 1; $i++) {
      if (($oldBytes[$i] -eq [byte][char]"`r") -and ($oldBytes[$i + 1] -eq [byte][char]"`n")) {
          continue;
      }
      $newBytes[$newLength++] = $oldBytes[$i]
  }
  $newBytes[$newLength++] = $oldBytes[$oldBytes.Length - 1]
  [byte[]]::Resize([ref]$newBytes, $newLength)
  [io.file]::WriteAllBytes($path, $newBytes)
}

Function Pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Discover things and create an $Entries object.
$NetworkInterfaces  = Get-NetIPInterface -AddressFamily IPv4 | Where-Object ConnectionState -EQ 'Connected' | Where-Object NlMtu -LT 9001
$DNSServerAddresses = Get-DnsClientServerAddress -AddressFamily IPv4
$DNSClients = Get-DnsClient

$Entries = $NetworkInterfaces | ForEach-Object {
  [PSCustomObject]@{
    'InterfaceAlias'      = $_.InterfaceAlias
    'InterfaceIndex'      = $_.InterfaceIndex
    'InterfaceMetric'     = $_.InterfaceMetric
    'DNSServerAddresses'  = ($DNSServerAddresses | Where-Object InterfaceIndex -EQ $_.InterfaceIndex | Where-Object AddressFamily -EQ 2).ServerAddresses | Where-Object { $_ -and $_.Trim() }
    'DNSSuffixes'  =  @(($DNSClients | Where-Object InterfaceIndex -EQ $_.InterfaceIndex).ConnectionSpecificSuffix) + @(($DNSClients).ConnectionSpecificSuffixSearchList | Out-Null) | Where-Object { $_ -and $_.Trim() }
  }
} | Sort-Object InterfaceMetric,InterfaceIndex -Unique

# Tell the console what we found.
Write-Output ([string]::Format("      Resolv.conf location: {0}", $ResolvConfFile))
Write-Output ([string]::Format("    DNS servers configured: {0}", ($Entries.DNSServerAddresses -join ",")))
if ($Entries.DNSSuffixes -gt 0) {
    Write-Output ([string]::Format("Search suffixes configured: {0}", ($Entries.DNSSuffixes -join ",")))
}

# Writing resolv.conf with things discovered.
$CommentLine = [string]::Format("# Generated by wsl-resolv-handler.ps1.")
Write-Output $CommentLine | Set-Content -Path $ResolvConfFile
if ($Entries.DNSSuffixes -gt 0) {
    $SearchLine = [string]::Format("search {0}", ($Entries.DNSSuffixes -join " "))
}
Write-Output $SearchLine | Add-Content -Path $ResolvConfFile
$Entries | ForEach-Object {
  $_.DNSServerAddresses | ForEach-Object {
    $NameServerLine = [string]::Format("nameserver {0}", $_)
    Write-Output $NameServerLine | Add-Content -Path $ResolvConfFile
  }
}

# Make sure where UNIXy.
Convert-To-UnixLineEndings $ResolvConfFile

# Tell the console we're done.
Pause "Press any key to continue..."
