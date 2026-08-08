# Tiger Detection System - System Requirements

Standalone Sphinx + sphinx-needs project containing the system-level requirements
for the Tiger Detection System (TDS).

## Prerequisites

- Python 3.9+
- pip

## Setup

```bash
# Create and activate a virtual environment
python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/macOS
# source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Build

```bash
# Generate HTML + needs.json
sphinx-build -b html . _build/html

# Or generate only needs.json (no HTML)
sphinx-build -b needs . _build/needs
```

The generated `_build/html/needs.json` is consumed by downstream projects.

## Output

After building, the following outputs are available:

- `_build/html/index.html` — Browsable HTML documentation
- `_build/html/needs.json` — Machine-readable needs export (used by `3-sw-req`)

## Requirement ID Convention

All system requirements use the prefix `TDS_` followed by a category code:

| Prefix | Category |
|--------|----------|
| `TDS_SAF_` | Safety |
| `TDS_OPS_` | Operational |
| `TDS_SEN_` | Sensor |
| `TDS_ALG_` | Algorithm |
| `TDS_WRN_` | Warning |
| `TDS_ENV_` | Environmental |


