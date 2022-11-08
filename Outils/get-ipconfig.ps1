# ==========================================================

# Get-IPConfig.ps1

# Made By : Assaf Miron

#  http://assaf.miron.googlepages.com

# Description : Formats the IP Config information into powershell

# ==========================================================



function Get-IPConfig{

param ( $RemoteComputer="LocalHost",

 $OnlyConnectedNetworkAdapters=$true

   )
     

Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $RemoteComputer | Where-Object { $_.IPEnabled -eq $OnlyConnectedNetworkAdapters } | Format-List @{ Label="Computer Name"; Expression= { $_.__SERVER }}, IPEnabled, Description, MACAddress, IPAddress, IPSubnet, DefaultIPGateway, DHCPEnabled, DHCPServer, @{ Label="DHCP Lease Expires"; Expression= { [dateTime]$_.DHCPLeaseExpires }}, @{ Label="DHCP Lease Obtained"; Expression= { [dateTime]$_.DHCPLeaseObtained }}


} 