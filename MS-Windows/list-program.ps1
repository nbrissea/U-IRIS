Clear
Write-host "Récupération de la liste des logiciels (Ctrl +C) pour annuler"
Wait-Event -Timeout 10
$ErrorActionPreference='SilentlyContinue'
$txt=$env:USERPROFILE+'\Desktop\logiciels.txt'
$path='HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
$keys=Get-ChildItem -path $path
ForEach($key in $Keys)
{
        $tmp=$path+'\'+$key.PSChildName
        Get-ItemProperty -Path $tmp |Select DisplayName,DisplayVersion|ForEach{
            If($_.DisplayName -ne $null)
            {
                $value='32 bit : '+$_.DisplayName+' '+$_.DisplayVersion
                Add-Content -Path $txt -Value $value
            }
        }
}
$path='HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$keys=Get-ChildItem -path $path
ForEach($key in $Keys)
{
        $tmp=$path+'\'+$key.PSChildName
        Get-ItemProperty -Path $tmp |Select DisplayName,DisplayVersion|ForEach{
            If($_.DisplayName -ne $null)
            {
                $value='64 bit : '+$_.DisplayName+' '+$_.DisplayVersion
                Add-Content -Path $txt -Value $value
            }
        }
}
Get-Content $txt
Write-Host "Fichier de sortie : $txt"
