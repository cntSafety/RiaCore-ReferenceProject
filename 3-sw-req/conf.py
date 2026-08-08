# -- Sphinx Configuration for Tiger Detection System - SW Requirements --
# Reference: https://sphinx-needs.readthedocs.io/en/stable/configuration.html
#
# This is the SOFTWARE-level requirements project.
# It references system requirements from 1-sys-req via needs_external_needs.
# SW requirements are solution-agnostic (no AUTOSAR-specific language).

project = "Tiger Detection System - SW Requirements"
author = "TDS Software Team"
release = "1.0.0"
version = "1.0.0"

# -- Extensions -----------------------------------------------------------
extensions = [
    "sphinx_needs",
]

# Use graphviz for needflow diagrams (no external PlantUML jar needed)
needs_flow_engine = "graphviz"

# -- Sphinx-Needs Configuration -------------------------------------------

# Custom need types for the SW requirements project
needs_types = [
    dict(
        directive="req",
        title="SW Requirement",
        prefix="SWREQ_",
        color="#C2E0F4",
        style="node",
    ),
    dict(
        directive="test",
        title="Test Case",
        prefix="TC_",
        color="#DCB239",
        style="node",
    ),
]

# Require explicit IDs on every need
needs_id_required = True

# ID validation pattern
needs_id_regex = "^[A-Z][A-Z0-9_]{3,}"

# Build needs.json alongside the HTML output
needs_build_json = True

# Output file name for the needs builder
needs_file = "needs.json"

# Custom fields for SW-level attributes
needs_fields = {
    "safety_level": {
        "description": "ASIL classification (A, B, C, D or QM)",
        "schema": {
            "type": "string",
            "enum": ["QM", "A", "B", "C", "D"],
        },
    },
    "verification_method": {
        "description": "Verification method (analysis, review, test, inspection)",
        "schema": {
            "type": "string",
        },
    },
}

# Link types — semantic traceability relationships
needs_links = {
    "satisfies": {
        "incoming": "is satisfied by",
        "outgoing": "satisfies",
        "copy": False,
        "style": "#0000AA",
        "style_start": "-",
        "style_end": "->",
    },
    "refines": {
        "incoming": "is refined by",
        "outgoing": "refines",
        "copy": False,
        "style": "#6600AA",
        "style_start": "-",
        "style_end": "->",
    },
    "verifies": {
        "incoming": "is verified by",
        "outgoing": "verifies",
        "copy": False,
        "style": "#00AA00",
        "style_start": "-",
        "style_end": "->",
    },
}

# -- External Needs (System Requirements from 1-sys-req) -------------------
# The SW project links to system-level requirements.
# Build 1-sys-req first to generate its needs.json, then build this project.
needs_external_needs = [
    {
        # Absolute path for local file:// browsing.
        # Note: For a real deployment (web server), replace the file:/// URL with
        # the actual hosted URL like https://docs.example.com/sys-req/.
        # The file:// approach works for local browsing during development.
        "base_url": "file:///C:/sandbox/RiaCoreDev/qualification/ref-project/1-sys-req/_build/html",
        # json_path: relative to conf.py
        "json_path": "../1-sys-req/_build/html/needs.json",
        "id_prefix": "",
        "css_class": "sys_req_link",
        "version": "1.0.0",
    },
]

# Table defaults
needs_table_style = "datatables"
needs_table_columns = "id;title;status;tags;outgoing"

# -- General Sphinx settings -----------------------------------------------
exclude_patterns = ["_build", ".venv", "Thumbs.db", ".DS_Store"]
suppress_warnings = ["needs.json_load", "needs.load_external_need"]
html_theme = "alabaster"
