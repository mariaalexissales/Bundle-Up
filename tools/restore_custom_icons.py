"""Point the pack items back at their own artwork once it exists.

The hide, construction, ingot and drink packs were shipped pointing at the
vanilla icon of whatever they contain, so nothing renders as a missing texture
while the custom art is outstanding. custom_icons.json records what each item
is meant to use instead.

Run with no arguments to see what is ready; run with --apply to rewrite.
Only items whose PNG is actually present in media/textures/ are touched, so it
is safe to run repeatedly and safe to run when only some of the art has landed.
"""
import io, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "Contents", "mods", "Vanilla", "42", "media")
ITEMS = os.path.join(MEDIA, "scripts", "items")
TEX = os.path.join(MEDIA, "textures")
MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_icons.json")


def main():
    apply = "--apply" in sys.argv
    wanted = json.load(open(MAP, encoding="utf-8"))
    have = {i for i in wanted.values()
            if os.path.exists(os.path.join(TEX, "Item_%s.png" % i))}
    missing = sorted(set(wanted.values()) - have)

    ready = {k: v for k, v in wanted.items() if v in have}
    print("%d items mapped, %d icons drawn, %d still outstanding"
          % (len(wanted), len(have), len(missing)))
    if missing:
        print("  outstanding: " + ", ".join(missing[:8])
              + (" ..." if len(missing) > 8 else ""))
    if not ready:
        print("nothing to do yet.")
        return
    if not apply:
        print("%d items would be rewired. re-run with --apply." % len(ready))
        return

    total = 0
    for fn in sorted(os.listdir(ITEMS)):
        if not fn.endswith(".txt"):
            continue
        p = os.path.join(ITEMS, fn)
        src = io.open(p, "r", encoding="utf-8", newline="").read()
        nl = "\r\n" if "\r\n" in src else "\n"
        out, cur, n = [], None, 0
        for line in src.replace("\r\n", "\n").split("\n"):
            m = re.match(r'\s*item\s+([A-Za-z0-9_]+)\s*\{', line)
            if m:
                cur = m.group(1)
            g = re.match(r'^(\s*Icon\s*=\s*)([^,\n]+)(,)\s*$', line)
            if g and cur in ready and g.group(2).strip() != ready[cur]:
                line = g.group(1) + ready[cur] + g.group(3)
                n += 1
            out.append(line)
        if n:
            io.open(p, "w", encoding="utf-8", newline="").write(
                "\n".join(out).replace("\n", nl))
            print("  %-16s %d" % (fn, n))
            total += n
    print("rewired %d item(s)." % total)


if __name__ == "__main__":
    main()
