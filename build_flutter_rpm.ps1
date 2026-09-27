# Сборка чистого Flutter RPM-пакета для ОС Аврора без QML
$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Сборка чистого Flutter RPM для ОС Аврора (ОМП)   " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot
$auroraDir = Join-Path $rootDir "aurora"
$vmshare = "C:\AuroraOS\emulator\AuroraOS-5.2.1.200\vmshare"

# Шаг 1. Компиляция Flutter Dart-бандла
$flutterAuroraBat = "C:\flutter-aurora\bin\flutter.bat"
if (Test-Path $flutterAuroraBat) {
    & cmd.exe /c "$flutterAuroraBat build bundle --target-platform aurora-x64 --asset-dir build\flutter_assets"
} else {
    & cmd.exe /c "flutter build bundle --target-platform linux-x64 --asset-dir build\flutter_assets"
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Не удалось скомпилировать Flutter бандл!" -ForegroundColor Red
    exit 1
}

# Нормализация путей в generated_plugins.cmake (устранение Windows backslashes для Linux Docker)
$genCmake = Join-Path $auroraDir "flutter\generated_plugins.cmake"
if (Test-Path $genCmake) {
    $c = Get-Content $genCmake -Raw
    $c = [System.Text.RegularExpressions.Regex]::Replace($c, 'list\(APPEND CMAKE_MODULE_PATH ".*?[\\/]ephemeral[\\/]\.plugin_symlinks[\\/]\$\{NATIVE_LIB\}[\\/]aurora"\)', 'list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/ephemeral/.plugin_symlinks/${NATIVE_LIB}/aurora")')
    [System.IO.File]::WriteAllText($genCmake, $c)
}

# Шаг 2. Подготовка артефактов в каталоге aurora/bundle
Write-Host "[2/3] Подготовка структуры бандла в aurora/bundle..." -ForegroundColor Green
$bundleAssetsDir = Join-Path $auroraDir "bundle\flutter_assets"
$bundleLibDir = Join-Path $auroraDir "bundle\lib"

if (-not (Test-Path $bundleAssetsDir)) { New-Item -ItemType Directory -Path $bundleAssetsDir -Force | Out-Null }
if (-not (Test-Path $bundleLibDir)) { New-Item -ItemType Directory -Path $bundleLibDir -Force | Out-Null }

Copy-Item -Path "$rootDir\build\flutter_assets\*" -Destination $bundleAssetsDir -Recurse -Force
Copy-Item -Path "$auroraDir\lib\x86_64\*.so" -Destination $bundleLibDir -Force

# Шаг 3. Сборка RPM пакета через aurora-build-tools Docker
Write-Host "[3/3] Сборка RPM через Docker aurora-build-tools:5.2.1.200..." -ForegroundColor Green

$buildCommands = @(
    "mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}",
    "tar --exclude='./*.rpm' -cjf /root/rpmbuild/SOURCES/ru.aurora.geometry_dash_aurora-1.0.0.tar.bz2 --transform 's,^\.,ru.aurora.geometry_dash_aurora-1.0.0,' .",
    "rpmbuild -ba rpm/ru.aurora.geometry_dash_aurora.spec",
    "cp -v /root/rpmbuild/RPMS/*/*.rpm /src/",
    "cp -v /root/rpmbuild/RPMS/*/*.rpm /vmshare/ 2>/dev/null || true"
) -join " && "

docker run --rm -v "${auroraDir}:/src" -v "${vmshare}:/vmshare" -w /src aurora-build-tools:5.2.1.200 sh -c $buildCommands

if ($LASTEXITCODE -eq 0) {
    Copy-Item -Path "$auroraDir\*.rpm" -Destination $rootDir -Force
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "  Flutter RPM-пакет успешно собран!                 " -ForegroundColor Yellow
    Get-Item "$rootDir\ru.aurora.geometry_dash_aurora-1.0.0-1.x86_64.rpm" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    Write-Host "====================================================" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Ошибка сборки RPM." -ForegroundColor Red
    exit 1
}
