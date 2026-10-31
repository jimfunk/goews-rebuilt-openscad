"""Tests for server.openscad module."""

import asyncio

import pytest

from server.openscad import OpenSCADError, build, openscad_failure


class TestOpenSCADFailure:
    """Tests for openscad_failure."""

    def test_returns_error_line(self):
        """Test that the OpenSCAD error line is reported."""
        stderr = b"ERROR: Assertion failed\nTRACE: called by new_bin\n"
        assert str(openscad_failure(stderr, "Model generation")) == "ERROR: Assertion failed"

    def test_falls_back_without_error_line(self):
        """Test that stderr without an error line reports a generic message."""
        error = openscad_failure(b"Can't open input file 'missing.scad'!\n", "Model generation")
        assert str(error) == "Model generation failed"


class TestBuild:
    """Tests for build."""

    def test_missing_model_raises(self):
        """Test that a missing model file raises an OpenSCADError."""
        with pytest.raises(OpenSCADError):
            asyncio.run(build("missing.scad", variant=0))

    def test_openscad_assertion_is_reported(self):
        """Test that an OpenSCAD assertion reaches the caller."""
        with pytest.raises(OpenSCADError) as exc_info:
            asyncio.run(
                build("gridfinity_bin.scad", bin_enable_thumbscrew=True, bin_bottom_thickness=1.2)
            )
        assert str(exc_info.value).startswith("ERROR:")
        assert "Thumscrews are not compatible" in str(exc_info.value)
