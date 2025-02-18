# GOEWS rebuilt in OpenSCAD

This is a rebuild of [GOEWS](https://goews.xyz/) in OpenSCAD to allow for easy
generation and customization of parts. It requires the
[BOSL2](https://github.com/BelfrySCAD/BOSL2) library.

It also introduces a variant with thicker cleats which improves the weight capacity of
the tiles by 60%.

## Supported parts

### Tiles

Arbitrary tiles of any size can be generated. Within the tiles hex units can be removed
using a skip list to work around obstacles such as electrical receptables.

#### Thicker cleats

The thicker cleats variant can hold 60% more weight when used without the threaded bolts. As a side-effect, the tiles actually use about 14% less filament and no longer have sharp edges.

From testing, the original cleats, without bolts, held at 25lb and failed at 30lb. The
thicker cleats held at 40lb and failed at 45lb.

### Hooks

Hooks are similar to the original ones. The shank and post dimensions are
configurable.

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

PRs are welcome :-)

* Shelves
* Boxes
* Cups
* Gridfinity plates
* Tile edge fillers
* Grid tiles
