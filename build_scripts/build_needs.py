#!/usr/bin/env python3
"""Build the sphinx-needs chain of the reference project in dependency order.

The three sphinx projects form a chain, each consuming the previous one's
export as *external* needs:

    0-safety-goals  ->  1-sys-req  ->  3-sw-req

Order is not optional. Building 3-sw-req before 1-sys-req re-exports whatever
1-sys-req last wrote, which may predate the change being propagated. This
script exists so the order cannot be got wrong by hand.

Every build passes ``-E``. Sphinx does not track the external ``needs.json``
files when deciding what is out of date, so after an upstream change an
incremental build finds no modified ``.rst``, reuses the cached environment in
``_build/.../.doctrees/``, and silently re-exports the *old* external needs.
``-E`` discards that cache. A chain build that omitted it would appear to
succeed while propagating nothing.

Note that 2-sys-design is absent on purpose: it is a SysML model exported
through a Jupyter kernel (see ``2-sys-design/export_model.py``), produces
``TigerDetectionSystem.json`` rather than ``needs.json``, and shares none of
this toolchain.

Usage
-----
    python build_needs.py              # needs.json for the whole chain
    python build_needs.py --html       # HTML + needs.json for the whole chain
    python build_needs.py --project 1-sys-req
                                       # one link, plus everything upstream of it
    python build_needs.py --list       # show the chain and exit

The interpreter used to launch this script does not matter; it locates the
virtual environment next to itself and builds with that.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Dependency order. Index matters: --project builds this list up to and
# including the named entry, because a link is only correct if everything
# upstream of it is current.
CHAIN: tuple[str, ...] = (
    "0-safety-goals",
    "1-sys-req",
    "3-sw-req",
)


def venv_python() -> Path:
    """Return the interpreter of the virtual environment in this folder."""
    candidates = (
        SCRIPT_DIR / ".venv" / "Scripts" / "python.exe",  # Windows
        SCRIPT_DIR / ".venv" / "bin" / "python",  # Linux / macOS
    )
    for candidate in candidates:
        if candidate.is_file():
            return candidate

    activate = (
        r".venv\Scripts\activate"
        if sys.platform == "win32"
        else "source .venv/bin/activate"
    )
    sys.exit(
        f"No virtual environment found in {SCRIPT_DIR}.\n"
        f"Create it once:\n"
        f"    cd {SCRIPT_DIR}\n"
        f"    python -m venv .venv\n"
        f"    {activate}\n"
        f"    pip install -r requirements.txt"
    )


def check_sphinx_needs(python: Path) -> None:
    """Fail early and legibly when the environment is not provisioned."""
    probe = subprocess.run(
        [str(python), "-c", "import sphinx, sphinx_needs"],
        capture_output=True,
        text=True,
    )
    if probe.returncode != 0:
        sys.exit(
            f"The virtual environment at {python.parent.parent} is missing "
            f"sphinx and/or sphinx-needs.\n"
            f"Install them:\n"
            f"    {python} -m pip install -r {SCRIPT_DIR / 'requirements.txt'}"
        )


def build(python: Path, project: str, builder: str) -> None:
    source = PROJECT_ROOT / project
    if not (source / "conf.py").is_file():
        sys.exit(f"{source} has no conf.py — not a sphinx project.")

    output = source / "_build" / builder
    # -E rebuilds from scratch; see the module docstring for why it is not
    # optional here.
    command = [
        str(python),
        "-m",
        "sphinx",
        "-E",
        "-b",
        builder,
        str(source),
        str(output),
    ]

    print(f"\n=== {project}  ({builder}) ".ljust(70, "=") + "\n", flush=True)
    started = time.perf_counter()
    result = subprocess.run(command, cwd=source)
    elapsed = time.perf_counter() - started

    if result.returncode != 0:
        # Stop the chain: a downstream project built against a failed upstream
        # export would produce a misleading success.
        sys.exit(
            f"\n{project} failed after {elapsed:.1f}s "
            f"(sphinx exit code {result.returncode}). Chain stopped."
        )

    print(f"\n{project} ok in {elapsed:.1f}s", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build the sphinx-needs chain in dependency order.",
        epilog="Builds always use -E, so an upstream change reliably propagates.",
    )
    parser.add_argument(
        "--html",
        action="store_true",
        help="build HTML as well as needs.json (default: needs.json only)",
    )
    parser.add_argument(
        "--project",
        choices=CHAIN,
        help="build up to and including this project, skipping downstream ones",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="print the build order and exit",
    )
    args = parser.parse_args()

    if args.list:
        print("Build order:")
        for position, project in enumerate(CHAIN, start=1):
            print(f"  {position}. {project}")
        print("\n2-sys-design is not part of this chain (SysML, not sphinx).")
        return

    # Upstream projects are included even when --project names a later link,
    # since a link is only correct if its inputs are current.
    if args.project:
        selected = CHAIN[: CHAIN.index(args.project) + 1]
    else:
        selected = CHAIN

    builder = "html" if args.html else "needs"

    python = venv_python()
    check_sphinx_needs(python)

    print(f"Environment: {python}")
    print(f"Build order: {' -> '.join(selected)}")

    started = time.perf_counter()
    for project in selected:
        build(python, project, builder)
    total = time.perf_counter() - started

    print("\n" + "=" * 70)
    print(f"Chain built in {total:.1f}s. Exports refreshed:")
    for project in selected:
        print(f"  {project}/build_ref/needs.json")
    if args.html:
        print("\nHTML output:")
        for project in selected:
            print(f"  {project}/_build/html/index.html")
    print(
        "\nbuild_ref/needs.json always shows as modified in git after a build: "
        "the export embeds a `created` timestamp, which changes even when no "
        "requirement did."
    )


if __name__ == "__main__":
    main()
