"""
Sprite generation pipeline for ENL200 Final Project: The Factory
Extracts, recolors, and creates all needed sprites for the game.
"""

from PIL import Image, ImageDraw
import numpy as np
import os

SPRITES_DIR = "sprites"
SOURCE_DIR  = "escapist-sprites"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load(filename):
    return Image.open(os.path.join(SOURCE_DIR, filename)).convert("RGBA")

def save(img, *path_parts):
    out = os.path.join(SPRITES_DIR, *path_parts)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print(f"  saved → {out}")

def palette_swap(img, replacements):
    """Replace specific RGB colors (ignores alpha). replacements = {(r,g,b): (r,g,b)}"""
    arr = np.array(img, dtype=np.uint8).copy()
    for old, new in replacements.items():
        mask = (
            (arr[:,:,0] == old[0]) &
            (arr[:,:,1] == old[1]) &
            (arr[:,:,2] == old[2]) &
            (arr[:,:,3] > 0)
        )
        arr[mask, 0] = new[0]
        arr[mask, 1] = new[1]
        arr[mask, 2] = new[2]
    return Image.fromarray(arr, "RGBA")

def fuzzy_palette_swap(img, replacements, tolerance=12):
    """Replace colors within a tolerance range."""
    arr = np.array(img, dtype=np.int32).copy()
    result = arr.copy()
    for old, new in replacements.items():
        dist = np.sqrt(
            (arr[:,:,0] - old[0])**2 +
            (arr[:,:,1] - old[1])**2 +
            (arr[:,:,2] - old[2])**2
        )
        mask = (dist <= tolerance) & (arr[:,:,3] > 0)
        result[mask, 0] = new[0]
        result[mask, 1] = new[1]
        result[mask, 2] = new[2]
    return Image.fromarray(result.astype(np.uint8), "RGBA")

def remove_bg(img):
    """Remove both purple background shades from player sprite sheet cells."""
    arr = np.array(img, dtype=np.int32).copy()
    for bg in [(75, 64, 123), (176, 127, 228), (138, 127, 228)]:
        dist = np.sqrt(
            (arr[:,:,0] - bg[0])**2 +
            (arr[:,:,1] - bg[1])**2 +
            (arr[:,:,2] - bg[2])**2
        )
        arr[dist <= 22, 3] = 0
    return Image.fromarray(arr.astype(np.uint8), "RGBA")

def scale2x(img):
    return img.resize((img.width * 2, img.height * 2), Image.NEAREST)

def scale4x(img):
    return img.resize((img.width * 4, img.height * 4), Image.NEAREST)

# ---------------------------------------------------------------------------
# Player sprite sheet layout (1024x1392)
# 5 outfit bands of 200px each across x-axis:
#   INMATE=0, POW=200, GUARD=400, INFIRMARY=600, PLAIN=800
# Within each 200px band, 4 directions occupy these local x offsets:
#   Front: lx=8  (2 frames, 16px each)
#   Left:  lx=56 (2 frames)
#   Back:  lx=104 (2 frames)
#   Right: lx=152 (2 frames)
# Key animation rows (y):
#   y=100  → Idle/Standing
#   y=416  → Janitor (working, frame 1)
#   y=432  → Janitor (working, frame 2)
#   y=448  → Gardener (outdoor work, frame 1)
#   y=464  → Gardener (outdoor work, frame 2)
# ---------------------------------------------------------------------------

OUTFIT_INMATE    = 0
OUTFIT_POW       = 200
OUTFIT_GUARD     = 400
OUTFIT_INFIRMARY = 600
OUTFIT_PLAIN     = 800

DIR_FRONT = 8
DIR_LEFT  = 56
DIR_BACK  = 104
DIR_RIGHT = 152

# y coords confirmed from pixel scan; characters are 16x16 starting at y=112
Y_IDLE      = 112
SPRITE_H    = 16
Y_JANITOR_1 = 440
Y_JANITOR_2 = 456
Y_GARDEN_1  = 472
Y_GARDEN_2  = 488

def extract_player(sheet, outfit_x, dir_lx, row_y):
    """Extract a 16xSPRITE_H sprite from the player sheet, background removed."""
    x = outfit_x + dir_lx
    crop = sheet.crop((x, row_y, x + 16, row_y + SPRITE_H))
    return remove_bg(crop)

