# Model generation cache

The STL cache sits behind `server.openscad.build()`.
`generation.py` fingerprints generation inputs, `model_cache.py` manages disk storage,
and `openscad.py` coordinates cache access and rendering.
The Makefile's prebuilt `build/` catalog is separate and is not consulted.
PNG screenshots use a separate in-memory cache.

See the [part generator documentation](../README.md#generated-model-cache)
for configuration and deployment requirements.

## Cache identity and invalidation

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

## Storage and concurrency

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

## Diagnostics

The `openscad` and `openscad.cache` loggers report hits, misses, render duration,
stored bytes, evictions, and cache failures at INFO/WARNING level.
Enable INFO logging for these loggers when inspecting cache effectiveness.
A cache hit guarantees byte identity;
a fresh render after eviction or invalidation is not a promise of identical
STL serialization across renderer or library versions.

## Tile-stack downloads

Tile-stack ZIPs are assembled on each download from the two generated STL artifacts.
Fixed member order, timestamps, permissions, and compression settings make unchanged
STL bytes produce identical ZIP bytes on the same compression runtime.
The member timestamp is intentionally `1980-01-01`, not the generation time.
This uses explicit [Python ZIP entry metadata](https://docs.python.org/3/library/zipfile.html#zipfile.ZipInfo)
rather than `writestr()`'s default current-time metadata.
Byte identity across different Python/zlib versions is not guaranteed.
