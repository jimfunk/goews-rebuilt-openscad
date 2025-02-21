from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class HookDefinition(BaseModel):
    hooks: Annotated[int, Field(gt=0)]
    width: Annotated[float, Field(gt=0)]
    gap: Annotated[float, Field(gt=0)]
    shank_length: Annotated[float, Field(gt=0)]
    shank_thickness: Annotated[float, Field(gt=0)]
    post_height: float
    post_thickness: float
    rounding: float
    variant: Variant


@app.post("/api/hook")
@validate(json=HookDefinition)
@openapi.body(HookDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS hook")
async def hook(request: Request, body: HookDefinition):
    return response.raw(
        await build(
            part=Part.Hook,
            variant=body.variant,
            hooks=body.hooks,
            hook_width=body.width,
            hook_gap=body.gap,
            hook_shank_length=body.shank_length,
            hook_shank_thickness=body.shank_thickness,
            hook_post_height=body.post_height,
            hook_post_thickness=body.post_thickness,
            hook_rounding=body.rounding,
        ),
        content_type="model/stl",
    )
