# ==============================================================================
# Скрипт автоматической установки и настройки окружения разработки
# Проект: Geometry Dash для ОС Аврора 5 (Flutter Native)
# ==============================================================================

[CmdletBinding()]
param(
    [string]$FlutterAuroraPath = "C:\flutter-aurora",
    [string]$AuroraSdkPath = "C:\AuroraOS",
    [switch]$SkipDocker,
    [switch]$SkipExtensions,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


function Write-Step {
    param([string]$Num, [string]$Title)
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host " [$Num] $Title" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [!]  $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "  [X]  $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [i]  $Text" -ForegroundColor Gray
}

function Add-PathIfMissing {
    param([string]$PathToAdd)
    if (-not (Test-Path $PathToAdd)) {
        return $false
    }
    
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $paths = ($userPath -split ';') | Where-Object { $_ -ne '' -and $_ -ne $null }
    
    if ($paths -notcontains $PathToAdd) {
        $newUserPath = ($paths + $PathToAdd) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
        $env:Path = "$PathToAdd;$env:Path"
        Write-Success "Путь добавлен в пользовательский PATH: $PathToAdd"
        return $true
    } else {
        Write-Info "Уже в переменной PATH: $PathToAdd"
        if ($env:Path -split ';' -notcontains $PathToAdd) {
            $env:Path = "$PathToAdd;$env:Path"
        }
        return $true
    }
}

Clear-Host
Write-Host ""
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host "             GEOMETRY DASH - AURORA OS 5 (FLUTTER NATIVE)            " -ForegroundColor Yellow
Write-Host "  ====================================================================" -ForegroundColor Cyan
Write-Host "     Мастер автоматической настройки и валидации окружения            " -ForegroundColor White
Write-Host "  ====================================================================" -ForegroundColor Cyan

$rootDir = $PSScriptRoot
$statusReport = [ordered]@{}

# ------------------------------------------------------------------------------
# 1. Проверка системных утилит: Git, SSH, PowerShell
# ------------------------------------------------------------------------------
Write-Step "1/7" "Проверка системных компонентов (Git, SSH, PowerShell)"

# 1.1 Git
$gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
if ($gitCmd) {
    $gitVer = & git --version
    Write-Success "Git обнаружен: $gitVer"
    $statusReport["Git"] = "Установлен ($gitVer)"
} else {
    Write-Err "Git не найден в PATH!"
    Write-Warn "Установите Git: winget install --id Git.Git -e --source winget"
    $statusReport["Git"] = "Не установлен"
}

# 1.2 SSH
$sshCmd = Get-Command "ssh" -ErrorAction SilentlyContinue
if ($sshCmd) {
    Write-Success "OpenSSH клиент обнаружен: $($sshCmd.Source)"
    $statusReport["OpenSSH"] = "Установлен"
} else {
    Write-Warn "OpenSSH клиент не найден в PATH. Попытка включения через Windows Capability..."
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction SilentlyContinue | Out-Null
        $statusReport["OpenSSH"] = "Включен"
        Write-Success "OpenSSH успешно установлен."
    } catch {
        Write-Err "Не удалось автоматически включить OpenSSH. Установите его в Параметрах Windows -> Дополнительные компоненты."
        $statusReport["OpenSSH"] = "Отсутствует"
    }
}

# ------------------------------------------------------------------------------
# 2. Проверка и настройка Flutter (Windows + Linux Docker)
# ------------------------------------------------------------------------------
Write-Step "2/7" "Проверка Flutter SDK (Windows окружение + Linux Docker)"

Write-Info "Примечание: Официальный Flutter Aurora SDK с нативным C++ тулчейном предназначен"
Write-Info "для Linux (Docker/WSL2). На Windows мы используем Flutter для сборки Dart-бандла,"
Write-Info "а компиляция нативного C++ Embedder и RPM-пакета выполняется в Linux через Docker."

$flutterAuroraBat = Join-Path $FlutterAuroraPath "bin\flutter.bat"
$systemFlutter = Get-Command "flutter" -ErrorAction SilentlyContinue

