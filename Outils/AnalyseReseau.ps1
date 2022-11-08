# =======================================================
# NAME: XXXXXX.ps1
# AUTHOR: Nom Prénom, Entreprise
# DATE: DD/MM/YYYY
#
# KEYWORDS: YYY, XXXXXXXXX , AAAAAA
# VERSION 1.X
# DD/MM/YYYY added help to the functions
# COMMENTS: Vérifications du réseau Local
# =======================================================

#Initialisation des variables
$list=@{}

#Fonctions
function Test-Port{   
<#     
.SYNOPSIS     
    Tests port on computer.   
     
.DESCRIPTION   
    Tests port on computer.  
      
.PARAMETER computer   
    Name of server to test the port connection on. 
       
.PARAMETER port   
    Port to test  
        
.PARAMETER tcp   
    Use tcp port  
       
.PARAMETER udp   
    Use udp port   
      
.PARAMETER UDPTimeOut  
    Sets a timeout for UDP port query. (In milliseconds, Default is 1000)   
       
.PARAMETER TCPTimeOut  
    Sets a timeout for TCP port query. (In milliseconds, Default is 1000) 
                  
.NOTES     
    Name: Test-Port.ps1   
    Author: Boe Prox   
    DateCreated: 18Aug2010    
    List of Ports: http://www.iana.org/assignments/port-numbers   
       
    To Do:   
        Add capability to run background jobs for each host to shorten the time to scan.          
.LINK     
    https://boeprox.wordpress.org  
      
.EXAMPLE     
    Test-Port -computer 'server' -port 80   
    Checks port 80 on server 'server' to see if it is listening   
     
.EXAMPLE     
    'server' | Test-Port -port 80   
    Checks port 80 on server 'server' to see if it is listening  
       
.EXAMPLE     
    Test-Port -computer @("server1","server2") -port 80   
    Checks port 80 on server1 and server2 to see if it is listening   
     
.EXAMPLE 
    Test-Port -comp dc1 -port 17 -udp -UDPtimeout 10000 
     
    Server   : dc1 
    Port     : 17 
    TypePort : UDP 
    Open     : True 
    Notes    : "My spelling is Wobbly.  It's good spelling but it Wobbles, and the letters 
            get in the wrong places." A. A. Milne (1882-1958) 
     
    Description 
    ----------- 
    Queries port 17 (qotd) on the UDP port and returns whether port is open or not 
        
.EXAMPLE     
    @("server1","server2") | Test-Port -port 80   
    Checks port 80 on server1 and server2 to see if it is listening   
       
.EXAMPLE     
    (Get-Content hosts.txt) | Test-Port -port 80   
    Checks port 80 on servers in host file to see if it is listening  
      
.EXAMPLE     
    Test-Port -computer (Get-Content hosts.txt) -port 80   
    Checks port 80 on servers in host file to see if it is listening  
         
.EXAMPLE     
    Test-Port -computer (Get-Content hosts.txt) -port @(1..59)   
    Checks a range of ports from 1-59 on all servers in the hosts.txt file       
             
#>    
[cmdletbinding(   
    DefaultParameterSetName = '',   
    ConfirmImpact = 'low'   
)]   
    Param(   
        [Parameter(   
            Mandatory = $True,   
            Position = 0,   
            ParameterSetName = '',   
            ValueFromPipeline = $True)]   
            [array]$computer,   
        [Parameter(   
            Position = 1,   
            Mandatory = $True,   
            ParameterSetName = '')]   
            [array]$port,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [int]$TCPtimeout=1000,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [int]$UDPtimeout=1000,              
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [switch]$TCP,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [switch]$UDP                                     
        )   
    Begin {   
        If (!$tcp -AND !$udp) {$tcp = $True}   
        #Typically you never do this, but in this case I felt it was for the benefit of the function   
        #as any errors will be noted in the output of the report           
        $ErrorActionPreference = "SilentlyContinue"   
        $report = @()   
    }   
    Process {      
        ForEach ($c in $computer) {   
            ForEach ($p in $port) {   
                If ($tcp) {     
                    #Create temporary holder    
                    $temp = "" | Select-Object Server, Port, TypePort, Open, Notes   
                    #Create object for connecting to port on computer   
                    $tcpobject = new-Object system.Net.Sockets.TcpClient   
                    #Connect to remote machine's port                 
                    $connect = $tcpobject.BeginConnect($c,$p,$null,$null)   
                    #Configure a timeout before quitting   
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)   
                    #If timeout   
                    If(!$wait) {   
                        #Close connection   
                        $tcpobject.Close()   
                        Write-Verbose "Connection Timeout"   
                        #Build report   
                        $temp.Server = $c   
                        $temp.Port = $p   
                        $temp.TypePort = "TCP"   
                        $temp.Open = "False"   
                        $temp.Notes = "Connection to Port Timed Out"   
                    } Else {   
                        $error.Clear()   
                        $tcpobject.EndConnect($connect) | out-Null   
                        #If error   
                        If($error[0]){   
                            #Begin making error more readable in report   
                            [string]$string = ($error[0].exception).message   
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()   
                            $failed = $true   
                        }   
                        #Close connection       
                        $tcpobject.Close()   
                        #If unable to query port to due failure   
                        If($failed){   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "False"   
                            $temp.Notes = "$message"   
                        } Else{   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "True"     
                            $temp.Notes = ""   
                        }   
                    }      
                    #Reset failed value   
                    $failed = $Null       
                    #Merge temp array with report               
                    $report += $temp   
                }       
                If ($udp) {   
                    #Create temporary holder    
                    $temp = "" | Select-Object Server, Port, TypePort, Open, Notes                                      
                    #Create object for connecting to port on computer   
                    $udpobject = new-Object system.Net.Sockets.Udpclient 
                    #Set a timeout on receiving message  
                    $udpobject.client.ReceiveTimeout = $UDPTimeout  
                    #Connect to remote machine's port                 
                    Write-Verbose "Making UDP connection to remote server"  
                    $udpobject.Connect("$c",$p)  
                    #Sends a message to the host to which you have connected.  
                    Write-Verbose "Sending message to remote host"  
                    $a = new-object system.text.asciiencoding  
                    $byte = $a.GetBytes("$(Get-Date)")  
                    [void]$udpobject.Send($byte,$byte.length)  
                    #IPEndPoint object will allow us to read datagrams sent from any source.   
                    Write-Verbose "Creating remote endpoint"  
                    $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)  
                    Try {  
                        #Blocks until a message returns on this socket from a remote host.  
                        Write-Verbose "Waiting for message return"  
                        $receivebytes = $udpobject.Receive([ref]$remoteendpoint)  
                        [string]$returndata = $a.GetString($receivebytes) 
                        If ($returndata) { 
                           Write-Verbose "Connection Successful"   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "UDP"   
                            $temp.Open = "True"   
                            $temp.Notes = $returndata    
                            $udpobject.close()    
                        }                        
                    } Catch {  
                        If ($Error[0].ToString() -match "\bRespond aformatFormat-Tableer a period of time\b") {  
                            #Close connection   
                            $udpobject.Close()   
                            #Make sure that the host is online and not a false positive that it is open  
                            If (Test-Connection -comp $c -count 1 -quiet) {  
                                Write-Verbose "Connection Open"   
                                #Build report   
                                $temp.Server = $c   
                                $temp.Port = $p   
                                $temp.TypePort = "UDP"   
                                $temp.Open = "True"   
                                $temp.Notes = ""  
                            } Else {  
                                <#  
                                It is possible that the host is not online or that the host is online,   
                                but ICMP is blocked by a firewall and this port is actually open.  
                                #>  
                                Write-Verbose "Host maybe unavailable"   
                                #Build report   
                                $temp.Server = $c   
                                $temp.Port = $p   
                                $temp.TypePort = "UDP"   
                                $temp.Open = "False"   
                                $temp.Notes = "Unable to verify if port is open or if host is unavailable."                                  
                            }                          
                        } ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) {  
                            #Close connection   
                            $udpobject.Close()   
                            Write-Verbose "Connection Timeout"   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "UDP"   
                            $temp.Open = "False"   
                            $temp.Notes = "Connection to Port Timed Out"                          
                        } Else {                       
                            $udpobject.close()  
                        }  
                    }      
                    #Merge temp array with report               
                    $report += $temp   
                }                                   
            }   
        }                   
    }   
    End {   
        #Generate Report   
        $report  
    } 
}
function Menu{
<#
 .SYNOPSIS
     Affiche un menu de choix
 .DESCRIPTION
     La fonction  retourne les valeurs entrées en liste sous forme de menu
 .PARAMETER $list
        list de valeurs au format system.string
  .NOTES
     Author : Nicolas Brisseau
     Requires : PowerShell Vx
 .EXAMPLE
     Menu $list
  #>
param(
[Parameter(Mandatory=$true)][System.Collections.ArrayList]$list 
)
$it=@{}
Clear-Host
For ($i=1;$i -le $list.count;$i++)
{
Write-Host "[$i]: $($list[$i-1])"
$it.add($i,$list[$i-1])
}
Write-Host "[0]: Exit"
$choix = Read-Host "Choisir une option"
}

