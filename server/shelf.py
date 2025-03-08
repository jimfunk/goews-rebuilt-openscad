from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class ShelfDefinition(BaseModel):
    width: Annotated[float, Field(gt=0)]
    depth: Annotated[float, Field(gt=0)]
    thickness: Annotated[float, Field(gt=0)]
    rear_fillet_radius: Annotated[float, Field(gte=0)]
    rounding: Annotated[float, Field(gte=0)]
    variant: Variant


@app.post("/api/shelf")
@validate(json=ShelfDefinition)
@openapi.body(ShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf")
async def shelf(request: Request, body: ShelfDefinition):
    return response.raw(
        await build(
            part=Part.Shelf,
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
    columns: Annotated[int, Field(gt=0)]
    rows: Annotated[int, Field(gt=0)]
    thickness: Annotated[float, Field(gt=0)]
    hole_radius: Annotated[float, Field(gt=0)]
    column_gap: Annotated[float, Field(gt=0)]
    row_gap: Annotated[float, Field(gt=0)]
    front_gap: Annotated[float, Field(gt=0)]
    rear_gap: Annotated[float, Field(gt=0)]
    side_gap: Annotated[float, Field(gt=0)]
    stagger: bool
    rear_fillet_radius: Annotated[float, Field(gte=0)]
    rounding: Annotated[float, Field(gte=0)]
    variant: Variant


@app.post("/api/hole_shelf")
@validate(json=HoleShelfDefinition)
@openapi.body(HoleShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf with holes")
async def hole_shelf(request: Request, body: HoleShelfDefinition):
    return response.raw(
        await build(
            part=Part.HoleShelf,
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
    slots: Annotated[int, Field(gt=0)]
    thickness: Annotated[float, Field(gt=0)]
    slot_length: Annotated[float, Field(gt=0)]
    slot_width: Annotated[float, Field(gt=0)]
    slot_rounding: Annotated[float, Field(gte=0)]
    gap: Annotated[float, Field(gt=0)]
    front_gap: Annotated[float, Field(gt=0)]
    rear_gap: Annotated[float, Field(gt=0)]
    side_gap: Annotated[float, Field(gt=0)]
    rear_fillet_radius: Annotated[float, Field(gte=0)]
    rounding: Annotated[float, Field(gte=0)]
    variant: Variant


@app.post("/api/slot_shelf")
@validate(json=SlotShelfDefinition)
@openapi.body(SlotShelfDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS shelf with slots")
async def slot_shelf(request: Request, body: SlotShelfDefinition):
    return response.raw(
        await build(
            part=Part.SlotShelf,
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
