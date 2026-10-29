#!/usr/bin/env python3
"""Remove Kconfig source lines whose target is missing.

Some OPPO kernel trees contain dangling symlinks into vendor/ directories
that are not published. Kconfig treats those as fatal errors. Removing the
source line only drops configuration symbols for drivers that cannot be
built from this tree anyway; the active kernel config decides what is built.

Author: Azizur Rahman
"""
import os
import re
import sys

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
SOURCE_RE = re.compile(r'^(\s*)(o|r)?source\s+"([^"]+)"\s*$')

removed = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    if ".git" in dirnames:
        dirnames.remove(".git")
    for name in filenames:
        if name != "Kconfig":
            continue
        path = os.path.join(dirpath, name)
        try:
            with open(path, "r", errors="ignore") as f:
                lines = f.readlines()
        except OSError:
            continue
        kept = []
        changed = False
        for line in lines:
            m = SOURCE_RE.match(line.rstrip("\n"))
            if m:
                prefix, kind, target = m.group(1), m.group(2), m.group(3)
                # Never touch paths that depend on make/kconfig variables.
                if "$" in target or target.startswith("/"):
                    kept.append(line)
                    continue
                base = ROOT
                if kind == "r":
                    base = os.path.dirname(path)
                target_path = os.path.normpath(os.path.join(base, target))
                if not os.path.exists(target_path):
                    removed.append((os.path.relpath(path, ROOT), target))
                    changed = True
                    continue
            kept.append(line)
        if changed:
            with open(path, "w", errors="ignore") as f:
                f.writelines(kept)

if removed:
    print("Removed %d missing Kconfig source line(s):" % len(removed))
    for path, target in removed:
        print("  %s -> %s" % (path, target))
else:
    print("No missing Kconfig source lines found")
