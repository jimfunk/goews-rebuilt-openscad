# GOEWS rebuilt in OpenSCAD

This is a rebuild of [GOEWS](https://goews.xyz/) in OpenSCAD to allow for easy
generation and customization of parts. It requires the
[BOSL2](https://github.com/BelfrySCAD/BOSL2) library and
[Gridfinity Rebuilt in OpenSCAD](https://github.com/kennetek/gridfinity-rebuilt-openscad)
installed in the library path.

It also introduces a variant with thicker cleats which improves the weight capacity of
the tiles by 60%.

## Supported parts

### Tiles

Arbitrary tiles of any size, both hex and grid, can be generated. Within the tiles
units can be removed using a skip list to work around obstacles such as electrical
receptables.

The tile mounting holes can be adjusted as well to accomodate different screw sizes and
types. Setting the countersink to 0 allows for flat screws to be used. This is
particularly useful to account for when anchors are not perfectly aligned avoiding
having to make new holes in your wall.

For hex tiles any tile edge can be optionally filled in. This is particularly useful
for the top edge as it adds additional mounting holes that are more likely to hit a top
plate on a standard drywall-covered wall.

#### Thicker cleats

The thicker cleats variant can hold 60% more weight when used without the threaded
bolts. As a side-effect, the tiles actually use about 14% less filament and no longer
have sharp edges.

From testing, the original cleats, without bolts, held at 25lb and failed at 30lb. The
thicker cleats held at 40lb and failed at 45lb.

### Hooks

Hooks are similar to the original ones. The shank and post dimensions are
configurable.

### Racks

Racks are a new type of part that can be used for hanging items with wide tops. This is
quite useful for storing cables, bar clamps, screwdrivers, etc.

### Shelves

Shelves can be generated with any width and depth. There are variants with holes,
slots, and Gridfinity bases as well.

### Bins

Bins are simple square bins with customizable width, depth, and height.

### Cups

Cups are simple cups with customizable inner diameter and height.

### Hanger mounts

Hanger mounts allow you to mount almost anything to GOEWS.

Holes can be placed at any position on the plate, which can be made thicker to account
for the hardware. The holes can be made for heat-set inserts, self-tapping screws, hex
nuts or bolts, sqare nuts, socket and button cap screws, and flat countersink screws.

### Cable clips

Cable clips are useful for organizing cables. Plates with multiple clips are supported
and clips can be made to hold single or multiple cables.

### Bolts

Bolts are similar to the original ones. The length and socket width are configurable.

## Part generator

A part generator is included that provides a web interface to generate the supported
parts. The `openscad` command must be available in the `PATH` for the user running the
server and BOSL2 must be available in the library path.

To run it locally in dev mode:

```bash
make serve
```

The application will be available at http://localhost:5173/

To build for production:

```bash
make server
```

There is Systemd unit definition in `systemd/goews.service`. It assumes the location of
this repo is checked out at `/srv/goews-rebuilt-openscad` and a user `goews` exists.
For security reasons, it is highly recommended that nothing under the checkout is
actually writable by the `goews` user.

## TODO

PRs and suggestions are welcome :-)

* Shelf supports
* Bins with dividers
* Multi-cups
* Optional multiple vertical hangers for taller items
* More socket and flange options for bolts
