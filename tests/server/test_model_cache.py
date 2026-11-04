"""Cache behavior through build(), using an isolated fake OpenSCAD executable."""

import asyncio
import json
import os
import subprocess
import sys

import pytest

from server import openscad


@pytest.fixture
def renderer(tmp_path, monkeypatch):
    """Provide an isolated model tree, cache, and fake OpenSCAD executable."""
    project = tmp_path / "models"
    project.mkdir()
    (project / "model.scad").write_text("cube(1);\n")
    libraries = tmp_path / "libraries"
    libraries.mkdir()
    (libraries / "library.scad").write_text("// library v1\n")
    executable = tmp_path / "openscad"
    executable.write_text(
        f"#!{sys.executable}\n"
        "import os, pathlib, sys, time\n"
        "root = pathlib.Path(__file__).parent\n"
        "if '--info' in sys.argv:\n"
        "    print('OpenSCAD Version: test-1')\n"
        "    print('OpenSCAD library path:')\n"
        "    print('  ' + str(root / 'libraries'))\n"
        "    print()\n"
        "else:\n"
        "    with (root / 'calls').open('a') as calls:\n"
        "        calls.write('render\\n')\n"
        "    if (root / 'delay').exists():\n"
        "        time.sleep(float((root / 'delay').read_text()))\n"
        "    if (root / 'fail').exists():\n"
        "        print('ERROR: test failure', file=sys.stderr)\n"
        "        sys.exit(1)\n"
        "    print('solid test')\n"
        "    print(pathlib.Path(sys.argv[3]).read_text())\n"
        "    print((root / 'libraries' / 'library.scad').read_text())\n"
        "    print(' '.join(sys.argv[4:]))\n"
        "    print('endsolid test')\n"
    )
    executable.chmod(0o700)
    monkeypatch.setenv("PATH", str(tmp_path) + os.pathsep + os.environ["PATH"])
    monkeypatch.setenv("GOEWS_CACHE_DIR", str(tmp_path / "cache"))
    monkeypatch.setenv("GOEWS_CACHE_MAX_BYTES", "1048576")
    monkeypatch.delenv("GOEWS_GENERATOR_REVISION", raising=False)
    monkeypatch.setattr(openscad, "top_dir", project)
    return tmp_path


def render_in_process(root, **params):
    """Build a model in a fresh worker process."""
    script = (
        "import asyncio, json, sys; from pathlib import Path; "
        "from server import openscad; openscad.top_dir = Path(sys.argv[1]); "
        "sys.stdout.buffer.write(asyncio.run(openscad.build('model.scad', "
        "**json.loads(sys.argv[2]))))"
    )
    return subprocess.run(
        [sys.executable, "-c", script, str(root / "models"), json.dumps(params)],
        check=True, capture_output=True, timeout=20,
    ).stdout


def render_count(root):
    """Return the number of renders recorded by the fake executable."""
    path = root / "calls"
    return len(path.read_text().splitlines()) if path.exists() else 0


