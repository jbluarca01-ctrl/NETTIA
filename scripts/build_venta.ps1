# Build de venta de Nettia (SPEC-005 RF19).
# Compila el APK release ofuscado. Se niega si falta la clave pública de
# venta, la huella del certificado o android/key.properties.
# Los símbolos (para leer errores) quedan en la carpeta del usuario, nunca
# en el repo ni en el APK. Uso:  powershell -File scripts/build_venta.ps1
param([switch]$SoloVerificar)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

function Falla([string]$motivo) {
    Write-Output "Build de venta cancelado: $motivo"
    exit 1
}

$config = Get-Content -Raw -Encoding UTF8 'lib/src/licencia_config.dart'
if ($config -match "clavePublicaVenta => _bytes\(''\);") {
    Falla 'Falta la clave pública de venta en lib/src/licencia_config.dart.'
}
if ($config.Contains("huellaVenta => '';")) {
    Falla 'Falta la huella SHA-256 del certificado en lib/src/licencia_config.dart.'
}
if (-not (Test-Path 'android/key.properties')) {
    Falla 'Falta android/key.properties (la keystore de publicación).'
}
if ($SoloVerificar) {
    Write-Output 'Listo para el build de venta.'
    exit 0
}

$simbolos = Join-Path $env:USERPROFILE ('nettia_simbolos\' + (Get-Date -Format 'yyyyMMdd-HHmm'))
flutter build apk --release --obfuscate --split-debug-info=$simbolos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Output "Símbolos (guárdalos, no se reparten): $simbolos"
