# Tiger Detection System — Safety Goals

First link in the sphinx-needs chain `0-safety-goals` → `1-sys-req` → `3-sw-req`.

This project defines its needs locally and pulls in no external needs, so it has
no upstream dependency. Both downstream projects consume its export, which means
a change to a safety goal here requires rebuilding the whole chain.

## Build

```bash
cd ../build_scripts
python build_needs.py
```

Setup, build order, and the reasoning behind both live in
[`../build_scripts/README.md`](../build_scripts/README.md).

## Output

- `build_ref/needs.json` — tracked needs export; read by RIA imports and by both
  downstream projects
- `_build/html/index.html` — browsable HTML documentation, from
  `build_needs.py --html` (untracked)
