$dsRegEx = [regex]"\[(\w+)\]"
$report = @()
get-vm | % {
	$vm = $_
    $vm.HardDisks | %{
		$row = "" | Select Name,MemoryMB,NUmCPU, Datastore, "Total Disk (Gb)"
		$row.Name = $vm.Name
		$row.MemoryMb = $vm.MemoryMb
		$row.NumCpu = $vm.NumCpu
		$row.Datastore = $dsRegEx.Match($_.Filename).Groups[1].Value
		$row.{Total Disk (Gb)} = "{0:N}" -f ($_.CapacityKB / 1Mb)
		$report += $row
	} 
}
$report | sort -property Name, datastore,"Total Disk" |Export-Csv "C:\chargeback.csv" -noTypeInformation
