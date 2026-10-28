# CPH2185 kernel - private workspace

**Author:** Azizur Rahman  
**GitHub:** [azixur-rahman](https://github.com/azixur-rahman)

This is the private CPH2185 (OPPO A15 / MT6765) kernel workspace.

The public fork was removed because GitHub does not allow a public fork to be
made private directly. The full source archive and the touch-fix files are in
the release attached to this repository.

## Contents

- `CPH2185-FIX.md` - full touch diagnosis and commit history
- `CPH2185-stock-vs-custom-kernel.txt` - stock vs custom comparison
- `CPH2185-touch-swrstd-fix.patch` - final kernel patch
- `packaging/cph2185-anykernel.sh` - CPH2185 AnyKernel installer
- `packaging/CPH2185-termux-logs.sh` - Termux log collector
- `.github/workflows/build-anykernel.yml` - build workflow
- `BUILD-AND-TEST.md` - build and test notes

## Release assets

- `AnyKernel-CPH2185-fix-touch-swrstd-safe.zip` - flashable kernel zip
- `kernel_oppo_CPH2185-deprecated-android-4.9-q.zip` - full source archive
- `CPH2185-touch-swrstd-fix.patch` - apply to the source archive

## Status

Touch is SOLVED on the CPH2185 with the safe zip. The stock DTBO is unchanged.
