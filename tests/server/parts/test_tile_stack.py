"""Tile-stack bundle packaging must not depend on the download time."""

import asyncio
import io
import zipfile

from sanic import Sanic

from server.parts import tile_stack


def test_bundle_is_byte_identical_at_different_times(monkeypatch):
    meshes = {"pla": b"solid pla\nendsolid pla\n", "petg": b"solid petg\nendsolid petg\n"}

    async def rendered_stl(model_file, **params):
        assert model_file == "tile_stack.scad"
        return meshes[params["part"]]

    monkeypatch.setattr(tile_stack, "build", rendered_stl)
    app = Sanic("tile-stack-bundle-test")
    app.post("/api/tile-stack-bundle")(tile_stack.tile_stack_bundle)

    async def requests():
        downloads = []
        for year in (2025, 2030):
            monkeypatch.setattr(zipfile.time, "localtime", lambda *args: (year, 6, 1, 12, 0, 0, 0, 1, -1))
            _, response = await app.asgi_client.post("/api/tile-stack-bundle", json={})
            assert response.status_code == 200
            assert response.headers["content-type"] == "application/zip"
            assert response.headers["content-disposition"] == (
                'attachment; filename="tile-stack-hex-4x4-3high-original.zip"'
            )
            downloads.append(response.content)
        return downloads

    first, second = asyncio.run(requests())
    assert first == second
    with zipfile.ZipFile(io.BytesIO(first)) as archive:
        assert archive.namelist() == [
            "tile-stack-hex-4x4-3high-original.stl",
            "tile-stack-hex-4x4-3high-original-spacers.stl",
        ]
        assert [archive.read(name) for name in archive.namelist()] == list(meshes.values())
        for entry in archive.infolist():
            assert entry.date_time == (1980, 1, 1, 0, 0, 0)
            assert entry.compress_type == zipfile.ZIP_DEFLATED
            assert entry.create_system == 3
            assert entry.external_attr >> 16 == 0o100644
