# =======================================================
# NAME: DescriptionChangeLogger.ps1
# AUTHOR: Mickael Dorigny, Florian Burnel - IT-Connect
# DATE: 31/03/2024
#
# VERSION 1.0
# COMMENTS: Créer un évènement dans l'Observateur d'évènement 
# Windows lors de la détection de modification d'une description
# d'un objet "Utilisateur". Se base pour cela sur une liste de
# descriptions (stockées sous forme GUID-hash) créée lors de la 
# première exécution, puis mise à jour à chaque nouvelle exécution.

# Le script va créer un fichier XML dans %TEMP% et y stockera les 
# données récoltées lors de la dernière analyse en date. Ces informations
# seront comparées à l'analyse en cours lors de la prochaine exécution.
#
# Requires -Version 2.0
# =======================================================
Import-Module ActiveDirectory

function Write-EventLogV2 {
    <#
    .SYNOPSIS
        Crée un évènement dans l'observateur d'évènement
    .DESCRIPTION
        La fonction utilise la CmdLet WriteEvent pour créer un évènement à partir des paramètres d'entrée. 
    .PARAMETER dataUser
        Nom utilisateur qui sera inscrit dans le contenu de l'évènement à créer
    .PARAMETER dataDescription
        Contenu de la description qui sera inscrite dans le contenu de l'évènement à créer
    .PARAMETER ID
        Event ID de l'évènement à créer
    .PARAMETER evtLog
        Journal de l'évènement à créer
    .PARAMETER evtSource
        Source de l'évènement à créer
    .EXAMPLE
        Write-EventLogV2 -dataUser "John" -dataDescription "new description"
    .OUTPUTS
        None
    #>
    param(
          [Parameter(Mandatory=$true)]$dataUser,
          $dataDescription="",
          $ID=10000,
          $evtLog="Application",
          $evtSource="AD - Change user description"
          )

    # Charge la source d'événement dans le journal si elle n'est pas déjà chargée.
    # Cette opération échouera si la source d'événement est déjà affectée à un autre journal.
    if ([System.Diagnostics.EventLog]::SourceExists($evtSource) -eq $false) {
        [System.Diagnostics.EventLog]::CreateEventSource($evtSource, $evtLog)
    }

    # Construire l'événement et l'enregistrer
    $evtID = New-Object System.Diagnostics.EventInstance($ID,1)
    $evtObject = New-Object System.Diagnostics.EventLog
    $evtObject.Log = $evtLog
    $evtObject.Source = $evtSource
    $evtObject.WriteEvent($evtID, @($dataUser,"Description : $dataDescription"))
  }

Function Get-SHA1 {
    <#
    .SYNOPSIS
        Retourne le hash SHA1 d'une chaine de caractère
    .DESCRIPTION
        La fonction utilise la CmdLet Get-FileHash pour générer le hash SHA1 d'une chaine de caractère passée en paramètre. 
    .PARAMETER stringToHash
        Chaine de caractère pour laquelle on souhaite obtenir un hash.
    .EXAMPLE
        Get-SHA1 -stringToHash "new description"
    .OUTPUT
        string: hash SHA1
    #>
    param(
        [string]$stringToHash
    )

    # Convertit la chaine de caractère en UTF8, puis en base64 pour éviter les problèmes d'encodage
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($stringToHash)
    $base64String = [System.Convert]::ToBase64String($bytes)

    # Génère le hash SHA1 de la chaine de caractère encodée
    $mystream = [IO.MemoryStream]::new([byte[]][char[]]$base64string)
    $hash = (Get-FileHash -InputStream $mystream -Algorithm SHA256).Hash
    return $hash
}

