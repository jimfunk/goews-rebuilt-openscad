from enum import StrEnum
from sanic_ext import openapi


@openapi.component
class Variant(StrEnum):
    ORIGINAL = "Original"
    THICKER_CLEATS = "Thicker Cleats"

    def to_int(self) -> int:
        """Convert to integer for OpenSCAD compatibility."""
        return 0 if self == self.ORIGINAL else 1
