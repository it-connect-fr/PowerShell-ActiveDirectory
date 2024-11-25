<#
.SYNOPSIS
    This script send LLMNR request on the network and create an event in the event viewer when a response is obtained.

.DESCRIPTION
    This script aims to help to detect attacker exploiting LLMNR protocol using LLMNR poisoning (https://attack.mitre.org/techniques/T1557/001/). It works by sending controlled LLMNR request. LLMNR protocol is no longer used in modern networks and only an attacker can be the source of an LLMNR response. This script can be customized using defined parameters, including delay between requests, hostnames requested, generated eventID, etc.

.AUTHOR
    Mickael Dorigny - IT-Connect.fr

.VERSION
    1.0 - Initial version.

.NOTES
    Filename: Manage-IPv6.ps1
    Creation Date: 08/2024
#>

# Param�tres
# Afficher les r�sultats dans le terminal
$TerminalOutput = $True 
# Nom de la source pour les logs Windows
$logSource = "LLMNR Attack Detection" 
# Log Windows o� les �v�nements seront �crits
$eventLog = "Application" 
# ID de l'�v�nement dans les logs Windows
$eventID = 10001 
# Temps minimal d'attente (en secondes)
$MinWaitTime = 1
# Temps maximal d'attente (en secondes)
$MaxWaitTime = 10 
# Liste de noms � tester
$hostnames = @("DSN121", "Imrpimante", "ActieDirector", "DNSS-Server", "File--server")

function Write-EventLogV2 {
    param(
          [Parameter(Mandatory=$true)]$hostname,
          $IP="",
          $ID=10000,
          $evtLog="PowerShell-Demo",
          $evtSource="Script-2"
          )

    # Charge la source d'�v�nement dans le journal si elle n'est pas d�j� charg�e.
    # Cette op�ration �chouera si la source d'�v�nement est d�j� affect�e � un autre journal.
    if ([System.Diagnostics.EventLog]::SourceExists($evtSource) -eq $false) {
        [System.Diagnostics.EventLog]::CreateEventSource($evtSource, $evtLog)
    }

    # Construire l'�v�nement et l'enregistrer
    $evtID = New-Object System.Diagnostics.EventInstance($ID,1)
    $evtObject = New-Object System.Diagnostics.EventLog
    $evtObject.Log = $evtLog
    $evtObject.Source = $evtSource
    $evtObject.WriteEvent($evtID, @("Attack Detected - Fake LLMNR Query has received a response.", "FakeHostname: $hostname","Responder IP: $IP"))
  }

# Boucle principale pour �mettre des requ�tes al�atoires
while ($true) {
    # S�lection al�atoire d'un nom d'h�te
    $randomHostname = $hostnames[$(Get-Random -Maximum $hostnames.Length)]

    # Envoi de la requ�te LLMNR
    $LLMNRResponse = Resolve-DnsName -Name $randomHostname -Type A -LlmnrOnly -ErrorAction SilentlyContinue
    
    # Affichage de la requ�te dans le terminal
    if ($TerminalOutput) {
        Write-Output "$(Get-Date) - LLMNR Query sent: `"$randomHostname`""
    }

    # Si une r�ponse est re�ue, journaliser
    if ($LLMNRResponse) {
        # Affichage dans le terminal
        if ($TerminalOutput) {
            Write-Output "$(Get-Date) - LLMNR response received from $($LLMNRResponse.IPAddress)"
        }
        # Ajout d'une entr�e dans les journaux Windows
        Write-EventLogV2 -ID $eventID -hostname $randomHostname -IP $($LLMNRResponse.IPAddress) -evtLog $eventLog -evtSource $logSource
    } else {
        if ($TerminalOutput) {
            Write-Output "$(Get-Date) - No response for LLMNR Query: `"$randomHostname`""
        }
    }

    # Pause al�atoire entre les requ�tes
    Start-Sleep -Seconds (Get-Random -Minimum $MinWaitTime -Maximum $MaxWaitTime)
}
