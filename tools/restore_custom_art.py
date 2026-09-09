"""Point the pack items and world models back at their own art once it exists.

The hide, construction, ingot and drink packs shipped pointing at the vanilla
art of whatever they contain, so nothing renders as a missing texture while the
custom art is outstanding. custom_art.json records what each one is meant to
use instead: "icons" maps an item id to its inventory icon, "models" maps a
model block in bu_models.txt to its world texture.

Run with no arguments to see what is ready; run with --apply to rewrite.
Only entries whose PNG is actually present are touched, so it is safe to run
repeatedly and safe to run when only some of the art has landed.
"""
import io, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "Contents", "mods", "Vanilla", "42", "media")
ITEMS = os.path.join(MEDIA, "scripts", "items")
MODELS = os.path.join(MEDIA, "scripts", "bu_models.txt")
TEX = os.path.join(MEDIA, "textures")
WORLD = os.path.join(TEX, "WorldItems")
MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_art.json")


def rewrite(path, fn):
    src = io.open(path, "r", encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    out, n = [], 0
    for line in src.replace("\r\n", "\n").split("\n"):
        new = fn(line)
        if new is not None and new != line:
            line, n = new, n + 1
        out.append(line)
    if n:
        io.open(path, "w", encoding="utf-8", newline="").write(
            "\n".join(out).replace("\n", nl))
    return n


def main():
    apply = "--apply" in sys.argv
    data = json.load(open(MAP, encoding="utf-8"))
    icons, models = data.get("icons", {}), data.get("models", {})

    have_i = {v for v in icons.values()
              if os.path.exists(os.path.join(TEX, "Item_%s.png" % v))}
    have_m = {v for v in models.values()
              if os.path.exists(os.path.join(WORLD, "%s.png" % v))}
    ready_i = {k: v for k, v in icons.items() if v in have_i}
    ready_m = {k: v for k, v in models.items() if v in have_m}

    out_i = sorted(set(icons.values()) - have_i)
    out_m = sorted(set(models.values()) - have_m)
    print("icons:  %d items -> %d artworks, %d still to draw"
          % (len(icons), len(set(icons.values())), len(out_i)))
    print("models: %d blocks -> %d textures, %d still to draw"
          % (len(models), len(set(models.values())), len(out_m)))
    if out_i:
        print("  icons outstanding:  " + ", ".join(out_i[:6])
              + (" ..." if len(out_i) > 6 else ""))
    if out_m:
        print("  models outstanding: " + ", ".join(out_m))
    if not ready_i and not ready_m:
        print("nothing to do yet.")
        return
    if not apply:
        print("%d item(s) and %d model(s) would be rewired. re-run with --apply."
              % (len(ready_i), len(ready_m)))
        return

    total = 0
    for fn in sorted(os.listdir(ITEMS)):
        if not fn.endswith(".txt"):
            continue
        state = {"cur": None}

        def line_fn(line):
            m = re.match(r'\s*item\s+([A-Za-z0-9_]+)\s*\{', line)
            if m:
                state["cur"] = m.group(1)
            g = re.match(r'^(\s*Icon\s*=\s*)([^,\n]+)(,)\s*$', line)
            if g and state["cur"] in ready_i:
                return g.group(1) + ready_i[state["cur"]] + g.group(3)
            return None

        n = rewrite(os.path.join(ITEMS, fn), line_fn)
        if n:
            print("  %-16s %d icon(s)" % (fn, n))
            total += n

    state = {"cur": None}

    def model_fn(line):
        m = re.match(r'\s*model\s+([A-Za-z0-9_]+)\s*\{', line)
        if m:
            state["cur"] = m.group(1)
        g = re.match(r'^(\s*texture\s*=\s*WorldItems/)([A-Za-z0-9_]+)(,)\s*$', line)
        if g and state["cur"] in ready_m:
            return g.group(1) + ready_m[state["cur"]] + g.group(3)
        return None

    n = rewrite(MODELS, model_fn)
    if n:
        print("  %-16s %d texture(s)" % ("bu_models.txt", n))
        total += n
    print("rewired %d line(s)." % total)


if __name__ == "__main__":
    main()
