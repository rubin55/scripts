#!/usr/bin/env python3
"""Alphabetize the GNOME Shell app grid (org.gnome.shell app-picker-layout)."""
import locale
import os
from itertools import batched

# note: env var must be set before import
os.environ.setdefault("XDG_CURRENT_DESKTOP", "GNOME")
from gi.repository import Gio, GLib  # type: ignore[reportMissingModuleSource]  # noqa: E402

# every stock grid mode holds 24 icons (3x8, 4x6, 6x4, 8x3)
PAGE_SIZE = 24
FOLDER_SCHEMA = "org.gnome.desktop.app-folders.folder"


def folder_name(folder, fid):
    """Same rules as the shell's _getFolderName()."""
    name = folder.get_string("name")
    if not folder.get_boolean("translate"):
        return name
    dirs = [os.path.join(d, "desktop-directories") for d in
            (GLib.get_user_data_dir(), *GLib.get_system_data_dirs())]
    kf = GLib.KeyFile()
    try:
        kf.load_from_dirs(name, dirs, GLib.KeyFileFlags.NONE)
        return kf.get_locale_string("Desktop Entry", "Name") or fid
    except GLib.Error:
        return name


def visible_apps():
    """Apps the shell puts in the grid: shown, not a dash favorite."""
    favorites = set(Gio.Settings.new("org.gnome.shell").get_strv("favorite-apps"))
    apps = {}
    for ai in Gio.AppInfo.get_all():
        did = ai.get_id()
        if not did or did in apps or did in favorites or not ai.should_show():
            continue
        cats = (ai.get_categories() or "").split(";")  # type: ignore[attr-defined]
        apps[did] = (ai.get_display_name() or ai.get_name(), set(filter(None, cats)))
    return apps


def collect_folders(apps):
    """Return (folder entries, ids swallowed by a folder)."""
    s = Gio.Settings.new("org.gnome.desktop.app-folders")
    entries, members = [], set()
    for fid in s.get_strv("folder-children"):
        folder = Gio.Settings.new_with_path(
            FOLDER_SCHEMA, f"/org/gnome/desktop/app-folders/folders/{fid}/"
        )
        cats = set(folder.get_strv("categories"))
        contents = {a for a in folder.get_strv("apps") if a in apps}
        contents |= {did for did, (_, c) in apps.items() if cats & c}
        contents -= set(folder.get_strv("excluded-apps"))
        if not contents:  # the shell hides empty folders
            continue
        members |= contents
        entries.append((folder_name(folder, fid), fid))
    return entries, members


def main():
    locale.setlocale(locale.LC_ALL, "")

    apps = visible_apps()
    entries, in_folder = collect_folders(apps)
    entries += [(name, did) for did, (name, _) in apps.items() if did not in in_folder]
    entries.sort(key=lambda kv: locale.strxfrm(kv[0].casefold()))

    pages = [list(b) for b in batched((did for _, did in entries), PAGE_SIZE)] or [[]]
    layout = GLib.Variant("aa{sv}", [
        {did: GLib.Variant("a{sv}", {"position": GLib.Variant("i", pos)})
         for pos, did in enumerate(page)}
        for page in pages
    ])

    Gio.Settings.new("org.gnome.shell").set_value("app-picker-layout", layout)
    print(f"Sorted {len(entries)} items across {len(pages)} pages.")


if __name__ == "__main__":
    main()
