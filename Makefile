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
TILE_SIZES = 1x1 2x2 4x4 4x5 5x4 5x5 5x6 6x5 6x6
TILES = $(foreach size,$(TILE_SIZES),$(foreach variant,$(VARIANTS),$(BUILD_DIR)/tile-$(variant)-$(size).stl))

PART_HOOK = 1
HOOK_SIZES= 10x10 10x20 10x30 10x40 10x50 10x60 20x10 20x20 20x30 20x40 20x50 20x60 20x70 20x80
HOOKS = $(foreach size,$(HOOK_SIZES),$(foreach variant,$(VARIANTS),$(BUILD_DIR)/hook-$(variant)-$(size).stl))

all: tiles hooks server
.PHONY: all

# Generate all tile models
tiles: $(TILES)
.PHONY: tiles

# Generate all hook models
hooks: $(HOOKS)
.PHONY: hooks

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
