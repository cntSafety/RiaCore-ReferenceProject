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
# HTML + needs.json
sphinx-build -b html . _build/html

# Only needs.json, no HTML — this is all RIA and the downstream projects need
sphinx-build -b needs . _build/needs
```

Either command regenerates `build_ref/needs.json`: sphinx-needs writes
`needs.json` into the build output directory, and the `build-finished` hook at the
bottom of `conf.py` copies it into `build_ref/`. `_build/` is gitignored, so
`build_ref/needs.json` is the only generated artifact under version control, and
it is the file every importer and test reads.

Do **not** point the output directory at `build_ref` (`-b needs . build_ref`). The
hook would then try to copy `needs.json` onto itself and the build fails in
`build-finished` (`WinError 32` on Windows, `SameFileError` elsewhere). It also
litters `build_ref/` with `.doctrees/` and `_static/`.

## Regenerating needs.json after an upstream change

Build the chain in order — each project's export feeds the next:

```bash
cd ../0-safety-goals && sphinx-build -E -b needs . _build/needs
cd ../1-sys-req     && sphinx-build -E -b needs . _build/needs
cd ../3-sw-req      && sphinx-build -E -b needs . _build/needs
```

`-E` matters here, and is the reason a plain rebuild can appear to do nothing.
This project pulls the safety goals in as *external* needs
(`needs_external_needs` → `../0-safety-goals/build_ref/needs.json`). Sphinx does
not track that file when deciding what is out of date, so after an upstream
change it finds no modified `.rst`, reuses the cached environment in
`_build/…/.doctrees/`, and re-exports the **old** external needs. `-E` discards
that cache and re-reads everything — the same effect as deleting `_build` by hand,
without deleting anything.

Within a single project, editing a local `.rst` is detected normally and `-E` is
not needed.

Note that `build_ref/needs.json` always shows as modified in git after a build:
the export embeds a `created` timestamp, which changes even when no requirement
did. `creator.version` also records the `sphinx-needs` version that produced it,
so an environment resolving a different version than the last committed build
will show that as a diff too.

## Output

- `build_ref/needs.json` — tracked needs export; the input for RIA imports and
  for downstream projects (`3-sw-req`)
- `_build/html/index.html` — browsable HTML documentation (untracked)
- `_build/html/needs.json` — the build's own copy, before the hook copies it
  into `build_ref/` (untracked)

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