#Script principal

$adapters=(Get-NetAdapter).InterfaceAliaS
$list=$adapters
Menu $list
if($choix -eq "0"){break}
Write-Host $choix
$choix1=$choix
$list='statut','Configuration','Test Réseau','Test Port','Retour menu principal'
Do{
menu $list
switch($choix)
{
        1 {get-netadapter $($adapters[$choix1-1])}
        2 {Get-NetIPAddress -InterfaceAlias $($adapters[$choix1-1])}
        3 {Get-NetTCPConnection -State Established| Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,state}
        4 {Test-Port}
        5 {menu $adapters}
}
pause
Clear-Host
}
until($choix -eq 0)






Write-Host "Etat des cartes reseaux"
Get-NetAdapter  |Select-Object InterfaceAlias,InterfaceDescription,AdminStatus,MacAddress,status

Get-NetIPInterface 

Get-WmiObject -Class Win32_Networkadapter -Filter (InterfaceAlias -eq "Ethernet")

Get-NetIPAddress | Sort-Object InterfaceIndex | Format-Table InterfaceIndex, InterfaceAlias, AddressFamily, IPAddress, PrefixLength –Autosize

Write-Host "Paramètres des cartes reseaux"
$ip=Get-NetAdapter | Get-NetIPAddress |Where-Object{$_.AddressFamily-eq 'IPv4' }| Select-Object InterfaceAlias,IpAddress
$ip.interfacealias

Get-NetAdapterAdvancedProperty
Get-NetAdapterBinding

Get-NetIPConfiguration | Select-Object *



Get-NetIPAddress | Select-Object InterfaceAlias,IpAddress


#Test d'accès ICMP, Port
1..10 | ForEach-Object { Test-NetConnection -ComputerName $compname -RemotePort $NumPort } | Format-Table -AutoSize
$ip=Get-NetAdapter | Get-NetIPAddress |Where-Object{$_.AddressFamily-eq 'IPv4' }| Select-Object InterfaceAlias,IpAddress
foreach ($iptest in $ip.ipaddress){
$result= Test-NetConnection $iptest | Select-Object ComputerName,PingSucceeded |Select-obSelect-Object-String -Pattern True
Write-output $result
}

