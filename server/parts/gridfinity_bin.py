from enum import StrEnum
from pydantic import BaseModel, Field
from sanic import Blueprint, response
from sanic.request import Request
from sanic_ext import openapi, validate
from typing import Annotated

from server.openscad import build
from server.enums import Variant
from server.api import api_bp


@openapi.component
class GridzDefine(StrEnum):
    """How gridz calculates height."""
    GRIDZ_UNITS = "Gridz Units (7mm excl lip)"
    INTERNAL_MM = "Internal mm (excl base & lip)"
    EXTERNAL_MM_EXCL_LIP = "External mm (excl lip)"
    EXTERNAL_MM = "External mm"

    def to_int(self) -> int:
        mapping = {
            self.GRIDZ_UNITS: 0,
            self.INTERNAL_MM: 1,
            self.EXTERNAL_MM_EXCL_LIP: 2,
            self.EXTERNAL_MM: 3,
        }
        return mapping[self]


@openapi.component
class StyleTab(StrEnum):
    """Tab style for bin compartments."""
    FULL = "Full"
    AUTO = "Auto"
    LEFT = "Left"
    CENTER = "Center"
    RIGHT = "Right"
    NONE = "None"

    def to_int(self) -> int:
        mapping = {
            self.FULL: 0,
            self.AUTO: 1,
            self.LEFT: 2,
            self.CENTER: 3,
            self.RIGHT: 4,
            self.NONE: 5,
        }
        return mapping[self]


@openapi.component
class PlaceTab(StrEnum):
    """Tab placement."""
    EVERYWHERE = "Everywhere"
    TOP_LEFT_DIVISION = "Top-Left Division"

    def to_int(self) -> int:
        mapping = {
            self.EVERYWHERE: 0,
            self.TOP_LEFT_DIVISION: 1,
        }
        return mapping[self]


@openapi.component
class GridfinityBinDefinition(BaseModel):
    gridx: Annotated[int, Field(ge=1, description="Number of grid units in x direction")] = 2
    gridy: Annotated[int, Field(ge=1, description="Number of grid units in y direction")] = 1
    gridz: Annotated[int, Field(ge=1, description="Bin height in 7mm increments")] = 3
    gridz_define: GridzDefine = GridzDefine.GRIDZ_UNITS
    height_internal: Annotated[float, Field(ge=0, description="Override internal block height in mm")] = 0
    enable_zsnap: Annotated[bool, Field(description="Snap gridz height to nearest 7mm")] = False
    include_lip: Annotated[bool, Field(description="Include stacking lip")] = True
    divx: Annotated[int, Field(ge=0, description="Number of X divisions (0 for solid)")] = 1
    divy: Annotated[int, Field(ge=0, description="Number of Y divisions (0 for solid)")] = 1
    cut_cylinders: Annotated[bool, Field(description="Use cylindrical cutouts")] = False
    cd: Annotated[float, Field(gt=0, description="Diameter of cylindrical cutouts in mm")] = 10
    c_chamfer: Annotated[float, Field(ge=0, description="Chamfer around cylindrical holes in mm")] = 0.5
    style_tab: StyleTab = StyleTab.NONE
    place_tab: PlaceTab = PlaceTab.EVERYWHERE
    scoop: Annotated[float, Field(ge=0, description="Scoop weight percentage")] = 1
    only_corners: Annotated[bool, Field(description="Only cut holes at corners")] = False
    refined_holes: Annotated[bool, Field(description="Use gridfinity refined hole style")] = False
    magnet_holes: Annotated[bool, Field(description="Add magnet holes")] = False
    screw_holes: Annotated[bool, Field(description="Add screw holes")] = False
    crush_ribs: Annotated[bool, Field(description="Magnet holes have crush ribs")] = True
    chamfer_holes: Annotated[bool, Field(description="Magnet/screw holes have chamfer")] = False
    printable_hole_top: Annotated[bool, Field(description="Magnet holes printable without supports")] = False
    enable_thumbscrew: Annotated[bool, Field(description="Enable thumbscrew hole")] = False
    wall_thickness: Annotated[float, Field(gt=0, description="Wall thickness in mm")] = 1.2
    bottom_thickness: Annotated[float, Field(gt=0, description="Bottom thickness in mm")] = 1.2
    hanger_tolerance: Annotated[float, Field(ge=0)] = 0.15
    variant: Variant = Variant.ORIGINAL


def make_gridfinity_bin_filename(body: GridfinityBinDefinition) -> str:
    parts = ["gridfinity-bin", f"{body.gridx}x{body.gridy}x{body.gridz}"]
    parts.append("original" if body.variant.to_int() == 0 else "thicker_cleats")

    options = []
    for name, info in type(body).model_fields.items():
        if name in ("gridx", "gridy", "gridz", "variant"):
            continue
        val = getattr(body, name)
        if val != info.default:
            if isinstance(val, bool):
                if val:
                    options.append(name)
                else:
                    options.append(f"no_{name}")
            else:
                options.append(f"{name}_{val}")

    if options:
        parts.append("_".join(options))

    return "-".join(parts) + ".stl"


@api_bp.post("/gridfinity_bin")
@openapi.body(GridfinityBinDefinition)
@openapi.response(200, "model/stl")
@openapi.description("Create a GOEWS Gridfinity bin")
@validate(json=GridfinityBinDefinition)
async def gridfinity_bin(request: Request, body: GridfinityBinDefinition):
    filename = make_gridfinity_bin_filename(body)
    return response.raw(
        await build(
            "gridfinity_bin.scad",
            hanger_tolerance=body.hanger_tolerance,
            variant=body.variant.to_int(),
            bin_gridx=body.gridx,
            bin_gridy=body.gridy,
            bin_gridz=body.gridz,
            bin_gridz_define=body.gridz_define.to_int(),
            bin_height_internal=body.height_internal,
            bin_enable_zsnap=body.enable_zsnap,
            bin_include_lip=body.include_lip,
            bin_divx=body.divx,
            bin_divy=body.divy,
            bin_cut_cylinders=body.cut_cylinders,
            bin_cd=body.cd,
            bin_c_chamfer=body.c_chamfer,
            bin_style_tab=body.style_tab.to_int(),
            bin_place_tab=body.place_tab.to_int(),
            bin_scoop=body.scoop,
            bin_only_corners=body.only_corners,
            bin_refined_holes=body.refined_holes,
            bin_magnet_holes=body.magnet_holes,
            bin_screw_holes=body.screw_holes,
            bin_crush_ribs=body.crush_ribs,
            bin_chamfer_holes=body.chamfer_holes,
            bin_printable_hole_top=body.printable_hole_top,
            bin_enable_thumbscrew=body.enable_thumbscrew,
            bin_wall_thickness=body.wall_thickness,
            bin_bottom_thickness=body.bottom_thickness,
        ),
        content_type="model/stl",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
