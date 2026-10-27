"""Convert Hyprland <0.53 windowrule/layerrule lines to the 0.53+ `match:` syntax."""
import re, sys

BOOL = {"float", "tile", "fullscreen", "maximize", "pin", "center", "pseudo", "noblur", "noshadow",
        "noborder", "nodim", "noanim", "noinitialfocus", "nofocus", "nomaxsize", "keepaspectratio",
        "stayfocused", "immediate", "xray", "dimaround", "ignorezero", "blur", "forceinput",
        "allowsinput", "nearestneighbor", "renderunfocused", "syncfullscreen", "noscreenshare",
        "persistentsize", "noclosefor", "focusonactivate", "forcergbx", "decorate"}
RENAME = {"noblur": "no_blur", "noshadow": "no_shadow", "noborder": "no_border", "nodim": "no_dim",
          "noanim": "no_anim", "noinitialfocus": "no_initial_focus", "nofocus": "no_focus",
          "nomaxsize": "no_max_size", "keepaspectratio": "keep_aspect_ratio",
          "stayfocused": "stay_focused", "dimaround": "dim_around", "ignorezero": "ignore_alpha 0",
          "ignorealpha": "ignore_alpha", "idleinhibit": "idle_inhibit", "bordercolor": "border_color",
          "bordersize": "border_size", "forceinput": "allows_input", "allowsinput": "allows_input",
          "nearestneighbor": "nearest_neighbor", "renderunfocused": "render_unfocused",
          "noscreenshare": "no_screen_share", "persistentsize": "persistent_size",
          "focusonactivate": "focus_on_activate", "forcergbx": "force_rgbx", "maxsize": "max_size",
          "minsize": "min_size", "suppressevent": "suppress_event", "noclosefor": "no_close_for",
          "syncfullscreen": "sync_fullscreen", "fullscreenstate": "fullscreen_state",
          "roundingpower": "rounding_power", "scrollmouse": "scroll_mouse",
          "scrolltouchpad": "scroll_touchpad", "nofollowmouse": "no_follow_mouse"}
MATCH = {"class": "class", "title": "title", "initialClass": "initial_class",
         "initialTitle": "initial_title", "tag": "tag", "xwayland": "xwayland", "floating": "float",
         "fullscreen": "fullscreen", "pinned": "pin", "focus": "focus", "workspace": "workspace",
         "onworkspace": "workspace", "content": "content", "fullscreenstate": "fullscreen_state"}

def pct(v, axis):
    m = re.fullmatch(r"(\d+(?:\.\d+)?)%", v)
    return f"(monitor_{axis}*{float(m.group(1))/100:g})" if m else v

def effect(e):
    parts = e.split()
    name, args = parts[0], parts[1:]
    if name in ("size", "move", "minsize", "maxsize") and len(args) == 2:
        args = [pct(args[0], "w"), pct(args[1], "h")]
    new = RENAME.get(name, name)
    if name in BOOL and not args and name != "ignorezero":
        args = ["on"]
    return " ".join([new] + args)

def convert(line):
    m = re.match(r"^(\s*)(windowrule|windowrulev2|layerrule)\s*=\s*(.*?)(\s*#.*)?$", line)
    if not m or "match:" in line:
        return line
    indent, kw, body, comment = m.group(1), m.group(2), m.group(3), m.group(4) or ""
    fields = [f.strip() for f in body.split(",")]
    eff, matchers = fields[0], fields[1:]
    out = []
    if kw == "layerrule":   # layerrule = effect, namespace
        return f"{indent}layerrule = match:namespace {matchers[0]}, {effect(eff)}{comment}"
    for f in matchers:
        k, _, v = f.partition(":")
        if k == "tag":
            v = v.rstrip("*")
        if k in ("floating", "xwayland", "pinned", "fullscreen", "focus"):
            v = {"1": "true", "0": "false"}.get(v, v)
        out.append(f"match:{MATCH.get(k, k)} {v}")
    return f"{indent}windowrule = {', '.join(out)}, {effect(eff)}{comment}"

src = open(sys.argv[1]).read().splitlines()
print("\n".join(convert(l) for l in src))
