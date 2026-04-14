from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class RackDefinition(BaseModel):
    slots: Annotated[int, Field(gt=0, description="Number of slots")] = 7
    slot_width: Annotated[float, Field(gt=0, description="Width of each slot in mm")] = 6
    divider_width: Annotated[float, Field(gt=0, description="Width of dividers in mm")] = 10
    divider_length: Annotated[float, Field(gt=0, description="Length of the dividers in mm")] = 80
    divider_thickness: Annotated[float, Field(gt=0, description="Thickness of the dividers in mm")] = 6
    lip: Annotated[bool, Field(description="Include lip at front of dividers")] = False
    lip_height: Annotated[float, Field(description="Height of the lip in mm")] = 8
    lip_thickness: Annotated[float, Field(description="Thickness of the lip in mm")] = 4
    rounding: Annotated[float, Field(description="Rounding of outer corners in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_rack_filename(body: RackDefinition) -> str:
    parts = ["rack", f"{body.slots}slot"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")
    
    options = []
    for name, info in type(body).model_fields.items():
        if name in ("slots", "variant"):
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


@api_bp.post("/rack")
@openapi.body(RackDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS rack")
@validate(json=RackDefinition)
async def rack(request: Request, body: RackDefinition):
    filename = make_rack_filename(body)
    return response.raw(
        await build(
            "rack.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            slots=body.slots,
            slot_width=body.slot_width,
            divider_width=body.divider_width,
            divider_length=body.divider_length,
            divider_thickness=body.divider_thickness,
            lip=body.lip,
            lip_height=body.lip_height,
            lip_thickness=body.lip_thickness,
            rounding=body.rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
