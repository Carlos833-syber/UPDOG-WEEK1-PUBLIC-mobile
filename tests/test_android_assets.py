import importlib.util
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "android_assets", Path(__file__).resolve().parents[1] / "scripts/prepare-android-assets.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AndroidAssetsTest(unittest.TestCase):
    def test_empty_assets_remain_in_extraction_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            old_root = module.ROOT
            self.addCleanup(setattr, module, "ROOT", old_root)
            module.ROOT = Path(directory)
            for name in ["assets/fonts/fonts-go-here.txt", "content/custom_events/dialogue.txt"]:
                path = module.ROOT / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"")
            entries = {entry["path"]: entry for entry in module.build_manifest()["files"]}
            self.assertEqual(len(entries), 2)
            for name, entry in entries.items():
                self.assertEqual(entry["id"], name)
                self.assertEqual(entry["size"], 0)
                self.assertEqual(entry["sha256"], hashlib.sha256(b"").hexdigest())

    def test_asset_ids_overrides_and_update_fingerprint(self):
        with tempfile.TemporaryDirectory() as directory:
            old_root = module.ROOT
            self.addCleanup(setattr, module, "ROOT", old_root)
            module.ROOT = Path(directory)
            files = {
                "assets/embeds/shared/base.txt": b"embedded",
                "assets/shared/base.txt": b"override",
                "assets/embeds/songs/tutorial/chart.json": b"{}",
                "assets/videos/intro.mp4": b"video",
                "assets/shared/song.mp3": b"web-only",
                "content/images/editor.fla": b"source-only",
                "assets/fonts/pixel.otf": b"font",
                "content/fonts/test.ttf": b"font",
                "content/stages/polus.hx": b"function create() {}",
            }
            for name, data in files.items():
                path = module.ROOT / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            first = module.build_manifest()
            entries = {entry["path"]: entry for entry in first["files"]}
            self.assertEqual(len(entries), 6)
            self.assertEqual(entries["assets/fonts/pixel.otf"]["id"], "android-fonts/assets/fonts/pixel.otf")
            self.assertEqual(entries["content/fonts/test.ttf"]["id"], "android-fonts/content/fonts/test.ttf")
            self.assertEqual(entries["assets/shared/base.txt"]["size"], len(b"override"))
            self.assertEqual(entries["assets/songs/tutorial/chart.json"]["id"], "assets/songs/tutorial/chart.json")
            self.assertEqual(entries["assets/videos/intro.mp4"]["id"], "videos:assets/videos/intro.mp4")
            self.assertEqual(entries["content/stages/polus.hx"]["id"], "content/stages/polus.hx")
            self.assertEqual(first, module.build_manifest())
            (module.ROOT / "content/stages/polus.hx").write_text("function create() { trace('changed'); }")
            self.assertNotEqual(first["version"], module.build_manifest()["version"])


class AssetCaseTest(unittest.TestCase):
    def test_atlas_pairs_and_character_images_use_exact_case(self):
        # Android's extracted filesystem is case-sensitive, unlike many dev PCs.
        root = Path(__file__).resolve().parents[1]
        image_dirs = [root / "content/images", root / "assets/shared/images", root / "assets/embeds/shared/images"]
        images = {str(path).lower(): path for directory in image_dirs for path in directory.rglob("*.png")}
        for directory in image_dirs:
            for atlas in directory.rglob("*.xml"):
                expected = atlas.with_suffix(".png")
                if str(expected).lower() in images:
                    self.assertTrue(expected.is_file(), f"Atlas/image case mismatch: {atlas}")
        for character in (root / "content/characters").glob("*.json"):
            image = json.loads(character.read_text()).get("image")
            if not image:
                continue
            for directory in image_dirs:
                expected = directory / (image + ".png")
                if str(expected).lower() in images:
                    self.assertTrue(expected.is_file(), f"Character image case mismatch: {character}: {image}")


if __name__ == "__main__":
    unittest.main()
