# Copia las migraciones versionadas de Supabase a infra/migraciones/sql
# para aplicarlas con dbmate en un VPS.
$origen = Join-Path $PSScriptRoot "..\..\supabase\migrations"
$destino = Join-Path $PSScriptRoot "..\migraciones\sql"

if (-not (Test-Path $destino)) {
    New-Item -ItemType Directory -Path $destino | Out-Null
}

Get-ChildItem -Path $origen -Filter "*.sql" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $destino $_.Name) -Force
    Write-Host "Copiado: $($_.Name)"
}

Write-Host "Migraciones sincronizadas en $destino"
