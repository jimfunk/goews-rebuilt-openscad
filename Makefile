# Makefile for generating STL files
#
# By default this will build a set of common parts under the build directory. You can
# build custom parts by specifying the desired filename. For example
#
#    make build/tile-original-2x4.stl
#
# will generate a tile with the original cleats, 2 columns, and 4 rows.
#

OPENSCAD = openscad
OPENSCAD_ARGS = --backend manifold

MAIN_SCAD = GOEWS.scad

BUILD_DIR = build

VARIANTS = original thicker_cleats

PART_TILE = 0
TILE_SIZES = 1x1 2x2 4x4 4x5 5x4 5x5 5x6 6x5 6x6
TILES = $(foreach size,$(TILE_SIZES),$(foreach variant,$(VARIANTS),$(BUILD_DIR)/tile-$(variant)-$(size).stl))

PART_HOOK = 1
HOOK_SIZES= 10x10 10x20 10x30 10x40 10x50 10x60 20x10 20x20 20x30 20x40 20x50 20x60 20x70 20x80
HOOKS = $(foreach size,$(HOOK_SIZES),$(foreach variant,$(VARIANTS),$(BUILD_DIR)/hook-$(variant)-$(size).stl))

all: tiles hooks

# Generate all tile models
tiles: $(TILES)

# Generate all hook models
hooks: $(HOOKS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Tile rule
$(BUILD_DIR)/tile-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_TILE)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'tile_columns=$(TILE_COLUMNS)' \
		-D 'tile_rows=$(TILE_ROWS)'

# Hook rule
$(BUILD_DIR)/hook-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval HOOK_WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval HOOK_SHANK_LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_HOOK)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'hook_width=$(HOOK_WIDTH)' \
		-D 'hook_shank_length=$(HOOK_SHANK_LENGTH)'

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all tiles hooks clean
