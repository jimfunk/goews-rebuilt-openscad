"""
Web-based GOEWS model generator
"""

from pathlib import Path

from sanic import Sanic, response
from sanic_ext import Extend, openapi

from server.api import api_bp

top_dir = (Path(__file__) / "../..").resolve()
frontend_dir = top_dir / "frontend/dist"
assets_dir = frontend_dir / "assets"


app = Sanic("GOEWS")
Extend(app)

app.config.OPENAPI_URI = "/docs/openapi.json"
app.config.OPENAPI_INFO_TITLE = "GOEWS Builder API"
app.config.OPENAPI_INFO_VERSION = "1.0.0"
app.config.OPENAPI_INFO_DESCRIPTION = "Parametric GOEWS part generator"


app.static("/assets/", assets_dir, name="assets")
app.static("/favicon.svg", frontend_dir / "favicon.svg", name="favicon")


@app.route("/")
@openapi.summary("Main application")
@openapi.description("This is the main page that returns the frontend application.")
async def main(request):
    return await response.file(frontend_dir / "index.html")


# Get the API calls loaded
import server.parts.bin
import server.parts.bolt
import server.parts.cableclip
import server.parts.cup
import server.parts.gridfinity_bin
import server.parts.gridfinity_shelf
import server.parts.hook
import server.parts.mount
import server.parts.rack
import server.parts.shelf
import server.parts.tile
import server.parts.tile_stack

# Register the blueprint after routes are added
app.blueprint(api_bp)


if __name__ == "__main__":
    app.run(host="::1", port=8000)
