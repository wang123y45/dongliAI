"""从品牌主图标生成 Electron 打包所需的 PNG / ICO / ICNS。"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "brand" / "app-icon-dark-1024.png"
BUILD = ROOT / "build"
BUILD.mkdir(exist_ok=True)


def main():
    im = Image.open(SRC).convert("RGBA")
    im.save(BUILD / "icon.png")
    im.save(
        BUILD / "icon.ico",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )

    # ICNS：128 / 256 / 512 / 1024 四个 PNG 分块，满足 Retina 与 Dock 显示。
    pngs = []
    for size, ostype in ((128, b"ic07"), (256, b"ic08"), (512, b"ic09"), (1024, b"ic10")):
        path = BUILD / f".icns-{size}.png"
        im.resize((size, size), Image.LANCZOS).save(path, "PNG")
        pngs.append((ostype, path.read_bytes()))
    body = b""
    for ostype, data in pngs:
        body += ostype + (len(data) + 8).to_bytes(4, "big") + data
    (BUILD / "icon.icns").write_bytes(b"icns" + (len(body) + 8).to_bytes(4, "big") + body)
    for path in BUILD.glob(".icns-*.png"):
        path.unlink(missing_ok=True)
    print("icons:", *(p.name for p in BUILD.iterdir() if p.name.startswith("icon")))


if __name__ == "__main__":
    main()
