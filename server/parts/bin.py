from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class BinDefinition(BaseModel):
    width: Annotated[float, Field(gt=0, description="Outer width in mm")] = 41.5
    depth: Annotated[float, Field(gt=0, description="Outer depth in mm")] = 41.5
    height: Annotated[float, Field(gt=0, description="Height in mm")] = 20
    wall_thickness: Annotated[float, Field(gt=0, description="Wall thickness in mm")] = 1
    bottom_thickness: Annotated[float, Field(gt=0, description="Bottom thickness in mm")] = 2
    lip_thickness: Annotated[float, Field(ge=0, description="Lip thickness in mm")] = 1
    inner_rounding: Annotated[float, Field(ge=0, description="Rounding of the inner edges in mm")] = 1
    outer_rounding: Annotated[float, Field(ge=0, description="Rounding of the outer edges in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_bin_filename(body: BinDefinition) -> str:
    """Generate filename for GOEWS bins."""
    parts = ["bin", f"{body.width}x{body.depth}x{body.height}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("width", "depth", "height", "variant"):
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


@api_bp.post("/bin")
@openapi.body(BinDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS bin")
@validate(json=BinDefinition)
async def bin(request: Request, body: BinDefinition):
    filename = make_bin_filename(body)
    return response.raw(
        await build(
            "bin.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            width=body.width,
            depth=body.depth,
            height=body.height,
            wall_thickness=body.wall_thickness,
            bottom_thickness=body.bottom_thickness,
            lip_thickness=body.lip_thickness,
            inner_rounding=body.inner_rounding,
            outer_rounding=body.outer_rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
