# CPH2185 / CPH2179 Falcon-AZ kernel

**Author:** Azizur Rahman  
**GitHub:** [azixur-rahman](https://github.com/azixur-rahman)

Custom kernel for the OPPO A15 (CPH2185) and CPH2179, MT6765.

## Download

**Falcon-AZ-CPH2185-CPH2179-1083a1b8eb06.zip**

https://github.com/azixur-rahman/CPH2185-kernel-private/releases/download/private-source-backup/Falcon-AZ-CPH2185-CPH2179-1083a1b8eb06.zip

- SHA256: `3d11a605c59c25e348e90ac70fbe253e0e70bf1b508e7f81270c6e0ca8fb118c`
- Size: `15,557,413` bytes
- Kernel commit: `1083a1b8eb06ae74622dd5e5f4919041a50d5674`
- Kernel version: `4.9.190-falcon-az`
- Same zip for CPH2185 and CPH2179
- AnyKernel, kernel-only, `do.devicecheck=0`
- No `boot.img`, no `/vendor` writes, no custom recovery required

## Working features

Confirmed working on the phone:

- WiFi: built into the kernel
- Bluetooth: built into the kernel, `/dev/stpbt` is created during
  connectivity bring-up
- Touch: working
- KernelSU + SUSFS
- WPDMA descriptors use volatile 32-bit accesses (WiFi crash fix)

## Flash

Flash the zip with your usual AnyKernel method, then reboot.
No extra modules or vendor files are needed.

## Working source

The complete working kernel source tree is in the **`falcon-az-source`**
branch:

https://github.com/azixur-rahman/CPH2185-kernel-private/tree/falcon-az-source

Direct download (full source):

- https://github.com/azixur-rahman/CPH2185-kernel-private/archive/refs/heads/falcon-az-source.zip
- https://github.com/azixur-rahman/CPH2185-kernel-private/archive/refs/heads/falcon-az-source.tar.gz

That branch contains only the source tree used for the working build -
no zip, no build output, no extra files.

This `main` branch holds only the build files:

- `.github/workflows/build-falcon-az-a15q.yml` - builds the kernel and
  AnyKernel zip
- `.github/workflows/publish-falcon-az.yml` - verifies the WPDMA descriptor
  stores and publishes the release asset
- `source/bt/mt66xx/` - Bluetooth source used by the build
- `packaging/cph2185-anykernel.sh` - AnyKernel installer
- `packaging/falcon-az-touch-fix.patch` - touch patch
- `scripts/check-desc-stores.sh` - WPDMA descriptor verifier
