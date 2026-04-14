from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class CupDefinition(BaseModel):
    inner_diameter: Annotated[float, Field(gt=0, description="Inner diameter in mm")] = 37.5
    height: Annotated[float, Field(gt=0, description="Height in mm")] = 24.39
    wall_thickness: Annotated[float, Field(gt=0, description="Wall thickness in mm")] = 2
    bottom_thickness: Annotated[float, Field(ge=0, description="Bottom thickness in mm")] = 2
    inner_rounding: Annotated[float, Field(ge=0, description="Rounding of the inner edges in mm")] = 0.5
    outer_rounding: Annotated[float, Field(ge=0, description="Rounding of the outer edges in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_cup_filename(body: CupDefinition) -> str:
    parts = ["cup", f"{body.inner_diameter}x{body.height}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")
    
    options = []
    for name, info in type(body).model_fields.items():
        if name in ("inner_diameter", "height", "variant"):
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


@api_bp.post("/cup")
@openapi.body(CupDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS cup")
@validate(json=CupDefinition)
async def cup(request: Request, body: CupDefinition):
    filename = make_cup_filename(body)
    return response.raw(
        await build(
            "cup.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            inner_diameter=body.inner_diameter,
            height=body.height,
            wall_thickness=body.wall_thickness,
            bottom_thickness=body.bottom_thickness,
            inner_rounding=body.inner_rounding,
            outer_rounding=body.outer_rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