class TestModelCache:
    """Tests for model caching through build and the API."""

    def test_reuses_stl_after_process_restart(self, renderer):
        """Test that a fresh process reuses the stored STL."""
        first = render_in_process(renderer, width=4)
        second = render_in_process(renderer, width=4)
        assert first == second
        assert render_count(renderer) == 1

    def test_parameter_order_does_not_change_identity(self, renderer):
        """Test that parameter order does not change the cache key."""
        async def requests():
            first = await openscad.build("model.scad", width=4, enabled=True)
            second = await openscad.build("model.scad", enabled=True, width=4)
            assert first == second

        asyncio.run(requests())
        assert render_count(renderer) == 1

    @pytest.mark.parametrize("changed", ["model", "shared", "library", "renderer", "revision"])
    def test_generation_changes_invalidate_cached_stl(self, renderer, monkeypatch, changed):
        """Test that changed generation inputs invalidate stored models."""
        async def requests():
            await openscad.build("model.scad", width=4)
            if changed == "model":
                (renderer / "models" / "model.scad").write_text("cube(2);\n")
            elif changed == "shared":
                (renderer / "models" / "constants.scad").write_text("size = 2;\n")
            elif changed == "library":
                (renderer / "libraries" / "library.scad").write_text("// library v2\n")
            elif changed == "renderer":
                executable = renderer / "openscad"
                executable.write_text(executable.read_text().replace("test-1", "test-2"))
            else:
                monkeypatch.setenv("GOEWS_GENERATOR_REVISION", "revision-2")
            await openscad.build("model.scad", width=4)

        asyncio.run(requests())
        assert render_count(renderer) == 2

    def test_effective_numeric_defaults_and_none_share_an_artifact(self, renderer):
        """Test that equivalent numeric values and omitted parameters share an artifact."""
        async def requests():
            assert await openscad.build("model.scad", width=4) == await openscad.build(
                "model.scad", width=4.0, unused=None
            )

        asyncio.run(requests())
        assert render_count(renderer) == 1

    def test_boolean_number_and_string_are_different_settings(self, renderer):
        """Test that booleans, numbers, and strings have distinct cache keys."""
        async def requests():
            for value in (True, 1, "1"):
                await openscad.build("model.scad", value=value)

        asyncio.run(requests())
        assert render_count(renderer) == 3

    def test_simultaneous_requests_render_once(self, renderer):
        """Test that concurrent requests share one render."""
        (renderer / "delay").write_text("0.2")

        async def requests():
            results = await asyncio.gather(*(
                openscad.build("model.scad", width=4) for _ in range(8)
            ))
            assert len(set(results)) == 1

        asyncio.run(requests())
        assert render_count(renderer) == 1

    def test_separate_workers_share_one_render(self, renderer):
        """Test that separate worker processes share one render."""
        (renderer / "delay").write_text("0.3")

        async def requests():
            return await asyncio.gather(*(
                asyncio.to_thread(render_in_process, renderer, width=4) for _ in range(3)
            ))

        assert len(set(asyncio.run(requests()))) == 1
        assert render_count(renderer) == 1

    def test_failed_render_is_not_cached(self, renderer):
        """Test that a failed render is retried rather than cached."""
        (renderer / "fail").touch()
        with pytest.raises(openscad.OpenSCADError, match="ERROR: test failure"):
            asyncio.run(openscad.build("model.scad", width=4))
        (renderer / "fail").unlink()
        asyncio.run(openscad.build("model.scad", width=4))
        assert render_count(renderer) == 2

    def test_cache_io_failure_does_not_prevent_generation(self, renderer, monkeypatch):
        """Test that an unavailable cache does not prevent rendering."""
        blocked = renderer / "not-a-directory"
        blocked.write_text("keep me")
        monkeypatch.setenv("GOEWS_CACHE_DIR", str(blocked))
        result = asyncio.run(openscad.build("model.scad", width=4))
        assert result.startswith(b"solid test")
        assert blocked.read_text() == "keep me"

    def test_zero_budget_disables_disk_storage(self, renderer, monkeypatch):
        """Test that a zero budget disables disk caching."""
        monkeypatch.setenv("GOEWS_CACHE_MAX_BYTES", "0")
        render_in_process(renderer, width=4)
        render_in_process(renderer, width=4)
        assert render_count(renderer) == 2
        assert not list((renderer / "cache").rglob("*.stl"))

    def test_oversized_result_is_returned_but_not_stored(self, renderer, monkeypatch):
        """Test that models exceeding the budget are returned without being stored."""
        monkeypatch.setenv("GOEWS_CACHE_MAX_BYTES", "1")
        first = render_in_process(renderer, width=4)
        assert len(first) > 1
        assert render_in_process(renderer, width=4) == first
        assert render_count(renderer) == 2
        assert not list((renderer / "cache").rglob("*.stl"))

    def test_budget_evicts_least_recently_used_artifact(self, renderer, monkeypatch):
        """Test that eviction preserves the most recently used artifacts."""
        first = render_in_process(renderer, width=1)
        monkeypatch.setenv("GOEWS_CACHE_MAX_BYTES", str(2 * len(first)))
        render_in_process(renderer, width=2)
        render_in_process(renderer, width=1)  # Touch the first entry.
        render_in_process(renderer, width=3)  # Evict width=2, not width=1.
        render_in_process(renderer, width=1)
        assert render_count(renderer) == 3
        render_in_process(renderer, width=2)
        assert render_count(renderer) == 4
        assert sum(p.stat().st_size for p in (renderer / "cache").rglob("*.stl")) <= 2 * len(first)

    def test_cancelled_waiter_does_not_cancel_shared_render(self, renderer):
        """Test that cancelling one caller does not cancel another caller's render."""
        (renderer / "delay").write_text("0.2")

        async def requests():
            first = asyncio.create_task(openscad.build("model.scad", width=4))
            second = asyncio.create_task(openscad.build("model.scad", width=4))
            async with asyncio.timeout(5):
                while render_count(renderer) == 0:
                    await asyncio.sleep(0.01)
            first.cancel()
            with pytest.raises(asyncio.CancelledError):
                await first
            assert (await second).startswith(b"solid test")

        asyncio.run(requests())
        assert render_count(renderer) == 1

    def test_inputs_changed_mid_render_are_not_published(self, renderer):
        """Test that a render is not cached if its inputs change while it runs."""
        (renderer / "delay").write_text("0.2")

        async def requests():
            task = asyncio.create_task(openscad.build("model.scad", width=4))
            async with asyncio.timeout(5):
                while render_count(renderer) == 0:
                    await asyncio.sleep(0.01)
            (renderer / "models" / "model.scad").write_text("cube(2);\n")
            await task
            assert not list((renderer / "cache").rglob("*.stl"))
            await openscad.build("model.scad", width=4)

        asyncio.run(requests())
        assert render_count(renderer) == 2

    def test_changed_source_with_preserved_mtime_invalidates(self, renderer):
        """Test that a source edit invalidates the cache even when mtime is preserved."""
        async def requests():
            path = renderer / "models" / "model.scad"
            await openscad.build("model.scad", width=4)
            previous = path.stat()
            path.write_text("cube(2);\n")
            os.utime(path, ns=(previous.st_atime_ns, previous.st_mtime_ns))
            await openscad.build("model.scad", width=4)

        asyncio.run(requests())
        assert render_count(renderer) == 2

    def test_cache_write_failure_returns_render_and_leaves_no_partial_artifact(self, renderer, monkeypatch):
        """Test that a failed cache write returns the model without leaving partial files."""
        def disk_full(*args):
            raise OSError("disk full")

        monkeypatch.setattr(os, "replace", disk_full)
        result = asyncio.run(openscad.build("model.scad", width=4))
        assert result.startswith(b"solid test")
        assert not list((renderer / "cache").rglob("*.stl"))
        assert not list((renderer / "cache").rglob(".write-*"))

    def test_unavailable_fingerprint_bypasses_cache(self, renderer):
        """Test that unknown generation inputs bypass disk caching."""
        executable = renderer / "openscad"
        executable.write_text(executable.read_text().replace("OpenSCAD library path:", "unknown format:"))
        render_in_process(renderer, width=4)
        render_in_process(renderer, width=4)
        assert render_count(renderer) == 2
        assert not list((renderer / "cache").rglob("*.stl"))

    def test_lowered_budget_prunes_existing_entries_on_read(self, renderer, monkeypatch):
        """Test that reading the cache enforces a reduced storage budget."""
        render_in_process(renderer, width=4)
        monkeypatch.setenv("GOEWS_CACHE_MAX_BYTES", "1")
        render_in_process(renderer, width=4)
        assert not list((renderer / "cache").rglob("*.stl"))
        assert render_count(renderer) == 2

    def test_symlinked_artifact_is_not_read_or_deleted(self, renderer):
        """Test that an artifact symlink is neither followed nor deleted."""
        render_in_process(renderer, width=4)
        artifact, = (renderer / "cache").rglob("*.stl")
        outside = renderer / "unrelated.stl"
        outside.write_bytes(b"not a cached model")
        artifact.unlink()
        artifact.symlink_to(outside)
        assert render_in_process(renderer, width=4) != outside.read_bytes()
        assert outside.read_bytes() == b"not a cached model"
        assert artifact.is_symlink()
        assert render_count(renderer) == 2

    def test_symlinked_namespace_is_not_used(self, renderer):
        """Test that a symlink cannot replace the private cache directory."""
        cache = renderer / "cache"
        cache.mkdir()
        outside = renderer / "unrelated"
        outside.mkdir(mode=0o700)
        (cache / "artifacts-v1").symlink_to(outside, target_is_directory=True)
        assert render_in_process(renderer, width=4).startswith(b"solid test")
        assert list(outside.iterdir()) == []

    def test_cleanup_preserves_unrelated_files(self, renderer):
        """Test that cleanup removes interrupted writes but preserves unrelated files."""
        render_in_process(renderer, width=4)
        artifact, = (renderer / "cache").rglob("*.stl")
        unrelated = artifact.parent / "user-model.stl"
        unrelated.write_bytes(b"keep me")
        orphan = artifact.parent / ".write-orphan"
        orphan.write_bytes(b"partial output")
        render_in_process(renderer, width=4)
        assert unrelated.read_bytes() == b"keep me"
        assert not orphan.exists()

    def test_observability_reports_hit_miss_render_and_storage(self, renderer, caplog):
        """Test that logs report cache usage and retained bytes."""
        caplog.set_level("INFO", logger="openscad")

        async def requests():
            await openscad.build("model.scad", width=4)
            # Leave the in-flight-only cache before the second request.
            await asyncio.sleep(0)
            await openscad.build("model.scad", width=4)

        asyncio.run(requests())
        assert "model_cache miss" in caplog.text
        assert "model_cache hit" in caplog.text
        assert "model_cache render" in caplog.text
        assert "storage_bytes=" in caplog.text

    def test_tile_stack_preview_and_bundle_reuse_artifacts(self, renderer):
        """Test that tile-stack previews and bundle downloads share cached models."""
        import io
        import zipfile
        from sanic import Sanic
        from server.parts.tile_stack import tile_stack, tile_stack_bundle

        # Do not start the production singleton: its ASGI lifecycle would leak into
        # the synchronous OpenAPI tests that run later in the same interpreter.
        app = Sanic("model-cache-test")
        app.post("/api/tile-stack")(tile_stack)
        app.post("/api/tile-stack-bundle")(tile_stack_bundle)
        (renderer / "models" / "tile_stack.scad").write_text("cube(1);\n")

        async def requests():
            previews = []
            for part in ("pla", "petg"):
                _, response = await app.asgi_client.post("/api/tile-stack", json={"part": part})
                assert response.status_code == 200
                previews.append(response.content)
            _, bundle = await app.asgi_client.post("/api/tile-stack-bundle", json={"part": "all"})
            assert bundle.status_code == 200
            with zipfile.ZipFile(io.BytesIO(bundle.content)) as archive:
                assert archive.namelist() == [
                    "tile-stack-hex-4x4-3high-original.stl",
                    "tile-stack-hex-4x4-3high-original-spacers.stl",
                ]
                assert [archive.read(name) for name in archive.namelist()] == previews

        asyncio.run(requests())
        assert render_count(renderer) == 2
