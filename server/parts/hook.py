from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class HookDefinition(BaseModel):
    hooks: Annotated[int, Field(gt=0, description="Number of hooks")] = 1
    width: Annotated[float, Field(gt=0, description="Width of the hook in mm")] = 10
    gap: Annotated[float, Field(gt=0, description="Gap between hooks")] = 10
    shank_length: Annotated[float, Field(gt=0, description="Length of the shank in mm")] = 10
    shank_thickness: Annotated[float, Field(gt=0, description="Thickness of the shank in mm")] = 8
    post_height: Annotated[float, Field(description="Height of the post in mm")] = 18
    post_thickness: Annotated[float, Field(description="Thickness of the post in mm")] = 6
    lip_thickness: Annotated[float, Field(description="Radius of lip at top of post")] = 0
    rounding: Annotated[float, Field(description="Rounding of outer corners in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_hook_filename(body: HookDefinition) -> str:
    parts = ["hook", f"{int(body.width)}x{int(body.shank_length)}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")
    
    options = []
    for name, info in type(body).model_fields.items():
        if name in ("width", "shank_length", "variant"):
            continue
        val = getattr(body, name)
        if val != info.default:
            if isinstance(val, bool):
                options.append(name)
            else:
                options.append(f"{name}_{val}")
    
    if options:
        parts.append("_".join(options))
    
    return "-".join(parts) + ".stl"


@api_bp.post("/hook")
@openapi.body(HookDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS hook")
@validate(json=HookDefinition)
async def hook(request: Request, body: HookDefinition):
    filename = make_hook_filename(body)
    return response.raw(
        await build(
            "hook.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            hooks=body.hooks,
            width=body.width,
            gap=body.gap,
            shank_length=body.shank_length,
            shank_thickness=body.shank_thickness,
            post_height=body.post_height,
            post_thickness=body.post_thickness,
            lip_thickness=body.lip_thickness,
            rounding=body.rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
