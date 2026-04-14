"""Test OpenAPI schema generation."""

import json
import pytest
from sanic import Sanic

import server.server

app = server.server.app


@pytest.fixture
def sanic_app():
    """Return the Sanic app for testing."""
    app.config.TESTING = True
    return app


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
