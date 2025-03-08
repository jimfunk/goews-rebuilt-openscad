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

MAIN_SCAD = GOEWS.scad

BUILD_DIR = build

VARIANTS = original thicker_cleats

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

GRID_TILES = $(foreach size,$(TILE_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/tile-grid-$(variant)-$(size).stl \
			) \
		)

PART_HOOK = 1
HOOK_SIZES= 10x10 10x20 10x30 10x40 10x50 10x60 20x10 20x20 20x30 20x40 20x50 20x60 20x70 20x80
HOOKS = $(foreach size,$(HOOK_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/hook-$(variant)-$(size).stl \
			) \
		)

PART_SHELF = 5
SHELF_SIZES = 83.5x30 83.5x60 125.5x30 125.5x60
SHELVES = $(foreach size,$(SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/shelf-$(variant)-$(size).stl \
			) \
		)

PART_HOLE_SHELF = 6
HOLE_SHELF_SIZES = 1x3 1x5 1x8 2x3 2x5 2x8
HOLE_SHELVES = $(foreach size,$(HOLE_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/hole-shelf-$(variant)-$(size).stl \
			) \
		)

PART_SLOT_SHELF = 7
SLOT_SHELF_SIZES = 10x40x4 10x40x8 20x60x4 20x60x8
SLOT_SHELVES = $(foreach size,$(SLOT_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(BUILD_DIR)/slot-shelf-$(variant)-$(size).stl \
			) \
		)

PART_BOLT = 2
BOLT_LENGTHS= 9 16
BOLTS = $(foreach length,$(BOLT_LENGTHS),$(BUILD_DIR)/bolt-$(length).stl)

all: tiles grid-tiles hooks shelves hole-shelves slot-shelves bolts
.PHONY: all

# Generate all tile models
tiles: $(TILES)
.PHONY: tiles

# Generate all grid tile models
grid-tiles: $(GRID_TILES)
.PHONY: grid-tiles

# Generate all hook models
hooks: $(HOOKS)
.PHONY: hooks

# Generate all shelf models
shelves: $(SHELVES)
.PHONY: shelves

# Generate all hole shelf models
hole-shelves: $(HOLE_SHELVES)
.PHONY: hole-shelves

# Generate all slot shelf models
slot-shelves: $(SLOT_SHELVES)
.PHONY: slot-shelves

# Generate all bolt models
bolts: $(BOLTS)
.PHONY: bolts

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Tile rule
$(BUILD_DIR)/tile-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(eval FILL_SUFFIX := $(word 3,$(subst -, ,$*)))  # Extract fill suffix (if any)
	$(eval FILL_PARAMS := $(if $(FILL_SUFFIX),$(shell echo $(FILL_SUFFIX) | awk '{gsub("_"," "); for(i=1;i<=NF;i++) print "tile_fill_" $$i "=true"}'),))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_TILE)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'tile_columns=$(TILE_COLUMNS)' \
		-D 'tile_rows=$(TILE_ROWS)' \
		$(foreach param,$(FILL_PARAMS),-D '$(param)')

# Grid tile rule
$(BUILD_DIR)/tile-grid-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(eval FILL_SUFFIX := $(word 3,$(subst -, ,$*)))  # Extract fill suffix (if any)
	$(eval FILL_PARAMS := $(if $(FILL_SUFFIX),$(shell echo $(FILL_SUFFIX) | awk '{gsub("_"," "); for(i=1;i<=NF;i++) print "tile_fill_" $$i "=true"}'),))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_GRID_TILE)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'tile_columns=$(TILE_COLUMNS)' \
		-D 'tile_rows=$(TILE_ROWS)' \
		$(foreach param,$(FILL_PARAMS),-D '$(param)')

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

# Shelf rule
$(BUILD_DIR)/shelf-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_SHELF)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'shelf_width=$(WIDTH)' \
		-D 'shelf_depth=$(DEPTH)'

# Hole shelf rule
$(BUILD_DIR)/hole-shelf-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval ROWS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval COLUMNS := $(word 2,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_HOLE_SHELF)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'hole_shelf_rows=$(ROWS)' \
		-D 'hole_shelf_columns=$(COLUMNS)'

# Slot shelf rule
$(BUILD_DIR)/slot-shelf-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval VARIANT_NAME := $(word 1,$(subst -, ,$*)))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT_NAME) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 2,$(subst -, ,$*)))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	$(eval SLOTS := $(word 3,$(subst x, ,$(SIZE))))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_SLOT_SHELF)' \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'slot_shelf_slot_width=$(WIDTH)' \
		-D 'slot_shelf_slot_length=$(LENGTH)' \
		-D 'slot_shelf_slots=$(SLOTS)'

# bolt rule
$(BUILD_DIR)/bolt-%.stl: $(MAIN_SCAD) $(BUILD_DIR)
	$(eval LENGTH := $(word 1,$(subst -, ,$*)))
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ $(MAIN_SCAD) \
		-D 'part=$(PART_BOLT)' \
		-D 'bolt_length=$(LENGTH)'

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