def extract_walk_cycle(sheet, outfit_x):
    """Extract idle sprites for all 4 directions."""
    return {
        "front": extract_player(sheet, outfit_x, DIR_FRONT, Y_IDLE),
        "left":  extract_player(sheet, outfit_x, DIR_LEFT,  Y_IDLE),
        "back":  extract_player(sheet, outfit_x, DIR_BACK,  Y_IDLE),
        "right": extract_player(sheet, outfit_x, DIR_RIGHT, Y_IDLE),
    }

def extract_work_cycle(sheet, outfit_x, row_y1, row_y2):
    """Extract 2-frame working animation for all 4 directions."""
    frames = {}
    for direction, lx in [("front", DIR_FRONT), ("left", DIR_LEFT),
                           ("back",  DIR_BACK),  ("right", DIR_RIGHT)]:
        f1 = extract_player(sheet, outfit_x, lx, row_y1)
        f2 = extract_player(sheet, outfit_x, lx, row_y2)
        frames[direction] = (f1, f2)
    return frames

def save_walk_cycle(sprites, folder, name):
    sheet = Image.new("RGBA", (16 * 4, 16), (0, 0, 0, 0))
    for i, direction in enumerate(["front", "left", "back", "right"]):
        sheet.paste(sprites[direction], (i * 16, 0))
    save(scale4x(sheet), folder, f"{name}_walk.png")
    for direction, spr in sprites.items():
        save(scale4x(spr), folder, f"{name}_{direction}.png")

def save_work_cycle(frames, folder, name, suffix="work"):
    for direction, (f1, f2) in frames.items():
        sheet = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
        sheet.paste(f1, (0, 0))
        sheet.paste(f2, (16, 0))
        save(scale4x(sheet), folder, f"{name}_{suffix}_{direction}.png")

# ---------------------------------------------------------------------------
# Confirmed colors from player sprite sheet (sampled directly):
#
# INMATE outfit (orange):
#   INMATE_L = (235, 99,  0)   bright orange
#   INMATE_D = (175, 79,  0)   dark orange
#
# GUARD outfit (dark navy blue):
#   GUARD_L  = (43,  83,  151) mid blue
#   GUARD_D  = (19,  43,  75)  dark navy
#   GUARD_A  = (51,  51,  51)  near-black accent
#
# INFIRMARY outfit (light gray):
#   INFIRM_L = (203, 203, 203) light gray
#   INFIRM_D = (135, 135, 135) mid gray
#
# Skin tones (shared across all):
#   SKIN_L   = (239, 163, 103)
#   SKIN_M   = (195, 115, 75)  / (183, 103, 67)
#   SKIN_D   = (139, 63,  43)
#   OUTLINE  = (0,   0,   8)
# ---------------------------------------------------------------------------

INMATE_L  = (235, 99,  0)
INMATE_D  = (175, 79,  0)
GUARD_L   = (43,  83,  151)
GUARD_D   = (19,  43,  75)
GUARD_A   = (51,  51,  51)
INFIRM_L  = (203, 203, 203)
INFIRM_D  = (135, 135, 135)
SKIN_L    = (239, 163, 103)
SKIN_M    = (183, 103, 67)
SKIN_S    = (195, 115, 75)
SKIN_D    = (139, 63,  43)

# ---------------------------------------------------------------------------
# Character palette swaps
# ---------------------------------------------------------------------------

# Yoshiko — gray rubber apron over Inmate base
YOSHIKO_PALETTE = {
    INMATE_L: (160, 158, 162),   # orange → gray apron (light)
    INMATE_D: (110, 108, 112),   # orange → gray apron (dark)
}

# Furufue — olive/khaki casual over Infirmary base
FURUFUE_PALETTE = {
    INFIRM_L: (185, 172, 128),   # light gray → khaki
    INFIRM_D: (135, 124, 88),    # mid gray → darker khaki
}

# Narrator — white shirt + charcoal pants over Guard base
NARRATOR_PALETTE = {
    GUARD_L:  (215, 215, 220),   # navy → white shirt
    GUARD_D:  (45,  45,  52),    # dark navy → charcoal pants
    GUARD_A:  (35,  35,  40),
}

