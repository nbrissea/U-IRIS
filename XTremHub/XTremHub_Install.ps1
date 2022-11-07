#==========================================================================
# NOM			: XTremHub_Install.ps1
# SOCIETE		: U-GIE-IRIS
# VERSIONS		: 1.0 - 08/09/2022 - Creation du Script - NBR
#               
#
# DESCRIPTION	: Installation de XTremHub
# ARGUMENTS		: -
#==========================================================================
#							CODE COMMUN
#==========================================================================


# Se positionne dans le répertoire du script pour installation en manuelle
Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Chargement des modules PowerShell

$ErrorActionPreference = "Stop"
Try {
    Foreach ($module in @("Tools","Registry")) {
        If (Get-Module $module) {
            Remove-Module $module
        }
	Import-Module "..\..\Modules\${module}.psm1"
    }
} Catch {
    Write-Host ("/!\\ Erreur lors du chargement des modules ") 
	Exit 1
}

$ErrorActionPreference = "Continue"
$StrFollowkeyPath   = "HKLM:\SOFTWARE\U-MOTEUR\MOTEUR\Follow"
$StrPathKeySI       = "HKLM:\SOFTWARE\U-MOTEUR\MOTEUR"
$StrPathKey         = "HKLM:\SOFTWARE\U-MOTEUR"
$MystrRegKeyName = "Statut"

#==========================================================================
#				CODE SPECIFIQUE
#==========================================================================

$etape = "Installation de l'agent XTremHub"

#### Declaration des fonctions
# Fonction de d'ecriture dans le fichier de log #
function Write-Log($Msg){ 
    #Ajoute la chaine $Msg au fichier de log
	$date = Get-Date -format dd.MM.yyyy  
	$time = Get-Date -format HH:mm:ss  
	Add-Content -Path $LogFile -Value ($date + " " + $time + "   " + $Msg) 
}

## fonction de Test d'existence cle registre
function FTestKeyRegistry($strRegKey,$strRegKeyName) {
    $val = Get-Item -LiteralPath $strRegKey -ErrorAction SilentlyContinue
    $val -and $null -ne $val.GetValue($strRegKeyName, $null)
}

## Fonction de creation du chemin de registre LANDESK
Function InitRegPath ($RegPath) {
if (-not (test-path $RegPath))
 { 
  Write-Output "Tentative de creation de la cle de registre $RegPath" 2>&1
  New-Item -Itemtype Directory -Path $RegPath | Out-null
  if (test-path $RegPath)
	{Write-Output "Creation de la cle de registre $RegPath : OK" }
	else 
	{Write-Output "Creation de la cle de registre $RegPath : KO" }
}
else {Write-Output "La cle de registre $RegPath existe dejà !! " }
}

## Fonction de creation de la cle de registre dans le chemin de registre LANDESK
Function InitKeyPath ($RegPath,$KeyPath,$keyValue){

# Test de presence de la propriete 
If ( FTestKeyRegistry $RegPath $KeyPath)
	{ 	
	   Set-ItemProperty -Path $RegPath -Name $KeyPath -Value "$($keyValue)"   | Out-null
	   Write-Output "La propriete $($RegPath)\$($KeyPath) a ete mise à $($keyValue)"
	}
else 
	{ 
       New-ItemProperty -Path $RegPath -Name $KeyPath -Value "$($keyValue)"  | Out-null
	   Write-Output "La propriete $($RegPath)\$($KeyPath) a ete creee à $($keyValue)"
	}
}

##Fonction No Install 
Function EXEC_ETAPE0 {
	Write-output "Cet Ordinateur n'est pas éligible à l'installation (VM Tech ad.pdv-u)"
    $global:EXITCODE = 0
	Return $global:EXITCODE
}

##Fonction d'installation de l'agent 
Function EXEC_ETAPE1 {
	Try {
		    Start-Process  -FilePath "$($MyPath)MCAgent.exe"
			Write-Output "Installation en cours ... Attente 5min"
			Start-Sleep -Seconds 300
			$global:EXITCODE = 0
    }	
	Catch {
		Write-Output "Erreur lors du lancement de MCAgent.exe : KO"
		$global:EXITCODE = 1
	}
	Return $global:EXITCODE
}

## Fonction de vérification de l'installation 
Function EXEC_ETAPE2 {
	Try {
		if ((Get-Service -Name MCAgent -ErrorAction SilentlyContinue).status -eq "Running"){
			Write-Output "Service MCAgent lancé"
			Write-Output $MCAgent
			$global:EXITCODE = 0
		}
		else {
			Write-Output "Erreur lors de l'installation du service MCAgent : KO"
			$global:EXITCODE = 1
		}
	}
	Catch{
		$global:EXITCODE = 1
	}
	Return $global:EXITCODE
}
    
## Fonction Post Installation	
Function EXEC_ETAPE3 {
	Try {
		If (Get-Process -Name MCAgent){
			Write-Output "Fermeture du process d'installation pour fermeture de la pop-up"
			Stop-Process -Name MCAgent
			$global:EXITCODE = 0
        }
	}	
    Catch {
			$global:EXITCODE = 1
    }
    Return $global:EXITCODE
}

## Fonction de contrôle du fichier de desinstallation
Function EXEC_ETAPE4 {
	Try {
		If (Test-Path -Path "C:\Program Files (x86)\SOTI\MobiControl\Uninstall.bat") {
			Write-Output "Remplacement du Uninstall.bat dans 'C:\Program Files (x86)\SOTI\MobiControl\'"
			Copy-Item "$($MyPath)Uninstall.bat" "C:\Program Files (x86)\SOTI\MobiControl\Uninstall.bat" -Force
			$global:EXITCODE = 0
        }
	}
	Catch {
		$global:EXITCODE =1
	}
	Return $global:EXITCODE
}

