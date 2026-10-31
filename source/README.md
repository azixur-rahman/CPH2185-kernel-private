# Falcon-AZ working source

This directory contains the Bluetooth source that is built into the
Falcon-AZ kernel for the OPPO CPH2185 / CPH2179 (MT6765).

The complete working kernel tree is stored in the `falcon-az-source`
branch. The files here are the Bluetooth part of that tree.

## Bluetooth layout

```text
source/bt/mt66xx/Makefile
source/bt/mt66xx/legacy/Makefile
source/bt/mt66xx/legacy/Makefile.oppo
source/bt/mt66xx/legacy/Android.mk
source/bt/mt66xx/legacy/bt.h
source/bt/mt66xx/legacy/stp_chrdev_bt.c
source/bt/mt66xx/legacy/fw_log_bt.c
source/bt/mt66xx/legacy/init.bt_drv.rc
```

`Makefile.oppo` is the original vendor file, kept for reference.
`Makefile` is the working built-in version used by the build.

## What was changed for Bluetooth

1. The top-level connectivity Makefile keeps this entry active:

   ```make
   obj-$(CONFIG_MTK_COMBO_BT) += bt/mt66xx/
   ```

2. A kbuild Makefile was added at `bt/mt66xx/Makefile`:

   ```make
   obj-$(CONFIG_MTK_COMBO_BT) += legacy/
   ```

3. The legacy driver Makefile was changed from a module to built-in:

   ```make
   obj-y += $(MODULE_NAME).o
   $(MODULE_NAME)-y += stp_chrdev_bt.o
   $(MODULE_NAME)-y += fw_log_bt.o
   ```

   The WMT include path was changed to the kernel tree:

   ```make
   WMT_SRC_FOLDER := $(srctree)/drivers/misc/mediatek/connectivity/common
   ```

4. `MTK_WCN_REMOVE_KERNEL_MODULE` is defined by the top-level connectivity
   Makefile. That makes `stp_chrdev_bt.c` export
   `mtk_wcn_stpbt_drv_init()` instead of using `module_init()`. The
   connectivity bring-up calls this function, which creates `/dev/stpbt`
   for the Bluetooth HAL.

## Config

The working defconfig contains:

```text
CONFIG_MTK_COMBO=y
CONFIG_MTK_COMBO_BT=y
CONFIG_MTK_COMBO_WIFI=y
CONFIG_MTK_COMBO_CHIP_CONSYS_6765=y
CONFIG_MTK_CONNSYS_DEDICATED_LOG_PATH=y
```

`CONFIG_BT` is intentionally not required. The legacy Bluetooth driver is
a character device (`/dev/stpbt`) and the vendor Bluetooth HAL speaks HCI
through it.

## Build

The GitHub Actions workflow is the supported build path. It prepares the
source, applies every patch, builds `Image.gz-dtb`, and packages a
kernel-only AnyKernel zip.