# Captain Samukawa — faded gray apron (same as Yoshiko but washed-out)
CAPTAIN_PALETTE = {
    INMATE_L: (148, 146, 142),
    INMATE_D: (100, 98,  95),
    SKIN_L:   (220, 148, 95),    # slightly paler, older
    SKIN_M:   (175, 92,  60),
    SKIN_S:   (155, 78,  50),
    SKIN_D:   (110, 50,  32),
}

# Itsumi — dark pink hoodie over Infirmary base
ITSUMI_PALETTE = {
    INFIRM_L: (215, 128, 155),   # light gray → pink
    INFIRM_D: (165, 88,  112),   # mid gray → dark pink
}

# Hanzake — worn earth-tone work clothes over Inmate base
HANZAKE_PALETTE = {
    INMATE_L: (95,  82,  65),    # orange → brown work clothes
    INMATE_D: (68,  58,  44),
}

# Goto — rumpled blue-gray suit over Guard base, flushed skin
GOTO_PALETTE = {
    GUARD_L:  (118, 128, 158),   # navy → blue-gray suit
    GUARD_D:  (78,  88,  115),
    GUARD_A:  (55,  60,  78),
    SKIN_L:   (242, 148, 92),    # reddened face
    SKIN_M:   (210, 108, 65),
    SKIN_S:   (185, 90,  52),
}

# Kasumi — peach/salmon top over Infirmary base
KASUMI_PALETTE = {
    INFIRM_L: (232, 168, 142),   # light gray → peach
    INFIRM_D: (185, 118, 95),    # mid gray → salmon
}

# Aoyama — ash-gray professional suit over Guard base
AOYAMA_PALETTE = {
    GUARD_L:  (162, 162, 165),   # navy → ash gray
    GUARD_D:  (108, 108, 112),
    GUARD_A:  (75,  75,  80),
}

# ---------------------------------------------------------------------------
# 1. CHARACTER SPRITES — extracted from player sheet, recolored per character
# ---------------------------------------------------------------------------
# Source outfit bases (confirmed from sprite sheet):
#   Inmate  (orange)    → Yoshiko, Captain, Hanzake
#   Guard   (dark blue) → Narrator, Goto, Aoyama
#   Infirm  (lt gray)   → Furufue, Itsumi, Kasumi
#
# All sprites are 16x16. Two animation frames per direction (frame2 = lx+16).
# ---------------------------------------------------------------------------

def get_char_sprites(sheet, outfit_x, palette):
    """Return dict of direction → (frame1, frame2) both recolored."""
    result = {}
    for direction, lx in [("front", DIR_FRONT), ("left", DIR_LEFT),
                           ("back",  DIR_BACK),  ("right", DIR_RIGHT)]:
        f1 = extract_player(sheet, outfit_x, lx,    Y_IDLE)
        f2 = extract_player(sheet, outfit_x, lx+16, Y_IDLE)
        result[direction] = (
            fuzzy_palette_swap(f1, palette, tolerance=15),
            fuzzy_palette_swap(f2, palette, tolerance=15),
        )
    return result

def get_work_sprites(sheet, outfit_x, palette, work_y):
    """Return dict of direction → (frame1, frame2) for a work animation."""
    result = {}
    for direction, lx in [("front", DIR_FRONT), ("left", DIR_LEFT),
                           ("back",  DIR_BACK),  ("right", DIR_RIGHT)]:
        f1 = extract_player(sheet, outfit_x, lx,    work_y)
        f2 = extract_player(sheet, outfit_x, lx+16, work_y)
        result[direction] = (
            fuzzy_palette_swap(f1, palette, tolerance=15),
            fuzzy_palette_swap(f2, palette, tolerance=15),
        )
    return result

