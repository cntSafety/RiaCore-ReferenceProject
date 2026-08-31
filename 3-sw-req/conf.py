from pathlib import Path

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
    # Preserve the task origin on imported system requirements.
    "originating_task": {
        "description": "Stable reference of the analysis task that generated a requirement",
        "schema": {"type": "string"},
    },
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
        "base_url": (Path(__file__).resolve().parent.parent / "0-safety-goals" / "_build" / "html").as_uri(),
        "json_path": "../0-safety-goals/build_ref/needs.json",
        "id_prefix": "",
        "css_class": "safety_goal_link",
        "version": "1.0.0",
    },
    {
        # Absolute path for local file:// browsing.
        # Note: For a real deployment (web server), replace the file:/// URL with
        # the actual hosted URL like https://docs.example.com/sys-req/.
        # The file:// approach works for local browsing during development.
        "base_url": (Path(__file__).resolve().parent.parent / "1-sys-req" / "_build" / "html").as_uri(),
        # json_path: relative to conf.py
        "json_path": "../1-sys-req/build_ref/needs.json",
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


def _copy_needs_json(app, exception):
    """Keep the tracked importer input in sync with successful Sphinx builds."""
    if exception is not None:
        return
    source = Path(app.outdir) / "needs.json"
    if source.exists():
        import shutil
        target = Path(app.confdir) / "build_ref" / "needs.json"
        target.parent.mkdir(exist_ok=True)
        shutil.copy2(source, target)


def setup(app):
    app.connect("build-finished", _copy_needs_json)
