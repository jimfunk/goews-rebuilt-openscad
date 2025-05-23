from enum import IntEnum


class Part(IntEnum):
    Tile = 0
    Hook = 1
    Bolt = 2
    Rack = 3
    GridTile = 4
    Shelf = 5
    HoleShelf = 6
    SlotShelf = 7
    Bin = 8
    Cup = 9
    GridfinityShelf = 10
    HangerMount = 11
    CableClip = 12


class Variant(IntEnum):
    Original = 0
    ThickerCleats = 1
