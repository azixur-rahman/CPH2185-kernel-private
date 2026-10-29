#!/system/bin/sh
# Falcon-AZ WiFi diagnostic for CPH2185 / CPH2179
# Author: Azizur Rahman
# Run as root: su -c sh /sdcard/Falcon-AZ-wifi-diag.sh
# Output: /sdcard/Falcon-AZ-wifi-diag.txt

OUT=/sdcard/Falcon-AZ-wifi-diag.txt
DMESG=/sdcard/Falcon-AZ-dmesg.txt
LOGCAT=/sdcard/Falcon-AZ-logcat.txt

exec >"$OUT" 2>&1

echo "===== Falcon-AZ WiFi diagnostic ====="
echo "date: $(date)"
echo "uname: $(uname -a)"
echo "proc_version: $(cat /proc/version)"
echo

echo "===== device props ====="
for p in ro.product.device ro.product.model ro.product.hw ro.build.display.id ro.build.display.ota ro.build.kernel.id ro.boot.hardware ro.boot.dtb_idx ro.boot.dtbo_idx ro.boot.boot_devices ro.boot.verifiedbootstate; do
  echo "$p=$(getprop $p)"
done
echo

echo "===== boot partition layout ====="
BOOT=/dev/block/by-name/boot
if [ -e "$BOOT" ]; then
  ls -l "$BOOT"
  dd if="$BOOT" of=/sdcard/Falcon-AZ-boot-header.bin bs=4096 count=1 2>/dev/null
  echo "kernel_size=$(od -An -tu4 -j 8 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
  echo "ramdisk_size=$(od -An -tu4 -j 16 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
  echo "second_size=$(od -An -tu4 -j 24 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
  echo "page_size=$(od -An -tu4 -j 36 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
  echo "header_version=$(od -An -tu4 -j 40 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
  echo "dtb_size=$(od -An -tu4 -j 1648 -N 4 /sdcard/Falcon-AZ-boot-header.bin | tr -d ' ')"
else
  echo "boot partition not found at $BOOT"
fi
echo

echo "===== loaded modules (/proc/modules) ====="
cat /proc/modules 2>/dev/null
echo

echo "===== stock module files and vermagic ====="
for f in /vendor/lib/modules/*.ko /system/lib/modules/*.ko /odm/lib/modules/*.ko; do
  [ -f "$f" ] || continue
  echo "--- $f"
  ls -l "$f"
  if command -v strings >/dev/null 2>&1; then
    strings "$f" | grep -m1 'vermagic=' || echo "vermagic not found"
  else
    grep -a -o 'vermagic=[^ ]*' "$f" | head -1 || echo "vermagic not found"
  fi
  if command -v modinfo >/dev/null 2>&1; then
    modinfo "$f" 2>/dev/null | grep -E '^(filename|vermagic|version|name):'
  fi
done
echo

echo "===== module load errors in dmesg ====="
dmesg 2>/dev/null | grep -iE 'version magic|vermagic|module verification|module:.*(wmt|wlan|conn)|unknown symbol|disagrees about version' | tail -200
echo

echo "===== wmt / wlan userspace and devices ====="
for f in /vendor/bin/wmt_loader /system/bin/wmt_loader /vendor/bin/connsys_launcher /vendor/bin/wmt_launcher; do
  [ -e "$f" ] && ls -l "$f"
done
ls -l /dev/stpwmt /dev/wmtWifi /dev/stpbt /dev/stpgps /dev/stpant 2>/dev/null
echo

echo "===== processes ====="
ps -A 2>/dev/null | grep -iE 'wmt|conn|wlan|wifi|netd|hostapd|wpa_supplicant'
echo

echo "===== init services and props ====="
getprop 2>/dev/null | grep -iE 'init\.svc\.(wmt|wifi|wlan|conn)|wmt|wlan|wifi|connsys' | sort
echo

echo "===== init rc files mentioning wmt/wlan/wifi ====="
for d in /vendor/etc/init /system/etc/init /odm/etc/init; do
  [ -d "$d" ] || continue
  find "$d" -maxdepth 2 -type f 2>/dev/null | grep -iE 'wmt|wlan|wifi|conn' | while read f; do
    echo "--- $f"
    grep -inE 'wmt|wlan|wifi|conn|insmod|stpwmt' "$f" | head -60
  done
done
echo

echo "===== kernel config (if available) ====="
if [ -f /proc/config.gz ]; then
  zcat /proc/config.gz | grep -E 'CONFIG_(MTK_COMBO|MTK_COMBO_WIFI|WLAN_DRV_BUILD_IN|MODVERSIONS|MODULE_SIG|LOCALVERSION)'
else
  echo "/proc/config.gz not available"
fi
echo

echo "===== full dmesg saved to $DMESG ====="
dmesg >"$DMESG" 2>/dev/null
grep -iE 'wmt|wlan|wifi|connsys|stp|rom_patch|srh_|consys|version magic|vermagic' "$DMESG" 2>/dev/null | tail -600
echo

echo "===== full logcat saved to $LOGCAT ====="
logcat -b all -d -v threadtime >"$LOGCAT" 2>/dev/null
grep -iE 'wmt|wlan|wifi|connsys|wmt_loader|insmod|vermagic|module' "$LOGCAT" 2>/dev/null | tail -300
echo

echo "===== done ====="
echo "Send these files from /sdcard:"
echo "  Falcon-AZ-wifi-diag.txt"
echo "  Falcon-AZ-dmesg.txt"
echo "  Falcon-AZ-logcat.txt"