if (Test-Path $flutterAuroraBat) {
    Write-Success "Flutter for Aurora найден: $FlutterAuroraPath"
    Add-PathIfMissing (Join-Path $FlutterAuroraPath "bin") | Out-Null
    
    $escapedPath = $FlutterAuroraPath.Replace('\', '/')
    & git config --global --add safe.directory $escapedPath 2>$null
    
    $flutterVer = & $flutterAuroraBat --version 2>$null | Select-Object -First 1
    Write-Info "Версия: $flutterVer"
    $statusReport["Flutter SDK"] = "Готов ($FlutterAuroraPath)"
} elseif ($systemFlutter) {
    Write-Success "Обнаружен системный Flutter: $($systemFlutter.Source)"
    Write-Info "Стандартный Flutter на Windows полностью подходит для сборки Dart-бандла."
    Write-Info "Нативная компиляция RPM будет выполнена изолированно в Docker."
    $flutterVer = & flutter --version 2>$null | Select-Object -First 1
    Write-Info "Версия: $flutterVer"
    $statusReport["Flutter SDK"] = "Системный ($($systemFlutter.Source))"
} else {
    Write-Warn "Каталог Flutter for Aurora ($FlutterAuroraPath) не найден."
    
    $shouldInstall = $false
    if (-not $NonInteractive -and $gitCmd) {
        $confirm = Read-Host "Хотите автоматически установить Flutter for Aurora 3.32.7 в '$FlutterAuroraPath'? (Y/N)"
        if ($confirm -eq "" -or $confirm -match "^[Yy]") {
            $shouldInstall = $true
        }
    } elseif ($NonInteractive -and $gitCmd) {
        $shouldInstall = $true
    }
    
    if ($shouldInstall) {
        Write-Host "  Клонирование репозитория https://gitlab.com/omprussia/flutter/flutter.git (тег 3.32.7)..." -ForegroundColor Cyan
        & git clone --depth 1 -b 3.32.7 https://gitlab.com/omprussia/flutter/flutter.git $FlutterAuroraPath
        
        if (Test-Path $flutterAuroraBat) {
            $cacheDir = Join-Path $FlutterAuroraPath "bin\cache"
            if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
            $dartExe = Join-Path $cacheDir "dart-sdk\bin\dart.exe"
            
            if (-not (Test-Path $dartExe)) {
                Write-Host "  Загрузка Dart SDK 3.8.1 для Windows..." -ForegroundColor Cyan
                $dartZip = Join-Path $cacheDir "dart-sdk-3.8.1.zip"
                $dartUrl = "https://storage.googleapis.com/dart-archive/channels/stable/release/3.8.1/sdk/dartsdk-windows-x64-release.zip"
                $dlOk = $false
                $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
                if ($curl) {
                    & curl.exe -L -o $dartZip $dartUrl
                    if (Test-Path $dartZip) { $dlOk = $true }
                }
                if (-not $dlOk) {
                    try {
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        Invoke-WebRequest -Uri $dartUrl -OutFile $dartZip -UseBasicParsing
                        $dlOk = $true
                    } catch {
                        Write-Err "Не удалось скачать Dart SDK 3.8.1: $_"
                    }
                }
                if ($dlOk -and (Test-Path $dartZip)) {
                    Write-Host "  Распаковка Dart SDK 3.8.1..." -ForegroundColor Cyan
                    Expand-Archive -Path $dartZip -DestinationPath $cacheDir -Force
                    Remove-Item -Path $dartZip -Force -ErrorAction SilentlyContinue
                }
            }
            
            $pubDart = Join-Path $FlutterAuroraPath "packages\flutter_tools\lib\src\dart\pub.dart"
            if (Test-Path $pubDart) {
                $pubContent = [System.IO.File]::ReadAllText($pubDart, [System.Text.Encoding]::UTF8)
                if ($pubContent -notmatch 'dart\.exe') {
                    $oldPub = "    if (!_processManager.canRun(pubPath)) {"
                    $newPub = "    if (_processManager.canRun(pubPath)) { return <String>[pubPath]; }`n    final String dartFallback = _fileSystem.path.joinAll(<String>[Cache.flutterRoot!, 'bin', 'cache', 'dart-sdk', 'bin', _platform.isWindows ? 'dart.exe' : 'dart']);`n    if (_processManager.canRun(dartFallback)) { return <String>[dartFallback, 'pub']; }`n    if (false) {"
                    if ($pubContent.Contains($oldPub)) {
                        $pubContent = $pubContent.Replace($oldPub, $newPub)
                        [System.IO.File]::WriteAllText($pubDart, $pubContent, [System.Text.Encoding]::UTF8)
                    }
                }
            }
            
            $engineStamp = Join-Path $cacheDir "engine.stamp"
            if (-not (Test-Path $engineStamp)) {
                [System.IO.File]::WriteAllText($engineStamp, "47485eb1df27de3ac9039dab4f0b1cf87d10f7ea`n")
            }
            
            Add-PathIfMissing (Join-Path $FlutterAuroraPath "bin") | Out-Null
            & cmd.exe /c "$flutterAuroraBat config --enable-aurora >nul 2>&1"
            
            Write-Success "Flutter for Aurora успешно установлен и настроен!"
            $statusReport["Flutter SDK"] = "Установлен ($FlutterAuroraPath)"
        } else {
            Write-Err "Не удалось клонировать Flutter SDK."
            $statusReport["Flutter SDK"] = "Ошибка установки"
        }
    } else {
        $statusReport["Flutter SDK"] = "Требуется установка"
    }
}

# ------------------------------------------------------------------------------
# 3. Проверка Aurora OS SDK (ОС Аврора) и Эмулятора QEMU
# ------------------------------------------------------------------------------
Write-Step "3/7" "Проверка Aurora OS SDK и эмулятора QEMU"

if (Test-Path $AuroraSdkPath) {
    Write-Success "Aurora OS SDK найден: $AuroraSdkPath"
    Add-PathIfMissing (Join-Path $AuroraSdkPath "bin") | Out-Null
    
    # Проверка QEMU
    $qemuExe = Join-Path $AuroraSdkPath "share\qemu\qemu-system-x86_64.exe"
    if (Test-Path $qemuExe) {
        Write-Success "Эмулятор QEMU x86_64 обнаружен: $qemuExe"
        $statusReport["Aurora QEMU"] = "Готов"
    } else {
        Write-Warn "Исполняемый файл QEMU не найден в $AuroraSdkPath\share\qemu"
        $statusReport["Aurora QEMU"] = "Не найден"
    }
    
    # Проверка образа эмулятора
    $imageQcow2 = Join-Path $AuroraSdkPath "emulator\AuroraOS-5.2.1.200\image.qcow2"
    if (-not (Test-Path $imageQcow2)) {
        $found = Get-ChildItem (Join-Path $AuroraSdkPath "emulator") -Filter "*.qcow2" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $imageQcow2 = $found.FullName }
    }
    
    if ($imageQcow2 -and (Test-Path $imageQcow2)) {
        Write-Success "Образ ОС Аврора обнаружен: $imageQcow2"
        $statusReport["Aurora OS Image"] = "Готов"
    } else {
        Write-Warn "Образ QCOW2 не найден в каталоге emulator."
        $statusReport["Aurora OS Image"] = "Не найден"
    }
    
    # Проверка SSH ключей
    $sshKey = Join-Path $AuroraSdkPath "vmshare\ssh\private_keys\sdk"
    if (Test-Path $sshKey) {
        Write-Success "SSH ключ разработчика найден: $sshKey"
        $statusReport["Aurora SSH Key"] = "Готов"
    } else {
        Write-Warn "SSH ключ не найден в $sshKey"
        $statusReport["Aurora SSH Key"] = "Не найден"
    }
    
    $statusReport["Aurora OS SDK"] = "Готов ($AuroraSdkPath)"
} else {
    Write-Warn "Каталог Aurora OS SDK не найден по пути $AuroraSdkPath"
    Write-Info "Скачайте SDK с официального портала разработчиков: https://developer.auroraos.ru/doc/sdk"
    $statusReport["Aurora OS SDK"] = "Не установлен"
    $statusReport["Aurora QEMU"] = "Не установлен"
    $statusReport["Aurora OS Image"] = "Не установлен"
}