def save_char_sprites(idle, work, folder, name):
    """Save walk sheet (4-dir idle) and work animation sheets."""
    h = SPRITE_H
    # Walk sheet: 4 directions × 2 frames = 8 sprites in one row
    walk_sheet = Image.new("RGBA", (16 * 8, h), (0, 0, 0, 0))
    for i, direction in enumerate(["front", "left", "back", "right"]):
        f1, f2 = idle[direction]
        walk_sheet.paste(f1, (i * 32, 0))
        walk_sheet.paste(f2, (i * 32 + 16, 0))
    save(scale4x(walk_sheet), folder, f"{name}_walk.png")

    # Individual direction idle sprites (single frame for Godot)
    for direction, (f1, _) in idle.items():
        save(scale4x(f1), folder, f"{name}_{direction}.png")

    # Work animation
    if work:
        work_sheet = Image.new("RGBA", (16 * 8, h), (0, 0, 0, 0))
        for i, direction in enumerate(["front", "left", "back", "right"]):
            f1, f2 = work[direction]
            work_sheet.paste(f1, (i * 32, 0))
            work_sheet.paste(f2, (i * 32 + 16, 0))
        save(scale4x(work_sheet), folder, f"{name}_work.png")

def make_character_sprites():
    print("\n[1] Character sprites")
    sheet = load("PC _ Computer - The Escapists - Playable Characters and Outfits - Rabbit (Inmate).png")

    characters = [
        # (outfit_x, palette, work_y, folder, name)
        (OUTFIT_INMATE,    YOSHIKO_PALETTE,  Y_JANITOR_1, "characters", "yoshiko"),
        (OUTFIT_INFIRMARY, FURUFUE_PALETTE,  Y_GARDEN_1,  "characters", "furufue"),
        (OUTFIT_GUARD,     NARRATOR_PALETTE, Y_JANITOR_1, "characters", "narrator"),
        (OUTFIT_INMATE,    CAPTAIN_PALETTE,  Y_JANITOR_1, "npcs",       "captain_samukawa"),
        (OUTFIT_INFIRMARY, ITSUMI_PALETTE,   Y_JANITOR_1, "npcs",       "itsumi"),
        (OUTFIT_INMATE,    HANZAKE_PALETTE,  Y_JANITOR_1, "npcs",       "hanzake"),
        (OUTFIT_GUARD,     GOTO_PALETTE,     None,        "npcs",       "goto"),
        (OUTFIT_INFIRMARY, KASUMI_PALETTE,   None,        "npcs",       "kasumi"),
        (OUTFIT_GUARD,     AOYAMA_PALETTE,   None,        "npcs",       "aoyama"),
    ]

    for outfit_x, palette, work_y, folder, name in characters:
        idle = get_char_sprites(sheet, outfit_x, palette)
        work = get_work_sprites(sheet, outfit_x, palette, work_y) if work_y else None
        save_char_sprites(idle, work, folder, name)

    # The Giant — same as narrator/guard but we stretch the sprite 2px taller
    idle_giant = get_char_sprites(sheet, OUTFIT_GUARD, {
        GUARD_L: (70, 78, 92), GUARD_D: (45, 52, 65), GUARD_A: (30, 32, 38)
    })
    # Vertically stretch each frame to suggest height
    stretched = {}
    for direction, (f1, f2) in idle_giant.items():
        s1 = f1.resize((16, 20), Image.NEAREST)
        s2 = f2.resize((16, 20), Image.NEAREST)
        stretched[direction] = (s1, s2)
    walk_sheet = Image.new("RGBA", (16 * 8, 20), (0, 0, 0, 0))
    for i, direction in enumerate(["front", "left", "back", "right"]):
        f1, f2 = stretched[direction]
        walk_sheet.paste(f1, (i * 32, 0))
        walk_sheet.paste(f2, (i * 32 + 16, 0))
    save(scale4x(walk_sheet), "npcs", "the_giant_walk.png")
    for direction, (f1, _) in stretched.items():
        save(scale4x(f1), "npcs", f"the_giant_{direction}.png")

# ---------------------------------------------------------------------------
# 2. FACTORY OBJECTS — drawn programmatically in pixel art
# ---------------------------------------------------------------------------

def px(draw, x, y, color):
    draw.point((x, y), fill=color)

def rect(draw, x1, y1, x2, y2, color):
    draw.rectangle([x1, y1, x2, y2], fill=color)

