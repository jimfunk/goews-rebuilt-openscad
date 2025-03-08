from pydantic import BaseModel, Field
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class CupDefinition(BaseModel):
    inner_diameter: Annotated[float, Field(gt=0)]
    height: Annotated[float, Field(gt=0)]
    wall_thickness: Annotated[float, Field(gt=0)]
    bottom_thickness: Annotated[float, Field(gte=0)]
    inner_rounding: Annotated[float, Field(gte=0)]
    outer_rounding: Annotated[float, Field(gte=0)]
    variant: Variant


@app.post("/api/cup")
@validate(json=CupDefinition)
@openapi.body(CupDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a GOEWS cup")
async def cup(request: Request, body: CupDefinition):
    return response.raw(
        await build(
            part=Part.Cup,
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
