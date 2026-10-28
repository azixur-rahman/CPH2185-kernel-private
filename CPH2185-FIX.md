# CPH2185 (OPPO A15 / MT6765) touch fix

**Author:** Azizur Rahman  
**GitHub:** [azixur-rahman](https://github.com/azixur-rahman)  
**Status:** SOLVED  
**Fix branch:** `fix/touch-swrstd`  
**Fix commit:** `36a14edd37fe61ffb77bae37ab87126d4eaa998b`

## What was wrong in the earlier custom kernel

The stock CPH2185 kernel uses OPPO's vendor `touchpanel` driver. The custom
kernel enabled the in-tree Novatek NT36525B SPI driver instead:

```text
CONFIG_TOUCHSCREEN_NT36xxx_HOSTDL_SPI=y
```

That driver needs the DT property `novatek,swrst-n8-addr`. The stock CPH2185
DTBO does **not** contain that property. In the old code, `nvt_parse_dt()`
returned an error when the property was missing, so `nvt_ts_probe()` aborted
before it could:

- configure the reset/IRQ GPIOs
- identify the chip
- register the `touchpanel` input device
- request the touch IRQ

That is why the custom kernel had no `touchpanel` input device and no IRQ 19.

Adding the property to `oppo6765.dts` / `oppo6765_20271.dts` did not help,
because those files are DTBO overlays. An AnyKernel zip replaces only the
kernel in the boot image; it does not flash the DTBO partition. The phone kept
using the stock DTBO, which has no `novatek,swrst-n8-addr`.

## Commit history: problems fixed one by one

| Commit | What it fixed |
|---|---|
| `946254e` | Enabled `CONFIG_TOUCHSCREEN_NT36xxx_HOSTDL_SPI`; added `novatek,swrst-n8-addr` to the kernel DTS (which did not reach the DTBO). |
| `3335836` | Duplicate firmware symbols caused build/link failures. |
| `2fc7781` | Missing Novatek gesture state variables caused compile errors. |
| `2f3d5b5` | Restored the touch resume path after suspend. |
| `d7ba966` | Aligned the NT36525B resume firmware recovery sequence. |
| `94cb0ff` | Replaced a mismatched firmware blob with the stock HLT NT36525B firmware. |
| `cac85a33` | Enabled the boot touch IRQ, used falling-edge trigger, added a `saved_command_line` fallback, defaulted to the HLT panel, and declared `nvt_irq_enable()`. |
| `36a14ed` | **Final fix:** missing `novatek,swrst-n8-addr` no longer aborts probe. Uses the stock `0x03F0FE` default and guards `reset_global_gpio`. |

After `cac85a33`, the driver still failed at `nvt_parse_dt()`. The final
`36a14ed` change lets probe continue, so the input device and IRQ can be
registered.

## Final code change

```c
uint32_t SWRST_N8_ADDR = 0x03F0FE;

ret = of_property_read_u32(np, "novatek,swrst-n8-addr", &SWRST_N8_ADDR);
if (ret) {
    SWRST_N8_ADDR = 0x03F0FE;
    NVT_LOG("novatek,swrst-n8-addr missing, using default 0x%06X\n",
            SWRST_N8_ADDR);
    ret = 0;
}
```

Also guarded the optional reset GPIO:

```c
if (!gpio_is_valid(ts->reset_global_gpio)) {
    NVT_LOG("%s : reset_global_gpio not available, skip", __func__);
    return;
}
```

## Flash

Use **only** the safe zip:

```text
AnyKernel-CPH2185-fix-touch-swrstd-safe.zip
```

It contains the new kernel plus the proven CPH2185 custom AnyKernel installer.
The plain `AnyKernel-CPH2185-fix-touch-swrstd.zip` uses the generic installer
and was not tested on this phone.

Release:
<https://github.com/azixur-rahman/kernel_oppo_CPH2185/releases/tag/touch-fix-swrstd-test>

Keep a stock `boot.img` backup before flashing. Do not wipe data.

## Verify after boot

```sh
su -c 'dmesg | grep -iE "novatek|nvt|touchpanel|swrst|irq"'
su -c 'cat /proc/bus/input/devices'
su -c 'cat /proc/interrupts'
su -c 'getevent -lp'
```

Expected:

- `novatek,swrst-n8-addr missing, using default 0x03F0FE`
- `nvt_ts_probe: end` or `request irq ... succeed`
- `touchpanel` input device
- IRQ 19 with `touchpanel`

## Log collector

Termux:

```sh
su -c 'sh /sdcard/CPH2185-termux-logs.sh'
```

Logs are saved to `/sdcard/CPH2185-logs/<date-time>/`.

## Credits

Kernel work, testing, and device support: **Azizur Rahman**.
