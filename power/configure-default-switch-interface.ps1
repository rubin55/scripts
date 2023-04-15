# Remove current IP address from default switch interface.
Get-NetIPAddress -InterfaceIndex (Get-NetAdapter -Name 'vEthernet (Default Switch)').ifIndex | Remove-NetIPAddress -Confirm:$false

# Set a specific IP address on default switch interface.
New-NetIPAddress -InterfaceAlias 'vEthernet (Default Switch)' -IPAddress '10.10.11.1' -PrefixLength 24

# Set the DNS server address for this interface to point to the previously configured IP address.
#Set-DnsClientServerAddress -InterfaceAlias 'vEthernet (Default Switch)' -ServerAddresses ("10.10.11.1")

# Remove any currently existing NAT setup.
Get-NetNat | Remove-NetNat -Confirm:$false

# Create a specific NAT setup matching the previously configured IP address.
New-NetNat -Name NAT -InternalIPInterfaceAddressPrefix 10.10.11.0/24

# Show the new configuration.
Get-NetAdapter -Name 'vEthernet (Default Switch)' | Get-NetIPAddress

# Tell the console we're done.
Pause "Press any key to continue..."
