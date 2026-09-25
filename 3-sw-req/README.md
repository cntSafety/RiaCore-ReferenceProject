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

To generate *only* the JSON (no HTML):

```bash
sphinx-build -b needs . _build/needs
```

### Where needs.json ends up

`needs_build_json = True` in `conf.py` makes sphinx-needs write `needs.json` into
the build output directory, and the `build-finished` hook at the bottom of
`conf.py` then copies it into `build_ref/`. Since `_build/` is gitignored,
`build_ref/needs.json` is the tracked artifact and the file RIA imports read.

Do **not** point the output directory at `build_ref` — the hook would try to copy
`needs.json` onto itself and the build fails in `build-finished`.

### Regenerating after an upstream change

This project pulls both the safety goals and the system requirements in as
*external* needs (`needs_external_needs` → `../0-safety-goals/build_ref/needs.json`
and `../1-sys-req/build_ref/needs.json`), so rebuild the whole chain in order:

```bash
cd ../0-safety-goals && sphinx-build -E -b needs . _build/needs
cd ../1-sys-req      && sphinx-build -E -b needs . _build/needs
cd ../3-sw-req       && sphinx-build -E -b needs . _build/needs
```

`-E` is what makes an upstream change take effect. Sphinx does not track those
external JSON files when deciding what is out of date, so without it the build
finds no modified `.rst`, reuses the cached environment under `_build/…/.doctrees/`,
and re-exports the **old** external needs. See `1-sys-req/README.md` for the full
explanation.

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
