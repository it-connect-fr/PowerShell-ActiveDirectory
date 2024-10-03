<#
.SYNOPSIS
    Lister les utilisateurs ayant les permissions DS-Replication-Get-Changes ou DS-Replication-Get-Changes-All qui permettent de r�aliser une attaque DCSync.

.EXAMPLE
    List-DCSyncPermissions.ps1

.INPUTS
.OUTPUTS
.NOTES
    NAME:   List-DCSyncPermissions.ps1
    AUTHOR: Mickael Dorigny
    VERSION HISTORY:
        1.0   30/06/2024
#>

# D�fini les permissions � v�rifier
$permissions = @("DS-Replication-Get-Changes", "DS-Replication-Get-Changes-All")

# Fonction de convertion des noms de permission en GUID
function Get-RightGuid {
    param ($RightName)
    switch ($RightName) {
        "DS-Replication-Get-Changes" { return "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2" }
        "DS-Replication-Get-Changes-All" { return "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" }
        default { return $null }
    }
}

# R�cup�re le DN de la racine du domaine
$rootDse = Get-ADRootDSE
$domainDn = $rootDse.defaultNamingContext

# R�cup�re les ACL sur l'objet domaine
$acl = Get-ACL -Path "AD:$domainDn"

# Filtre les ACE qui correspondate avec les permission recherch�es
$matches = foreach ($ace in $acl.Access) {
    foreach ($perm in $permissions) {
        if ($ace.ObjectType -eq (Get-RightGuid -RightName $perm)) {
            [PSCustomObject]@{
                IdentityReference = $ace.IdentityReference
                Permission = $perm
            }
        }
    }
}

Write-Host "[+] Les objets suivants peuvent DCSync :"
# Affichage des r�sultats
$matches | Format-Table -AutoSize
