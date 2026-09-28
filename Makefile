# Makefile for generating STL files
#
# By default this will build a set of common parts under the build directory. You can
# build custom parts by specifying the desired filename. For example
#
#    make build/tile/original/tile-2x4-original.stl
#
# will generate a tile with the original cleats, 2 columns, and 4 rows.
#
# To run the web-based part generator in dev mode:
#    make serve
#
# To build the web-based part generator for production:
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
PYTEST = $(VIRTUALENV_DIR)/bin/pytest
TEST_VIRTUALENV = $(VIRTUALENV_DIR)/.test-stamp

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

all: server
.PHONY: all

VARIANTS = original thicker_cleats


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

$(TEST_VIRTUALENV): $(VIRTUALENV) server/requirements-test.txt
	$(PIP) install -r server/requirements-test.txt
	touch $(TEST_VIRTUALENV)

test: $(TEST_VIRTUALENV)
	$(PYTEST)
.PHONY: test


parts: \
	parts-bins \
	parts-bolts \
	parts-cups \
	parts-grid-tiles \
	parts-gridfinity-bins \
	parts-hole-shelves \
	parts-hooks \
	parts-pliers-hangers \
	parts-shelf-brackets \
	parts-shelves \
	parts-slot-shelves \
	parts-tiles
clean-parts: \
	clean-parts-bins \
	clean-parts-bolts \
	clean-parts-cups \
	clean-parts-grid-tiles \
	clean-parts-gridfinity-bins \
	clean-parts-hole-shelves \
	clean-parts-hooks \
	clean-parts-pliers-hangers \
	clean-parts-shelf-brackets \
	clean-parts-shelves \
	clean-parts-slot-shelves \
	clean-parts-tiles
.PHONY: parts clean-parts


#
# Tiles
#
TILE_DIR = $(BUILD_DIR)/tile
TILE_SIZES = 1x1 2x2 4x4 4x5 5x4 5x5 5x6 6x5 6x6
TILE_FILL_OPTIONS = top bottom left right
TILE_FILL_PERMUTATIONS = $(shell \
  for i in "" $(TILE_FILL_OPTIONS); do \
       for j in "" $(TILE_FILL_OPTIONS); do \
         for k in "" $(TILE_FILL_OPTIONS); do \
           for l in "" $(TILE_FILL_OPTIONS); do \
             echo "$$i $$j $$k $$l" | tr ' ' '\n' | grep -v '^$$' | sort -u | sed 's/^/fill_/' | paste -sd '_' -; \
           done; \
         done; \
       done; \
     done \
  | sort -u)

TILES = $(foreach size,$(TILE_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(TILE_DIR)/$(variant)/tile-$(size)-$(variant).stl \
				$(foreach fill,$(TILE_FILL_PERMUTATIONS), \
					$(TILE_DIR)/$(variant)/tile-$(size)-$(variant)-$(fill).stl \
				) \
			) \
		)

$(BUILD_DIR)/tile/%.stl: tile.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst tile-,,$(API_FN)))))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	$(eval FILL_TOP := $(if $(findstring fill_top,$(API_FN)),-D 'fill_top=true',))
	$(eval FILL_BOTTOM := $(if $(findstring fill_bottom,$(API_FN)),-D 'fill_bottom=true',))
	$(eval FILL_LEFT := $(if $(findstring fill_left,$(API_FN)),-D 'fill_left=true',))
	$(eval FILL_RIGHT := $(if $(findstring fill_right,$(API_FN)),-D 'fill_right=true',))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ tile.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'columns=$(TILE_COLUMNS)' \
		-D 'rows=$(TILE_ROWS)' \
		$(FILL_TOP) $(FILL_BOTTOM) $(FILL_LEFT) $(FILL_RIGHT)

parts-tiles: $(TILES)
clean-parts-tiles:
	rm -rf $(TILE_DIR)
.PHONY: parts-tiles clean-parts-tiles


