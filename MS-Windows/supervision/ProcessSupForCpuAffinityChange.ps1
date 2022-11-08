################################################################################
# Script d'installation d'une tâche de surveillance WMI pour un processus donné#
# L'action change l'affinité processeur du process pour libérer le core 0      #
# 08/01/2019 - Nicolas Brisseau                                                #
# Desinstallation par la commande get-job -id | remove-job -force
################################################################################

$query = "Select * From Win32_ProcessStartTrace where processname = 'BlackboxTCP4.exe'"
$action =
{
$Process = Get-Process -Name BlackboxTCP4
$ProcessAffinity =  $Process|select -ExpandProperty ProcessorAffinity
if ($ProcessAffinity -eq 255)
{
    $Process.ProcessorAffinity = 254
    New-Event -SourceIdentifier Notepad -MessageData "L'affinité CPU a été modifiée pour le processus $Process par le job wmi $process"
}
}
Register-WMIEvent -query $query -SourceIdentifier "BlackboxTCP4" –action $action
