# Tiger Detection System - System Requirements

Standalone Sphinx + sphinx-needs project containing the system-level requirements
for the Tiger Detection System (TDS).

Second link in the chain `0-safety-goals` → `1-sys-req` → `3-sw-req`. It pulls the
safety goals in as external needs and exports the system requirements for
`3-sw-req` to consume.

## Build

Do not build this project on its own — it has an upstream dependency, and its
downstream consumer needs rebuilding after any change here. Use the chain
builder:

```bash
cd ../build_scripts
python build_needs.py
```

Setup, build order, and the reasoning behind both live in
[`../build_scripts/README.md`](../build_scripts/README.md).

## Output

- `build_ref/needs.json` — tracked needs export; the input for RIA imports and
  for `3-sw-req`
- `_build/html/index.html` — browsable HTML documentation, from
  `build_needs.py --html` (untracked)

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
