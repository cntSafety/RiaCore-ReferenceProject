# Tiger Detection System — SW Requirements (sphinx-needs)

Software-level requirements for the multi-sensor tiger detection system, managed
with [sphinx-needs](https://sphinx-needs.readthedocs.io/). SW requirements are
solution-agnostic — no AUTOSAR-specific language.

Last link in the chain `0-safety-goals` → `1-sys-req` → `3-sw-req`. It pulls both
upstream exports in as external needs and has no downstream consumer in the
sphinx chain.

## Build

Both of this project's inputs are generated, so building it alone can silently
re-export stale upstream needs. Use the chain builder:

```bash
cd ../build_scripts
python build_needs.py
```

Setup, build order, and the reasoning behind both live in
[`../build_scripts/README.md`](../build_scripts/README.md).

## Output

- `build_ref/needs.json` — tracked needs export; the file RIA imports read
- `_build/html/index.html` — browsable HTML documentation, from
  `build_needs.py --html` (untracked)

## Project structure

```
3-sw-req/
├── conf.py                          # Sphinx + sphinx-needs configuration
├── config.rst                       # Documents the sphinx-needs setup
├── index.rst                        # Root toctree
├── requirements/
│   └── swRequirements.rst           # SW requirements
└── README.md
```

Diagrams use graphviz, not PlantUML: `conf.py` sets
`needs_flow_engine = "graphviz"`, so no external PlantUML jar is needed.

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