def make_shredder():
    """16x16 top-down view of a document shredder machine"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Machine body — dark gray box
    rect(d, 1, 1, 14, 14, (80, 80, 85))
    # Top face highlight
    rect(d, 2, 2, 13, 5,  (110, 110, 115))
    # Feed slot — dark horizontal slit
    rect(d, 3, 6, 12, 7,  (20, 20, 22))
    # Outlet / waste chute indicator
    rect(d, 4, 9, 11, 11, (50, 50, 55))
    # Corner bolts
    for bx, by in [(2,2),(13,2),(2,13),(13,13)]:
        px(d, bx, by, (40, 40, 44))
    # Power light — green
    px(d, 12, 3, (60, 200, 60))
    return img

def make_shredder_on():
    """Shredder with paper being fed in — orange/warm light"""
    img = make_shredder()
    d = ImageDraw.Draw(img)
    # Paper strip in slot
    rect(d, 4, 6, 11, 7, (230, 220, 200))
    # Power light — orange (active)
    px(d, 12, 3, (255, 160, 20))
    return img

def make_shredder_jammed():
    """Shredder jammed — red light"""
    img = make_shredder()
    d = ImageDraw.Draw(img)
    rect(d, 3, 5, 12, 8, (200, 180, 160))  # crumpled paper
    px(d, 12, 3, (220, 40, 40))             # red warning light
    return img

def make_filing_cabinet():
    """16x16 top-down filing cabinet with two drawers"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Cabinet body
    rect(d, 1, 1, 14, 14, (160, 158, 150))
    # Top surface highlight
    rect(d, 2, 2, 13, 3,  (190, 188, 180))
    # Two drawer faces
    rect(d, 2, 4, 13, 8,  (145, 143, 135))
    rect(d, 2, 10, 13, 14, (145, 143, 135))
    # Drawer dividers
    rect(d, 2, 9, 13, 9,  (100, 98, 92))
    # Drawer handles
    rect(d, 6, 6, 9, 6,   (90, 85, 75))
    rect(d, 6, 12, 9, 12, (90, 85, 75))
    # Shadow edge
    rect(d, 14, 2, 14, 14, (100, 98, 92))
    rect(d, 2, 14, 14, 14, (100, 98, 92))
    return img

def make_document_packet():
    """16x16 stack of papers / document packet"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Paper stack shadow
    rect(d, 3, 4, 13, 14, (180, 175, 165))
    # Top sheet
    rect(d, 2, 3, 12, 13, (235, 232, 225))
    # Lines on top sheet
    for ly in [5, 7, 9, 11]:
        rect(d, 4, ly, 10, ly, (190, 185, 175))
    # Clip / staple at top
    rect(d, 4, 3, 10, 4, (130, 128, 120))
    # Corner fold
    rect(d, 11, 3, 12, 4, (200, 195, 185))
    return img

def make_document_packet_open():
    """Open document packet — pages fanned out"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Back page
    rect(d, 4, 2, 14, 14, (200, 196, 188))
    # Middle page
    rect(d, 3, 3, 12, 13, (220, 216, 208))
    # Top page
    rect(d, 2, 4, 11, 14, (240, 237, 230))
    # Lines
    for ly in [6, 8, 10, 12]:
        rect(d, 4, ly, 9, ly, (190, 186, 178))
    # Red pen mark (proofreader's red ink)
    rect(d, 5, 7, 8, 7, (200, 50, 50))
    return img

