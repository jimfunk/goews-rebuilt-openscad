from pydantic import BaseModel, Field, field_validator
from sanic import Sanic, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Part, Variant


app = Sanic.get_app()


class BoltDefinition(BaseModel):
    length: Annotated[float, Field(gt=0)]
    socket_width: Annotated[float, Field(gt=0)]


@app.post("/api/bolt")
@validate(json=BoltDefinition)
@openapi.body(BoltDefinition, required=True)
@openapi.response(200, {"model/stl": bytes})
@openapi.description("Create a standard GOEWS bolt")
async def bolt(request: Request, body: BoltDefinition):
    return response.raw(
        build(
            part=Part.Bolt,
            bolt_length=body.length,
            bolt_socket_width=body.socket_width,
        ),
        content_type="model/stl",
    )
