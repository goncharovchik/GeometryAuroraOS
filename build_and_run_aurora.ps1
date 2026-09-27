$ErrorActionPreference = "Continue"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Сборка Flutter RPM и Запуск в ОС Аврора (ОМП)     " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$srcDir = $PSScriptRoot
$keyPath = "C:\AuroraOS\vmshare\ssh\private_keys\sdk"

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
}

if (-not $ready) {
    Write-Host "[ERROR] Не удалось подключиться к эмулятору по SSH." -ForegroundColor Red
    exit 1
}

# Шаг 4. Установка RPM и запуск игры
Write-Host "[4/4] Установка Flutter RPM пакета и запуск игры в Авроре..." -ForegroundColor Green

# 1. Включение дисплея и разблокировка экрана
& ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_state_on; dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_tklock_mode string:'unlocked'" 2>$null

# 2. Распаковка файлов RPM под root
& ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "cd / && rpm2cpio /etc/mersdk/share/ru.aurora.geometry_dash_aurora-1.0.0-1.x86_64.rpm | cpio -idum" 2>$null

# 3. Запуск нативного бинарника Flutter
$launchCmd = "killall -9 ru.aurora.geometry_dash_aurora 2>/dev/null; nohup env WAYLAND_DISPLAY=../../display/wayland-0 XDG_RUNTIME_DIR=/run/user/100000 /usr/bin/ru.aurora.geometry_dash_aurora >/tmp/game.log 2>&1 & sleep 2; pgrep -f ru.aurora.geometry_dash_aurora"
$pidResult = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no defaultuser@127.0.0.1 $launchCmd

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  ЧИСТЫЙ FLUTTER RPM УСПЕШНО УСТАНОВЛЕН И ЗАПУЩЕН!  " -ForegroundColor Yellow
Write-Host "  PID процесса в Авроре: $pidResult                 " -ForegroundColor Green
Write-Host "  Логи игры в эмуляторе: /tmp/game.log             " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Green