#
# Grid tiles
#
GRID_TILE_DIR = $(BUILD_DIR)/grid-tile
GRID_TILES = $(foreach size,$(TILE_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(GRID_TILE_DIR)/$(variant)/grid-tile-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/grid-tile/%.stl: grid_tile.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst grid-tile-,,$(API_FN)))))
	$(eval TILE_COLUMNS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval TILE_ROWS := $(word 2,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ grid_tile.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'columns=$(TILE_COLUMNS)' \
		-D 'rows=$(TILE_ROWS)'

parts-grid-tiles: $(GRID_TILES)
clean-parts-grid-tiles:
	rm -rf $(GRID_TILE_DIR)
.PHONY: parts-grid-tiles clean-parts-grid-tiles


#
# Bolts
#
BOLT_DIR = $(BUILD_DIR)/bolt
BOLT_LENGTHS= 9 16
BOLTS = $(foreach length,$(BOLT_LENGTHS),$(BOLT_DIR)/bolt-$(length).stl)

$(BUILD_DIR)/bolt/%.stl: bolt.scad
	$(eval LENGTH := $(subst bolt-,,$*))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ bolt.scad \
		-D 'length=$(LENGTH)'

parts-bolts: $(BOLTS)
clean-parts-bolts:
	rm -rf $(BOLT_DIR)
.PHONY: parts-bolts clean-parts-bolts


#
# Hooks
#
HOOK_DIR = $(BUILD_DIR)/hook
HOOK_SIZES= 10x10 10x20 10x30 10x40 10x50 10x60 20x10 20x20 20x30 20x40 20x50 20x60 20x70 20x80
HOOKS = $(foreach size,$(HOOK_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(HOOK_DIR)/$(variant)/hook-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/hook/%.stl: hook.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst hook-,,$(API_FN)))))
	$(eval HOOK_WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval HOOK_SHANK_LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ hook.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'hooks=1' \
		-D 'width=$(HOOK_WIDTH)' \
		-D 'shank_length=$(HOOK_SHANK_LENGTH)'

parts-hooks: $(HOOKS)
clean-parts-hooks:
	rm -rf $(HOOK_DIR)
.PHONY: parts-hooks clean-parts-hooks


#
# Pliers hangers (default size, both cleat variants)
#
PLIERS_HANGER_DIR = $(BUILD_DIR)/pliers-hanger
PLIERS_HANGERS = $(foreach variant,$(VARIANTS), \
	$(PLIERS_HANGER_DIR)/$(variant)/pliers-hanger-24x25x18-$(variant).stl)

$(PLIERS_HANGERS): $(PLIERS_HANGER_DIR)/%.stl: pliers_hanger.scad hanger.scad constants.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval VARIANT_NUM := $(if $(filter original,$(VARIANT)),0,1))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ pliers_hanger.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'width=24' \
		-D 'depth=25' \
		-D 'height=18' \
		-D 'tip_width=4' \
		-D 'lip_height=4' \
		-D 'lip_thickness=3' \
		-D 'rounding=1' \
		-D 'hanger_tolerance=0.15'

parts-pliers-hangers: $(PLIERS_HANGERS)
clean-parts-pliers-hangers:
	rm -rf $(PLIERS_HANGER_DIR)
.PHONY: parts-pliers-hangers clean-parts-pliers-hangers


#
# Shelves
#
SHELF_DIR = $(BUILD_DIR)/shelf
SHELF_SIZES = 83.5x30 83.5x60 125.5x30 125.5x60
SHELVES = $(foreach size,$(SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(SHELF_DIR)/$(variant)/shelf-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/shelf/%.stl: shelf.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst shelf-,,$(API_FN)))))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'width=$(WIDTH)' \
		-D 'depth=$(DEPTH)'

parts-shelves: $(SHELVES)
clean-parts-shelves:
	rm -rf $(SHELF_DIR)
.PHONY: parts-shelves clean-parts-shelves


