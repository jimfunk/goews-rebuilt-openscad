from enum import StrEnum
from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class CableClipOrientation(StrEnum):
    VERTICAL = "Vertical"
    HORIZONTAL_LEFT = "Horizontal Left"
    HORIZONTAL_RIGHT = "Horizontal Right"

    def to_int(self) -> int:
        mapping = {self.VERTICAL: 1, self.HORIZONTAL_LEFT: 2, self.HORIZONTAL_RIGHT: 3}
        return mapping[self]


@openapi.component
class CableclipDefinition(BaseModel):
    orientation: Annotated[CableClipOrientation, Field(description="Clip orientation")] = CableClipOrientation.VERTICAL
    clips: Annotated[int, Field(gt=0, description="Number of clips to generate")] = 1
    cable_diameter: Annotated[float, Field(gt=0, description="Diameter of the cable in mm")] = 5
    width: Annotated[float, Field(gt=0, description="Width of clip in mm")] = 6
    height: Annotated[float, Field(gt=0, description="Height of the clip in mm")] = 8
    thickness: Annotated[float, Field(gt=0, description="Thickness of the clip in mm")] = 3
    gap: Annotated[float, Field(gt=0, description="Gap between clips in mm")] = 10
    lip_thickness: Annotated[float, Field(description="Thickness of the lip in mm")] = 2
    rounding: Annotated[float, Field(description="Rounding of the clip in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_cableclip_filename(body: CableclipDefinition) -> str:
    parts = ["cableclip", f"{int(body.cable_diameter)}mm"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")
    
    options = []
    for name, info in type(body).model_fields.items():
        if name in ("cable_diameter", "variant"):
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


@api_bp.post("/cableclip")
@openapi.body(CableclipDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS cableclip")
@validate(json=CableclipDefinition)
async def cableclip(request: Request, body: CableclipDefinition):
    filename = make_cableclip_filename(body)
    return response.raw(
        await build(
            "cableclip.scad",
            orientation=body.orientation.to_int(),
            clips=body.clips,
            cable_diameter=body.cable_diameter,
            width=body.width,
            height=body.height,
            thickness=body.thickness,
            gap=body.gap,
            lip_thickness=body.lip_thickness,
            rounding=body.rounding,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
