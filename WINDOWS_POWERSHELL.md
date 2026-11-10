# Windows ohne Ubuntu: PowerShell

Empfohlen ist Ubuntu in WSL ([`RUNBOOK.md`](RUNBOOK.md), *Was du brauchst*), dort gelten alle Befehle
der Unterlagen unverändert. Diese Seite nur für Windows **ohne** Ubuntu-Terminal: Docker Desktop
mit WSL 2 läuft, Befehle in der normalen PowerShell. Aufgeführt sind nur die Abweichungen.

## RUNBOOK Schritt 1: Workshop-Ordner herunterladen

```powershell
cd $HOME
Invoke-WebRequest https://github.com/gplug-ch/ki-workshop/archive/refs/heads/main.zip -OutFile ki-workshop.zip
Expand-Archive ki-workshop.zip -DestinationPath . ; Rename-Item ki-workshop-main ki-workshop ; Remove-Item ki-workshop.zip
cd ki-workshop
```

## RUNBOOK Schritt 3: Docker-Image laden, Agent starten

Statt `./docker-run.sh`:

```powershell
.\docker-run.ps1 bash           # Shell im Container
.\docker-run.ps1                # opencode im Container
.\docker-run.ps1 --build        # Image lokal bauen (nach dem Workshop)
```

Meldet PowerShell `UnauthorizedAccess` bzw. „Ausführung von Skripts ist deaktiviert“: im selben
Fenster freigeben (gilt nur für dieses Fenster), dann erneut starten:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## RUNBOOK Schritt 6 und Übung: Geräte-Skripte

`upload.sh`, `log.sh`, `brcmd.sh` und `echo … > .gplug` laufen nicht in PowerShell. Zuerst die
Container-Shell öffnen (`.\docker-run.ps1 bash`), dort die Befehle wie in den Unterlagen eingeben.
Der Agent (`.\docker-run.ps1`) führt sie selbst im Container aus.

## SETUP_OPENCODE Schritt 3: eigener Zugang

Nur im aktuellen Fenster:

```powershell
$env:INFOMANIAK_PRODUCT_ID = "123456"
$env:INFOMANIAK_API_KEY    = "xxxxxxxxxxxxxxxx"

curl.exe -s "https://api.infomaniak.com/2/ai/$env:INFOMANIAK_PRODUCT_ID/openai/v1/models" `
  -H "Authorization: Bearer $env:INFOMANIAK_API_KEY"
```

Dauerhaft für den eigenen Benutzer, danach **alle** Terminal-Fenster schliessen und neu öffnen:

```powershell
[Environment]::SetEnvironmentVariable("INFOMANIAK_PRODUCT_ID", "123456", "User")
[Environment]::SetEnvironmentVariable("INFOMANIAK_API_KEY", "xxxxxxxxxxxxxxxx", "User")
```

Prüfen (zeigt den Token nicht an), erwartet `ID=123456 KEY=True`:

```powershell
"ID=$env:INFOMANIAK_PRODUCT_ID KEY=$([bool]$env:INFOMANIAK_API_KEY)"
```

Windows-Variablen sind in Ubuntu/WSL nicht sichtbar, dort `~/.bashrc` verwenden.
