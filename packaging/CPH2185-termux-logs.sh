#!/system/bin/sh
# CPH2185 touch log collector - Termux/root ke liye
# Author: Azizur Rahman <iremm12rr@gmail.com>
# Sab logs /sdcard/CPH2185-logs/<date-time>/ me save honge.

ROOT=/sdcard/CPH2185-logs
TS=$(date +%Y%m%d-%H%M%S)
D="$ROOT/$TS"

mkdir -p "$D" || {
    echo "ERROR: $D create nahi hua. Termux me 'termux-setup-storage' chalao."
    exit 1
}
cd "$D" || exit 1

echo "Logs save ho rahe hain: $D"
echo "Ab se 12 second tak screen ko touch karte raho..."
echo

{
    echo "===== CPH2185 TOUCH LOG ====="
    echo "date: $(date)"
    echo "uname: $(uname -a)"
    echo "proc_version: $(cat /proc/version)"
    echo "build: $(getprop ro.build.display.id)"
    echo "fingerprint: $(getprop ro.build.fingerprint)"
    echo "device: $(getprop ro.product.device) / $(getprop ro.product.model)"
    echo "hardware: $(getprop ro.hardware)"
    echo "slot: $(getprop ro.boot.slot_suffix)"
    echo "dtb_idx: $(getprop ro.boot.dtb_idx)"
    echo "bootreason: $(getprop ro.boot.bootreason)"
    echo "cmdline: $(cat /proc/cmdline)"
} > 00-device.txt 2>&1

getprop > 01-getprop.txt 2>&1
cat /proc/cmdline > 02-cmdline.txt 2>&1

{
    echo "===== /proc/bus/input/devices ====="
    cat /proc/bus/input/devices
    echo
    echo "===== input event names ====="
    for f in /sys/class/input/event*/device/name; do
        [ -f "$f" ] || continue
        echo "$f: $(cat "$f")"
    done
    echo
    echo "===== /dev/input ====="
    ls -l /dev/input 2>/dev/null
} > 03-input-devices.txt 2>&1

cat /proc/interrupts > 04-interrupts.txt 2>&1
grep -iE 'touch|nt36|novatek|spi|eint|^ *19:' /proc/interrupts > 05-interrupts-touch.txt 2>&1

if ! dmesg -s 1048576 > 06-dmesg-full.txt 2>&1; then
    dmesg > 06-dmesg-full.txt 2>&1
fi
grep -iE 'novatek|nvt|nt36|touch|touchpanel|swrst|chip|firmware|probe|spi|irq|error|fail' \
    06-dmesg-full.txt > 07-dmesg-touch.txt 2>&1

logcat -b all -d -v threadtime > 08-logcat-full.txt 2>&1
grep -iE 'novatek|nvt|nt36|touch|touchpanel|spi|input|error|fail' \
    08-logcat-full.txt > 09-logcat-touch.txt 2>&1

dumpsys input > 10-dumpsys-input.txt 2>&1

{
    echo "===== SPI DEVICES ====="
    ls -l /sys/bus/spi/devices 2>/dev/null
    echo
    for d in /sys/bus/spi/devices/*; do
        [ -e "$d" ] || continue
        echo "--- $d"
        cat "$d/modalias" 2>/dev/null
        readlink "$d/driver" 2>/dev/null
    done
    echo
    echo "===== SPI DRIVERS ====="
    ls -l /sys/bus/spi/drivers 2>/dev/null
} > 11-spi.txt 2>&1

{
    echo "===== DEVICE TREE TOUCH / SPI ====="
    DT=/proc/device-tree
    [ -d "$DT" ] || DT=/sys/firmware/devicetree/base
    find "$DT" -type f 2>/dev/null \
        | grep -Ei 'touch|novatek|spi@11013000' \
        | while read f; do
            echo "--- $f"
            tr '\000' ' ' < "$f" 2>/dev/null
            echo
        done
} > 12-devicetree-touch.txt 2>&1

{
    echo "===== getevent -lp ====="
    if command -v timeout >/dev/null 2>&1; then
        timeout 5 getevent -lp
    else
        getevent -lp
    fi
} > 13-getevent-list.txt 2>&1

{
    echo "===== LIVE EVENTS 12 SEC ====="
    getevent -lt &
    P=$!
    sleep 12
    kill "$P" 2>/dev/null
    wait "$P" 2>/dev/null
    echo "===== LIVE EVENTS END ====="
} > 14-getevent-live.txt 2>&1

{
    echo "CPH2185 LOG SUMMARY"
    echo "Author: Azizur Rahman"
    echo "Date: $(date)"
    echo "Folder: $D"
    echo
    echo "===== TOUCH INPUT DEVICE? ====="
    grep -i -A15 'Name="touchpanel"' /proc/bus/input/devices 2>/dev/null
    echo
    echo "===== TOUCH IRQ? ====="
    grep -iE 'touch|19:' /proc/interrupts 2>/dev/null
    echo
    echo "===== KEY DMESG LINES ====="
    grep -iE 'novatek,swrst-n8-addr missing|SWRST_N8_ADDR|nvt_ts_probe|touchpanel|chip is not identified|parse dt error|gpio config error|request irq|no nova ic' \
        06-dmesg-full.txt 2>/dev/null | tail -80
    echo
    echo "===== FILES ====="
    ls -lh
} > 15-SUMMARY.txt 2>&1

chmod -R 0777 "$D" 2>/dev/null

cd "$ROOT" || exit 1
tar -czf "CPH2185-logs-$TS.tar.gz" "$TS" 2>/dev/null
chmod 0666 "CPH2185-logs-$TS.tar.gz" 2>/dev/null

echo
echo "DONE"
echo "Folder: $D"
echo "Bundle: $ROOT/CPH2185-logs-$TS.tar.gz"
echo
echo "15-SUMMARY.txt, 07-dmesg-touch.txt, 03-input-devices.txt aur bundle chat me bhejo."
