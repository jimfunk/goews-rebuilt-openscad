"""Single-pliers hanger parameters and STL generation."""

from typing import Self

from pydantic import BaseModel, ConfigDict, Field, model_validator
from sanic import response
from sanic.request import Request
from sanic_ext import openapi, validate

from server.api import api_bp
from server.enums import Variant
from server.openscad import build


@openapi.component
class PliersHangerDefinition(BaseModel):
    model_config = ConfigDict(allow_inf_nan=False)

    width: float = Field(default=24.0, gt=0, description="Nominal support base width in mm")
    depth: float = Field(
        default=25.0, gt=0,
        description="Usable outward support length in mm, excluding lip thickness",
    )
    height: float = Field(default=18.0, gt=0, description="Support peak height in mm")
    tip_width: float = Field(
        default=4.0, gt=0, description="Flat top width in mm; must be less than width",
    )
    lip_height: float = Field(
        default=4.0, ge=0, description="Additional peak height in mm; 0 disables the front retainer",
    )
    lip_thickness: float = Field(
        default=3.0, ge=0, description="Front lip depth in mm; must be positive when the lip is enabled",
    )
    rounding: float = Field(
        default=1.0, ge=0,
        description="Cross-section corner radius in mm; 0 for sharp corners; twice the radius must be less than tip_width and height",
    )
    hanger_tolerance: float = Field(default=0.15, ge=0, description="Hanger fit tolerance in mm")
    variant: Variant = Variant.ORIGINAL

    @model_validator(mode="after")
    def validate_cross_section(self) -> Self:
        if self.tip_width >= self.width:
            raise ValueError("tip_width must be less than width")
        if 2 * self.rounding >= min(self.tip_width, self.height):
            raise ValueError("2 * rounding must be less than both tip_width and height")
        if self.lip_height > 0 and self.lip_thickness == 0:
            raise ValueError("lip_thickness must be positive when lip_height is positive")
        return self


def make_pliers_hanger_filename(body: PliersHangerDefinition) -> str:
    parts = ["pliers-hanger", f"{body.width:g}x{body.depth:g}x{body.height:g}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")
    options = []
    for name, info in type(body).model_fields.items():
        if name in ("width", "depth", "height", "variant"):
            continue
        value = getattr(body, name)
        if value != info.default:
            options.append(f"{name}_{value}")
    if options:
        parts.append("_".join(options))
    return "-".join(parts) + ".stl"


@api_bp.post("/pliers_hanger")
@openapi.body(PliersHangerDefinition)
@openapi.response(200, "model/stl")
@openapi.summary("Pliers Hanger")
@openapi.description("Create a GOEWS single-pliers hanger with a central support and optional front retainer")
@validate(json=PliersHangerDefinition)
async def pliers_hanger(request: Request, body: PliersHangerDefinition):
    filename = make_pliers_hanger_filename(body)
    return response.raw(
        await build(
            "pliers_hanger.scad",
            width=body.width,
            depth=body.depth,
            height=body.height,
            tip_width=body.tip_width,
            lip_height=body.lip_height,
            lip_thickness=body.lip_thickness,
            rounding=body.rounding,
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
