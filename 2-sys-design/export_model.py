#!/usr/bin/env python3
"""Validate tiger.sysml and export JSON using the official SysML Jupyter kernel.

Requires jupyter-client and an installed `sysml` kernel. SYSML_KERNEL_DIR may
point to an isolated kernels directory containing sysml/kernel.json.

If the kernel is installed in Conda `base`, activate that environment and run
`python export_model.py` from this directory.
"""
import base64
import json
import os
import re
import tempfile
from pathlib import Path

from jupyter_client import KernelManager
from jupyter_client.kernelspec import KernelSpecManager


def main():
    root = Path(__file__).resolve().parent
    source = (root / "tiger.sysml").read_text(encoding="utf-8")
    options = {}
    if os.environ.get("SYSML_KERNEL_DIR"):
        options["kernel_spec_manager"] = KernelSpecManager(kernel_dirs=[os.environ["SYSML_KERNEL_DIR"]])
    manager = KernelManager(kernel_name="sysml", **options)
    exported_data = None
    with tempfile.TemporaryDirectory(
        prefix="tiger-sysml-export-", ignore_cleanup_errors=True
    ) as directory:
        manager.start_kernel(cwd=directory)
        client = manager.client()
        client.start_channels()
        try:
            client.wait_for_ready(timeout=120)
            for command in (source, "%export TigerDetectionSystemExample"):
                message_id = client.execute(command, stop_on_error=True)
                failed = False
                while True:
                    message = client.get_iopub_msg(timeout=120)
                    if message.get("parent_header", {}).get("msg_id") != message_id:
                        continue
                    kind, content = message["msg_type"], message["content"]
                    if kind == "error":
                        failed = True
                        print(content, flush=True)
                    elif kind in {"stream", "display_data", "execute_result"}:
                        mime_data = content.get("data", {})
                        text = content.get("text") or mime_data.get("text/plain", "")
                        # The official kernel returns a downloadable JSON data URL,
                        # rather than writing a file into the working directory.
                        encoded = re.search(r"data:application/json;base64,([A-Za-z0-9+/=]+)",
                                            mime_data.get("text/html", ""))
                        if encoded:
                            exported_data = json.loads(base64.b64decode(encoded[1]))
                        print(text, flush=True)
                        if "ERROR:" in text or "Error:" in text:
                            failed = True
                    elif kind == "status" and content.get("execution_state") == "idle":
                        break
                while True:
                    reply = client.get_shell_msg(timeout=30)
                    if reply.get("parent_header", {}).get("msg_id") == message_id:
                        break
                if failed or reply["content"].get("status") != "ok":
                    raise RuntimeError(f"SysML validation/export failed: {reply['content']}; existing JSON was not replaced")
            data = exported_data
            if not data:
                raise RuntimeError("SysML kernel exported an empty model")
            (root / "TigerDetectionSystem.json").write_text(
                json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        finally:
            client.stop_channels()
            manager.shutdown_kernel(now=True)
    if Path(directory).exists():
        print(f"Warning: could not remove temporary kernel directory: {directory}", flush=True)
    notebook_path = root / "tiger.ipynb"
    notebook = json.loads(notebook_path.read_text(encoding="utf-8"))
    notebook["cells"][0]["source"] = source.splitlines(keepends=True)
    for cell in notebook["cells"]:
        if cell["cell_type"] == "code":
            cell["execution_count"] = None
            cell["outputs"] = []
    notebook_path.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Validated source, exported TigerDetectionSystem.json, and synchronized tiger.ipynb.")


if __name__ == "__main__":
    main()
