#!/usr/bin/env python3
"""Gera todos os ícones do Bonum a partir da folha vetorial.

Uso (na raiz do projeto):  python3 tool/generate_icons.py
Requer: Pillow (pip install pillow)

Saídas:
  android/app/src/main/res/mipmap-*/ic_launcher.png   ícone legado (Android < 8)
  android/app/src/main/res/drawable-*/splash_leaf.png folha da tela de abertura
  web/favicon.png, web/icons/*.png                    ícones da versão web
  assets/icon/play_store_512.png                      ícone para a Play Store
  assets/icon/bonum_icon.svg                          arte mestre (vetorial)

O ícone adaptativo (Android 8+) é vetorial e fica em
android/app/src/main/res/drawable/ic_launcher_foreground.xml, com a mesma folha.
"""

import os
import re

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SAGE = (79, 127, 95, 255)  # #4F7F5F — verde do app
BG = (234, 242, 235, 255)  # #EAF2EB — fundo do ícone

# Folha (Material "eco", grade 24x24) — o mesmo desenho usado no app.
LEAF = (
    "M6.05,8.05c-2.73,2.73 -2.73,7.15 -0.02,9.88c1.47,-3.4 4.09,-6.24 7.36,-7.93"
    "c-2.77,2.34 -4.71,5.61 -5.39,9.32c2.6,1.23 5.8,0.78 7.95,-1.37"
    "C19.43,14.47 20,4 20,4S9.53,4.57 6.05,8.05z"
)

SS = 4  # supersampling para bordas suaves


def leaf_points(steps=40):
    """Converte o path SVG (M, c, C, S, z) em uma lista de pontos."""
    tokens = re.findall(r"[MmCcSsZz]|-?\d*\.?\d+", LEAF)
    pts, i, cmd = [], 0, None
    cur = (0.0, 0.0)
    last_ctrl = None

    def num():
        nonlocal i
        v = float(tokens[i])
        i += 1
        return v

    def bezier(p0, p1, p2, p3):
        for k in range(1, steps + 1):
            t = k / steps
            mt = 1 - t
            x = mt**3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t**3 * p3[0]
            y = mt**3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t**3 * p3[1]
            pts.append((x, y))

    while i < len(tokens):
        if re.match(r"[A-Za-z]", tokens[i]):
            cmd = tokens[i]
            i += 1
            if cmd in "Zz":
                continue
        if cmd == "M":
            cur = (num(), num())
            pts.append(cur)
        elif cmd in "Cc":
            rel = cmd == "c"
            c1 = (num(), num())
            c2 = (num(), num())
            end = (num(), num())
            if rel:
                c1 = (cur[0] + c1[0], cur[1] + c1[1])
                c2 = (cur[0] + c2[0], cur[1] + c2[1])
                end = (cur[0] + end[0], cur[1] + end[1])
            bezier(cur, c1, c2, end)
            last_ctrl, cur = c2, end
        elif cmd in "Ss":
            rel = cmd == "s"
            c2 = (num(), num())
            end = (num(), num())
            if rel:
                c2 = (cur[0] + c2[0], cur[1] + c2[1])
                end = (cur[0] + end[0], cur[1] + end[1])
            c1 = (2 * cur[0] - last_ctrl[0], 2 * cur[1] - last_ctrl[1]) if last_ctrl else cur
            bezier(cur, c1, c2, end)
            last_ctrl, cur = c2, end
    return pts


POINTS = leaf_points()
MINX = min(p[0] for p in POINTS)
MAXX = max(p[0] for p in POINTS)
MINY = min(p[1] for p in POINTS)
MAXY = max(p[1] for p in POINTS)


def draw_leaf(img, leaf_size, color=SAGE):
    """Desenha a folha centralizada (pelo bbox) ocupando leaf_size px de largura/altura máx."""
    w, h = img.size
    scale = leaf_size / max(MAXX - MINX, MAXY - MINY)
    ox = (w - (MAXX - MINX) * scale) / 2 - MINX * scale
    oy = (h - (MAXY - MINY) * scale) / 2 - MINY * scale
    ImageDraw.Draw(img).polygon([(ox + x * scale, oy + y * scale) for x, y in POINTS], fill=color)


def make_icon(size, rounded=True, leaf_ratio=0.56, background=BG):
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    if background:
        d = ImageDraw.Draw(img)
        if rounded:
            d.rounded_rectangle([0, 0, big - 1, big - 1], radius=int(big * 0.225), fill=background)
        else:
            d.rectangle([0, 0, big, big], fill=background)
    draw_leaf(img, big * leaf_ratio)
    return img.resize((size, size), Image.LANCZOS)


def save(img, *rel):
    path = os.path.join(ROOT, *rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print("  ", os.path.relpath(path, ROOT), f"{img.size[0]}x{img.size[1]}")


def write_svg():
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Bonum — arte mestre do ícone. Verde #4F7F5F sobre #EAF2EB. -->
  <rect width="512" height="512" rx="115" fill="#EAF2EB"/>
  <g transform="translate({256 - (MINX + MAXX) / 2 * 17.9:.2f} {256 - (MINY + MAXY) / 2 * 17.9:.2f}) scale(17.9)">
    <path fill="#4F7F5F" d="{LEAF}"/>
  </g>
</svg>
"""
    path = os.path.join(ROOT, "assets", "icon", "bonum_icon.svg")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(svg)
    print("  ", os.path.relpath(path, ROOT))


def main():
    res = ("android", "app", "src", "main", "res")
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

    print("Android — ícone legado:")
    for name, f in densities.items():
        save(make_icon(int(48 * f)), *res, f"mipmap-{name}", "ic_launcher.png")

    print("Android — folha da tela de abertura (96dp):")
    for name, f in densities.items():
        save(make_icon(int(96 * f), background=None, leaf_ratio=0.9), *res, f"drawable-{name}", "splash_leaf.png")

    print("Web:")
    save(make_icon(32), "web", "favicon.png")
    save(make_icon(192), "web", "icons", "Icon-192.png")
    save(make_icon(512), "web", "icons", "Icon-512.png")
    # Maskable: fundo sangrado e folha dentro da zona segura (círculo de 80%).
    save(make_icon(192, rounded=False, leaf_ratio=0.46), "web", "icons", "Icon-maskable-192.png")
    save(make_icon(512, rounded=False, leaf_ratio=0.46), "web", "icons", "Icon-maskable-512.png")

    print("Play Store:")
    # A Play Store aplica a máscara arredondada sozinha: enviar quadrado cheio.
    save(make_icon(512, rounded=False), "assets", "icon", "play_store_512.png")

    print("Arte mestre:")
    write_svg()


if __name__ == "__main__":
    main()
