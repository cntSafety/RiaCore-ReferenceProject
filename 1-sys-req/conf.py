from pathlib import Path

# -- Sphinx Configuration for Tiger Detection System - System Requirements --
# This is the system-level requirements project.
# The SW team can reference these needs via needs_external_needs or needimport.

project = "Tiger Detection System - System Requirements"
author = "TDS Systems Engineering Team"
release = "1.0.0"

# -- Extensions -----------------------------------------------------------
extensions = [
    "sphinx_needs",
]

needs_flow_engine = "graphviz"

# -- Sphinx-Needs Configuration -------------------------------------------

needs_types = [
    dict(
        directive="req",
        title="System Requirement",
        prefix="TDS_",
        color="#BFD8D2",
        style="node",
    ),
]

# Require explicit IDs on every need
needs_id_required = True

# ID validation pattern
needs_id_regex = "^[A-Z][A-Z0-9_]{3,}"

# Build needs.json alongside the HTML output (written into the build dir)
needs_build_json = True

# Version tag for needs.json (used by downstream projects)
version = "1.0.0"

# Custom fields for system-level attributes
needs_fields = {
    "originating_task": {
        "description": "Stable reference of the analysis task that generated this requirement",
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

# Link types
needs_links = {
    "refines": {
        "incoming": "is refined by",
        "outgoing": "refines",
        "copy": False,
        "style": "#6600AA",
        "style_start": "-",
        "style_end": "->",
    },
}

# -- External Needs (Safety Goals from 0-safety-goals) ---------------------
# The safety goals (e.g. TDS_SAF_001) live in a SEPARATE sphinx-needs build
# (0-safety-goals). System requirements here link to them via `refines`.
# needs_external_needs pulls in those needs from the other project's
# generated needs.json without re-authoring them locally, so cross-build
# links like `:refines: TDS_SAF_001` resolve to the safety-goals build.
#
# Build 0-safety-goals FIRST to generate its needs.json, then build this
# project.
needs_external_needs = [
    {
        # base_url: where the safety-goals HTML is served. Absolute file:// URL
        # works for local browsing; for a hosted deployment replace it with the
        # real URL (e.g. https://docs.example.com/safety-goals/).
        "base_url": (Path(__file__).resolve().parent.parent / "0-safety-goals" / "_build" / "html").as_uri(),
        # json_path: relative to this conf.py.
        "json_path": "../0-safety-goals/build_ref/needs.json",
        "id_prefix": "",
        "css_class": "safety_goal_link",
        "version": "1.0.0",
    },
]

# Table defaults
needs_table_style = "datatables"
needs_table_columns = "id;title;status;tags;outgoing"

# -- General Sphinx settings -----------------------------------------------
exclude_patterns = ["_build", ".venv", "Thumbs.db", ".DS_Store"]
# Silence non-fatal warnings raised while loading the external needs.json.
suppress_warnings = ["needs.json_load", "needs.load_external_need"]

# Furo provides native light/dark mode: it follows the OS prefers-color-scheme
# setting and adds a light/dark toggle button. No custom CSS required.
html_theme = "furo"

html_theme_options = {
    # Palette tweaks per mode. Defaults are sensible; these just ensure the
    # sphinx-needs tables/links stay readable in both modes.
    "light_css_variables": {
        "color-brand-primary": "#0a6e6e",
        "color-brand-content": "#0a6e6e",
    },
    "dark_css_variables": {
        "color-brand-primary": "#5ec8c8",
        "color-brand-content": "#5ec8c8",
    },
}

# Custom CSS: integrates sphinx-needs need rendering with Furo's dark mode.
html_static_path = ["_static"]
html_css_files = ["custom.css"]

# -- Copy needs.json into build_ref/ after the build ----------------------
# Git tracks only the generated needs.json (in build_ref/), not the full HTML
# export. sphinx-needs writes needs.json into the build output dir, so after
# each build we copy it into build_ref/ next to this conf.py. Downstream
# import configs and tests point at 1-sys-req/build_ref/needs.json.
import logging
import os
import shutil


def _copy_needs_json(app, exception):
    # Skip if the build failed.
    if exception is not None:
        return

    source = os.path.join(app.outdir, "needs.json")
    if not os.path.exists(source):
        logging.getLogger(__name__).warning(
            "needs.json not found in %s; nothing copied to build_ref/", app.outdir
        )
        return

    dest_dir = os.path.join(app.confdir, "build_ref")
    os.makedirs(dest_dir, exist_ok=True)
    shutil.copy2(source, os.path.join(dest_dir, "needs.json"))
    logging.getLogger(__name__).info("Copied needs.json to %s", dest_dir)


def setup(app):
    app.connect("build-finished", _copy_needs_json)
