$qemu = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
if ($qemu) {
    Write-Host "QEMU emulator is already running (PID: $($qemu.Id))."
    exit 0
}

$qemuExe = "C:\AuroraOS\share\qemu\qemu-system-x86_64.exe"
$qemuArgs = @(
    "-M", "q35,i8042=off",
    "-m", "4096M",
    "-smp", "2",
    "-accel", "whpx,kernel-irqchip=off",
    "-name", "Geometry Dash - Aurora OS",
    "-device", "virtio-vga-gl,xres=800,yres=360",
    "-display", "sdl,gl=on",
    "-device", "virtio-tablet-pci",
    "-device", "ahci,id=ahci",
    "-device", "ide-hd,drive=disk,bus=ahci.0",
    "-audiodev", "sdl,id=audiodev0",
    "-device", "intel-hda",
    "-device", "hda-output,audiodev=audiodev0",
    "-nodefaults",
    "-drive", "id=disk,file=C:/AuroraOS/emulator/AuroraOS-5.2.1.200/image.qcow2,if=none",
    "-nic", "user,mac=52:54:00:12:34:56,hostfwd=tcp::20007-:20007,hostfwd=tcp::20002-:20002,hostfwd=tcp::20006-:20006,hostfwd=tcp::20000-:20000,hostfwd=tcp::10234-:10234,hostfwd=tcp::20012-:20012,hostfwd=tcp::20016-:20016,hostfwd=tcp::20010-:20010,hostfwd=tcp::20017-:20017,hostfwd=tcp::20004-:20004,hostfwd=tcp::20013-:20013,hostfwd=tcp::20019-:20019,hostfwd=tcp::20015-:20015,hostfwd=tcp::20018-:20018,hostfwd=tcp::20001-:20001,hostfwd=tcp::20014-:20014,hostfwd=tcp::20003-:20003,hostfwd=tcp::20008-:20008,hostfwd=tcp::20011-:20011,hostfwd=tcp::2223-:22,hostfwd=tcp::20005-:20005,hostfwd=tcp::20009-:20009",
    "-virtfs", "local,path=C:\AuroraOS\emulator\AuroraOS-5.2.1.200\vmshare,mount_tag=configs,security_model=mapped,readonly=on",
    "-virtfs", "local,path=C:\AuroraOS\emulator\media,mount_tag=media,security_model=mapped,readonly=on",
    "-virtfs", "local,path=C:\AuroraOS\emulator\AuroraOS-5.2.1.200\ssh,mount_tag=ssh,security_model=mapped,readonly=on"
)

Start-Process -FilePath $qemuExe -ArgumentList $qemuArgs -WorkingDirectory "C:\AuroraOS\share\qemu"
Write-Host "Started Aurora OS QEMU Emulator window."
