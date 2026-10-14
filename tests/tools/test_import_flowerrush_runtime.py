"""Safety and idempotence tests for the FlowerRush assets-only importer."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

SOURCE_SCRIPT = Path(__file__).resolve().parents[2] / "tools" / "import_flowerrush_runtime.py"
spec = importlib.util.spec_from_file_location("import_flowerrush_runtime", SOURCE_SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AssetImportTest(unittest.TestCase):
    def test_pinned_inventory_has_no_quarantine_or_duplicates(self):
        inventory = module.read_inventory()
        self.assertEqual(len(inventory["items"]), 131)
        self.assertEqual(len(set(i["target_path"] for i in inventory["items"])), 131)
        for item in inventory["items"]:
            self.assertNotIn("/source/", item["source_path"])
            self.assertNotIn("quarantine", item["source_path"])

    def test_dry_run_apply_rerun_and_collision(self):
        with tempfile.TemporaryDirectory() as folder:
            source, target = Path(folder) / "source", Path(folder) / "target"
            source.mkdir()
            target.mkdir()
            (source / "project.godot").touch()
            (target / "project.godot").touch()
            raw = b"\x89PNG\r\n\x1a\nsample-data"
            src = "assets/sprites/plants/cultivation_c_v1/test.png"
            dst = "assets/reused/flowerrush/sprites/plants/cultivation_c_v1/test.png"
            item = {"source_path": src, "target_path": dst,
                    "bytes": len(raw), "git_blob_sha": module.git_blob_sha(raw)}
            (source / src).parent.mkdir(parents=True)
            (source / src).write_bytes(raw)
            self.assertEqual(module.transfer(source, target, [item], False)["copied"], 0)
            self.assertFalse((target / dst).exists())
            self.assertEqual(module.transfer(source, target, [item], True)["copied"], 1)
            self.assertEqual((target / dst).read_bytes(), raw)
            self.assertEqual(module.transfer(source, target, [item], True)["already_identical"], 1)
            (target / dst).write_bytes(b"changed")
            with self.assertRaisesRegex(RuntimeError, "collision"):
                module.transfer(source, target, [item], True)

    def test_missing_source_aborts_entire_batch_before_writing(self):
        with tempfile.TemporaryDirectory() as folder:
            source, target = Path(folder) / "source", Path(folder) / "target"
            source.mkdir()
            target.mkdir()
            (source / "project.godot").touch()
            (target / "project.godot").touch()
            raw = b"same"
            present = {"source_path": "assets/a.png",
                       "target_path": "assets/reused/flowerrush/a.png",
                       "bytes": len(raw), "git_blob_sha": module.git_blob_sha(raw)}
            absent = {"source_path": "assets/b.png",
                      "target_path": "assets/reused/flowerrush/b.png",
                      "bytes": 1, "git_blob_sha": "0" * 40}
            (source / "assets").mkdir()
            (source / present["source_path"]).write_bytes(raw)
            with self.assertRaisesRegex(RuntimeError, "Missing source"):
                module.transfer(source, target, [present, absent], True)
            self.assertFalse((target / present["target_path"]).exists())


if __name__ == "__main__":
    unittest.main()
