from enum import IntEnum
from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part


app = Sanic.get_app()


class HeadType(IntEnum):
    Original = 0
    Round = 1


class HeadRecessType(IntEnum):
    Hex = 0
    Slot = 1
    Philips2 = 2
    Philips3 = 3


class BoltDefinition(BaseModel):
    length: Annotated[float, Field(gt=0)] = 9
    head_type: HeadType = HeadType.Original
    head_recess_type: HeadRecessType = HeadRecessType.Hex
    head_recess_depth: Annotated[float, Field(ge=0)] = 0
    hex_socket_width: Annotated[float, Field(gt=0)] = 8.4
    slot_recess_width: Annotated[float, Field(gt=0)] = 2
    slot_recess_length: Annotated[float, Field(gt=0)] = 10


@app.post("/api/bolt")
@validate(json=BoltDefinition)
@openapi.body(BoltDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a standard GOEWS bolt")
async def bolt(request: Request, body: BoltDefinition):
    return response.raw(
        await build(
            part=Part.Bolt,
            bolt_length=body.length,
            bolt_head_type=body.head_type,
            bolt_head_recess_type=body.head_recess_type,
            bolt_head_recess_depth=body.head_recess_depth,
            bolt_hex_socket_width=body.hex_socket_width,
            bolt_slot_recess_width=body.slot_recess_width,
            bolt_slot_recess_length=body.slot_recess_length,
        ),
        content_type="model/stl",
    )
