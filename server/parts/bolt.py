from enum import StrEnum
from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.api import api_bp


@openapi.component
class HeadType(StrEnum):
    ORIGINAL = "Original"
    ROUND = "Round"

    def to_int(self) -> int:
        return 0 if self == self.ORIGINAL else 1


@openapi.component
class HeadRecessType(StrEnum):
    HEX = "Hex"
    SLOT = "Slot"
    PHILIPS2 = "Philips 2"
    PHILIPS3 = "Philips 3"

    def to_int(self) -> int:
        mapping = {self.HEX: 0, self.SLOT: 1, self.PHILIPS2: 2, self.PHILIPS3: 3}
        return mapping[self]


@openapi.component
class BoltDefinition(BaseModel):
    length: Annotated[float, Field(gt=0, description="Length of threaded part in mm")] = 9
    head_type: HeadType = HeadType.ORIGINAL
    head_recess_type: HeadRecessType = HeadRecessType.HEX
    head_recess_depth: Annotated[float, Field(ge=0, description="Depth of head recess in mm")] = 0
    hex_socket_width: Annotated[float, Field(gt=0, description="Width of hex socket in mm")] = 8.4
    slot_recess_width: Annotated[float, Field(gt=0, description="Width of slot recess in mm")] = 2
    slot_recess_length: Annotated[float, Field(gt=0, description="Length of slot recess in mm")] = 10


def make_bolt_filename(body: BoltDefinition) -> str:
    parts = ["bolt", str(int(body.length))]
    
    options = []
    for name, info in type(body).model_fields.items():
        if name == "length":
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


@api_bp.post("/bolt")
@openapi.body(BoltDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a standard GOEWS bolt")
@validate(json=BoltDefinition)
async def bolt(request: Request, body: BoltDefinition):
    filename = make_bolt_filename(body)
    return response.raw(
        await build(
            "bolt.scad",
            length=body.length,
            head_type=body.head_type.to_int(),
            head_recess_type=body.head_recess_type.to_int(),
            head_recess_depth=body.head_recess_depth,
            hex_socket_width=body.hex_socket_width,
            slot_recess_width=body.slot_recess_width,
            slot_recess_length=body.slot_recess_length,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
