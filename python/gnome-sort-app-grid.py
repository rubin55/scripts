#!/usr/bin/env python3
"""Alphabetize the GNOME Shell app grid (org.gnome.shell app-picker-layout)."""
import locale
import os
from itertools import batched

# note: env var must be set before import
os.environ.setdefault("XDG_CURRENT_DESKTOP", "GNOME")
from gi.repository import Gio, GLib  # type: ignore[reportMissingModuleSource]  # noqa: E402

PAGE_SIZE = 24


def collect_folders():
    s = Gio.Settings.new("org.gnome.desktop.app-folders")
    members, names = set(), {}
    for fid in s.get_strv("folder-children"):
        folder = Gio.Settings.new_with_path(
            "org.gnome.desktop.app-folders.folder",
            f"/org/gnome/desktop/app-folders/folders/{fid}/",
        )
        members.update(a for a in folder.get_strv("apps") if a.endswith(".desktop"))
        n = folder.get_string("name")
        names[fid] = n if not n.startswith("@") else fid.title()
    return members, names


def main():
    locale.setlocale(locale.LC_ALL, "")
    folder_members, folder_names = collect_folders()

    entries = []
    seen = set()
    for ai in Gio.AppInfo.get_all():
        if not ai.should_show():
            continue
        did, name = ai.get_id(), ai.get_display_name() or ai.get_name()
        if did in folder_members or did in seen:
            continue
        seen.add(did)
        entries.append((name, did))
    entries += [(n, f"folder:{fid}") for fid, n in folder_names.items()]
    entries.sort(key=lambda kv: locale.strxfrm(kv[0].casefold()))

    pages = [list(b) for b in batched((did for _, did in entries), PAGE_SIZE)] or [[]]

    text = "[" + ", ".join(
        "{" + ", ".join(f"'{did}': <{{'position': <{pos}>}}>" for pos, did in enumerate(p)) + "}"
        for p in pages
    ) + "]"

    Gio.Settings.new("org.gnome.shell").set_value(
        "app-picker-layout", GLib.Variant.parse(None, text, None, None)
    )
    print(f"Sorted {len(entries)} apps across {len(pages)} pages.")


if __name__ == "__main__":
    main()
