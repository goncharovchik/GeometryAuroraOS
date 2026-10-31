[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 >$null 2>&1

$qemu = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
if ($qemu) {
    Write-Host "QEMU emulator is already running (PID: $($qemu.Id))."
    exit 0
}

$auroraSdk = "C:\AuroraOS"
if ($env:AURORA_SDK_PATH -and (Test-Path $env:AURORA_SDK_PATH)) {
    $auroraSdk = $env:AURORA_SDK_PATH
}

$qemuExe = Join-Path $auroraSdk "share\qemu\qemu-system-x86_64.exe"
if (-not (Test-Path $qemuExe)) {
    Write-Host "[ERROR] QEMU не найден по пути $qemuExe" -ForegroundColor Red
    Write-Host "Убедитесь, что Aurora OS SDK установлен в $auroraSdk" -ForegroundColor Yellow
    exit 1
}

$emulDir = Join-Path $auroraSdk "emulator\AuroraOS-5.2.1.200"
if (-not (Test-Path $emulDir)) {
    $found = Get-ChildItem (Join-Path $auroraSdk "emulator") -Directory -Filter "AuroraOS*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $emulDir = $found.FullName }
}

$imagePath = Join-Path $emulDir "image.qcow2"
$vmsharePath = Join-Path $emulDir "vmshare"
$sshPath = Join-Path $emulDir "ssh"
$mediaPath = Join-Path $auroraSdk "emulator\media"

if (-not (Test-Path $imagePath)) {
    Write-Host "[ERROR] Образ эмулятора не найден: $imagePath" -ForegroundColor Red
    exit 1
}

$imageForward = $imagePath.Replace('\', '/')

$qemuArgs = @(
    "-M", "q35,i8042=off",
    "-m", "4096M",
    "-smp", "2",
    "-accel", "whpx,kernel-irqchip=off",
    "-name", "AuroraOS-5.2.1.200",
    "-device", "virtio-vga-gl,xres=800,yres=360",
    "-display", "sdl,gl=on",
    "-device", "virtio-tablet-pci",
    "-device", "ahci,id=ahci",
    "-device", "ide-hd,drive=disk,bus=ahci.0",
    "-audiodev", "sdl,id=audiodev0",
    "-device", "intel-hda",
    "-device", "hda-output,audiodev=audiodev0",
    "-nodefaults",
    "-drive", "id=disk,file=$imageForward,if=none",
    "-nic", "user,mac=52:54:00:12:34:56,hostfwd=tcp::2223-:22",
    "-virtfs", "local,path=$vmsharePath,mount_tag=configs,security_model=mapped,readonly=on",
    "-virtfs", "local,path=$mediaPath,mount_tag=media,security_model=mapped,readonly=on",
    "-virtfs", "local,path=$sshPath,mount_tag=ssh,security_model=mapped,readonly=on"
)

Start-Process -FilePath $qemuExe -ArgumentList $qemuArgs -WorkingDirectory (Join-Path $auroraSdk "share\qemu")
Write-Host "Started Aurora OS QEMU Emulator window."