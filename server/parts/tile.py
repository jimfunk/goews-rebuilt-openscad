from pydantic import BaseModel, Field, field_validator
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class TileDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0)] = 4
    rows: Annotated[int, Field(gt=0)] = 4
    fill_top: bool = False
    fill_bottom: bool = False
    fill_left: bool = False
    fill_right: bool = False
    reverse_stagger: bool = False
    exact_width: bool = False
    mounting_hole_shank_diameter: Annotated[float, Field(gt=0)] = 4
    mounting_hole_head_diameter: Annotated[float, Field(gt=0)] = 8
    mounting_hole_inset_depth: Annotated[float, Field(gt=0)] = 1
    mounting_hole_countersink_depth: Annotated[float, Field(gte=0)] = 2
    skip_list: list[list[int, int]] = []
    variant: Variant = Variant.Original

    @field_validator('skip_list', mode="after")
    @classmethod
    def validate_skip_list(cls, value: list[list[int, int]]) -> list[list[int, int]]:
        for coordinate in value:
            if len(coordinate) != 2:
                raise ValueError("Skip list must be a list of [row, column] pairs")
            if not (isinstance(coordinate[0], int) and isinstance(coordinate[1], int)):
                raise ValueError("Skip list rows and columns must be integers")
            if coordinate[0] <= 0 or coordinate[1] <= 0:
                raise ValueError("Skip list rows and columns must be greater than zero.")
        return value


@app.post("/api/tile")
@validate(json=TileDefinition)
@openapi.body(TileDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS hex tile")
async def tile(request: Request, body: TileDefinition):
    skip_list = ",".join(repr(entry) for entry in body.skip_list)
    return response.raw(
        await build(
            part=Part.Tile,
            variant=body.variant,
            tile_columns=body.columns,
            tile_rows=body.rows,
            tile_fill_top=body.fill_top,
            tile_fill_bottom=body.fill_bottom,
            tile_fill_left=body.fill_left,
            tile_fill_right=body.fill_right,
            tile_reverse_stagger=body.reverse_stagger,
            tile_exact_width=body.exact_width,
            tile_mounting_hole_shank_diameter=body.mounting_hole_shank_diameter,
            tile_mounting_hole_head_diameter=body.mounting_hole_head_diameter,
            tile_mounting_hole_inset_depth=body.mounting_hole_inset_depth,
            tile_mounting_hole_countersink_depth=body.mounting_hole_countersink_depth,
            tile_skip_list=skip_list,
        ),
        content_type="model/stl",
    )


class GridTileDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0)] = 4
    rows: Annotated[int, Field(gt=0)] = 4
    mounting_hole_shank_diameter: Annotated[float, Field(gt=0)] = 4
    mounting_hole_head_diameter: Annotated[float, Field(gt=0)] = 8
    mounting_hole_inset_depth: Annotated[float, Field(gt=0)] = 1
    mounting_hole_countersink_depth: Annotated[float, Field(gte=0)] = 2
    skip_list: list[list[int, int]] = []
    variant: Variant = Variant.Original

    @field_validator('skip_list', mode="after")
    @classmethod
    def validate_skip_list(cls, value: list[list[int, int]]) -> list[list[int, int]]:
        for coordinate in value:
            if len(coordinate) != 2:
                raise ValueError("Skip list must be a list of [row, column] pairs")
            if not (isinstance(coordinate[0], int) and isinstance(coordinate[1], int)):
                raise ValueError("Skip list rows and columns must be integers")
            if coordinate[0] <= 0 or coordinate[1] <= 0:
                raise ValueError("Skip list rows and columns must be greater than zero.")
        return value


@app.post("/api/grid-tile")
@validate(json=GridTileDefinition)
@openapi.body(GridTileDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS grid tile")
async def grid_tile(request: Request, body: GridTileDefinition):
    skip_list = ",".join(repr(entry) for entry in body.skip_list)
    return response.raw(
        await build(
            part=Part.GridTile,
            variant=body.variant,
            tile_columns=body.columns,
            tile_rows=body.rows,
            tile_mounting_hole_shank_diameter=body.mounting_hole_shank_diameter,
            tile_mounting_hole_head_diameter=body.mounting_hole_head_diameter,
            tile_mounting_hole_inset_depth=body.mounting_hole_inset_depth,
            tile_mounting_hole_countersink_depth=body.mounting_hole_countersink_depth,
            tile_skip_list=skip_list,
        ),
        content_type="model/stl",
    )
