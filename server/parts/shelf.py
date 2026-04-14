from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class ShelfDefinition(BaseModel):
    width: Annotated[float, Field(gt=0, description="Width of shelf in mm")] = 83.5
    depth: Annotated[float, Field(gt=0, description="Depth of shelf in mm")] = 30
    thickness: Annotated[float, Field(gt=0, description="Thickness of shelf in mm")] = 4
    rear_fillet_radius: Annotated[float, Field(ge=0, description="Rear fillet radius in mm")] = 1
    rounding: Annotated[float, Field(ge=0, description="Rounding of the front edges in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_shelf_filename(body: ShelfDefinition) -> str:
    parts = ["shelf", f"{body.width}x{body.depth}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("width", "depth", "variant"):
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


@api_bp.post("/shelf")
@openapi.body(ShelfDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS shelf")
@validate(json=ShelfDefinition)
async def shelf(request: Request, body: ShelfDefinition):
    filename = make_shelf_filename(body)
    return response.raw(
        await build(
            "shelf.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            width=body.width,
            depth=body.depth,
            thickness=body.thickness,
            rear_fillet_radius=body.rear_fillet_radius,
            rounding=body.rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@openapi.component
class HoleShelfDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0, description="Number of columns in the shelf")] = 3
    rows: Annotated[int, Field(gt=0, description="Number of rows in the shelf")] = 1
    thickness: Annotated[float, Field(gt=0, description="Thickness of shelf in mm")] = 4
    hole_radius: Annotated[float, Field(gt=0, description="Radius of hole in mm")] = 3.5
    column_gap: Annotated[float, Field(gt=0, description="Gap between holes in a column in mm")] = 15
    row_gap: Annotated[float, Field(gt=0, description="Gap between holes in a row in mm")] = 15
    front_gap: Annotated[float, Field(gt=0, description="Gap between front of shelf and holes in mm")] = 15
    rear_gap: Annotated[float, Field(gt=0, description="Gap between back of shelf and holes in mm")] = 15
    side_gap: Annotated[float, Field(gt=0, description="Gap between side of shelf and holes in mm")] = 15
    stagger: Annotated[bool, Field(description="Stagger the rows")] = False
    rear_fillet_radius: Annotated[float, Field(ge=0, description="Rear fillet radius in mm")] = 1
    rounding: Annotated[float, Field(ge=0, description="Rounding of the front edges in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_hole_shelf_filename(body: HoleShelfDefinition) -> str:
    parts = ["hole-shelf", f"{body.rows}x{body.columns}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("rows", "columns", "variant"):
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


@api_bp.post("/hole_shelf")
@openapi.body(HoleShelfDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS shelf with holes")
@validate(json=HoleShelfDefinition)
async def hole_shelf(request: Request, body: HoleShelfDefinition):
    filename = make_hole_shelf_filename(body)
    return response.raw(
        await build(
            "hole_shelf.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            columns=body.columns,
            rows=body.rows,
            thickness=body.thickness,
            hole_radius=body.hole_radius,
            column_gap=body.column_gap,
            row_gap=body.row_gap,
            front_gap=body.front_gap,
            rear_gap=body.rear_gap,
            side_gap=body.side_gap,
            stagger=body.stagger,
            rear_fillet_radius=body.rear_fillet_radius,
            rounding=body.rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@openapi.component
class SlotShelfDefinition(BaseModel):
    slots: Annotated[int, Field(gt=0, description="Number of slots in the shelf")] = 4
    thickness: Annotated[float, Field(gt=0, description="Thickness of shelf in mm")] = 4
    slot_length: Annotated[float, Field(gt=0, description="Slot length in mm")] = 40
    slot_width: Annotated[float, Field(gt=0, description="Slot width in mm")] = 10
    slot_rounding: Annotated[float, Field(ge=0, description="Slot corner rounding in mm")] = 1
    gap: Annotated[float, Field(gt=0, description="Gap between slots in mm")] = 10
    front_gap: Annotated[float, Field(gt=0, description="Gap between front of shelf and slots in mm")] = 5
    rear_gap: Annotated[float, Field(gt=0, description="Gap between back of shelf and slots in mm")] = 10
    side_gap: Annotated[float, Field(gt=0, description="Gap between side of shelf and slots in mm")] = 5
    rear_fillet_radius: Annotated[float, Field(ge=0, description="Rear fillet radius in mm")] = 1
    rounding: Annotated[float, Field(ge=0, description="Rounding of the front edges in mm")] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_slot_shelf_filename(body: SlotShelfDefinition) -> str:
    parts = ["slot-shelf", f"{body.slot_width}x{body.slot_length}x{body.slots}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("slot_width", "slot_length", "slots", "variant"):
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


@api_bp.post("/slot_shelf")
@openapi.body(SlotShelfDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS shelf with slots")
@validate(json=SlotShelfDefinition)
async def slot_shelf(request: Request, body: SlotShelfDefinition):
    filename = make_slot_shelf_filename(body)
    return response.raw(
        await build(
            "slot_shelf.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            slots=body.slots,
            thickness=body.thickness,
            slot_length=body.slot_length,
            slot_width=body.slot_width,
            slot_rounding=body.slot_rounding,
            gap=body.gap,
            front_gap=body.front_gap,
            rear_gap=body.rear_gap,
            side_gap=body.side_gap,
            rear_fillet_radius=body.rear_fillet_radius,
            rounding=body.rounding,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
