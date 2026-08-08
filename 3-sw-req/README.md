# Tiger Detection System — Requirements (sphinx-needs)

Reference project for managing safety requirements of a multi-sensor tiger
detection system using [sphinx-needs](https://sphinx-needs.readthedocs.io/).

## Quick start

```bash
# 1. Create and activate a virtual environment
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux / macOS

# 2. Install dependencies
pip install -r requirements.txt

# 3. Build HTML + needs.json
sphinx-build -b html . _build/html

# 4. Open the docs
start _build/html/index.html  # Windows
```

The `needs.json` file is generated automatically in `_build/html/needs.json`
because `needs_build_json = True` is set in `conf.py`.

To generate *only* the JSON (no HTML):

```bash
sphinx-build -b needs . _build/needs
```

## Project structure

```
ref-project/
├── conf.py                          # Sphinx + sphinx-needs configuration
├── config.rst                       # Documents the sphinx-needs setup
├── index.rst                        # Root toctree
├── requirements/
│   └── tigerDetectionReq.rst        # Tiger detection requirements
├── requirements.txt                 # Python dependencies
└── README.md
```

## System overview

The Tiger Detection System (TDS) combines camera, LiDAR, and infrared sensors
with detection algorithms to identify approaching tigers within a 50 m radius
and warn exploration personnel via sound and display.

Key safety target: ASIL B with ≥ 98 % detection rate for adult tigers in
daytime (cloudy + sunny) and nighttime conditions.

## Requirement IDs

| Prefix    | Area                |
|-----------|---------------------|
| TDS_SAF_  | Safety              |
| TDS_SEN_  | Sensors             |
| TDS_ALG_  | Algorithms          |
| TDS_WRN_  | Warnings            |
| TDS_ENV_  | Environment         |
