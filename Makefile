# Makefile for generating STL files
#
# By default this will build a set of common parts under the build directory. You can
# build custom parts by specifying the desired filename. For example
#
#    make build/tile-original-2x4.stl
#
# will generate a tile with the original cleats, 2 columns, and 4 rows.
#
# To run the web-based part generator in dev mode:
#
#    make serve
#
# To build the web-based part generator for production:
#
#    make server
#
SHELL := /bin/bash

ifeq ($(shell command -v python3.11),)
	PYTHON = python3
else
	PYTHON = python3.11
endif

VIRTUALENV_DIR = venv
VIRTUALENV = $(VIRTUALENV_DIR)/.stamp
PIP = $(VIRTUALENV_DIR)/bin/pip
SANIC = $(VIRTUALENV_DIR)/bin/sanic

NPM = npm

FRONTEND_DIR = frontend
FRONTEND_ENV_DIR = $(FRONTEND_DIR)/node_modules
FRONTEND_ENV = $(FRONTEND_ENV_DIR)/.stamp
FRONTEND_DIST = $(FRONTEND_DIR)/dist/index.html
FRONTEND_SOURCES = \
	$(FRONTEND_DIR)/index.html \
	$(FRONTEND_DIR)/svelte.config.js \
	$(FRONTEND_DIR)/vite.config.js \
	$(FRONTEND_DIR)/package.json \
	$(shell find $(FRONTEND_DIR)/src -type f)

OPENSCAD = openscad
OPENSCAD_ARGS = --backend manifold

BUILD_DIR = build

all: tiles grid-tiles bolts hooks shelves hole-shelves slot-shelves bins gridfinity-bins cups
.PHONY: all

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

VARIANTS = original thicker_cleats

#
# Tiles
#
PART_TILE = 0
PART_GRID_TILE = 4
TILE_SIZES = 1x1 2x2 4x4 4x5 5x4 5x5 5x6 6x5 6x6
TILE_FILL_OPTIONS = top bottom left right
TILE_FILL_PERMUTATIONS = $(shell \
  echo "" \
  && for i in "" $(TILE_FILL_OPTIONS); do \
       for j in "" $(TILE_FILL_OPTIONS); do \
         for k in "" $(TILE_FILL_OPTIONS); do \
           for l in "" $(TILE_FILL_OPTIONS); do \
             echo "$$i $$j $$k $$l" | tr ' ' '\n' | sort -u | paste -sd '_' -; \
           done; \
         done; \
       done; \
     done \
  | sed 's/^_//' | sed 's/_$$//' | sort -u)

TILES = $(foreach size,$(TILE_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/tile-$(variant)-$(size).stl \
				$(foreach fill,$(TILE_FILL_PERMUTATIONS), \
					$(BUILD_DIR)/tile-$(variant)-$(size)-fill_$(fill).stl \
				) \
			) \
		)

tiles: $(TILES)
.PHONY: tiles

$(BUILD_DIR)/tile-%.stl: tile.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(eval FILL_SUFFIX := $(word 3,$(subst -, ,$*)))  # Extract fill suffix (if any)
	$(eval FILL_PARAMS := $(if $(FILL_SUFFIX),$(shell echo $(FILL_SUFFIX) | awk '{gsub("_"," "); for(i=1;i<=NF;i++) print "fill_" $$i "=true"}'),))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ tile.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'columns=$(TILE_COLUMNS)' \
		-D 'rows=$(TILE_ROWS)' \
		$(foreach param,$(FILL_PARAMS),-D '$(param)')


#
# Grid tiles
#
GRID_TILES = $(foreach size,$(TILE_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/tile-grid-$(variant)-$(size).stl \
			) \
		)

$(BUILD_DIR)/tile-grid-%.stl: grid_tile.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(eval FILL_SUFFIX := $(word 3,$(subst -, ,$*)))  # Extract fill suffix (if any)
	$(eval FILL_PARAMS := $(if $(FILL_SUFFIX),$(shell echo $(FILL_SUFFIX) | awk '{gsub("_"," "); for(i=1;i<=NF;i++) print "tile_fill_" $$i "=true"}'),))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ grid_tile.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'columns=$(TILE_COLUMNS)' \
		-D 'rows=$(TILE_ROWS)' \
		$(foreach param,$(FILL_PARAMS),-D '$(param)')


grid-tiles: $(GRID_TILES)
.PHONY: grid-tiles

#
# Bolts
#
BOLT_LENGTHS= 9 16
BOLTS = $(foreach length,$(BOLT_LENGTHS),$(BUILD_DIR)/bolt-$(length).stl)

bolts: $(BOLTS)
.PHONY: bolts

$(BUILD_DIR)/bolt-%.stl: bolt.scad $(BUILD_DIR)
	$(eval LENGTH := $(word 1,$(subst -, ,$*)))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ bolt.scad \
		-D 'length=$(LENGTH)'


#
# Hooks
#
HOOK_SIZES= 10x10 10x20 10x30 10x40 10x50 10x60 20x10 20x20 20x30 20x40 20x50 20x60 20x70 20x80
HOOKS = $(foreach size,$(HOOK_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/hook-$(variant)-$(size).stl \
			) \
		)

hooks: $(HOOKS)
.PHONY: hooks

$(BUILD_DIR)/hook-%.stl: hook.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval HOOK_WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval HOOK_SHANK_LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ hook.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'hooks=1' \
		-D 'width=$(HOOK_WIDTH)' \
		-D 'shank_length=$(HOOK_SHANK_LENGTH)'


