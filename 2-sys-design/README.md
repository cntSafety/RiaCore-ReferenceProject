# Tiger Detection System — System Design (SysML v2)

Behavioral and interface specification of the monitored RGB + LWIR + lidar
reference architecture, written in SysML v2.

## Not part of the sphinx-needs chain

This project shares no toolchain with its numbered neighbours. It produces
`TigerDetectionSystem.json` from a SysML model, not a `needs.json` from Sphinx,
so `build_scripts/build_needs.py` does not touch it and the venv in
`build_scripts/` does not cover it. The needs chain is
`0-safety-goals` → `1-sys-req` → `3-sw-req`.

The link to the requirements is by reference rather than by build: the model
names system requirement IDs (`TDS_ALG_004`, `TDS_WRN_003`, …) in its `doc`
comments, and SW requirements trace to those IDs through their RST `satisfies`
attributes in `3-sw-req`.

## Contents

| file | role |
|---|---|
| `tiger.sysml` | the model source — the file to edit |
| `TigerDetectionSystem.json` | tracked export, regenerated from the source |
| `tiger.ipynb` | notebook view, kept synchronized with the source |
| `export_model.py` | validates the source and regenerates the two files above |

## Regenerating the export

```bash
python export_model.py
```

Requires `jupyter-client` and an installed SysML v2 Jupyter kernel named
`sysml`. Set `SYSML_KERNEL_DIR` to point at an isolated kernels directory
containing `sysml/kernel.json` if the kernel is not on the default search path.

The script validates `tiger.sysml` first and raises rather than writing when
validation or export fails, so a broken model leaves the existing
`TigerDetectionSystem.json` in place. It also rewrites `tiger.ipynb` on success:
the first cell is replaced with the current model source, and all code cell
outputs and execution counts are cleared.

## Scope

This is an interface and behavior specification, not executable perception
software and not validated safety evidence. A healthy status in the model does
not establish SOTIF performance for every pose, target size, or thermal
contrast.
