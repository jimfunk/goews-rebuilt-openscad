from enum import IntEnum
from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()

class CableClipOrientation(IntEnum):
    Vertical = 1
    HorizontalLeft = 2
    HorizontalRight = 3


class CableclipDefinition(BaseModel):
    orientation: CableClipOrientation = CableClipOrientation.Vertical
    clips: Annotated[int, Field(gt=0)] = 1
    cable_diameter: Annotated[float, Field(gt=0)] = 5
    width: Annotated[float, Field(gt=0)] = 6
    height: Annotated[float, Field(gt=0)] = 8
    thickness: Annotated[float, Field(gt=0)] = 3
    gap: Annotated[float, Field(gt=0)] = 10
    lip_thickness: float = 2
    rounding: float = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/cableclip")
@validate(json=CableclipDefinition)
@openapi.body(CableclipDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS cableclip")
async def cableclip(request: Request, body: CableclipDefinition):
    return response.raw(
        await build(
            part=Part.CableClip,
            cable_clip_orientation=body.orientation,
            cable_clip_clips=body.clips,
            cable_clip_cable_diameter=body.cable_diameter,
            cable_clip_width=body.width,
            cable_clip_height=body.height,
            cable_clip_thickness=body.thickness,
            cable_clip_gap=body.gap,
            cable_clip_lip_thickness=body.lip_thickness,
            cable_clip_rounding=body.rounding,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
        ),
        content_type="model/stl",
    )
