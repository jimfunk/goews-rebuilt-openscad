# GOEWS rebuilt in OpenSCAD

This is a rebuild of [GOEWS](https://goews.ws/) in OpenSCAD to allow for easy
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

#### Tile stacks

Tile stacks allow multiple tiles to be printed in a single job by alternating normal
tile geometry with thin separator layers. The intended use is to print the tiles in
PLA and the separators in PETG, taking advantage of the poor adhesion between those
materials so the finished stack can be separated after printing.

This requires a multi-material printer, toolchanger, or filament changer capable of
printing PLA and PETG in the same job. Examples include toolchanger printers such as
the [Snapmaker U1](https://www.snapmaker.com/en-CA/snapmaker-u1), multi-material
systems such as the [Sovol M1D](https://www.sovol3d.com/pages/sovol-m1d-landing-page),
or community filament changers such as the
[Enraged Rabbit Project](https://github.com/EtteGit/EnragedRabbitProject) or [BoxTurtle Project](https://github.com/ArmoredTurtle/BoxTurtle)  for
Voron/Klipper-style printers.

In the web generator, tile stacks are available under **Tiles** as **Tile Stack**.
The generator supports both hex and grid tiles, a configurable stack count, and the
same tile sizing and mounting-hole options as the normal tile generators. The browser
preview shows the tile bodies and separator layers as separate materials.

When downloading a tile stack from the web generator, the download is a ZIP file
containing two STL files:

* `tile-stack-*.stl` — the tile bodies and any PLA support geometry
* `tile-stack-*-spacers.stl` — the PETG separator layers and pull tabs

The ZIP is assembled from the cached STL artifacts on each download.
It uses fixed member order, timestamps, permissions, and compression settings,
so unchanged STL bytes produce identical ZIP bytes on the same compression runtime.
The member timestamp is intentionally `1980-01-01`, not the generation time.
This uses explicit [Python ZIP entry metadata](https://docs.python.org/3.13/library/zipfile.html#zipfile.ZipInfo)
rather than `writestr()`'s default current-time metadata.
Byte identity across different Python/zlib versions is not guaranteed.

Import both STLs into the slicer together as one multi-part object, keeping their
relative positions unchanged. Assign the tile body STL to PLA and the spacer STL to
PETG.

In OrcaSlicer, enable multi-material printing, assign PLA and PETG to the two imported
parts, then enable **Print Settings → Multimaterial → Advanced → Interface Shells**.
This ensures solid layers are generated between the tile bodies and the separator
layers. Do not enable interlocking beams for this use case; the goal is for the PLA and
PETG layers to release from each other after printing, not to bond more strongly.


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

### Generated model cache

The API caches successful STL output on disk behind `server.openscad.build()`.
Ordinary previews, downloads, and the two members of a tile-stack bundle
share this cache.
The Makefile's prebuilt `build/` catalog is separate and is not consulted.
No HTTP endpoint, parameter default, or download filename changes are required.

| Environment variable | Default | Purpose |
| --- | --- | --- |
| `GOEWS_CACHE_DIR` | `$XDG_CACHE_HOME/goews`, or `~/.cache/goews` | Parent of the private `artifacts-v1` cache directory. |
| `GOEWS_CACHE_MAX_BYTES` | `536870912` (512 MiB) | Maximum retained STL bytes; `0` disables disk caching. |
| `GOEWS_GENERATOR_REVISION` | Empty | Additional deployment revision to invalidate artifacts when other generation inputs change. |

Use a local filesystem on Linux or macOS.
All workers must use the same directory and budget to share artifacts safely.
For production, provision a directory such as `/var/cache/goews`
owned by the service user and set `GOEWS_CACHE_DIR` in the service environment.
Keep it outside the checkout and outside OpenSCAD library directories;
the service does not need write access to the source tree.
The cache creates its private namespace with mode `0700`
and refuses a namespace owned by another user, accessible by other users,
or replaced by a symbolic link.
Do not share it with untrusted writers or use a network filesystem.
The deployment example is not changed or installed automatically.

Keys hash the model identity, sorted effective OpenSCAD parameters,
backend/export format, and a generation fingerprint.
Omitted API defaults and explicit equivalent values share an artifact,
including integer-valued floats;
booleans and strings remain distinct from numbers.
`None` values are omitted because they do not produce a `-D` argument.
List order is preserved rather than assuming geometric equivalence.
Download filenames are not cache keys.

The fingerprint covers project SCAD sources and common imported asset formats,
source trees in OpenSCAD's reported library search paths,
the renderer executable and its reported build information,
and `GOEWS_GENERATOR_REVISION`.
Project scans exclude hidden directories, `build/`, `venv/`, `frontend/`,
and `__pycache__/`.
Library scans exclude hidden directories and follow library-directory symlinks.
Each request rechecks the source trees;
unchanged file hashes are memoized using file identity, size, and timestamps.
Source additions, removals, and edits invalidate existing keys,
and a render whose fingerprint changes while it runs is not stored.
This deliberately invalidates the whole generation cache,
rather than maintaining per-model dependency graphs.

OpenSCAD search paths and build information come from `openscad --info`
(see the [command-line manual](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Using_OpenSCAD_in_a_command_line_environment)),
with discovery memoized by executable content and `OPENSCADPATH`.
Restart workers when changing the renderer's surrounding runtime environment
or a launcher script's target without changing the launcher itself.
Use `GOEWS_GENERATOR_REVISION` for other inputs not covered by the scan,
such as system fonts, custom assets outside those trees,
or deployment-specific toolchain changes.
If fingerprint discovery fails, generation continues without disk caching
rather than risking an incorrectly identified artifact.

Cache hits return the stored STL bytes unchanged.
Concurrent identical requests share an in-flight task in each worker,
and bounded POSIX lock files coordinate renders between workers.
Completed STL results are not retained in a separate in-memory LRU.
A disconnected client does not cancel a render shared by other callers.
Writes use temporary files and atomic replacement;
failed renders are not stored, and cache I/O failures fall back to generation.

Least-recently-used artifacts are evicted on reads and writes to respect the budget,
including artifacts from previous generation fingerprints.
Oversized results are returned but not stored.
The budget counts retained STL content, not filesystem overhead or in-flight
response buffers; writes can temporarily require additional disk space.
Interrupted-write temporary files are cleaned on the next cache operation.
The zero-budget setting bypasses the cache without deleting old files.
To clear it manually, stop all workers before removing its private namespace;
never remove live lock files while workers are using them.

The `openscad` and `openscad.cache` loggers report hits, misses, render duration,
stored bytes, evictions, and cache failures at INFO/WARNING level.
Enable INFO logging for these loggers when inspecting cache effectiveness.
A cache hit guarantees byte identity;
a fresh render after eviction or invalidation is not a promise of identical
STL serialization across renderer or library versions.

## TODO

PRs and suggestions are welcome :-)

* Shelf supports
* Bins with dividers
* Multi-cups
* Optional multiple vertical hangers for taller items
