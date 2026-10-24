# docker-run.ps1 – Workshop-Sandbox holen (beim ersten Mal) und opencode darin starten (Windows).
#   .\docker-run.ps1            opencode im Container
#   .\docker-run.ps1 bash       Shell im Container (zum Prüfen)
#   .\docker-run.ps1 --build    Image lokal aus dem Dockerfile bauen statt von ghcr.io laden
# Sichtbar ist nur dieser Ordner (/work). Infomaniak-Zugang steckt im Workshop-Image;
# INFOMANIAK_PRODUCT_ID / INFOMANIAK_API_KEY aus der eigenen Shell haben Vorrang (eigener Zugang).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$Image = "ghcr.io/gplug-ch/ki-workshop:workshop"

$rest = @($args)
if ($rest.Count -gt 0 -and $rest[0] -eq "--build") {
  $rest = @($rest | Select-Object -Skip 1)
  docker build -t $Image --build-arg WORKSHOP_VERSION="$((Get-Content VERSION).Trim())" .
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} elseif (-not (docker images -q $Image)) {
  # docker images -q statt image inspect: kein stderr, sonst bricht PowerShell 5.1 mit "Stop" ab
  docker pull $Image
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Image nicht ladbar (Workshop vorbei?): .\docker-run.ps1 --build baut es lokal"
    exit $LASTEXITCODE
  }
}

# Eigene Werte nur durchreichen, wenn gesetzt: leeres -e würde die Werte aus dem Image löschen
$envArgs = @()
foreach ($name in "INFOMANIAK_PRODUCT_ID", "INFOMANIAK_API_KEY", "GPLUG") {
  if ([Environment]::GetEnvironmentVariable($name)) { $envArgs += "-e", $name }
}

docker run -it --rm @envArgs `
  -v "${PWD}:/work" -w /work `
  -v gplug-workshop-data:/home/agent/.local/share/opencode `
  $Image @rest
