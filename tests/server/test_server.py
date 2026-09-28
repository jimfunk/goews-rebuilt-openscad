"""Test OpenAPI schema generation."""

import asyncio
import json
import pytest
from sanic import Sanic

import server.server
from server.openscad import OpenSCADError

app = server.server.app


@pytest.fixture
def sanic_app():
    """Return the Sanic app for testing."""
    app.config.TESTING = True
    return app


def test_openscad_error_handler():
    """Test that a failed build reports the OpenSCAD error to the client."""
    response = asyncio.run(
        server.server.openscad_error(None, OpenSCADError("ERROR: Assertion failed"))
    )

    assert response.status == 400
    assert response.body == b"ERROR: Assertion failed"


def test_openapi_schema(sanic_app):
    """Test that OpenAPI schema includes request bodies."""
    # Get OpenAPI schema
    _, response = sanic_app.test_client.get("/docs/openapi.json")

    assert response.status == 200
    data = response.json

    # Check bolt endpoint
    bolt_endpoint = data["paths"].get("/api/bolt", {})
    post = bolt_endpoint.get("post", {})
    request_body = post.get("requestBody")

    # Assert requestBody exists
    assert request_body is not None, "Request body should be present in bolt endpoint"

    # Check if BoltDefinition schema exists
    schemas = data.get("components", {}).get("schemas", {})
    assert "BoltDefinition" in schemas, "BoltDefinition schema should exist"


def test_pliers_hanger_openapi_discovery(sanic_app):
    """The live schema exposes all controls needed by the generic frontend."""
    _, response = sanic_app.test_client.get("/docs/openapi.json")
    assert response.status == 200
    data = response.json
    assert "/api/pliers_hanger" in data["paths"]
    post = data["paths"]["/api/pliers_hanger"]["post"]
    assert post["summary"] == "Pliers Hanger"
    request_content = post["requestBody"]["content"]
    request_schema = (request_content.get("application/json") or request_content["*/*"])["schema"]
    assert request_schema["$ref"] == "#/components/schemas/PliersHangerDefinition"
    response_content = post["responses"]["200"]["content"]
    assert "model/stl" in response_content or "*/*" in response_content

    schemas = data["components"]["schemas"]
    properties = schemas["PliersHangerDefinition"]["properties"]
    defaults = {
        "width": 24, "depth": 25, "height": 18, "tip_width": 4,
        "lip_height": 4, "lip_thickness": 3, "rounding": 1,
        "hanger_tolerance": 0.15, "variant": "Original",
    }
    assert set(properties) == set(defaults)
    for field, default in defaults.items():
        assert properties[field]["default"] == default
        if field != "variant":
            assert properties[field]["type"] == "number"
            assert properties[field]["description"]
    for field in ("width", "depth", "height", "tip_width"):
        assert properties[field]["exclusiveMinimum"] == 0
    for field in ("lip_height", "lip_thickness", "rounding", "hanger_tolerance"):
        assert properties[field]["minimum"] == 0
    assert "excluding" in properties["depth"]["description"].lower()
    assert "0 disables" in properties["lip_height"]["description"].lower()
    assert "0 for sharp" in properties["rounding"]["description"].lower()
    assert properties["variant"]["$ref"] == "#/components/schemas/Variant"
    assert schemas["Variant"]["enum"] == ["Original", "Thicker Cleats"]
