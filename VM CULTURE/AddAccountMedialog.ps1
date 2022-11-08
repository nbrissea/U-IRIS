<#Script de creation des Objets AD pour VM culture
Arguments : Code carte U, Nombre de comptes, mot de passe par défaut
Création : 21/09/2022 -NBR
Contexte d'execution : a executer depuis un serveur RSAT
#>

#Récupération des paramètres en entrée
$ccu = read-host "Entrer le CCU"
$nbuser = Read-Host "Entrer le nombre d'utilisateurs souhaités"
$passwd = Read-Host -AsSecureString "Password par défaut"
$confirm = Read-Host "Entrer 'OK' pour confirmer la creation de $nbuser comptes MEDIALOG"

#initialisation des variables 
[int]$u = 0
$accountlist = @()
$filer = $ccu + "fichier11"
$username = $null

#Confirmation de création
if ($confirm -eq "ok") {

    # Creation du groupe d'utilisateurs
    $LdapEnum = "OU=$ccu,OU=PDV_utilisateurs,DC=recad,DC=pdv-u,DC=fr"
    $user = get-adgroup -Server recad.pdv-u.fr -SearchBase "$LdapEnum" -Filter { (Name -like "*medialog*") }
    If ($null -eq $user) {
        $groupname = $ccu + '_MedialogTSE'
        New-ADGroup -Name $groupname -GroupScope Global -GroupCategory Security -Path $LdapEnum
    }

    # Création des Utlisateurs Medialog et des répertoires personnels
    while ($u -ne $nbuser) {
        $u++
        $username = $ccu + "MEDIALOG" + $u
        New-ADUser -Name $username `
            -Path $LdapEnum `
            -Surname $username.substring(1, 13) `
            -SamAccountName $username `
            -AccountPassword $passwd `
            -ChangePasswordAtLogon $false `
            -DisplayName $username `
            -Enabled $True `
            -PasswordNeverExpires $True
        $accountlist += "$username"
    }
    start-sleep 5
    # Ajout des utilisateurs au groupe 
    while ($null -eq (get-adgroup -Server recad.pdv-u.fr -SearchBase "$LdapEnum" -Filter { (Name -like "*medialog*") })) {
        Start-Sleep 30
    }
    $session = New-CimSession -ComputerName $filer
    Foreach ($account in $accountlist) {
        Add-ADPrincipalGroupMembership -Identity $account -MemberOf $groupname
        New-Item -ItemType Directory -Path \\$filer\p$\STOCKAGE\UTILISATEURS\ -Name $account
        $sharename = $account + "$"
        New-SmbShare -Name $sharename -Path "P:\STOCKAGE\UTILISATEURS\$account" -FullAccess $account -CimSession $session

    }
    Remove-CimSession -CimSession $session
}
else {
    Write-Output "Annulation : Aucun ajout effectué !"
}