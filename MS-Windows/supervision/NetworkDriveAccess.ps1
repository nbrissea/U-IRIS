################################################################################
# Script d'installation d'une tâche de surveillance WMI pour un processus      #
#                                                                              #
# 08/01/2019 - Nicolas Brisseau                                                #
# Desinstallation par la commande get-job -id | remove-job -force              #
################################################################################

$query = "Select * From Win32_ProcessStartTrace where processname = 'BTCHCLOT.exe'"
$action =
{
$Process = Get-Process -Name BTCHCLOT
$path =  W:\ULIS\EXE
if (test-path $path -eq FALSE)
{
    procmon.exe /AcceptEula /Quiet /Minimized /BackingFile “c:\temp\btchclot.pml”
    New-Event -SourceIdentifier BTCHCLOT -MessageData "Le processus $Process ne peut pas ouvrir $path"
}
}
Register-WMIEvent -query $query -SourceIdentifier "BTCHCLOT" –action $action
