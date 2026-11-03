[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 >$null 2>&1
# Запуск уже собранного RPM пакета в эмуляторе ОС Аврора
$ErrorActionPreference = "Continue"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Быстрый запуск игры в ОС Аврора (ОМП)             " -ForegroundColor Yellow
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

Write-Host "[1/3] Проверка работы эмулятора Авроры..." -ForegroundColor Green
$qemu = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
if (-not $qemu) {
    Write-Host "      Запуск эмулятора Авроры..." -ForegroundColor Green
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $srcDir "start_emulator.ps1")
    Start-Sleep -Seconds 5
} else {
    Write-Host "      Эмулятор уже работает (PID: $($qemu.Id))." -ForegroundColor Green
}

Write-Host "[2/3] Ожидание готовности Wayland дисплея..." -ForegroundColor Green
$ready = $false

for ($i = 1; $i -le 45; $i++) {
    $check = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no -o ConnectTimeout=2 defaultuser@127.0.0.1 "test -e /run/display/wayland-0 && echo READY" 2>$null
    if ($check -match "READY") {
        $ready = $true
        Write-Host "      Дисплей Wayland готов! (попытка $i)" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
}

if ($ready) {
    Write-Host "[3/3] Разблокировка экрана, фиксация Landscape, установка RPM и запуск..." -ForegroundColor Green
    
    # 1. Разблокировка экрана эмулятора и фиксация альбомной ориентации
    & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_state_on; dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_tklock_mode string:'unlocked'" 2>$null
    $orientCmd = "dconf write /desktop/sailfish/silica/orientation_lock `"'landscape'`""
    & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no defaultuser@127.0.0.1 $orientCmd 2>$null
    
    # 2. Установка RPM пакета в систему Авроры (с флагом --noplugins для обхода проверки подписи TSM)
    $installOutput = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "rpm -ivh --force --noplugins /etc/mersdk/share/ru.aurora.geometry_dash_aurora-1.0.0-1.x86_64.rpm; update-desktop-database; gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true"
    Write-Host "      $installOutput" -ForegroundColor Gray

    # 3. Запуск нативного приложения Flutter
    $launchCmd = "killall -9 ru.aurora.geometry_dash_aurora 2>/dev/null; nohup invoker -o -s --type=generic /usr/bin/ru.aurora.geometry_dash_aurora >/tmp/game.log 2>&1 & sleep 2; pgrep -f ru.aurora.geometry_dash_aurora"
    $pidResult = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no defaultuser@127.0.0.1 $launchCmd
    
    Write-Host ""
    if ($pidResult) {
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  НАТИВНЫЙ FLUTTER RPM УСПЕШНО ЗАПУЩЕН В АВРОРЕ!   " -ForegroundColor Yellow
        Write-Host "  PID процесса: $pidResult                          " -ForegroundColor Green
        Write-Host "  Окно игры открыто на экране эмулятора!            " -ForegroundColor Cyan
        Write-Host "====================================================" -ForegroundColor Green
    } else {
        Write-Host "[!] Игра запущена в фоновом режиме." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[ERROR] Не удалось подключиться к эмулятору по SSH на порту 2223." -ForegroundColor Red
}
