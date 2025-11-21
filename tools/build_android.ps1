Param(
    [switch]$Doctor,
    [switch]$Clean,
    [switch]$AppBundle
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg){ Write-Host "[STEP] $msg" -ForegroundColor Cyan }
function Fail($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# Root path (script location)
$Root = Split-Path -Parent $PSCommandPath
Set-Location $Root\..  # move to project root

Write-Step "Proyecto: $(Get-Location)"

# Ensure Flutter available
if(-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Fail "Flutter CLI no encontrado en PATH" }

if($Doctor){ flutter doctor -v }

# Validar keystore y key.properties
$keyPropsPath = Join-Path (Get-Location) 'android\key.properties'
if(-not (Test-Path $keyPropsPath)){ Fail "key.properties no existe: $keyPropsPath" }

$props = Get-Content $keyPropsPath | Where-Object { $_ -match '=' } | ForEach-Object {
    $parts = $_.Split('='); [PSCustomObject]@{ Key=$parts[0]; Value=$parts[1] }
}
$storeFile = ($props | Where-Object Key -eq 'storeFile').Value
$storePassword = ($props | Where-Object Key -eq 'storePassword').Value
$keyAlias = ($props | Where-Object Key -eq 'keyAlias').Value
$keyPassword = ($props | Where-Object Key -eq 'keyPassword').Value

if(-not $storeFile){ Fail "storeFile vacío en key.properties" }

# Expand relative path
if($storeFile -notmatch '^[A-Za-z]:'){ $storeFile = Join-Path (Get-Location) $storeFile }

if(-not (Test-Path $storeFile)){ Fail "Keystore no encontrado: $storeFile" }

Write-Step "Keystore OK: $storeFile (alias esperado: $keyAlias)"

# Opcional limpieza
if($Clean){
    Write-Step "Ejecutando flutter clean (ignorando errores de borrado por OneDrive)"
    flutter clean || Write-Host "Aviso: clean tuvo errores, continuando..." -ForegroundColor Yellow
}

Write-Step "Resolviendo dependencias"
flutter pub get

# Build
if($AppBundle){
    Write-Step "Compilando App Bundle (AAB release)"
    flutter build appbundle --release
}else{
    Write-Step "Compilando APK release"
    flutter build apk --release
}

Write-Step "Finalizado. Artefactos en build\app\outputs"
