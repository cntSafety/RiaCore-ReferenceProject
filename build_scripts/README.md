# Build scripts

Single place to build the sphinx-needs chain of the reference project, and the
single virtual environment all of it runs in.

## Setup

Once, on a fresh clone:

```bash
cd build_scripts
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # Linux/macOS
pip install -r requirements.txt
```

One environment covers every sphinx project in the chain — their requirements
were identical or compatible supersets, so there is no reason to install three.
`.venv/` is gitignored.

## Build

```bash
python build_needs.py              # needs.json for the whole chain
python build_needs.py --html       # HTML + needs.json for the whole chain
python build_needs.py --project 1-sys-req
                                   # one link, plus everything upstream of it
python build_needs.py --list       # show the build order and exit
```

Activating the environment is optional. The script finds `.venv` next to itself
and builds with that interpreter, so `python build_needs.py` works from a plain
system python too.

## Build order

```
0-safety-goals  ->  1-sys-req  ->  3-sw-req
```

Each project consumes the previous one's export as *external* needs, via
`needs_external_needs` in its `conf.py`:

| project | reads | writes |
|---|---|---|
| `0-safety-goals` | nothing external | `0-safety-goals/build_ref/needs.json` |
| `1-sys-req` | `0-safety-goals/build_ref/needs.json` | `1-sys-req/build_ref/needs.json` |
| `3-sw-req` | both exports above | `3-sw-req/build_ref/needs.json` |

Order is not a preference. Building `3-sw-req` before `1-sys-req` picks up
whatever `1-sys-req` last wrote, which may predate the change being propagated,
and the build still reports success. The script exists so this cannot be got
wrong by hand: the chain is a list in one place, `--project` implies everything
upstream of the named link, and a failure anywhere stops the run rather than
letting a downstream project build against a stale or failed input.

`2-sys-design` is deliberately not in the chain. It is a SysML model exported
through a Jupyter kernel (`2-sys-design/export_model.py`), it produces
`TigerDetectionSystem.json` rather than `needs.json`, and it shares none of this
toolchain. `4-sw-arch-arxml` and `5-safety` are likewise not sphinx projects.

## Why every build passes `-E`

`-E` is the reason a plain rebuild can appear to do nothing, and the script
always passes it.

Sphinx does not track the external `needs.json` files when deciding what is out
of date. After an upstream change, an incremental build of a downstream project
finds no modified `.rst`, reuses the cached environment in
`_build/…/.doctrees/`, and re-exports the **old** external needs. `-E` discards
that cache and re-reads everything — the same effect as deleting `_build` by
hand, without deleting anything.

The cost is small (the whole chain builds in a few seconds) and the failure it
prevents is silent, so there is no option to turn it off.

## Where needs.json ends up

`needs_build_json = True` makes sphinx-needs write `needs.json` into the build
output directory, and the `build-finished` hook at the bottom of each `conf.py`
copies it into that project's `build_ref/`. `_build/` is gitignored, so
`build_ref/needs.json` is the only generated artifact under version control, and
it is the file every RIA importer and test reads.

Do **not** point a build's output directory at `build_ref` (`-b needs . build_ref`).
The hook would then try to copy `needs.json` onto itself and the build fails in
`build-finished` (`WinError 32` on Windows, `SameFileError` elsewhere). It also
litters `build_ref/` with `.doctrees/` and `_static/`. The script always writes
to `_build/<builder>/`.

## Expected git noise

`build_ref/needs.json` always shows as modified after a build: the export embeds
a `created` timestamp, which changes even when no requirement did.

`creator.version` also records the `sphinx-needs` version that produced the
file. Since `requirements.txt` pins a range rather than an exact version, an
environment that resolves a different version than the last committed build will
show that as a diff too. Keeping one shared environment is what stops the three
projects in the chain from disagreeing here for no substantive reason.
