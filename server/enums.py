from enum import IntEnum


class Part(IntEnum):
    Tile = 0
    Hook = 1
    Bolt = 2
    Rack = 3


class Variant(IntEnum):
    Original = 0
    ThickerCleats = 1