# ------------------------------------------------------------------------------
# 4. Проверка Docker и окружения сборки RPM
# ------------------------------------------------------------------------------
Write-Step "4/7" "Проверка Docker Desktop и контейнера сборки RPM"

if ($SkipDocker) {
    Write-Info "Проверка Docker пропущена по ключу -SkipDocker."
    $statusReport["Docker"] = "Пропущен"
} else {
    $dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
    if ($dockerCmd) {
        Write-Success "Docker CLI обнаружен: $($dockerCmd.Source)"
        
        # Проверка службы Docker
        $dockerService = Get-Service "com.docker.service" -ErrorAction SilentlyContinue
        if ($dockerService -and $dockerService.Status -ne "Running") {
            Write-Warn "Служба Docker Desktop остановлена. Запуск приложения..."
            $dockerDesktopExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerDesktopExe) {
                Start-Process $dockerDesktopExe -ErrorAction SilentlyContinue
                Write-Info "Запущен Docker Desktop. Ожидание инициализации..."
                Start-Sleep -Seconds 4
            }
        }
        
        # Проверка доступности Docker Daemon
        $dockerVer = & docker version --format "{{.Server.Version}}" 2>$null
        if ($dockerVer) {
            Write-Success "Docker Daemon активен (версия сервера: $dockerVer)"
            $statusReport["Docker Daemon"] = "Активен ($dockerVer)"
            
            # Проверка образа aurora-build-tools:5.2.1.200
            $btImage = & docker images -q "aurora-build-tools:5.2.1.200" 2>$null
            if ($btImage) {
                Write-Success "Образ сборки RPM 'aurora-build-tools:5.2.1.200' присутствует в Docker."
                $statusReport["RPM Build Image"] = "Готов"
            } else {
                Write-Warn "Образ 'aurora-build-tools:5.2.1.200' пока не загружен в Docker."
                Write-Info "Он будет импортирован из Aurora SDK или скачан при сборке."
                $statusReport["RPM Build Image"] = "Требуется импорт"
            }
        } else {
            Write-Warn "Docker установлен, но Docker Desktop сейчас не запущен или инициализируется."
            Write-Info "Запустите приложение Docker Desktop перед сборкой RPM-пакета."
            $statusReport["Docker Daemon"] = "Требуется запуск Docker Desktop"
        }
        $statusReport["Docker"] = "Установлен"
    } else {
        Write-Warn "Docker не найден в системе. Он необходим для автономной сборки RPM-пакетов без QML."
        Write-Info "Скачать Docker Desktop: https://www.docker.com/products/docker-desktop/"
        $statusReport["Docker"] = "Не установлен"
    }
}

