from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class RackDefinition(BaseModel):
    slots: Annotated[int, Field(gt=0)]
    slot_width: Annotated[float, Field(gt=0)]
    divider_width: Annotated[float, Field(gt=0)]
    divider_length: Annotated[float, Field(gt=0)]
    divider_thickness: Annotated[float, Field(gt=0)]
    lip: bool
    lip_height: float
    lip_thickness: float
    rounding: float
    variant: Variant


@app.post("/api/rack")
@validate(json=RackDefinition)
@openapi.body(RackDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS rack")
async def rack(request: Request, body: RackDefinition):
    return response.raw(
        await build(
            part=Part.Rack,
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
