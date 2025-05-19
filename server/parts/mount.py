from enum import IntEnum
from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class MountHoleType(IntEnum):
    Round = 1
    Hex = 2
    Square = 3
    SocketHead = 4
    ButtonHead = 5
    CountersinkHead = 6


class MountHole(BaseModel):
    hole_type: MountHoleType
    x_offset: Annotated[float, Field(gt=0)]
    y_offset: Annotated[float, Field(gt=0)]
    diameter: Annotated[float, Field(gt=0)]
    depth: Annotated[float, Field(gt=0)]

    def as_list(self):
        return [
            int(self.hole_type),
            self.x_offset,
            self.y_offset,
            self.diameter,
            self.depth,
        ]


class MountDefinition(BaseModel):
    holes: list[MountHole]
    plate_thickness: Annotated[float, Field(gt=0)] = 3
    minimum_width: Annotated[float, Field(gte=0)] = 0
    minimum_height: Annotated[float, Field(gte=0)] = 0
    bolt_notch: bool = True
    hanger_tolerance: Annotated[float, Field(gt=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/mount")
@validate(json=MountDefinition)
@openapi.body(MountDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS mount")
async def mount(request: Request, body: MountDefinition):
    return response.raw(
        await build(
            part=Part.HangerMount,
            hanger_mount_holes=str([hole.as_list() for hole in body.holes]),
            hanger_mount_plate_thickness=body.plate_thickness,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            hanger_mount_minimum_width= body.minimum_width,
            hanger_mount_minimum_height=body.minimum_height,
            hanger_mount_bolt_notch=body.bolt_notch,
        ),
        content_type="model/stl",
    )
