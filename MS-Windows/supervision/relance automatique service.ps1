$serviceName = 'Audiosrv'
$query = "Select * From __InstanceOperationEvent
          within 3 
          Where TargetInstance ISA 'Win32_service'
          AND TargetInstance.Name='$serviceName'" 
$action = 
{
    if ( (Get-Service $serviceName).Status -ne 'running' )
    {
        Write-Warning "Démarrage du service $serviceName"

        Start-Service $serviceName
    }
} 
Register-WMIEvent -query $query -sourceIdentifier "ArretService" –action $action