Function Find-XMLfile {
    <#
    .SYNOPSIS
        Cherche la présence d'un fichier XML utilisé par le script dans un répertoire donné
    .DESCRIPTION
        La fonction va rechercher un fichier de type XML commençant par "descChangeLogger" et retouner
        son chemin si un tel fichier est trouvé.
    .PARAMETER targetFolder
        Répertoire dans lequel chercher le fichier
    .EXAMPLE
        Get-SHA1 -targetFolder
    .OUTPUTS
        Chemin vers le fichier découvert ou $null
    #>
    param(
          $targetFolder=$env:TEMP
          )

    $xmlFiles = Get-ChildItem $targetFolder -Filter descChangeLogger-*.xml
    if ($xmlFiles) {
        return $xmlFiles.FullName
    }
    return $null
}

Function CollectDescriptions {
    <#
    .SYNOPSIS
        Collecte les descriptions des objets utilisateur de l'Active Directory
    .DESCRIPTION
        La fonction utilise la CmdLetGet-ADUSer du module ActiveDirectory pour 
        récupérer les attributs SamAccountName, ObjectGUID et Description.
    .OUTPUTS
        PSCustomObject : objets utilisateurs avec SamAccountName, ObjetGUID
        Description et Hash SHA1 de la description.
    #>
    $descriptions = Get-ADUser -Filter * -Properties Description, ObjectGUID, SamAccountName |
                    Select-Object SamAccountName, ObjectGUID, Description, @{Name='DescriptionHash';Expression={Get-SHA1 $_.Description}}
    return $descriptions
}

# Recherche un précédent fichier XML contenant les données générées par le script
$tempDir = $env:TEMP
$previousXMLFile = Find-XMLFile -targetFolder $tempDir

# Si un fichier XML a été trouvé, comparaison des hashs des descriptions relevées avec les descriptions actuelles
if ($previousXMLFile -ne $null) {
    
    # Chargement des objectGUID et hash de description du précédent relevé
    $previousDescriptions = Import-Clixml $previousXMLFile
    
    # Suppression du dernier relevé
    Remove-Item $previousXMLFile

    # Archivage des descriptions actuelles dans un fichier XML pour comparaison lors de la prochaine exécution
    $todayDescriptions = CollectDescriptions
    $currentDate = Get-Date -Format "yyMMddHHmmss"
    $todayDescriptions | Select-Object -Property SamAccountName, ObjectGUID, Description, DescriptionHash | Export-Clixml "$tempDir/descChangeLogger-$currentDate.xml"

    # Comparaison des hash des descriptions entre le relevé précédent et le relevé actuel
    # Boucle sur la liste des utilisateurs du relevé actuel
    foreach ($todayUser in $todayDescriptions) {
        $todayUserName = $todayUser.SamAccountName
        $todayUserGUID = $todayUser.ObjectGUID
        $todayUserDescription = $todayUser.Description  
        $todayUserDescriptionHash = Get-SHA1 -stringToHash $todayUserDescription

        $previousUserDescription = ""
        $previousUser = ""
        
        $previousUser = $previousDescriptions | Where-Object { $_.ObjectGUID -eq $todayUserGUID }
        $previousUserGUID = $previousUser.ObjectGUID
        $previousUserDescriptionHash = $previousUser.DescriptionHash

        # Création d'un évènement en cas de différence de hash de description
        if ($previousUser -ne "" -and $todayUserDescriptionHash -ne $previousUserDescriptionHash) {
            Write-EventLogV2 -dataUser $todayUserName -dataDescription $todayUserDescription
        }
        # Création d'un évènement si l'utilisateur n'existait pas dans l'archive précédente (création)
        if ($previousUser -eq "") {
            Write-EventLogV2 -dataUser $todayUserName -dataDescription "OK $todayUserDescription"
        }
    }
}

# Si aucun relevé précédent n'existe, le créer
else {
    $currentDate = Get-Date -Format "yyMMddHHmmss"
    CollectDescriptions | Select-Object -Property SamAccountName, ObjectGUID, Description, DescriptionHash | Export-Clixml "$tempDir/descChangeLogger-currentDate.xml"
 
}
