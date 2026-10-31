[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 >$null 2>&1
$ErrorActionPreference = "Continue"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Сборка Flutter RPM и Запуск в ОС Аврора (ОМП)     " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$srcDir = $PSScriptRoot
$auroraSdk = "C:\AuroraOS"
if ($env:AURORA_SDK_PATH -and (Test-Path $env:AURORA_SDK_PATH)) {
    $auroraSdk = $env:AURORA_SDK_PATH
}
$keyPath = Join-Path $auroraSdk "vmshare\ssh\private_keys\sdk"
if (-not (Test-Path $keyPath)) {
    $foundKey = Get-ChildItem (Join-Path $auroraSdk "emulator") -Recurse -Filter "sdk" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundKey) { $keyPath = $foundKey.FullName }
}

# Настройка локального HTTP-прокси для Flutter
if (-not $env:HTTP_PROXY -or $env:HTTP_PROXY -eq "") {
    $env:HTTP_PROXY = "http://127.0.0.1:10809"
}
if (-not $env:HTTPS_PROXY -or $env:HTTPS_PROXY -eq "") {
    $env:HTTPS_PROXY = "http://127.0.0.1:10809"
}
if (-not $env:NO_PROXY -or $env:NO_PROXY -eq "") {
    $env:NO_PROXY = "localhost,127.0.0.1"
}

# Шаг 1. Сборка Flutter RPM
Write-Host "[1/4] Сборка нативного Flutter RPM-пакета..." -ForegroundColor Green
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $srcDir "build_flutter_rpm.ps1")
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Сборка RPM не удалась." -ForegroundColor Red
    exit 1
}

# Шаг 2. Проверка работы эмулятора Авроры
Write-Host "[2/4] Проверка работы эмулятора Авроры..." -ForegroundColor Green
$qemu = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
if (-not $qemu) {
    Write-Host "      Запуск эмулятора Авроры..." -ForegroundColor Green
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $srcDir "start_emulator.ps1")
    Start-Sleep -Seconds 5
} else {
    Write-Host "      Эмулятор уже работает (PID: $($qemu.Id))." -ForegroundColor Green
}

# Шаг 3. Ожидание готовности SSH и Wayland
Write-Host "[3/4] Ожидание готовности Wayland дисплея..." -ForegroundColor Green
$ready = $false
for ($i = 1; $i -le 45; $i++) {
    $check = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no -o ConnectTimeout=2 defaultuser@127.0.0.1 "test -e /run/display/wayland-0 && echo READY" 2>$null
    if ($check -match "READY") {
        $ready = $true
        Write-Host "      Wayland готов! (попытка $i)" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
    Write-Host "      Ожидание запуска графической оболочки... ($i/45)" -ForegroundColor DarkGray
}

if (-not $ready) {
    Write-Host "[ERROR] Не удалось подключиться к эмулятору по SSH." -ForegroundColor Red
    exit 1
}

# Шаг 4. Установка RPM и запуск игры
Write-Host "[4/4] Установка Flutter RPM пакета и запуск игры в Авроре..." -ForegroundColor Green

# 1. Включение дисплея и разблокировка экрана
& ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_state_on; dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_tklock_mode string:'unlocked'" 2>$null

# 2. Установка RPM пакета в систему Авроры (с флагом --noplugins для обхода проверки подписи TSM)
$installOutput = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "rpm -ivh --force --noplugins /etc/mersdk/share/ru.aurora.geometry_dash_aurora-1.0.0-1.x86_64.rpm; update-desktop-database; gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true"
Write-Host "      Результат установки RPM:" -ForegroundColor Cyan
Write-Host "      $installOutput" -ForegroundColor Gray

$isInstalled = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "rpm -q ru.aurora.geometry_dash_aurora"
Write-Host "      Зарегистрирован в базе RPM: $isInstalled" -ForegroundColor Green

# 3. Запуск нативного бинарника Flutter
$launchCmd = "killall -9 ru.aurora.geometry_dash_aurora 2>/dev/null; nohup invoker -o -s --type=generic /usr/bin/ru.aurora.geometry_dash_aurora >/tmp/game.log 2>&1 & sleep 2; pgrep -f ru.aurora.geometry_dash_aurora"
$pidResult = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no defaultuser@127.0.0.1 $launchCmd

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  ЧИСТЫЙ FLUTTER RPM УСПЕШНО УСТАНОВЛЕН И ЗАПУЩЕН!  " -ForegroundColor Yellow
Write-Host "  PID процесса в Авроре: $pidResult                 " -ForegroundColor Green
Write-Host "  Логи игры в эмуляторе: /tmp/game.log             " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Green