#
# Hole shelves
#
HOLE_SHELF_DIR = $(BUILD_DIR)/hole-shelf
HOLE_SHELF_SIZES = 1x3 1x5 1x8 2x3 2x5 2x8
HOLE_SHELVES = $(foreach size,$(HOLE_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(HOLE_SHELF_DIR)/$(variant)/hole-shelf-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/hole-shelf/%.stl: hole_shelf.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst hole-shelf-,,$(API_FN)))))
	$(eval ROWS := $(word 1,$(subst x, ,$(SIZE))))
	$(eval COLUMNS := $(word 2,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ hole_shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'rows=$(ROWS)' \
		-D 'columns=$(COLUMNS)'

parts-hole-shelves: $(HOLE_SHELVES)
clean-parts-hole-shelves:
	rm -rf $(HOLE_SHELF_DIR)
.PHONY: parts-hole-shelves clean-parts-hole-shelves


#
# Slot shelves
#
SLOT_SHELF_DIR = $(BUILD_DIR)/slot-shelf
SLOT_SHELF_SIZES = 10x40x4 10x40x8 20x60x4 20x60x8
SLOT_SHELVES = $(foreach size,$(SLOT_SHELF_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(SLOT_SHELF_DIR)/$(variant)/slot-shelf-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/slot-shelf/%.stl: slot_shelf.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst slot-shelf-,,$(API_FN)))))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval LENGTH := $(word 2,$(subst x, ,$(SIZE))))
	$(eval SLOTS := $(word 3,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ slot_shelf.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'slot_width=$(WIDTH)' \
		-D 'slot_length=$(LENGTH)' \
		-D 'slots=$(SLOTS)'

parts-slot-shelves: $(SLOT_SHELVES)
clean-parts-slot-shelves:
	rm -rf $(SLOT_SHELF_DIR)
.PHONY: parts-slot-shelves clean-parts-slot-shelves


#
# Bins
#
BIN_DIR = $(BUILD_DIR)/bin
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
				$(BIN_DIR)/$(variant)/bin-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/bin/%.stl: bin.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst bin-,,$(API_FN)))))
	$(eval WIDTH := $(word 1,$(subst x, ,$(SIZE))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(SIZE))))
	$(eval HEIGHT := $(word 3,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ bin.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'width=$(WIDTH)' \
		-D 'depth=$(DEPTH)' \
		-D 'height=$(HEIGHT)'

parts-bins: $(BINS)
clean-parts-bins:
	rm -rf $(BIN_DIR)
.PHONY: parts-bins clean-parts-bins


#
# Gridfinity bins
#
GRIDFINITY_BIN_DIR = $(BUILD_DIR)/gridfinity-bin
GRIDFINITY_BIN_X = 1 2 3 4 5 6
GRIDFINITY_BIN_Y = 1 2 3 4 5 6
GRIDFINITY_BIN_Z = 3 4 5 6 7

GRIDFINITY_BIN_SIZES = $(foreach x,$(GRIDFINITY_BIN_X),$(foreach y,$(GRIDFINITY_BIN_Y),$(foreach z,$(GRIDFINITY_BIN_Z),$(x)x$(y)x$(z))))

GRIDFINITY_BINS = $(foreach size,$(GRIDFINITY_BIN_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(GRIDFINITY_BIN_DIR)/$(variant)/gridfinity-bin-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/gridfinity-bin/%.stl: gridfinity_bin.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst gridfinity-bin-,,$(API_FN)))))
	$(eval GRIDX := $(word 1,$(subst x, ,$(SIZE))))
	$(eval GRIDY := $(word 2,$(subst x, ,$(SIZE))))
	$(eval GRIDZ := $(word 3,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ gridfinity_bin.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'bin_gridx=$(GRIDX)' \
		-D 'bin_gridy=$(GRIDY)' \
		-D 'bin_gridz=$(GRIDZ)'

parts-gridfinity-bins: $(GRIDFINITY_BINS)
clean-parts-gridfinity-bins:
	rm -rf $(GRIDFINITY_BIN_DIR)
.PHONY: parts-gridfinity-bins clean-parts-gridfinity-bins


#
# Shelf brackets
#
SHELF_BRACKET_DIR = $(BUILD_DIR)/shelf-bracket
SHELF_BRACKET_HEIGHTS = 1 2 3
SHELF_BRACKET_WIDTHS = 41.5 28.0
SHELF_BRACKET_SHORT_DEPTHS = 50 75
SHELF_BRACKET_MEDIUM_DEPTHS = 100 150
SHELF_BRACKET_LARGE_DEPTHS = 200 250 300

# $(1)=height $(2)=variant $(3)=depth $(4)=top_holes $(5)=width
SHELF_BRACKET_FILES = \
	$(SHELF_BRACKET_DIR)/$(2)/no_mounting_holes/shelf-bracket-$(1)x$(3)x$(5)-$(2).stl \
	$(SHELF_BRACKET_DIR)/$(2)/mounting_holes/shelf-bracket-$(1)x$(3)x$(5)-$(2)-top_mounting_holes_$(4).stl

SHELF_BRACKETS = \
	$(foreach h,$(SHELF_BRACKET_HEIGHTS),\
		$(foreach v,$(VARIANTS),\
			$(foreach d,$(SHELF_BRACKET_SHORT_DEPTHS),\
				$(foreach w,$(SHELF_BRACKET_WIDTHS),$(call SHELF_BRACKET_FILES,$(h),$(v),$(d),1,$(w)))) \
			$(foreach d,$(SHELF_BRACKET_MEDIUM_DEPTHS),\
				$(foreach w,$(SHELF_BRACKET_WIDTHS),$(call SHELF_BRACKET_FILES,$(h),$(v),$(d),2,$(w)))) \
			$(foreach d,$(SHELF_BRACKET_LARGE_DEPTHS),\
				$(foreach w,$(SHELF_BRACKET_WIDTHS),$(call SHELF_BRACKET_FILES,$(h),$(v),$(d),3,$(w))))))

$(BUILD_DIR)/shelf-bracket/%.stl: shelf_bracket.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval HEIGHT_DEPTH_WIDTH := $(word 1,$(subst -, ,$(subst shelf-bracket-,,$(API_FN)))))
	$(eval HEIGHT_UNITS := $(word 1,$(subst x, ,$(HEIGHT_DEPTH_WIDTH))))
	$(eval DEPTH := $(word 2,$(subst x, ,$(HEIGHT_DEPTH_WIDTH))))
	$(eval WIDTH := $(word 3,$(subst x, ,$(HEIGHT_DEPTH_WIDTH))))
	$(eval TOP_HOLES := 0)
	$(eval TOP_HOLES := $(if $(findstring top_mounting_holes_1,$(API_FN)),1,$(TOP_HOLES)))
	$(eval TOP_HOLES := $(if $(findstring top_mounting_holes_2,$(API_FN)),2,$(TOP_HOLES)))
	$(eval TOP_HOLES := $(if $(findstring top_mounting_holes_3,$(API_FN)),3,$(TOP_HOLES)))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ shelf_bracket.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'height_units=$(HEIGHT_UNITS)' \
		-D 'depth=$(DEPTH)' \
		-D 'width=$(WIDTH)' \
		-D 'top_mounting_holes=$(TOP_HOLES)'

parts-shelf-brackets: $(SHELF_BRACKETS)
clean-parts-shelf-brackets:
	rm -rf $(SHELF_BRACKET_DIR)
.PHONY: parts-shelf-brackets clean-parts-shelf-brackets


#
# Cups
#
CUP_DIR = $(BUILD_DIR)/cup
CUP_SIZES = 37.5x20 37.5x42
CUPS = $(foreach size,$(CUP_SIZES), \
			$(foreach variant,$(VARIANTS), \
				$(CUP_DIR)/$(variant)/cup-$(size)-$(variant).stl \
			) \
		)

$(BUILD_DIR)/cup/%.stl: cup.scad
	$(eval VARIANT := $(word 1,$(subst /, ,$*)))
	$(eval API_FN := $(notdir $*))
	$(eval VARIANT_NUM := $(shell echo $(VARIANT) | awk '{if ($$1 == "original") print 0; else print 1;}'))
	$(eval SIZE := $(word 1,$(subst -, ,$(subst cup-,,$(API_FN)))))
	$(eval INNER_DIAMETER := $(word 1,$(subst x, ,$(SIZE))))
	$(eval HEIGHT := $(word 2,$(subst x, ,$(SIZE))))
	mkdir -p $(dir $@)
	$(OPENSCAD) $(OPENSCAD_ARGS) \
		-o $@ cup.scad \
		-D 'variant=$(VARIANT_NUM)' \
		-D 'inner_diameter=$(INNER_DIAMETER)' \
		-D 'height=$(HEIGHT)'

parts-cups: $(CUPS)
clean-parts-cups:
	rm -rf $(CUP_DIR)
.PHONY: parts-cups clean-parts-cups

clean: clean-parts
	rm -rf $(VIRTUALENV_DIR) $(FRONTEND_ENV) $(FRONTEND_DIST)

.PHONY: clean
