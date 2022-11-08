Function Check-DellHapi()
{
    $a = driverquery.exe /v /fo csv | ConvertFrom-CSV | Where {$_.'Module Name' -match 'Dcdbas'}
    
    if (! $a) {
        Write-Output "Dell HAPI driver is not installed on $env:COMPUTERNAME."
    }
    else {
        if (!($a.State -eq "Running"))
        {
            Write-Output "Dell HAPI driver is installed but not running on $env:COMPUTERNAME."
        }
        else
        {
             Write-Output "Dell HAPI driver is installed and running on $env:COMPUTERNAME."
        }
    }
}

Check-DellHapi