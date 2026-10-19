# docker-run.ps1 – Workshop-Sandbox bauen (beim ersten Mal) und opencode darin starten (Windows).
#   .\docker-run.ps1            opencode im Container
#   .\docker-run.ps1 bash       Shell im Container (zum Prüfen)
#   .\docker-run.ps1 --build    Image neu bauen
# Sichtbar ist nur dieser Ordner (/work). Infomaniak-Werte aus den Umgebungsvariablen.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$Image = "gplug-workshop"

$rest = @($args)
docker image inspect $Image *> $null
$missing = $LASTEXITCODE -ne 0
if ($rest.Count -gt 0 -and $rest[0] -eq "--build") {
  $rest = @($rest | Select-Object -Skip 1)
  $missing = $true
}
if ($missing) {
  docker build -t $Image .
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $env:INFOMANIAK_PRODUCT_ID -or -not $env:INFOMANIAK_API_KEY) {
  Write-Warning "INFOMANIAK_PRODUCT_ID oder INFOMANIAK_API_KEY nicht gesetzt (SETUP_OPENCODE.md Schritt 3)"
}

docker run -it --rm `
  -v "${PWD}:/work" -w /work `
  -v gplug-workshop-data:/home/agent/.local/share/opencode `
  -e INFOMANIAK_PRODUCT_ID -e INFOMANIAK_API_KEY -e GPLUG `
  $Image @rest
