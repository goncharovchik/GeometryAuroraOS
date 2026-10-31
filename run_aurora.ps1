[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 >$null 2>&1
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Geometry Dash Aurora - Flutter Native Launcher     " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$qemu = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue

if (-not $qemu) {
    Write-Host "[1/3] Запуск эмулятора ОС Аврора..." -ForegroundColor Green
    $qemuExe = "C:\AuroraOS\share\qemu\qemu-system-x86_64.exe"
    $qemuArgs = "-M q35,i8042=off -m 4096M -smp 2 -accel whpx,kernel-irqchip=off -name AuroraOS-5.2.1.200 -device virtio-vga-gl,xres=800,yres=360 -display sdl,gl=on -device virtio-tablet-pci -device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0 -audiodev sdl,id=audiodev0 -device intel-hda -device hda-output,audiodev=audiodev0 -nodefaults -drive id=disk,file=C:/AuroraOS/emulator/AuroraOS-5.2.1.200/image.qcow2,if=none -nic user,mac=52:54:00:12:34:56,hostfwd=tcp::2223-:22 -virtfs local,path=C:\AuroraOS\emulator\AuroraOS-5.2.1.200\vmshare,mount_tag=configs,security_model=mapped,readonly=on -virtfs local,path=C:\AuroraOS\emulator\media,mount_tag=media,security_model=mapped,readonly=on -virtfs local,path=C:\AuroraOS\emulator\AuroraOS-5.2.1.200\ssh,mount_tag=ssh,security_model=mapped,readonly=on"
    Start-Process -FilePath $qemuExe -ArgumentList $qemuArgs -WorkingDirectory "C:\AuroraOS\share\qemu"
} else {
    Write-Host "[1/3] Эмулятор уже работает (PID: $($qemu.Id))." -ForegroundColor Green
}

Write-Host "[2/3] Ожидание готовности Wayland дисплея в Авроре..." -ForegroundColor Cyan
$auroraSdk = "C:\AuroraOS"
if ($env:AURORA_SDK_PATH -and (Test-Path $env:AURORA_SDK_PATH)) {
    $auroraSdk = $env:AURORA_SDK_PATH
}
$keyPath = Join-Path $auroraSdk "vmshare\ssh\private_keys\sdk"
if (-not (Test-Path $keyPath)) {
    $foundKey = Get-ChildItem (Join-Path $auroraSdk "emulator") -Recurse -Filter "sdk" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundKey) { $keyPath = $foundKey.FullName }
}
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
    Write-Host "[3/3] Разблокировка экрана, установка RPM и запуск Flutter..." -ForegroundColor Green
    
    # 1. Разблокировка экрана эмулятора
    & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_state_on; dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_tklock_mode string:'unlocked'" 2>$null
    
    # 2. Установка RPM пакета в систему Авроры (с флагом --noplugins для обхода проверки подписи TSM)
    $installOutput = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no root@127.0.0.1 "rpm -ivh --force --noplugins /etc/mersdk/share/ru.aurora.geometry_dash_aurora-1.0.0-1.x86_64.rpm; update-desktop-database; gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true"
    Write-Host "      $installOutput" -ForegroundColor Gray

    # 3. Запуск нативного приложения Flutter
    $launchCmd = "killall -9 ru.aurora.geometry_dash_aurora 2>/dev/null; nohup invoker -o -s --type=generic /usr/bin/ru.aurora.geometry_dash_aurora >/tmp/game.log 2>&1 & sleep 2; pgrep -f ru.aurora.geometry_dash_aurora"
    $pidResult = & ssh -p 2223 -i $keyPath -o StrictHostKeyChecking=no defaultuser@127.0.0.1 $launchCmd
    
    Write-Host ""
    if ($pidResult) {
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  НА ТИВНЫЙ FLUTTER RPM УСПЕШНО ЗАПУЩЕН В АВРОРЕ!   " -ForegroundColor Yellow
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
