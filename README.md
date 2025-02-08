# GOEWS rebuilt in OpenSCAD

This is a rebuild of [GOEWS](https://goews.xyz/) in OpenSCAD to allow for easy
generation and customization of parts.

It also introduces a variant with thicker cleats which improves the weight capacity of
the tiles by 60%.

## Tiles

Arbitrary tiles of any size can be generated. Within the tiles hex units can be removed
using a skip list to work around obstacles such as electrical receptables.

### Thicker cleats

The thicker cleats variant can hold 60% more weight when used without the threaded bolts. As a side-effect, the tiles actually use about 14% less filament and no longer have sharp edges.

From testing, the original cleats, without bolts, held at 25lb and failed at 30lb. The
thicker cleats held at 40lb and failed at 45lb.

## Hooks

Hooks are similar to the original ones. The shank and post dimensions are
configurable.

## TODO

PRs are welcome :-)

* Bolts
* Shelves
* Boxes
* Cups
* Hangers
* Gridfinity plates
* Tile edge fillers
* Grid tiles
