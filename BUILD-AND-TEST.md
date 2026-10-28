# CPH2185 kernel build and touchscreen test

**Author:** Azizur Rahman  
**GitHub:** [azixur-rahman](https://github.com/azixur-rahman)

The GitHub Actions workflow at `.github/workflows/build-anykernel.yml` builds
the `CPH2185_defconfig` target and uploads an `AnyKernel-CPH2185-*.zip`
artifact. It packages the kernel with `packaging/cph2185-anykernel.sh`, the
CPH2185-specific installer.

The full touch diagnosis and the earlier commit history are in
[`CPH2185-FIX.md`](CPH2185-FIX.md).

## Flashing checklist

1. Keep a copy of the stock `boot.img` and know how to restore it.
2. Unlock the bootloader and use a recovery/installer that supports AnyKernel3.
3. Download the workflow's **AnyKernel-CPH2185** artifact and extract the zip.
4. Flash it without wiping data. Do not flash the debug artifact as a kernel zip.
5. After boot, check whether touch works before changing other kernel settings.

If the phone bootloops or the display stays black, restore the stock boot image
from fastboot/recovery. Do not repeatedly reboot a failing kernel.

## Logs to collect if touch still does not work

The easiest method is Termux with root:

```sh
su -c 'sh /sdcard/CPH2185-termux-logs.sh'
```

The script saves everything to `/sdcard/CPH2185-logs/<date-time>/`.

If you are using a PC with adb instead:

```sh
adb shell getprop ro.product.device
adb shell getprop ro.build.display.id
adb shell getprop ro.boot.slot_suffix
adb shell uname -a
adb shell cat /proc/cmdline
adb shell cat /proc/version
adb shell cat /proc/bus/input/devices
adb shell getevent -lp
adb shell 'for f in /sys/class/input/event*/device/name; do printf "%s: " "$f"; cat "$f"; done'
adb shell 'su -c "dmesg"' > dmesg-after-cph2185-touch-fix.txt
adb logcat -b all -d -v threadtime > logcat-after-cph2185-touch-fix.txt
```

Then, while touching the screen for about ten seconds, run:

```sh
adb shell getevent -lt > getevent-touch-test.txt
```

Stop it with `Ctrl-C`. If `getevent` blocks, that is useful evidence too. Also
send the exact workflow run URL, the installed zip filename, and whether the
phone booted normally, bootlooped, or booted with touch missing.

The most important lines are those containing `NVT-ts`, `novatek`, `SWRST`,
`spi3`, `gpio`, `irq`, `firmware`, `input`, or `touch`. Do not trim kernel
oops/panic text or replace it with a screenshot.
