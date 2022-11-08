# ==========================================================
# Get-IPConfig.ps1
# Auteur : Nicolas Brisseau
# Description : Présente les informations IP d'un ordinateur du réseau
# ==========================================================

function Get-IPConfig{
  param ( 
    [String]$RemoteComputer='localhost',
    $OnlyConnectedNetworkAdapters=$true
  )
  Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $RemoteComputer -Credential | Where-Object { $_.IPEnabled -eq $OnlyConnectedNetworkAdapters } | Format-List @{ Label="Computer Name"; Expression= { $_.__SERVER }}, IPEnabled, Description, MACAddress, IPAddress, IPSubnet, DefaultIPGateway, DHCPEnabled, DHCPServer, @{ Label="DHCP Lease Expires"; Expression= { [dateTime]$_.DHCPLeaseExpires }}, @{ Label="DHCP Lease Obtained"; Expression= { [dateTime]$_.DHCPLeaseObtained }}
} 
Get-IPConfig