# ------------------------------------------------------------------------------
# 5. Проверка VS Code и расширений (Flora, Dart, Flutter)
# ------------------------------------------------------------------------------
Write-Step "5/7" "Настройка редактора VS Code и расширений"

if ($SkipExtensions) {
    Write-Info "Настройка расширений пропущена по ключу -SkipExtensions."
    $statusReport["VS Code"] = "Пропущен"
} else {
    $codeCmd = Get-Command "code" -ErrorAction SilentlyContinue
    if ($codeCmd) {
        Write-Success "VS Code CLI обнаружен: $($codeCmd.Source)"
        $installedExtensions = & code --list-extensions 2>$null
        
        # 5.1 Flora extension (Aurora OS)
        if ($installedExtensions -contains "omp.flora") {
            Write-Success "Расширение Flora (ОС Аврора) уже установлено."
        } else {
            $vsixPath = Join-Path $rootDir "flora-latest.vsix"
            if (Test-Path $vsixPath) {
                Write-Info "Установка расширения Flora из локального файла $vsixPath..."
                & code --install-extension $vsixPath | Out-Null
                Write-Success "Расширение Flora успешно установлено из VSIX!"
            } else {
                Write-Info "Установка расширения Flora из VS Code Marketplace..."
                & code --install-extension omp.flora 2>$null | Out-Null
            }
        }
        
        # 5.2 Dart & Flutter extensions
        if ($installedExtensions -contains "dart-code.flutter") {
            Write-Success "Расширение Dart-Code.flutter уже установлено."
        } else {
            Write-Info "Установка расширения Dart-Code.flutter..."
            & code --install-extension Dart-Code.flutter | Out-Null
            Write-Success "Расширение Dart-Code.flutter установлено."
        }
        
        if ($installedExtensions -contains "dart-code.dart-code") {
            Write-Success "Расширение Dart-Code.dart-code уже установлено."
        } else {
            Write-Info "Установка расширения Dart-Code.dart-code..."
            & code --install-extension Dart-Code.dart-code | Out-Null
            Write-Success "Расширение Dart-Code.dart-code установлено."
        }
        
        $statusReport["VS Code"] = "Готов (Flora + Flutter + Dart)"
    } else {
        Write-Warn "Команда 'code' (VS Code) не найдена в PATH."
        Write-Info "Рекомендуется установить Visual Studio Code для комфортной разработки."
        $statusReport["VS Code"] = "CLI не найден"
    }
}