def make_red_pen():
    """8x16 item: red ballpoint pen"""
    img = Image.new("RGBA", (8, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Pen body
    rect(d, 3, 1, 4, 13, (200, 40, 40))
    # Pen clip
    rect(d, 4, 1, 4, 8,  (170, 30, 30))
    # Pen tip
    rect(d, 3, 14, 4, 15, (40, 40, 44))
    # Cap end
    rect(d, 3, 0, 4, 1,  (220, 60, 60))
    return img

def make_moss_patch():
    """16x16 ground tile: moss growing on concrete"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Base concrete
    rect(d, 0, 0, 15, 15, (140, 138, 132))
    # Concrete texture flecks
    for cx, cy in [(2,3),(7,1),(11,5),(4,10),(13,8),(9,13),(1,13),(6,7)]:
        px(d, cx, cy, (120, 118, 112))
    # Moss patches — varied greens
    for mx, my, mw, mh, mc in [
        (1, 1, 4, 3,  (70, 120, 55)),
        (3, 2, 2, 2,  (90, 145, 65)),
        (8, 5, 5, 4,  (65, 115, 50)),
        (10, 6, 3, 2, (85, 140, 60)),
        (2, 10, 4, 4, (75, 125, 58)),
        (4, 11, 2, 2, (95, 150, 68)),
        (11, 11, 4, 3,(68, 118, 52)),
    ]:
        rect(d, mx, my, mx+mw-1, my+mh-1, mc)
    return img

def make_moss_dense():
    """Dense moss tile — mostly green"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Base — dark green
    rect(d, 0, 0, 15, 15, (60, 100, 45))
    # Texture variation
    for mx, my, mc in [
        (0,0,  (75,120,58)), (4,0,  (55,95,40)),  (8,0,  (80,128,62)),
        (12,0, (58,98,43)),  (2,4,  (88,135,68)),  (6,2,  (65,108,50)),
        (10,3, (72,118,55)), (14,2, (58,96,42)),
        (1,8,  (82,130,64)), (5,7,  (60,100,46)),  (9,6,  (78,125,60)),
        (13,8, (55,92,40)),  (3,12, (85,133,66)),  (7,11, (63,104,48)),
        (11,13,(76,122,58)), (15,12,(57,95,41)),
    ]:
        px(d, mx, my, mc)
    # Tiny lighter tips (spore capsules)
    for tx, ty in [(3,1),(9,4),(5,9),(12,6),(7,13)]:
        px(d, tx, ty, (160, 185, 100))
    return img

def make_black_bird():
    """8x8 top-down bird sprite — the factory shags"""
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body — oil black
    rect(d, 2, 2, 5, 5, (18, 18, 20))
    # Wing spread hint
    px(d, 1, 3, (22, 22, 24))
    px(d, 6, 3, (22, 22, 24))
    px(d, 1, 4, (20, 20, 22))
    px(d, 6, 4, (20, 20, 22))
    # Head
    rect(d, 3, 1, 4, 2, (15, 15, 17))
    # Beak
    px(d, 3, 0, (90, 85, 70))
    # Sheen highlight
    px(d, 3, 2, (50, 55, 65))
    return img

def make_coypu():
    """12x8 top-down coypu (large rodent)"""
    img = Image.new("RGBA", (12, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body
    rect(d, 2, 1, 9, 6, (110, 85, 55))
    # Belly
    rect(d, 3, 2, 8, 5, (145, 115, 75))
    # Head
    rect(d, 0, 2, 3, 5, (100, 78, 50))
    # Snout
    rect(d, 0, 3, 1, 4, (130, 100, 68))
    # Tail
    rect(d, 9, 3, 11, 4, (85, 65, 42))
    # Eye
    px(d, 1, 2, (20, 15, 10))
    # Fur texture
    for fx, fy in [(4,2),(6,2),(8,2),(3,5),(5,5),(7,5)]:
        px(d, fx, fy, (95, 73, 46))
    return img

def make_apron_item():
    """8x8 item: gray apron (Yoshiko's)"""
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rect(d, 1, 0, 6, 7, (150, 150, 155))
    # Neck strap
    rect(d, 3, 0, 4, 1, (120, 120, 125))
    # Pocket
    rect(d, 2, 4, 5, 6, (130, 130, 135))
    # Shadow
    rect(d, 6, 1, 6, 7, (115, 115, 120))
    return img

def make_id_badge(strap_color):
    """8x8 item: ID badge on lanyard"""
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Lanyard
    rect(d, 3, 0, 4, 2, strap_color)
    # Badge
    rect(d, 1, 3, 6, 7, (220, 215, 205))
    # Photo box
    rect(d, 2, 4, 3, 6, (160, 175, 210))
    # Text lines
    rect(d, 4, 4, 5, 4, (100, 95, 90))
    rect(d, 4, 5, 6, 5, (100, 95, 90))
    rect(d, 4, 6, 5, 6, (100, 95, 90))
    # Border
    rect(d, 1, 3, 6, 3, (140, 135, 125))
    return img

def make_shred_bag():
    """12x14 — full bag of shredded paper strips"""
    img = Image.new("RGBA", (12, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Bag body — black plastic
    rect(d, 1, 3, 10, 13, (25, 25, 28))
    # Tie at top
    rect(d, 4, 1, 7, 3,   (35, 35, 38))
    # Shredded paper showing through (semi-transparent look via lighter patches)
    for sx, sy in [(2,5),(5,5),(8,5),(3,8),(6,8),(9,8),(2,11),(5,11),(8,11)]:
        px(d, sx, sy, (50, 50, 54))
    # Bag highlight
    rect(d, 1, 3, 1, 12, (45, 45, 48))
    return img

def make_factory_floor():
    """16x16 factory floor tile — concrete with subtle grid lines"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, (145, 142, 138))
    # Grout lines
    rect(d, 0, 0, 15, 0, (120, 117, 113))
    rect(d, 0, 0, 0, 15, (120, 117, 113))
    rect(d, 15, 0, 15, 15, (125, 122, 118))
    rect(d, 0, 15, 15, 15, (125, 122, 118))
    # Subtle wear spots
    for wx, wy in [(3,4),(9,2),(12,7),(5,11),(13,13)]:
        px(d, wx, wy, (135, 132, 128))
    return img

def make_basement_floor():
    """16x16 darker basement floor"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 15, 15, (115, 113, 110))
    rect(d, 0, 0, 15, 0,  (95, 93, 90))
    rect(d, 0, 0, 0, 15,  (95, 93, 90))
    rect(d, 15, 0, 15, 15,(100, 98, 95))
    rect(d, 0, 15, 15, 15,(100, 98, 95))
    for wx, wy in [(2,5),(7,3),(11,8),(4,12),(13,10)]:
        px(d, wx, wy, (105, 103, 100))
    return img

def make_wall_tile():
    """16x16 factory wall — gray industrial"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Wall body
    rect(d, 0, 0, 15, 15, (90, 88, 86))
    # Brick pattern
    rect(d, 0, 7, 15, 8,  (75, 73, 71))
    for bx in [0, 8]:
        rect(d, bx, 0, bx+1, 6, (75, 73, 71))
    for bx in [4, 12]:
        rect(d, bx, 9, bx+1, 15, (75, 73, 71))
    # Top highlight
    rect(d, 0, 0, 15, 1, (110, 108, 106))
    return img

def make_desk():
    """16x16 top-down office desk"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Desk surface
    rect(d, 1, 1, 14, 14, (175, 155, 115))
    # Top edge (front face of desk)
    rect(d, 1, 14, 14, 15, (130, 115, 85))
    # Side edge
    rect(d, 14, 1, 15, 15, (130, 115, 85))
    # Surface highlight
    rect(d, 2, 2, 8, 3, (195, 175, 130))
    # Leg shadows
    for lx, ly in [(1,1),(13,1),(1,13),(13,13)]:
        px(d, lx, ly, (105, 90, 65))
    return img

def make_tran_cart():
    """16x16 top-down document delivery cart (TRAN workers)"""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Cart base
    rect(d, 1, 3, 14, 13, (170, 165, 158))
    # Document boxes stacked on cart
    rect(d, 2, 4, 13, 8,  (200, 195, 185))
    rect(d, 2, 9, 13, 12, (195, 190, 180))
    # Box divider
    rect(d, 7, 4, 7, 12, (155, 150, 143))
    # Cart handle at back
    rect(d, 1, 1, 14, 2,  (100, 98, 94))
    rect(d, 1, 1, 1,  3,  (100, 98, 94))
    rect(d, 14, 1, 14, 3, (100, 98, 94))
    # Wheels
    for wx in [2, 7, 12]:
        rect(d, wx, 13, wx+1, 14, (60, 58, 55))
    return img

def make_power_tower():
    """8x16 — the Captain's exercise machine"""
    img = Image.new("RGBA", (8, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Vertical post
    rect(d, 3, 0, 4, 15, (90, 88, 85))
    # Crossbars
    rect(d, 1, 3, 6, 4,  (110, 108, 105))
    rect(d, 1, 8, 6, 9,  (110, 108, 105))
    # Pull-up bar at top
    rect(d, 0, 1, 7, 2,  (100, 98, 95))
    # Base feet
    rect(d, 0, 14, 7, 15, (75, 73, 70))
    # Highlight
    rect(d, 3, 0, 3, 15, (115, 113, 110))
    return img

# ---------------------------------------------------------------------------
# 3. FACTORY TILESET — assemble a usable tileset sheet
# ---------------------------------------------------------------------------

def make_factory_tileset():
    """Assemble a 128x64 tileset sheet with all floor/wall tiles"""
    tiles = [
        make_factory_floor(),
        make_basement_floor(),
        make_wall_tile(),
        make_moss_patch(),
        make_moss_dense(),
    ]
    # Pad to 16x16 each
    sheet = Image.new("RGBA", (16 * len(tiles), 16), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t.resize((16, 16), Image.NEAREST), (i * 16, 0))
    return sheet

# ---------------------------------------------------------------------------
# 4. ITEMS SHEET — all collectible / usable items
# ---------------------------------------------------------------------------

def make_items_sheet():
    items = {
        "red_pen":        make_red_pen().resize((16, 16), Image.NEAREST),
        "document_packet": make_document_packet(),
        "document_open":   make_document_packet_open(),
        "apron":           make_apron_item().resize((16, 16), Image.NEAREST),
        "id_badge_red":    make_id_badge((180, 40, 40)).resize((16, 16), Image.NEAREST),
        "id_badge_silver": make_id_badge((180, 180, 185)).resize((16, 16), Image.NEAREST),
        "shred_bag":       make_shred_bag().resize((16, 16), Image.NEAREST),
    }
    sheet = Image.new("RGBA", (16 * len(items), 16), (0, 0, 0, 0))
    for i, (name, item) in enumerate(items.items()):
        item_16 = item.resize((16, 16), Image.NEAREST)
        sheet.paste(item_16, (i * 16, 0))
    return items, sheet

# ---------------------------------------------------------------------------
# 5. OBJECTS SHEET — machines and furniture
# ---------------------------------------------------------------------------

def make_objects_sheet():
    objects = {
        "shredder":        make_shredder(),
        "shredder_on":     make_shredder_on(),
        "shredder_jammed": make_shredder_jammed(),
        "filing_cabinet":  make_filing_cabinet(),
        "desk":            make_desk(),
        "tran_cart":       make_tran_cart(),
        "power_tower":     make_power_tower().resize((16, 16), Image.NEAREST),
    }
    sheet = Image.new("RGBA", (16 * len(objects), 16), (0, 0, 0, 0))
    for i, (name, obj) in enumerate(objects.items()):
        obj_16 = obj.resize((16, 16), Image.NEAREST)
        sheet.paste(obj_16, (i * 16, 0))
    return objects, sheet

# ---------------------------------------------------------------------------
# 6. CREATURES
# ---------------------------------------------------------------------------

def make_creatures():
    return {
        "factory_shag": make_black_bird(),
        "coypu":        make_coypu(),
    }

# ---------------------------------------------------------------------------
# RUN ALL
# ---------------------------------------------------------------------------

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    print("=== Factory Sprite Pipeline ===")

    # Characters
    make_character_sprites()

    # Objects
    print("\n[2] Factory objects")
    objects, obj_sheet = make_objects_sheet()
    for name, obj in objects.items():
        save(scale4x(obj), "objects", f"{name}.png")
    save(scale4x(obj_sheet), "objects", "_sheet_objects.png")

    # Items
    print("\n[3] Items")
    items, item_sheet = make_items_sheet()
    for name, item in items.items():
        save(scale4x(item), "items", f"{name}.png")
    save(scale4x(item_sheet), "items", "_sheet_items.png")

    # Tileset
    print("\n[4] Tilesets")
    tiles = {
        "factory_floor":   make_factory_floor(),
        "basement_floor":  make_basement_floor(),
        "wall":            make_wall_tile(),
        "moss_patch":      make_moss_patch(),
        "moss_dense":      make_moss_dense(),
    }
    for name, tile in tiles.items():
        save(scale4x(tile), "tilesets", f"{name}.png")
    tileset = make_factory_tileset()
    save(scale4x(tileset), "tilesets", "_sheet_tileset.png")

    # Creatures
    print("\n[5] Creatures")
    creatures = make_creatures()
    for name, c in creatures.items():
        save(scale4x(c), "objects", f"{name}.png")

    print("\n✓ All sprites generated in /sprites/")

if __name__ == "__main__":
    main()
