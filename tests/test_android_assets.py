import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "android_assets", Path(__file__).resolve().parents[1] / "scripts/prepare-android-assets.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AndroidAssetsTest(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
