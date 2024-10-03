<#
.SYNOPSIS
	Obtenir la date et l'heure de dernière connexion d'un utilisateur ou de tous les utilisateurs activés, via lecture de l'attribut lastLogon sur tous les DC.

.EXAMPLE
    Get-ADUserLastLogon -Identity "admin.fb"
    Get-ADUserLastLogon
    
.INPUTS
.OUTPUTS
.NOTES
	NAME:	Get-ADUserLastLogon.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	VERSION HISTORY:
        1.0   14/05/2024
        1.1   18/07/2024

#>

function Get-ADUserLastLogon {

    [CmdletBinding()]
    
    param(
        [Parameter(Mandatory=$false)][ValidateScript({Get-ADUser $_})]$Identity=$null
    )

    # Création d'un tableau vide
    $LastLogonTab = @() 

    # Récupérer la liste de tous les DC du domaine AD
    $DCList = Get-ADDomainController -Filter * | Sort-Object Name | Select-Object Name

    # Déterminer la liste des utilisateurs (un utilisateur ou tous les utilisateurs activés)
    if($Identity -eq $null){

        $TargetUsersList = (Get-ADUser -Filter {Enabled -eq $true}).samAccountName
    }else{

        $TargetUsersList = $TargetUser
    }

    Foreach($TargetUser in $TargetUsersList){

        # Initialiser le LastLogon sur $null comme point de départ
        $TargetUserLastLogon = $null

        Foreach($DC in $DCList){

                $DCName = $DC.Name
 
                Try {
            
                    # Récupérer la valeur de l'attribut lastLogon à partir d'un DC (chaque DC tour à tour)
                    $LastLogonDC = Get-ADUser -Identity $TargetUser -Properties lastLogon -Server $DCName

                    # Convertir la valeur au format date/heure
                    $LastLogon = [Datetime]::FromFileTime($LastLogonDC.lastLogon)

                    # Si la valeur obtenue est plus récente que celle contenue dans $TargetUserLastLogon
                    # la variable est actualisée : ceci assure d'avoir le lastLogon le plus récent à la fin du traitement
                    If ($LastLogon -gt $TargetUserLastLogon)
                    {
                        $TargetUserLastLogon = $LastLogon
                    }
 
                    # Nettoyer la variable
                    Clear-Variable LastLogon
                    }

                Catch {
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
        }

        $LastLogonTab += New-Object -TypeName PSCustomObject -Property @{
            SamAccountName = $TargetUser
            LastLogon = $TargetUserLastLogon
        }

        Write-Host "lastLogon de $TargetUser : $TargetUserLastLogon"
        Clear-Variable -Name "TargetUserLastLogon"
    }

    return $LastLogonTab

}