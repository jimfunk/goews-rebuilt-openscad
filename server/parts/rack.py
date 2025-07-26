from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class RackDefinition(BaseModel):
    slots: Annotated[int, Field(gt=0)] = 7
    slot_width: Annotated[float, Field(gt=0)] = 6
    divider_width: Annotated[float, Field(gt=0)] = 10
    divider_length: Annotated[float, Field(gt=0)] = 80
    divider_thickness: Annotated[float, Field(gt=0)] = 6
    lip: bool = False
    lip_height: float = 8
    lip_thickness: float = 4
    rounding: float = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/rack")
@validate(json=RackDefinition)
@openapi.body(RackDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS rack")
async def rack(request: Request, body: RackDefinition):
    return response.raw(
        await build(
            part=Part.Rack,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            rack_slots=body.slots,
            rack_slot_width=body.slot_width,
            rack_divider_width=body.divider_width,
            rack_divider_length=body.divider_length,
            rack_divider_thickness=body.divider_thickness,
            rack_lip=body.lip,
            rack_lip_height=body.lip_height,
            rack_lip_thickness=body.lip_thickness,
            rack_slot_rounding=body.rounding,
        ),
        content_type="model/stl",
    )