#
# Shelves
#
SHELF_SIZES = 83.5x30 83.5x60 125.5x30 125.5x60
SHELVES = $(foreach size,$(SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/shelf-$(variant)-$(size).stl \
			) \
		)

shelves: $(SHELVES)
.PHONY: shelves

$(BUILD_DIR)/shelf-%.stl: shelf.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'width=$(WIDTH)' \
		-D 'depth=$(DEPTH)'


#
# Hole shelves
#
HOLE_SHELF_SIZES = 1x3 1x5 1x8 2x3 2x5 2x8
HOLE_SHELVES = $(foreach size,$(HOLE_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/hole-shelf-$(variant)-$(size).stl \
			) \
		)

hole-shelves: $(HOLE_SHELVES)
.PHONY: hole-shelves

$(BUILD_DIR)/hole-shelf-%.stl: hole_shelf.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval ROWS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval COLUMNS := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ hole_shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'rows=$(ROWS)' \
		-D 'columns=$(COLUMNS)'


#
# Slot shelves
#
SLOT_SHELF_SIZES = 10x40x4 10x40x8 20x60x4 20x60x8
SLOT_SHELVES = $(foreach size,$(SLOT_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/slot-shelf-$(variant)-$(size).stl \
			) \
		)

slot-shelves: $(SLOT_SHELVES)
.PHONY: slot-shelves

$(BUILD_DIR)/slot-shelf-%.stl: slot_shelf.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	$(eval SLOTS := $(word 3,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ slot_shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'slot_width=$(WIDTH)' \
		-D 'slot_length=$(LENGTH)' \
		-D 'slots=$(SLOTS)'


#
# Bins
#
BIN_SIZES = \
	41.5x41.5x20 \
	41.5x41.5x42 \
	41.5x83.5x20 \
	41.5x83.5x42 \
	83.5x41.5x20 \
	83.5x41.5x42 \
	83.5x83.5x20 \
	83.5x83.5x42
BINS = $(foreach size,$(BIN_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/bin-$(variant)-$(size).stl \
			) \
		)

bins: $(BINS)
.PHONY: bins

$(BUILD_DIR)/bin-%.stl: bin.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(SIZE))))
	$(eval HEIGHT := $(word 3,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ bin.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'width=$(WIDTH)' \
		-D 'depth=$(DEPTH)' \
		-D 'height=$(HEIGHT)'


#
# Gridfinity bins
#
GRIDFINITY_BIN_X = 1 2 3 4 5 6
GRIDFINITY_BIN_Y = 1 2 3 4 5 6
GRIDFINITY_BIN_Z = 3 4 5 6 7

GRIDFINITY_BIN_SIZES = $(foreach x,$(GRIDFINITY_BIN_X),$(foreach y,$(GRIDFINITY_BIN_Y),$(foreach z,$(GRIDFINITY_BIN_Z),$(x)x$(y)x$(z))))

GRIDFINITY_BINS = $(foreach size,$(GRIDFINITY_BIN_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/gridfinity-bin-$(variant)-$(size).stl \
			) \
		)

gridfinity-bins: $(GRIDFINITY_BINS)
.PHONY: gridfinity-bins

$(BUILD_DIR)/gridfinity-bin-%.stl: gridfinity_bin.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval GRIDX := $(word 1,$(subst x, ,$(SIZE))))
	$(eval GRIDY := $(word 2,$(subst x, ,$(SIZE))))
	$(eval GRIDZ := $(word 3,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ gridfinity_bin.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'bin_gridx=$(GRIDX)' \
		-D 'bin_gridy=$(GRIDY)' \
		-D 'bin_gridz=$(GRIDZ)'


#
# Cups
#
CUP_SIZES = 37.5x20 37.5x42
CUPS = $(foreach size,$(CUP_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/cup-$(variant)-$(size).stl \
			) \
		)

cups: $(CUPS)
.PHONY: cups

$(BUILD_DIR)/cup-%.stl: cup.scad $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval INNER_DIAMETER := $(word 1,$(subst x, ,$(SIZE))))
	$(eval HEIGHT := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ cup.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'inner_diameter=$(INNER_DIAMETER)' \
		-D 'height=$(HEIGHT)'


#
# Server
#
$(VIRTUALENV): server/requirements.txt
	$(PYTHON) -m venv $(VIRTUALENV_DIR)
	$(PIP) install -r server/requirements.txt
	touch $(VIRTUALENV)

virtualenv: $(VIRTUALENV)
.PHONY: virtualenv

$(FRONTEND_ENV): $(FRONTEND_DIR)/package.json
	cd $(FRONTEND_DIR); $(NPM) install
	touch $(FRONTEND_ENV)

$(FRONTEND_DIST): $(FRONTEND_ENV) $(FRONTEND_SOURCES)
	cd $(FRONTEND_DIR); $(NPM) run build

frontend: $(FRONTEND_DIST)
.PHONY: frontend

server: frontend virtualenv

serve: $(VIRTUALENV) $(FRONTEND_ENV)
	(trap 'kill 0' SIGINT; \
		$(SANIC) --dev server.server & \
		$(NPM) run --prefix $(FRONTEND_DIR) dev & \
		wait)
.PHONY: serve

clean:
	rm -rf $(BUILD_DIR) $(VIRTUALENV_DIR) $(FRONTEND_ENV) $(FRONTEND_DIST)

.PHONY: clean
