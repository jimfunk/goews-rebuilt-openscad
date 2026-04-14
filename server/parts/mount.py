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
class MountHoleType(StrEnum):
    ROUND = "Round"
    HEX = "Hex"
    SQUARE = "Square"
    SOCKET_HEAD = "Socket Head"
    BUTTON_HEAD = "Button Head"
    COUNTERSINK_HEAD = "Countersink Head"

    def to_int(self) -> int:
        mapping = {
            self.ROUND: 1,
            self.HEX: 2,
            self.SQUARE: 3,
            self.SOCKET_HEAD: 4,
            self.BUTTON_HEAD: 5,
            self.COUNTERSINK_HEAD: 6,
        }
        return mapping[self]


@openapi.component
class MountHole(BaseModel):
    hole_type: MountHoleType
    x_offset: Annotated[float, Field(gt=0, description="X offset in mm")]
    y_offset: Annotated[float, Field(gt=0, description="Y offset in mm")]
    diameter: Annotated[float, Field(gt=0, description="Hole diameter in mm")]
    depth: Annotated[float, Field(gt=0, description="Hole depth in mm")]

    def as_list(self):
        return [
            self.hole_type.to_int(),
            self.x_offset,
            self.y_offset,
            self.diameter,
            self.depth,
        ]


@openapi.component
class MountDefinition(BaseModel):
    holes: Annotated[list[MountHole], Field(description="Holes to make in the plate")]
    plate_thickness: Annotated[float, Field(gt=0, description="Thickness of plate in mm")] = 3
    minimum_width: Annotated[float, Field(ge=0, description="Minimum width of plate in mm")] = 0
    minimum_height: Annotated[float, Field(ge=0, description="Minimum height of plate in mm")] = 0
    bolt_notch: Annotated[bool, Field(description="Add bolt notch for thicker plates")] = True
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_mount_filename(body: MountDefinition) -> str:
    parts = ["mount", f"{len(body.holes)}hole"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("holes", "variant"):
            continue
        val = getattr(body, name)
        if val != info.default:
            if isinstance(val, bool):
                if val:
                    options.append(name)
                else:
                    options.append(f"no_{name}")
            else:
                options.append(f"{name}_{val}")

    if options:
        parts.append("_".join(options))

    return "-".join(parts) + ".stl"


@api_bp.post("/mount")
@openapi.body(MountDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS mount")
@validate(json=MountDefinition)
async def mount(request: Request, body: MountDefinition):
    filename = make_mount_filename(body)
    return response.raw(
        await build(
            "hanger_mount.scad",
            hanger_mount_holes=str([hole.as_list() for hole in body.holes]),
            hanger_mount_plate_thickness=body.plate_thickness,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            hanger_mount_minimum_width=body.minimum_width,
            hanger_mount_minimum_height=body.minimum_height,
            hanger_mount_bolt_notch=body.bolt_notch,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
