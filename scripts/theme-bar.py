#!/usr/bin/env python3
"""theme-bar.py — mini-bar GTK com botões abaixo do HUD (Neon/Nórdica/Paper/Stealth)."""
import os
import subprocess
import sys

try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk
except Exception as e:
    sys.stderr.write(f"[theme-bar] Gtk indisponivel: {e}\n")
    sys.exit(1)

HOME = os.path.expanduser("~")
SW = f"{HOME}/.config/conky/scripts/theme-switch.sh"
CUR = f"{HOME}/.cache/conky/theme.current"
THEMES = [("neon", "Neon"), ("nord", "Nórdica"), ("paper", "Paper"), ("stealth", "Stealth")]


def current():
    try:
        return open(CUR).read().strip().lower()
    except Exception:
        return "neon"


def paint(btns, active):
    for key, btn in btns.items():
        ctx = btn.get_style_context()
        if key == active:
            ctx.add_class("active")
        else:
            ctx.remove_class("active")


def on_click(_btn, key, btns):
    try:
        subprocess.Popen([SW, key])
    except Exception as e:
        sys.stderr.write(f"[theme-bar] {e}\n")
        return
    try:
        open(CUR, "w").write(key)
    except Exception:
        pass
    paint(btns, key)


win = Gtk.Window(title="conky-theme-bar")
win.set_default_size(320, 36)
win.set_decorated(False)
win.set_keep_above(True)
win.set_skip_taskbar_hint(True)
win.set_app_paintable(True)
win.stick()
visual = win.get_screen().get_rgba_visual()
if visual:
    win.set_visual(visual)
# 1360-320-12 = 1028; y ~700 fica logo abaixo do HUD de ~620px + gap_y 30
win.move(1028, 700)
win.connect("destroy", Gtk.main_quit)

css = b"""
window { background: rgba(10,12,16,0.72); border-radius: 10px; }
button { background: transparent; color: #8b949e; border: 0;
         font: bold 11px sans; padding: 4px 14px; }
button.active { background: #00d7ff; color: #06121a; border-radius: 7px; }
button:hover { color: #ffffff; }
"""
provider = Gtk.CssProvider()
provider.load_from_data(css)
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(), provider, 600)

box = Gtk.Box(spacing=2, homogeneous=True)
box.set_margin_top(2)
box.set_margin_bottom(2)
box.set_margin_start(4)
box.set_margin_end(4)
win.add(box)

buttons = {}
for key, label in THEMES:
    b = Gtk.Button(label=label)
    b.set_can_focus(False)
    b.set_tooltip_text(f"Tema {label}")
    b.connect("clicked", on_click, key, buttons)
    box.pack_start(b, True, True, 0)
    buttons[key] = b

paint(buttons, current())
win.show_all()
Gtk.main()
