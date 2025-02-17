from dataclasses import dataclass
from sanic import Sanic, response
from sanic.exceptions import BadRequest
from sanic.request import Request
from sanic_ext import openapi

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


@dataclass
class HookDefinition:
    width: float
    shank_length: float
    shank_thickness: float
    post_height: float
    post_thickness: float
    rounding: float
    variant: Variant


@app.post("/api/hook")
@openapi.body(HookDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS hook")
async def hook(request: Request):
    params = request.json

    width = params.get("width", 1)
    shank_length = params.get("shank_length", 1)
    shank_thickness = params.get("shank_thickness", 1)
    post_height = params.get("post_height", 1)
    post_thickness = params.get("post_thickness", 1)
    rounding = params.get("rounding", 1)
    try:
        variant = Variant(params.get("variant", 0))
    except ValueError:
        raise BadRequest("Invalid variant")

    return response.raw(
        build(
            part=Part.Hook,
            variant=variant,
            hook_width=width,
            hook_shank_length=shank_length,
            hook_shank_thickness=shank_thickness,
            hook_post_height=post_height,
            hook_post_thickness=post_thickness,
            hook_rounding=rounding,
        ),
        content_type="model/stl",
    )
