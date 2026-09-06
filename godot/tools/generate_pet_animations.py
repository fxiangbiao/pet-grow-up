#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_pet_animations.py
为 pet-grow-up Godot 工程生成 Q 版猫精灵的占位动画帧。
使用 PIL 程序化绘制，输出到 assets/sprites/pet/。
表情：idle(呼吸) / wave(招手) / cheer(欢呼) / wrong(答错) / think(思考)
"""
import math
import os
from PIL import Image, ImageDraw

W, H = 64, 64

COLORS = {
    "body": (120, 220, 200),
    "body_dark": (88, 180, 165),
    "body_light": (170, 240, 225),
    "ear_in": (255, 170, 190),
    "eye": (40, 44, 70),
    "white": (255, 255, 255),
    "blush": (255, 150, 170),
    "mouth": (60, 50, 70),
    "sweat": (120, 200, 255),
    "bubble": (220, 235, 255),
    "star": (255, 220, 90),
}

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "pet")
os.makedirs(OUT, exist_ok=True)


def draw_critter(anim, fi, total):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    t = fi / max(total - 1, 1)
    prog = fi / total

    cx = W // 2
    base_y = 34  # 身体中心基准
    bob = 0
    rot = 0.0
    eye = "normal"
    mouth = "smile"
    paw_l = None  # (dx, dy, scale)
    paw_r = None
    extra = None  # 附加元素

    if anim == "idle":
        bob = int(math.sin(prog * math.pi * 2) * 1.5)
        eye = "normal"
    elif anim == "wave":
        bob = int(abs(math.sin(prog * math.pi * 2)) * 1)
        # 右手上下摆
        paw_r = (16, -10 - int(math.sin(prog * math.pi * 2) * 5), 1.0)
        eye = "happy"
    elif anim == "cheer":
        bob = -int(abs(math.sin(prog * math.pi * 2)) * 4)
        paw_l = (-15, -12, 1.1)
        paw_r = (15, -12, 1.1)
        eye = "star"
        mouth = "open"
    elif anim == "wrong":
        rot = math.sin(prog * math.pi * 4) * 8.0
        eye = "squeeze"
        mouth = "frown"
        extra = "sweat"
    elif anim == "think":
        bob = int(math.sin(prog * math.pi * 2) * 1)
        eye = "up"
        extra = "bubble"

    cy = base_y + bob

    # 后爪（脚）
    foot_w, foot_h = 12, 7
    d.rounded_rectangle([cx - 14, cy + 14, cx - 2, cy + 14 + foot_h], radius=3, fill=COLORS["body_dark"])
    d.rounded_rectangle([cx + 2, cy + 14, cx + 14, cy + 14 + foot_h], radius=3, fill=COLORS["body_dark"])

    # 身体（圆）
    bw, bh = 40, 38
    bb = [cx - bw // 2, cy - bh // 2, cx + bw // 2, cy + bh // 2]
    d.ellipse(bb, fill=COLORS["body"])
    # 肚子高光
    d.ellipse([cx - 14, cy - 6, cx + 14, cy + 14], fill=COLORS["body_light"])

    # 耳朵（猫三角）
    for s in (-1, 1):
        ex = cx + s * 13
        d.polygon([(ex - 8, cy - bh // 2 + 2), (ex + 8, cy - bh // 2 + 2), (ex, cy - bh // 2 - 12)], fill=COLORS["body"])
        d.polygon([(ex - 4, cy - bh // 2), (ex + 4, cy - bh // 2), (ex, cy - bh // 2 - 7)], fill=COLORS["ear_in"])

    # 腮红
    if eye != "squeeze":
        d.ellipse([cx - 15, cy + 1, cx - 9, cy + 6], fill=COLORS["blush"])
        d.ellipse([cx + 9, cy + 1, cx + 15, cy + 6], fill=COLORS["blush"])

    # 眼睛
    ey = cy - 3
    if eye == "normal":
        d.ellipse([cx - 9, ey - 3, cx - 5, ey + 1], fill=COLORS["eye"])
        d.ellipse([cx + 5, ey - 3, cx + 9, ey + 1], fill=COLORS["eye"])
    elif eye == "happy":
        d.arc([cx - 11, ey - 4, cx - 3, ey + 2], 180, 360, fill=COLORS["eye"], width=2)
        d.arc([cx + 3, ey - 4, cx + 11, ey + 2], 180, 360, fill=COLORS["eye"], width=2)
    elif eye == "star":
        for s in (-1, 1):
            ex = cx + s * 7
            d.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=COLORS["eye"])
            d.ellipse([ex - 1, ey - 1, ex + 1, ey + 1], fill=COLORS["star"])
    elif eye == "squeeze":
        d.line([cx - 11, ey - 1, cx - 4, ey + 2], fill=COLORS["eye"], width=2)
        d.line([cx - 4, ey + 2, cx - 2, ey - 1], fill=COLORS["eye"], width=2)
        d.line([cx + 4, ey - 1, cx + 11, ey + 2], fill=COLORS["eye"], width=2)
        d.line([cx + 11, ey + 2, cx + 13, ey - 1], fill=COLORS["eye"], width=2)
    elif eye == "up":
        d.ellipse([cx - 9, ey - 5, cx - 5, ey - 1], fill=COLORS["eye"])
        d.ellipse([cx + 5, ey - 5, cx + 9, ey - 1], fill=COLORS["eye"])

    # 嘴巴
    if mouth == "smile":
        d.arc([cx - 4, ey + 3, cx + 4, ey + 9], 0, 180, fill=COLORS["mouth"], width=2)
    elif mouth == "open":
        d.ellipse([cx - 4, ey + 3, cx + 4, ey + 9], fill=COLORS["mouth"])
    elif mouth == "frown":
        d.arc([cx - 4, ey + 3, cx + 4, ey + 8], 180, 360, fill=COLORS["mouth"], width=2)

    # 爪子
    for paw in (paw_l, paw_r):
        if paw:
            dx, dy, sc = paw
            r = int(6 * sc)
            d.ellipse([cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r], fill=COLORS["body"])
            d.ellipse([cx + dx - r + 1, cy + dy - r + 1, cx + dx + r - 1, cy + dy + r - 1], fill=COLORS["body_light"])

    # 附加
    if extra == "sweat":
        d.ellipse([cx + 14, cy - 8, cx + 19, cy - 3], fill=COLORS["sweat"])
    elif extra == "bubble":
        d.ellipse([cx + 12, cy - 22, cx + 20, cy - 14], fill=COLORS["white"])
        d.ellipse([cx + 18, cy - 28, cx + 24, cy - 22], fill=COLORS["white"])
        d.ellipse([cx + 20, cy - 24, cx + 23, cy - 21], fill=COLORS["bubble"])

    if rot != 0.0:
        img = img.rotate(rot, resample=Image.Resampling.BICUBIC, center=(cx, cy))
    return img


def draw_apple(color_fill, color_dark):
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = 14
    # 果身
    d.ellipse([cx - 9, 6, cx + 9, 26], fill=color_fill)
    d.ellipse([cx - 9, 6, cx + 9, 26], outline=color_dark, width=1)
    # 高光
    d.ellipse([cx - 5, 9, cx - 1, 13], fill=(255, 255, 255, 180))
    # 叶子 + 柄
    d.line([cx, 6, cx, 2], fill=(120, 80, 40), width=2)
    d.polygon([(cx, 5), (cx + 7, 2), (cx + 2, 8)], fill=(90, 180, 90))
    return img


def draw_bowl():
    img = Image.new("RGBA", (140, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 碗体（半圆）
    d.pieslice([10, 10, 130, 130], 0, 180, fill=(225, 235, 245), outline=(150, 170, 200), width=3)
    # 碗口椭圆
    d.ellipse([10, 8, 130, 30], fill=(235, 245, 255), outline=(150, 170, 200), width=3)
    return img


def draw_slot(filled=False, fill_color=(255, 150, 150)):
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if filled:
        d.ellipse([3, 3, 25, 25], fill=fill_color)
    else:
        d.ellipse([3, 3, 25, 25], outline=(150, 170, 200), width=2)
    return img


def draw_tile():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([4, 4, 60, 60], radius=12, fill=(255, 255, 255), outline=(120, 160, 220), width=3)
    return img


def main():
    anims = {"idle": 4, "wave": 4, "cheer": 4, "wrong": 2, "think": 4}
    for name, n in anims.items():
        for i in range(n):
            draw_critter(name, i, n).save(os.path.join(OUT, f"pet_{name}_{i}.png"))
    # 静态占位素材
    draw_apple((235, 90, 90), (180, 50, 50)).save(os.path.join(OUT, "apple_red.png"))
    draw_apple((120, 200, 110), (80, 150, 75)).save(os.path.join(OUT, "apple_green.png"))
    draw_bowl().save(os.path.join(OUT, "bowl.png"))
    draw_slot(False).save(os.path.join(OUT, "slot_empty.png"))
    draw_slot(True, (235, 90, 90)).save(os.path.join(OUT, "slot_filled.png"))
    draw_tile().save(os.path.join(OUT, "tile.png"))
    print("OK ->", OUT)


if __name__ == "__main__":
    main()
