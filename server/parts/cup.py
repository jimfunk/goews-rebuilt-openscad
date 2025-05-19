from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class CupDefinition(BaseModel):
    inner_diameter: Annotated[float, Field(gt=0)] = 37.5
    height: Annotated[float, Field(gt=0)] = 24.39
    wall_thickness: Annotated[float, Field(gt=0)] = 2
    bottom_thickness: Annotated[float, Field(gte=0)] = 2
    inner_rounding: Annotated[float, Field(gte=0)] = 0.5
    outer_rounding: Annotated[float, Field(gte=0)] = 0.5
    hanger_tolerance: Annotated[float, Field(gt=0)] = 0.15
    variant: Variant = Variant.Original


@app.post("/api/cup")
@validate(json=CupDefinition)
@openapi.body(CupDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS cup")
async def cup(request: Request, body: CupDefinition):
    return response.raw(
        await build(
            part=Part.Cup,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant,
            cup_inner_diameter=body.inner_diameter,
            cup_height=body.height,
            cup_wall_thickness=body.wall_thickness,
            cup_bottom_thickness=body.bottom_thickness,
            cup_inner_rounding=body.inner_rounding,
            cup_outer_rounding=body.outer_rounding,
        ),
        content_type="model/stl",
    )
