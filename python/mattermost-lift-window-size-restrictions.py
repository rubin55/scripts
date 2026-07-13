#!/usr/bin/env python3

# Lift mattermost-desktop's hardcoded BrowserWindow minWidth/minHeight.
#
# The constants f=600 (minWidth) and w=500 (minHeight) live in module 3694 of
# the bundled app.asar index.js, under "use strict".

# Replacing 600/500 with the same-length literal 0x0 (=0, strict-safe) keeps
# the asar byte layout intact, so no header/offset rebuild is required.

import json
import os
import shutil
import struct
import sys
import tempfile

ASAR = "/usr/lib/mattermost-desktop/app.asar"
OLD = b"f=600,w=500"
NEW = b"f=0x0,w=0x0"


def main():
    if os.geteuid() != 0:
        sys.exit(f"must run as root (need write access to {ASAR})")
    if not os.path.exists(ASAR):
        sys.exit(f"asar not found: {ASAR}")

    with open(ASAR, "rb") as fh:
        data = fh.read()

    # asar layout: [4=size][hdr_block_size][4=size][json_len][json][payloads].
    sizes = struct.unpack_from("<IIII", data, 0)
    if sizes[0] != 4:
        sys.exit(f"unexpected asar header (s1={sizes[0]}); not asar?")
    header = json.loads(data[16:16 + sizes[3]].decode("utf-8"))
    data_start = 8 + sizes[1]  # end of header block == start of file payloads
    entry = header["files"]["index.js"]
    off, size = data_start + int(entry["offset"]), entry["size"]
    content = data[off:off + size]

    if content.count(OLD) == 0:
        if NEW in content:
            print("already patched; nothing to do.")
            return
        sys.exit("target string not found in index.js; asar layout changed, "
                 "consider updating the script.")

    patched = content.replace(OLD, NEW)
    if len(patched) != len(content):
        sys.exit("length mismatch; refusing to write (asar would break).")

    bak = ASAR + ".orig"
    if not os.path.exists(bak):
        shutil.copy2(ASAR, bak)
        print(f"backup -> {bak}")

    st = os.stat(ASAR)
    out = data[:off] + patched + data[off + size:]
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(ASAR), prefix=".mm-patch-")
    with os.fdopen(fd, "wb") as f:
        f.write(out)
    os.chmod(tmp, st.st_mode & 0o7777)
    os.chown(tmp, st.st_uid, st.st_gid)
    os.replace(tmp, ASAR)
    print(f"patched index.js: minWidth/minHeight 600/500 -> 0 in {ASAR}")


if __name__ == "__main__":
    main()
