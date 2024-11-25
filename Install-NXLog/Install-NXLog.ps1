<#

.SYNOPSIS
	Installer l'application NXLog sur la machine Windows (x64) - Installation unique
    Copier tous les fichiers .conf dans le répertoire "conf/nxlog.d" de l'agent - A chaque exécution
    Modifiez les chemins dans l'appel de la fonction (fin de script)

.PARAMETER MsiPath
    Chemin UNC vers le package MSI de NXLog

.PARAMETER ConfigPath
    Chemin UNC vers le répertoire qui contient le(s) fichier(s) de config à copier (*.conf)

.EXAMPLE
    Install-NXLog.ps1
    
.INPUTS
.OUTPUTS
.NOTES
	NAME:	Install-NXLog.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	VERSION HISTORY:
        1.0   31/10/2024
#>

function Install-NXLog {
  param (
    [Parameter(Mandatory=$true)][string] $MsiPath,
    [Parameter(Mandatory=$true)][string] $ConfigPath
  )

  $NXLogConfigPath = "C:\Program Files\nxlog\conf\nxlog.d"
  $NXLogExePath = "C:\Program Files\nxlog\nxlog.exe"

  if ((Test-Path $MsiPath) -and (-not (Test-Path $NXLogExePath))) {
    & msiexec.exe /quiet /i $MsiPath
    Start-Sleep -Seconds 30
  }

  if ((Test-Path $ConfigPath) -and (Test-Path $NXLogConfigPath)){

    Get-ChildItem -Path $ConfigPath -Filter "*.conf" | Foreach{
        Copy-Item $_.FullName -Destination $NXLogConfigPath -Force
    }
  }

  $NXLogService = (Get-Service -Name nxlog -ErrorAction SilentlyContinue)
  if ($NXLogService) {
        Restart-Service -InputObject $NXLogService
  }
}

Install-NXLog   -MsiPath "\\it-connect.local\NETLOGON\NXLog\nxlog-ce-3.2.2329.msi" `
                -ConfigPath "\\it-connect.local\NETLOGON\NXLog"