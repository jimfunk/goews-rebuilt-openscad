from pydantic import BaseModel, Field, field_validator
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class TileDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0, description="Tile columns in units")] = 4
    rows: Annotated[int, Field(gt=0, description="Tile rows in units")] = 4
    fill_top: Annotated[bool, Field(description="Fill the top row edge")] = False
    fill_bottom: Annotated[bool, Field(description="Fill the bottom row edge")] = False
    fill_left: Annotated[bool, Field(description="Fill the left row edge")] = False
    fill_right: Annotated[bool, Field(description="Fill the right row edge")] = False
    reverse_stagger: Annotated[bool, Field(description="Reverse row stagger")] = False
    exact_width: Annotated[bool, Field(description="Make the tile exact width")] = False
    mounting_hole_shank_diameter: Annotated[float, Field(gt=0, description="Shank diameter in mm")] = 4
    mounting_hole_head_diameter: Annotated[float, Field(gt=0, description="Head diameter in mm")] = 8
    mounting_hole_inset_depth: Annotated[float, Field(gt=0, description="Inset depth in mm")] = 1
    mounting_hole_countersink_depth: Annotated[float, Field(ge=0, description="Countersink depth")] = 2
    skip_list: Annotated[list[list[int, int]], Field(description="Tiles to exclude")] = []
    variant: Variant = Variant.ORIGINAL

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


def make_tile_filename(body: TileDefinition) -> str:
    parts = ["tile", f"{body.columns}x{body.rows}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("columns", "rows", "variant"):
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


@openapi.component
class GridTileDefinition(BaseModel):
    columns: Annotated[int, Field(gt=0, description="Tile columns in units")] = 4
    rows: Annotated[int, Field(gt=0, description="Tile rows in units")] = 4
    mounting_hole_shank_diameter: Annotated[float, Field(gt=0, description="Shank diameter in mm")] = 4
    mounting_hole_head_diameter: Annotated[float, Field(gt=0, description="Head diameter in mm")] = 8
    mounting_hole_inset_depth: Annotated[float, Field(gt=0, description="Inset depth in mm")] = 1
    mounting_hole_countersink_depth: Annotated[float, Field(ge=0, description="Countersink depth")] = 2
    skip_list: Annotated[list[list[int, int]], Field(description="Tiles to exclude")] = []
    variant: Variant = Variant.ORIGINAL

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


def make_grid_tile_filename(body: GridTileDefinition) -> str:
    parts = ["grid-tile", f"{body.columns}x{body.rows}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("columns", "rows", "variant"):
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


@api_bp.post("/tile")
@openapi.body(TileDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS hex tile")
@validate(json=TileDefinition)
async def tile(request: Request, body: TileDefinition):
    skip_list = ",".join(repr(entry) for entry in body.skip_list)
    filename = make_tile_filename(body)
    return response.raw(
        await build(
            "tile.scad",
            variant=body.variant.to_int(),
            columns=body.columns,
            rows=body.rows,
            fill_top=body.fill_top,
            fill_bottom=body.fill_bottom,
            fill_left=body.fill_left,
            fill_right=body.fill_right,
            reverse_stagger=body.reverse_stagger,
            exact_width=body.exact_width,
            mounting_hole_shank_diameter=body.mounting_hole_shank_diameter,
            mounting_hole_head_diameter=body.mounting_hole_head_diameter,
            mounting_hole_inset_depth=body.mounting_hole_inset_depth,
            mounting_hole_countersink_depth=body.mounting_hole_countersink_depth,
            skip_list=skip_list,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@api_bp.post("/grid-tile")
@openapi.body(GridTileDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS grid tile")
@validate(json=GridTileDefinition)
async def grid_tile(request: Request, body: GridTileDefinition):
    skip_list = ",".join(repr(entry) for entry in body.skip_list)
    filename = make_grid_tile_filename(body)
    return response.raw(
        await build(
            "grid_tile.scad",
            variant=body.variant.to_int(),
            columns=body.columns,
            rows=body.rows,
            mounting_hole_shank_diameter=body.mounting_hole_shank_diameter,
            mounting_hole_head_diameter=body.mounting_hole_head_diameter,
            mounting_hole_inset_depth=body.mounting_hole_inset_depth,
            mounting_hole_countersink_depth=body.mounting_hole_countersink_depth,
            skip_list=skip_list,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
