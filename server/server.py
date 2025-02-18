"""
Web-based GOEWS model generator
"""

from pathlib import Path
from sanic import Sanic, response
from sanic_ext import openapi


top_dir = (Path(__file__) / "../..").resolve()
frontend_dir = top_dir / "frontend/dist"
assets_dir = frontend_dir / "assets"


app = Sanic("GOEWS")


app.static("/assets/", assets_dir)


@app.route("/")
@openapi.summary("Main application")
@openapi.description("This is the main page that returns the frontend application.")
async def main(request):
    return await response.file(frontend_dir / "index.html")


# Get the API calls loaded
import server.tile
import server.hook
import server.bolt


if __name__ == "__main__":
    app.run(host="::1", port=8000)
