from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class BinDefinition(BaseModel):
    width: Annotated[float, Field(gt=0)]
    depth: Annotated[float, Field(gt=0)]
    height: Annotated[float, Field(gt=0)]
    wall_thickness: Annotated[float, Field(gt=0)]
    bottom_thickness: Annotated[float, Field(gt=0)]
    lip_thickness: Annotated[float, Field(gte=0)]
    inner_rounding: Annotated[float, Field(gte=0)]
    outer_rounding: Annotated[float, Field(gte=0)]
    variant: Variant


@app.post("/api/bin")
@validate(json=BinDefinition)
@openapi.body(BinDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS bin")
async def bin(request: Request, body: BinDefinition):
    return response.raw(
        await build(
            part=Part.Bin,
            variant=body.variant,
            bin_width=body.width,
            bin_depth=body.depth,
            bin_height=body.height,
            bin_wall_thickness=body.wall_thickness,
            bin_bottom_thickness=body.bottom_thickness,
            bin_lip_thickness=body.lip_thickness,
            bin_inner_rounding=body.inner_rounding,
            bin_outer_rounding=body.outer_rounding,
        ),
        content_type="model/stl",
    )
