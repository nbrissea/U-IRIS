<# Script de suppression d'une VM en Cluster Hyper-V U Store Box
Création : 15/09/2022 - NBR
Environnement : A executer sur un serveur RSATPDV du domaine de recette
Arguments: -
#>

# on teste l'environnement d'execution
Add-Type -AssemblyName PresentationCore, PresentationFramework
if ($env:USERDOMAIN -ne "recad-u"){
    [System.Windows.MessageBox]::Show('le script est à lancer sur un serveur RSAT du domaine RECAD-U')
    exit
    }

## Variables communes
$computer=Read-Host "ordinateur du domaine $env:USERDNSDOMAIN à supprimer du cluster U Store Box:"
$ccu=$computer.Substring(0,5)
$base11=$ccu+"BASE11"
$base12=$ccu+"BASE12"
$Cluster=$ccu+"clus11"

if ((get-vm -ComputerName $base11).Name -eq $computer){
    Write-Output "le serveur est hebergé sur $base11"
    $VMHost=$base11
    }Elseif ((get-vm -ComputerName $base12).Name -eq $computer){
            Write-Output "le serveur est hebergé sur $base12"
            $VMHost=$base12
            }else {
                Write-Output "Le serveur hôte n'a pas été trouvé"
                break
                }

<## suppresion de la préparation du site
# Problème de suppression des clés dans la base de données !!!
try {
    $session=New-PSSession -ComputerName 30000web01
    Start-Sleep 10
    $sqlqryresult=Invoke-Command -ComputerName $session.ComputerName -ArgumentList $computer -ScriptBlock{param($computer); sqlcmd -s localhost\30000web01 -d prepausb -q "select IdPreparation from prepa_serveur where (NomServeur='$computer')"} 
    $IdPrepa = $sqlqryresult[2].Trim()
    Invoke-Command -ComputerName $session.ComputerName -ArgumentList $IdPrepa -ScriptBlock{powershell D:\SCRIPTS\DelPrepaDiffusion.ps1 $IdPrepa | out-host}
    Remove-PSSession $session
    Write-Output "Suppression de la préparation OK"
}
catch {
    write-output "Problème lors de la suppression des données du site de prépa"
    [System.Windows.MessageBox]::Show($Error.Message)
}
#>

## Suppression tâche sauvegarde Hyper-V
$nbcar=$computer.Length - $ccu.Length
$taskfilter=$computer.Substring($computer.Length-$nbcar)
$schtask=(Get-ScheduledTask -CimSession $VMHost).TaskName -like "*$taskfilter"
Unregister-ScheduledTask -CimSession $VMHost -TaskName $schtask
Write-Output "Tâche planifiée $schtask supprimée !"

#Suppression des lignes dans le fichier INI de la sauvegarde
$inifile=$null
$svgconfigpath="\\$VMHost\c$\Masterisation\AdminTools\VMBackup\VMBackupParams.ini"
    if (Test-Path $svgconfigpath){
        $linestart=(Select-String -Pattern "$computer" -Path $svgconfigpath).LineNumber
    }elseif ($null -ne $linestart){ 
        $inifile=Select-String "[$computer]" -Path $svgconfigpath | Where-Object {($_.LineNumber -ge $linestart+7) -or ($_.linenumber -lt $linestart)}
        Set-Content -Path $svgconfigpath -Value ($inifile).line
    }Else { 
    Write-Output "le fichier n'a pas de configuration pour $computer"
    }

## Check snapshot et suppression si necessaire
Try {
    Write-Output "Recherche existance snapshot ..."
    $snapshot=(Get-VMSnapshot -VMName $computer -CimSession $VMHost |Sort-Object -Descending).Name[0]
    Get-VMSnapshot -Name $snapshot -VMName $computer -CimSession $VMHost
    Write-output "Appliquer le dernier snapshot $snapshot Demande de confirmation ..."
    start-sleep 5
    Remove-VMSnapshot -VMName $computer -CimSession $VMHost -IncludeAllChildSnapshots -Confirm
    
    
}catch{
    Write-Output "Snapshot non trouvé : KO"
    }

## Arrêt VM
get-vm -Name $computer -CimSession $VMHost|Stop-VM -TurnOff
## suppresion VM du cluster

$ressourcename=(Get-Clustergroup -Cluster $Cluster).name -eq $computer
Remove-ClusterGroup -Cluster $Cluster -Name $ressourcename -RemoveResources -Verbose

## supression VM de l'hyperviseur
get-VM -Name $computer -CimSession $VMHost
Remove-VM -Name $computer -CimSession $VMHost

## supression du répertoire de stockage résiduel
$path=(Get-ChildItem -Path "\\$VMHost\c$\ClusterStorage" -Recurse -Filter $computer).FullName
remove-item -Recurse -Path $path

## Suppression du compte Ordinateur 
Try {
    Get-ADComputer -Identity $computer
    Write-Output "Enregistrement trouvé. Demande de confirmation ...Répondre 'oui pour tous'"
    Start-Sleep 5
    Remove-ADComputer -Identity $computer -Server recad.pdv-u.fr -TurnOff
    
}
catch {
    Write-Output "Enregistrement non trouvé : KO"
}

## Suppression de l'enregistrement DNS
$dnsserver = (Get-DnsClientServerAddress).ServerAddresses[0]
$DNSRecord = Get-DnsServerResourceRecord -ComputerName $dnsserver -zonename $env:USERDNSDOMAIN -RRType "A" -name $computer
if ($DNSRecord) {
    $DNSRecord
    Write-Output "Enregistrement trouvé. Demande de confirmation ..."
    Start-Sleep 5
    Remove-DnsServerResourceRecord -ComputerName $dnsserver -zonename $env:USERDNSDOMAIN -RRType "A" -name $computer

}
else { Write-Output "Aucun enregistrement trouvé dans $env:USERDNSDOMAIN pour $computer" }




[System.Windows.MessageBox]::Show('Prévoir de supprimer les entrées sous Ivanti, WSUS01  et sentinel')


