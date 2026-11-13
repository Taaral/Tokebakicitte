"""Génère les textures TGA de l'addon (drapeau du Québec et fleur de lys).

Usage: python tools/make_textures.py
Requiert Pillow. La fleur de lys est dessinée à partir de courbes (aucune
police externe), donc les textures peuvent être redistribuées librement.
WoW exige des dimensions en puissances de 2.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
MEDIA = ROOT / "Media"
BLUE = (0, 61, 165, 255)
WHITE = (255, 255, 255, 255)

# Taille de la fenêtre d'options en jeu (Options.lua) : on dessine le drapeau
# dans ce ratio, puis on le redimensionne en carré pour que l'étirement en jeu
# le remette aux bonnes proportions.
FRAME_W, FRAME_H = 560, 560
TEX_SIZE = 1024


def bezier(p0, p1, p2, p3, steps=48):
    """Points d'une courbe de Bézier cubique (p0 exclu)."""
    pts = []
    for i in range(1, steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((
            u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
        ))
    return pts


def path(start, *curves):
    """Polygone fait de courbes de Bézier enchaînées : curves = (c1, c2, fin)."""
    pts = [start]
    for c1, c2, end in curves:
        pts += bezier(pts[-1], c1, c2, end)
    return pts


def mirror(pts):
    return [(1 - x, y) for x, y in pts]


# Formes de la fleur de lys, en coordonnées normalisées (0..1, y vers le bas).
# Les pièces latérales sont dessinées pour la gauche puis reflétées.
CENTER_PETAL = path(
    (0.50, 0.02),
    ((0.64, 0.16), (0.66, 0.38), (0.54, 0.58)),
    ((0.52, 0.60), (0.48, 0.60), (0.46, 0.58)),
    ((0.34, 0.38), (0.36, 0.16), (0.50, 0.02)),
)
SIDE_PETAL = path(
    (0.46, 0.58),
    ((0.40, 0.30), (0.12, 0.16), (0.04, 0.32)),   # dos du pétale, vers le haut
    ((0.00, 0.40), (0.04, 0.50), (0.12, 0.52)),   # bout recourbé vers le bas
    ((0.10, 0.44), (0.14, 0.36), (0.22, 0.38)),   # retour intérieur
    ((0.32, 0.40), (0.38, 0.52), (0.40, 0.60)),
)
BAND = [(0.26, 0.56), (0.74, 0.56), (0.74, 0.66), (0.26, 0.66)]
FOOT = path(
    (0.43, 0.66),
    ((0.45, 0.76), (0.48, 0.84), (0.50, 0.92)),
    ((0.52, 0.84), (0.55, 0.76), (0.57, 0.66)),
)
SIDE_FOOT = path(
    (0.44, 0.66),
    ((0.42, 0.82), (0.28, 0.90), (0.16, 0.82)),   # dessous, vers le bout
    ((0.24, 0.80), (0.31, 0.75), (0.33, 0.66)),   # dessus, retour à la bande
)


def fleur(size, color=WHITE):
    """Fleur de lys pleine, centrée sur une image transparente de size x size."""
    big = size * 8  # suréchantillonnage pour des bords lisses
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    for shape in (CENTER_PETAL, SIDE_PETAL, mirror(SIDE_PETAL), BAND,
                  FOOT, SIDE_FOOT, mirror(SIDE_FOOT)):
        draw.polygon([(x * big, y * big) for x, y in shape], fill=255)

    img = Image.new("RGBA", (big, big), color)
    img.putalpha(mask)
    return img.resize((size, size), Image.LANCZOS)


def flag():
    scale = 2
    w, h = FRAME_W * scale, FRAME_H * scale
    img = Image.new("RGBA", (w, h), BLUE)
    draw = ImageDraw.Draw(img)

    cross = h // 6
    cx, cy = w // 2, h // 2
    draw.rectangle([cx - cross // 2, 0, cx + cross // 2, h], fill=WHITE)
    draw.rectangle([0, cy - cross // 2, w, cy + cross // 2], fill=WHITE)

    qw, qh = (w - cross) // 2, (h - cross) // 2
    size = int(min(qw, qh) * 0.6)
    lys = fleur(size)
    for qx in (0, cx + cross // 2):
        for qy in (0, cy + cross // 2):
            img.alpha_composite(lys, (qx + (qw - size) // 2, qy + (qh - size) // 2))

    return img.resize((TEX_SIZE, TEX_SIZE), Image.LANCZOS)


def flag_icon(size=64):
    """Drapeau carré pour le bouton de la minicarte (rogné en rond en jeu)."""
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), BLUE)
    draw = ImageDraw.Draw(img)
    cross = s // 5
    c = s // 2
    draw.rectangle([c - cross // 2, 0, c + cross // 2, s], fill=WHITE)
    draw.rectangle([0, c - cross // 2, s, c + cross // 2], fill=WHITE)
    q = (s - cross) // 2
    lys_size = int(q * 0.62)
    lys = fleur(lys_size)
    # Les fleurs sont rapprochées du centre pour rester visibles une fois rognées en rond
    for qx in (0, c + cross // 2):
        for qy in (0, c + cross // 2):
            ox = qx + (q - lys_size) // 2 + (q // 8 if qx == 0 else -q // 8)
            oy = qy + (q - lys_size) // 2 + (q // 8 if qy == 0 else -q // 8)
            img.alpha_composite(lys, (ox, oy))
    return img.resize((size, size), Image.LANCZOS)


def main():
    MEDIA.mkdir(exist_ok=True)
    flag().save(MEDIA / "QuebecFlag.tga")
    flag_icon().save(MEDIA / "FlagIcon.tga")
    fleur(64).save(MEDIA / "FleurDeLys.tga")
    print("Textures écrites dans", MEDIA)


if __name__ == "__main__":
    main()