## Declaration des variables
$path = FLireRegistry $StrPathKeySI "Path"
$strinifile = $path+"SERVER.INI"
$iniFile  = Get-IniContent "$($strInifile)"
$SiteName = $($iniFile["domaineAD"]["SiteName"])
$NameAD = $($iniFile["domaineAD"]["NameAD"])
$userFCT = "$($NameAD)\"+$iniFile["Credentials"]["LoginTachePlan"].split(",")[0]
$passwordFCT = $iniFile["Credentials"]["LoginTachePlan"].split(",")[1]
$CodecarteU = $($iniFile["Server"]["CodeCarteU"])
$serveur = $env:Computername
$Mypath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Mypath+="\"
$datetime = $(Get-Date -format yyyyMMddHHmmss)
$LogFile = $Mypath+$datetime+"_"+$MyInvocation.MyCommand.Definition.Substring($Mypath.Length,($MyInvocation.MyCommand.Definition.Length-$Mypath.Length-4))+".log"
$blockerrors = 0
$noblockerrors = 0



## Contexte d'execution ISE ou pas 
If ($MyInvocation.MyCommand.Path -eq $null) {
	$Mypath = $psISE.CurrentFile.FullPath.Substring(0,$psISE.CurrentFile.FullPath.LastIndexOf("\"))
 
}
Else
{
	$Mypath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}

$ParentPath = Split-Path -parent $Mypath
$CurrentDir = Split-Path $ParentPath -Leaf
$ParentPath = Split-Path -parent $ParentPath
$MypathLog = $ParentPath+"\Logs\"+$CurrentDir
$filename = $MyInvocation.MyCommand.Definition.Substring($mypath.Length,($MyInvocation.MyCommand.Definition.Length-$mypath.Length-4))
$MyLogfile = $mypathlog+"$($filename).LOG"
$MyPath+="\"

## Nombre d erreur rencontres
Write-Output "ERREURS RENCONTREES : $($errors)"
$RegPath = "HKLM:\SOFTWARE\Wow6432Node\SU\Packages\XtremHub"
InitRegPath "HKLM:\SOFTWARE\Wow6432Node\SU"
InitRegPath "HKLM:\SOFTWARE\Wow6432Node\SU\Packages"
InitRegPath $RegPath
$KeyPath = "Install_Soti_XtremHub"

## Déclaration des étapes fonctions à executer & test d'éligibilité
$IsInstall = (gwmi Win32_computersystem).domain -eq "Ad.pdv-u.fr" -and $env:COMPUTERNAME -like "*TECH11"
Switch ($IsInstall -eq $true){
$true{
$strFichier = [ordered]@{
ETAPE1  = 'EXEC_ETAPE1;Install'
ETAPE2  = 'EXEC_ETAPE2;Check Install'
ETAPE3  = 'EXEC_ETAPE3;Check Fin Installer'
ETAPE4  = 'EXEC_ETAPE3;Check Uninstaller'
}
}
$false{
$strFichier = [ordered]@{
ETAPE1  = 'EXEC_ETAPE0;NoInstall'
}
}
}

$IntNbr=1 
$IntNbrLn=$($strFichier).Count

If ((FLireRegistry $StrPathKeySI $MystrRegKeyName) -eq "RUN") {  ## Traitemnt dans le cadre du Moteur

  Trace_etapes_start $etape
  
  ## Traitement des Fonctions de l'étape 

  ForEach ($ligne in $($strFichier).GetEnumerator()) {
    
    $split                      = ($ligne.Value) -split ";"
    $Function_Etape             = $split[0] ## Nom de la fonction d'appel
    $Description_Etape          = $split[1] ## Description de l'étape
	
    ## Execution de la fonction
    Write-Output "$($Description_Etape) ..."
    & $Function_Etape 
    If ($global:EXITCODE -ne 0) {Erreur "Probleme sur $($Description_Etape) - $($IntNbr)/$($IntNbrLn) - Exitcode : $($global:EXITCODE)" $StrFollowkeyPath}
    
    Write-output "Etape $($IntNbr)/$($IntNbrLn) : OK - Exitcode : $($global:EXITCODE)"
    $IntNbr++ 
  }

    if ($global:EXITCODE -ne 0) {$regvalue = 0} Else {$regvalue = 1}
    InitKeyPath $RegPath $KeyPath $regvalue

   	InfoQuit "Traitement termine avec succes - Exitcode : $($EXITCODE)" $StrFollowkeyPath

} Else { ## Traitemnt lancement manuel
    
    Start-Transcript $MyLogfile
   
    write-output $etape 

    ## Traitement des Fonctions de l'étape 

    ForEach ($ligne in $($strFichier).GetEnumerator()) {
    
       $split                      = ($ligne.Value) -split ";"
       $Function_Etape             = $split[0] ## Nom de la fonction d'appel
       $Description_Etape          = $split[1] ## Description de l'étape
	
       ## Execution de la fonction
       Write-Output "$($Description_Etape) ..."
       & $Function_Etape 
       If ($global:EXITCODE -ne 0) {Write-output "Probleme sur $($Description_Etape) - $($IntNbr)/$($IntNbrLn) - Exitcode : $($global:EXITCODE)" ; break}
    
       Write-output "Etape $($IntNbr)/$($IntNbrLn) : OK - Exitcode : $($global:EXITCODE)"
       $IntNbr++ 
    }

    if ($global:EXITCODE -ne 0) {$regvalue = 0} Else {$regvalue = 1}
    InitKeyPath $RegPath $KeyPath $regvalue
    Write-output "Traitement termine avec succes."

	Stop-Transcript
}