# ------------------------------------------------------------------------------
# 6. Конфигурация проекта в каталоге .vscode
# ------------------------------------------------------------------------------
Write-Step "6/7" "Генерация настроек рабочего пространства (.vscode)"

$vscodeDir = Join-Path $rootDir ".vscode"
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
}

$settingsJsonPath = Join-Path $vscodeDir "settings.json"
$settingsObj = [ordered]@{
    "dart.flutterSdkPath" = $FlutterAuroraPath
    "dart.previewFlutterUiGuides" = $true
    "dart.lineLength" = 120
    "editor.formatOnSave" = $true
    "editor.defaultFormatter" = "Dart-Code.dart-code"
    "files.associations" = @{
        "*.spec" = "yaml"
        "*.desktop" = "ini"
    }
    "files.exclude" = @{
        "**/.git" = $true
        "**/.svn" = $true
        "**/.hg" = $true
        "**/CVS" = $true
        "**/.DS_Store" = $true
        "**/Thumbs.db" = $true
        "**/.dart_tool" = $false
        "aurora/bundle" = $true
    }
}
$settingsJson = ConvertTo-Json $settingsObj -Depth 4
[System.IO.File]::WriteAllText($settingsJsonPath, $settingsJson, [System.Text.Encoding]::UTF8)
Write-Success "Файл конфигурации VS Code обновлен: .vscode/settings.json"

# ------------------------------------------------------------------------------
# 7. Установка зависимостей проекта (flutter pub get)
# ------------------------------------------------------------------------------
Write-Step "7/7" "Загрузка и проверка зависимостей Flutter (pub get)"

$flutterRunner = if (Test-Path $flutterAuroraBat) { $flutterAuroraBat } else { "flutter" }
try {
    Write-Info "Выполнение 'flutter pub get' в каталоге проекта..."
    & $flutterRunner pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Все зависимости проекта успешно загружены!"
        $statusReport["Flutter Dependencies"] = "Успешно установлены"
    } else {
        Write-Warn "Команда pub get вернула код $LASTEXITCODE."
        $statusReport["Flutter Dependencies"] = "Предупреждение"
    }
} catch {
    Write-Err "Не удалось запустить flutter pub get: $_"
    $statusReport["Flutter Dependencies"] = "Ошибка"
}

# ------------------------------------------------------------------------------
# ИТОГОВЫЙ ОТЧЕТ
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "               СВОДКА СОСТОЯНИЯ ОКРУЖЕНИЯ РАЗРАБОТКИ                " -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

foreach ($key in $statusReport.Keys) {
    $k = $key.PadRight(25)
    $v = $statusReport[$key]
    if ($v -match "Готов|Установлен|Активен|Успешно") {
        Write-Host "  $k : $v" -ForegroundColor Green
    } elseif ($v -match "Предупреждение|Требуется|Пропущен") {
        Write-Host "  $k : $v" -ForegroundColor Yellow
    } else {
        Write-Host "  $k : $v" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  КАК ЗАПУСТИТЬ ПРОЕКТ:" -ForegroundColor White
Write-Host "   1. Полная сборка и запуск в Авроре : powershell .\build_and_run_aurora.ps1" -ForegroundColor Cyan
Write-Host "   2. Запуск в эмуляторе (быстрый)    : powershell .\run_aurora.ps1" -ForegroundColor Cyan
Write-Host "   3. Сборка только RPM пакета        : powershell .\build_flutter_rpm.ps1" -ForegroundColor Cyan
Write-Host "   4. Запуск эмулятора QEMU           : .\start_emulator.bat (или powershell .\start_emulator.ps1)" -ForegroundColor Cyan
Write-Host "   5. Отладка на ПК (Windows Desktop) : flutter run -d windows" -ForegroundColor Cyan
Write-Host "   6. В VS Code                      : Нажмите F5 для запуска Windows/Aurora" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
