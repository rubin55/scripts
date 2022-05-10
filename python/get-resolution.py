#!/usr/bin/env python3

from gi import require_version
require_version("Gdk", "3.0")
from gi.repository import Gdk

def get_screen_size(display):
    mon_geoms = [
        display.get_monitor(i).get_geometry()
        for i in range(display.get_n_monitors())
    ]

    x0 = min(r.x            for r in mon_geoms)
    y0 = min(r.y            for r in mon_geoms)
    x1 = max(r.x + r.width  for r in mon_geoms)
    y1 = max(r.y + r.height for r in mon_geoms)

    return f'{x1 - x0}x{y1 - y0}'

# example use
print(get_screen_size(Gdk.Display.get_default()))
