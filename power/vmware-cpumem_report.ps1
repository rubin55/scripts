# vmware-cpumem_report.ps1 - Report cpu and memory usage for all ESX hosts.


# Connect to Virtual Center.
connect-viserver 127.0.0.1

#Global variables.
$out = "vmware-hostreport_all.csv"
$share =  "\\somehost\someshare"
$vms = get-vm
$vmhs = get-vmhost
$report = @()

# Main body of work.
foreach ($vmh in $vmhs) {
    $nicename = $vmh | %{$_ -replace ".some.tld",""} | %{$_ -replace ".msi.cell",""}
    write-host "Updating $nicename entry in $out..."
	$hosts = get-vmhost $vmh.Name | %{get-view $_.ID}
	$row = "" | select-object Name, NumCpuCores, Hz, Memory, CpuUtil, MemUtil
	$row.Name = $nicename
	$row.NumCpuCores = $hosts.Hardware.CpuInfo.NumCpuCores
	$row.Hz = [math]::round(($hosts.Hardware.CpuInfo.Hz)/10000, 0)
	$row.Memory = [math]::round(($hosts.Hardware.MemorySize)/1024, 0)
	$row.CpuUtil = (get-stat -Entity $vmh -Stat cpu.usage.average -Realtime -MaxSamples 1 | where {$_.Instance -eq ""}).Value
	$row.MemUtil = (get-stat -Entity $vmh -Stat mem.usage.average -Realtime -MaxSamples 1).Value
	$report += $row

    $curstate = @()
    $meh= "" | select-object Date, Time, CpuUtil, Memutil
    $meh.Date = get-date -uformat "%Y-%m-%d"
    $meh.Time = get-date -uformat "%R:%S"
    $meh.CpuUtil = $row.CpuUtil
    $meh.MemUtil = $row.MemUtil
    $curstate += $meh

    $rhaah = "vmware-hostreport_$nicename.csv"
    $filexist = test-path $rhaah
    if ($filexist -eq $false) {
        write-host "Writing out host-specific data in $rhaah.."
        $curstate | export-csv $rhaah -noTypeInformation -encoding Unicode
    }
    else {
        write-host "Appending host-specific data in $rhaah..."
        $curstate | export-csv "$rhaah.tmp" -noTypeInformation -encoding Unicode
        $mystring = cat "$rhaah.tmp" | findstr /V Date
        $mystring | out-file -filepath "$rhaah" -append
        rm "$rhaah.tmp"
    }
    
}

# Write out results.
write-host "Writing out $out..."
$report | export-Csv $out -noTypeInformation -encoding Unicode
disconnect-viserver -confirm:$false

# Send report to some share
write-host "Sending csv data to $share"
cp *.csv $share\
