# Tiger Detection System — Safety Goals

First link in the sphinx-needs chain: `0-safety-goals` → `1-sys-req` → `3-sw-req`.
Setup, conventions, and the full build story live in
[`../1-sys-req/README.md`](../1-sys-req/README.md).

## Regenerating needs.json

```bash
# Only needs.json, no HTML
sphinx-build -b needs . _build/needs

# HTML + needs.json
sphinx-build -b html . _build/html
```

Either command regenerates `build_ref/needs.json` — sphinx-needs writes
`needs.json` into the build output directory and the `build-finished` hook in
`conf.py` copies it into `build_ref/`, which is the tracked file RIA imports and
the downstream projects read.

This project defines its needs locally and pulls in no external needs, so editing
an `.rst` here is picked up by a plain incremental build; `-E` is not required.

After changing a safety goal, rebuild the downstream projects too — they consume
this export as *external* needs and **do** need `-E` to pick it up. See
[`../1-sys-req/README.md`](../1-sys-req/README.md).
