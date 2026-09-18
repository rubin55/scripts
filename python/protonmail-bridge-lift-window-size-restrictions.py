#!/usr/bin/env python3

# Lift protonmail-bridge's hardcoded main-window minimum size.
#
# The GUI is Qt6/QML (not Electron). The limits live in the embedded
# MainWindow.qml resource: minimumWidth 1080, minimumHeight 650.
#
# Qt stores each resource file as [u32be compressed_size][zstd frame].
# This script recompresses the patched QML so the frame keeps its exact
# byte size, leaving all offsets intact (same idea as the mattermost
# script's same-length replacement). The stale per-user QML disk cache
# is cleared so the new QML is compiled on next launch.

import hashlib
import os
import pwd
import re
import shutil
import sys
import tempfile

EXE = "/usr/lib/protonmail/bridge/bridge-gui"
MAGIC = bytes.fromhex("28b52ffd")
OLD = (b"minimumHeight: ProtonStyle.window_minimum_height\n"
       b"    minimumWidth: ProtonStyle.window_minimum_width")
NEW = b"minimumHeight: 0\n    minimumWidth: 0"

# (label, builder) tried in order; first exact-size hit wins.
PAD_SEED = b"proton-bridge-minsize"


def pad(n):
    out = b""
    h = PAD_SEED
    while len(out) < n:
        h = hashlib.sha256(h).digest()
        out += bytes(c for c in h.hex().encode() if c not in b"*/")
    return out[:n]


def frame_extent(data, off):
    if data[off:off + 4] != MAGIC:
        raise ValueError("bad magic")
    p = off + 4
    desc = data[p]
    p += 1
    fcs_flag = (desc >> 6) & 3
    single = (desc >> 5) & 1
    csum = (desc >> 2) & 1
    dic = desc & 3
    if not single:
        p += 1
    p += {0: 0, 1: 1, 2: 2, 3: 4}[dic]
    n = {0: 1 if single else 2, 1: 2, 2: 4, 3: 8}[fcs_flag]
    p += n
    while True:
        b0, b1, b2 = data[p], data[p + 1], data[p + 2]
        last, typ = b0 & 1, (b0 >> 1) & 3
        if typ == 3:
            raise ValueError("reserved block")
        p += 3 + ((b0 >> 3) | (b1 << 5) | (b2 << 13))
        if last:
            break
    return p - off + (4 if csum else 0)


def main():
    if sys.version_info < (3, 14):
        sys.exit("needs python >= 3.14 (compression.zstd)")
    from compression import zstd
    if os.geteuid() != 0:
        sys.exit(f"must run as root (need write access to {EXE})")
    if not os.path.exists(EXE):
        sys.exit(f"binary not found: {EXE}")

    with open(EXE, "rb") as fh:
        data = fh.read()

    offs = [m.start() for m in re.finditer(re.escape(MAGIC), data)]
    targets = []
    for off in offs:
        try:
            size = frame_extent(data, off)
        except (ValueError, IndexError):
            continue
        try:
            plain = zstd.decompress(data[off:off + size])
        except Exception:
            continue
        if OLD in plain:
            targets.append((off, size, plain))
    if not targets:
        for off in offs:
            try:
                size = frame_extent(data, off)
                plain = zstd.decompress(data[off:off + size])
            except Exception:
                continue
            if NEW in plain:
                print("already patched; nothing to do.")
                return
        sys.exit("target QML not found; binary layout changed, "
                 "consider updating the script.")
    if len(targets) > 1:
        sys.exit(f"target found in {len(targets)} resources; refusing "
                 "to guess, consider updating the script.")
    off, size, plain = targets[0]
    if plain.count(OLD) != 1:
        sys.exit("target string not unique; refusing to patch.")
    base = plain.replace(OLD, NEW)

    cands = [base]
    cands += [base + b" " * n for n in range(1, 129)]
    cands += [base + b"\n    /*" + pad(n) + b"*/\n"
              for n in range(0, 2048)]
    levels = [19] + [lv for lv in range(22, 0, -1) if lv != 19]
    frame = None
    for lv in levels:
        for cand in cands:
            comp = zstd.compress(cand, level=lv)
            if len(comp) == size and zstd.decompress(comp) == cand:
                frame = comp
                break
        if frame is not None:
            break
    if frame is None:
        sys.exit("no exact-size recompression found; refusing to write.")

    if int.from_bytes(data[off - 4:off], "big") != size:
        sys.exit("size header mismatch; refusing to write.")

    bak = EXE + ".orig"
    if not os.path.exists(bak):
        shutil.copy2(EXE, bak)
        print(f"backup -> {bak}")
    elif open(bak, "rb").read() != data:
        # Package was upgraded since the last run; current file is the
        # new pristine upstream binary, so refresh the stale backup.
        shutil.copy2(EXE, bak)
        print(f"refreshed stale backup -> {bak}")

    st = os.stat(EXE)
    out = data[:off] + frame + data[off + size:]
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(EXE), prefix=".pb-patch-")
    with os.fdopen(fd, "wb") as f:
        f.write(out)
    os.chmod(tmp, st.st_mode & 0o7777)
    os.chown(tmp, st.st_uid, st.st_gid)
    os.replace(tmp, EXE)
    print(f"patched MainWindow.qml: minimumWidth/minimumHeight -> 0 in {EXE}")

    for pw in pwd.getpwall():
        if pw.pw_uid != 0 and pw.pw_uid < 1000:
            continue
        cache = os.path.join(pw.pw_dir, ".cache/Proton AG/Proton Mail Bridge",
                             "qmlcache")
        if os.path.isdir(cache):
            shutil.rmtree(cache)
            print(f"cleared QML cache -> {cache}")


if __name__ == "__main__":
    main()
