param(
  [string]$Destination = (Join-Path $PSScriptRoot 'backups')
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$archiveName = "n8n-data-$timestamp.tar.gz"

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
docker run --rm `
  -v n8n_n8n_data:/data:ro `
  -v "${Destination}:/backup" `
  alpine:3.20 `
  tar czf "/backup/$archiveName" -C /data .

Write-Host "Backup created: $(Join-Path $Destination $archiveName)"
