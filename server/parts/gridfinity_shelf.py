from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated, Literal

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class GridfinityShelfDefinition(BaseModel):
    gridx: Annotated[int, Field(ge=1, description="Number of grid units in the X direction")] = 2
    gridy: Annotated[int, Field(ge=1, description="Number of grid units in the Y direction")] = 1
    rear_offset: Annotated[float, Field(gt=0, description="Distance between plate and base in mm")] = 4.5
    max_rear_offset_fillet: Annotated[float, Field(ge=0, description="Maximum radius of the fillet between plate and base in mm")] = 10
    plate_thickness: Annotated[float, Field(gt=0, description="Thickness of rear plate")] = 3
    base_thickness: Annotated[float, Field(ge=0, description="Additional base thickness in mm. This improves rigidity but can be 0 to implement a thin baseplate")] = 0
    skeletonized: Annotated[bool, Field(description="When the base thickness is > 0 this will remove unnecessary material from the base")] = True
    sides: Annotated[bool, Field(description="Adds sides to the shelf. This can greatly improve rigidity")] = False
    side_thickness: Annotated[float, Field(gt=0, description="Thickness of sides")] = 2
    side_height: Annotated[float, Field(gt=0, description="Height of sides")] = 20
    front: Annotated[bool, Field(description="Adds a front to the shelf. This can improve rigidity")] = False
    front_thickness: Annotated[float, Field(gt=0, description="Thickness of front")] = 2
    front_height: Annotated[float, Field(gt=0, description="Height of front")] = 20
    magnet_holes: Annotated[bool, Field(description="Add magnet holes. Will be ignored if base thickness is < 4")] = False
    magnet_hole_crush_ribs: Annotated[bool, Field(description="Add crush ribs to the magnet holes")] = False
    magnet_hole_chamfer: Annotated[bool, Field(description="Add a chamfer to the magnet holes")] = False
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_gridfinity_shelf_filename(body: GridfinityShelfDefinition) -> str:
    parts = ["gridfinity-shelf", f"{body.gridx}x{body.gridy}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("gridx", "gridy", "variant"):
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


@api_bp.post("/gridfinity_shelf")
@openapi.body(GridfinityShelfDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS Gridfinity shelf")
@validate(json=GridfinityShelfDefinition)
async def gridfinity_shelf(request: Request, body: GridfinityShelfDefinition):
    filename = make_gridfinity_shelf_filename(body)
    return response.raw(
        await build(
            "gridfinity_shelf.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            gridx=body.gridx,
            gridy=body.gridy,
            rear_offset=body.rear_offset,
            max_rear_offset_fillet=body.max_rear_offset_fillet,
            plate_thickness=body.plate_thickness,
            base_thickness=body.base_thickness,
            skeletonized=body.skeletonized,
            sides=body.sides,
            side_thickness=body.side_thickness,
            side_height=body.side_height,
            front=body.front,
            front_thickness=body.front_thickness,
            front_height=body.front_height,
            magnet_holes=body.magnet_holes,
            magnet_hole_crush_ribs=body.magnet_hole_crush_ribs,
            magnet_hole_chamfer=body.magnet_hole_chamfer,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
