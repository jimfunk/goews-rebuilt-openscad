from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class ShelfDefinition(BaseModel):
    width: Annotated[float, Field(gt=0)] = 83.5
    depth: Annotated[float, Field(gt=0)] = 30
    thickness: Annotated[float, Field(gt=0)] = 4
    rear_fillet_radius: Annotated[float, Field(gte=0)] = 1
    rounding: Annotated[float, Field(gte=0)] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/shelf")
@validate(json=ShelfDefinition)
@openapi.body(ShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf")
async def shelf(request: Request, body: ShelfDefinition):
    return response.raw(
        await build(
            part=Part.Shelf,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            shelf_width=body.width,
            shelf_depth=body.depth,
            shelf_thickness=body.thickness,
            shelf_rear_fillet_radius=body.rear_fillet_radius,
            shelf_rounding=body.rounding,
        ),
        content_type="model/stl",
    )


class HoleShelfDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0)] = 3
    rows: Annotated[int, Field(gt=0)] = 1
    thickness: Annotated[float, Field(gt=0)] = 4
    hole_radius: Annotated[float, Field(gt=0)] = 3.5
    column_gap: Annotated[float, Field(gt=0)] = 15
    row_gap: Annotated[float, Field(gt=0)] = 15
    front_gap: Annotated[float, Field(gt=0)] = 15
    rear_gap: Annotated[float, Field(gt=0)] = 15
    side_gap: Annotated[float, Field(gt=0)] = 15
    stagger: bool = False
    rear_fillet_radius: Annotated[float, Field(gte=0)] = 1
    rounding: Annotated[float, Field(gte=0)] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/hole_shelf")
@validate(json=HoleShelfDefinition)
@openapi.body(HoleShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf with holes")
async def hole_shelf(request: Request, body: HoleShelfDefinition):
    return response.raw(
        await build(
            part=Part.HoleShelf,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            hole_shelf_columns=body.columns,
            hole_shelf_rows=body.rows,
            hole_shelf_thickness=body.thickness,
            hole_shelf_hole_radius=body.hole_radius,
            hole_shelf_column_gap=body.column_gap,
            hole_shelf_row_gap=body.row_gap,
            hole_shelf_front_gap=body.front_gap,
            hole_shelf_rear_gap=body.rear_gap,
            hole_shelf_side_gap=body.side_gap,
            hole_shelf_stagger=body.stagger,
            hole_shelf_rear_fillet_radius=body.rear_fillet_radius,
            hole_shelf_rounding=body.rounding,
        ),
        content_type="model/stl",
    )


class SlotShelfDefinition(BaseModel):
    slots: Annotated[int, Field(gt=0)] = 4
    thickness: Annotated[float, Field(gt=0)] = 4
    slot_length: Annotated[float, Field(gt=0)] = 40
    slot_width: Annotated[float, Field(gt=0)] = 10
    slot_rounding: Annotated[float, Field(gte=0)] = 1
    gap: Annotated[float, Field(gt=0)] = 10
    front_gap: Annotated[float, Field(gt=0)] = 5
    rear_gap: Annotated[float, Field(gt=0)] = 10
    side_gap: Annotated[float, Field(gt=0)] = 5
    rear_fillet_radius: Annotated[float, Field(gte=0)] = 1
    rounding: Annotated[float, Field(gte=0)] = 0.5
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/slot_shelf")
@validate(json=SlotShelfDefinition)
@openapi.body(SlotShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf with slots")
async def slot_shelf(request: Request, body: SlotShelfDefinition):
    return response.raw(
        await build(
            part=Part.SlotShelf,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            slot_shelf_slots=body.slots,
            slot_shelf_thickness=body.thickness,
            slot_shelf_slot_length=body.slot_length,
            slot_shelf_slot_width=body.slot_width,
            slot_shelf_slot_rounding=body.slot_rounding,
            slot_shelf_gap=body.gap,
            slot_shelf_front_gap=body.front_gap,
            slot_shelf_rear_gap=body.rear_gap,
            slot_shelf_side_gap=body.side_gap,
            slot_shelf_rear_fillet_radius=body.rear_fillet_radius,
            slot_shelf_rounding=body.rounding,
        ),
        content_type="model/stl",
    )


class GridfinityShelfDefinition(BaseModel):
    gridx: Annotated[int, Field(gt=0)] = 2
    gridy: Annotated[int, Field(gt=0)] = 1
    plate_thickness: Annotated[float, Field(gte=0)] = 3
    rear_offset: Annotated[float, Field(gte=0)] = 4.5
    max_rear_offset_fillet: Annotated[float, Field(gte=0)] = 10
    base_thickness: Annotated[float, Field(gte=0)] = 0
    skeletonized: bool = True
    sides: bool = False
    side_thickness: Annotated[float, Field(gt=0)] = 2
    side_height: Annotated[float, Field(gt=0)] = 20
    front: bool = False
    front_thickness: Annotated[float, Field(gt=0)] = 2
    front_height: Annotated[float, Field(gt=0)] = 20
    magnet_holes: bool = False
    magnet_hole_crush_ribs: bool = False
    magnet_hole_chamfer: bool = False
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/gridfinity_shelf")
@validate(json=GridfinityShelfDefinition)
@openapi.body(GridfinityShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS Gridfinity shelf")
async def gridfinity_shelf(request: Request, body: GridfinityShelfDefinition):
    return response.raw(
        await build(
            part=Part.GridfinityShelf,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            gridfinity_shelf_gridx=body.gridx,
            gridfinity_shelf_gridy=body.gridy,
            gridfinity_shelf_plate_thickness=body.plate_thickness,
            gridfinity_shelf_rear_offset=body.rear_offset,
            gridfinity_shelf_max_rear_offset_fillet=body.max_rear_offset_fillet,
            gridfinity_shelf_base_thickness=body.base_thickness,
            gridfinity_shelf_skeletonized=body.skeletonized,
            gridfinity_shelf_sides=body.sides,
            gridfinity_shelf_side_thickness=body.side_thickness,
            gridfinity_shelf_side_height=body.side_height,
            gridfinity_shelf_front=body.front,
            gridfinity_shelf_front_thickness=body.front_thickness,
            gridfinity_shelf_front_height=body.front_height,
            gridfinity_shelf_magnet_holes=body.magnet_holes,
            gridfinity_shelf_magnet_hole_crush_ribs=body.magnet_hole_crush_ribs,
            gridfinity_shelf_magnet_hole_chamfer=body.magnet_hole_chamfer,
        ),
        content_type="model/stl",
    )
