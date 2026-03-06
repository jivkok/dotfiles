#!/usr/bin/env python3

# ==============================================================================
# Goal/requirements
# ------------------------------------------------------------------------------
# Mirror a VS Code extension into a VSCodium installation on macOS/Linux by:
#   - copying the extension directory from VS Code -> VSCodium, and
#   - copying the corresponding extension entry from VS Code's extensions.json
#     into VSCodium's extensions.json.
#
# Extension Identification
# ------------------------------------------------------------------------------
# - Extensions are identified strictly by: "publisher.name"
#   (e.g. "ms-python.python")
# - Do NOT infer or guess based on folder names alone.
#
# Target Platforms
# ------------------------------------------------------------------------------
# - macOS
# - Linux
#
# Canonical Locations (macOS/Linux)
# ------------------------------------------------------------------------------
# VS Code extensions:
#   ~/.vscode/extensions/
#
# VSCodium extensions:
#   ~/.vscode-oss/extensions/
#
# VS Code extensions manifest:
#   ~/.config/Code/User/extensions.json
#
# VSCodium extensions manifest:
#   ~/.config/VSCodium/User/extensions.json
#
# Required Behavior
# ------------------------------------------------------------------------------
# 1) Ensure extension exists in VS Code
#    - Check ~/.vscode/extensions for a directory matching "publisher.name-*".
#    - If not present:
#        * Install the extension into VS Code temporarily.
#        * Record that it was installed temporarily (temp_install = True).
#
# 2) Copy extension directory
#    - Copy the extension directory from VS Code into VSCodium.
#    - Overwrite/update if it already exists.
#    - Operation must be safe to re-run (idempotent).
#
# 3) Sync extensions.json entry
#    - Read VS Code's extensions.json.
#    - Locate the entry whose identifier matches "publisher.name".
#    - Insert or update the same entry in VSCodium's extensions.json.
#    - Preserve valid JSON structure; do not corrupt formatting.
#
# 4) Cleanup
#    - If temp_install == True:
#        * Uninstall/remove the extension from VS Code after copying completes.
#
# Non-Goals
# ------------------------------------------------------------------------------
# - Do NOT modify extension contents beyond copying.
# - Do NOT install extensions directly into VSCodium.
# - Do NOT guess manifest entries or identifiers.
#
# Error Handling Expectations
# ------------------------------------------------------------------------------
# - Fail fast if required directories or manifest files are missing.
# - Produce clear, actionable error messages.
# ==============================================================================

import argparse
import copy
import json
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$")


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def run(cmd: List[str]) -> Tuple[int, str]:
    """Run a command and return (returncode, stdout)."""
    try:
        p = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False
        )
        return p.returncode, p.stdout
    except FileNotFoundError:
        return 127, f"Command not found: {cmd[0]}"
    except Exception as ex:
        return 1, f"Error running command: {ex}"


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as ex:
        raise RuntimeError(f"Failed to parse JSON: {path} ({ex})")


def save_json(path: Path, data: Any) -> None:
    """Save JSON data atomically to avoid corruption on write failure."""
    path.parent.mkdir(parents=True, exist_ok=True)
    json_str = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    # Atomic write: write to temp file, then rename
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, delete=False, suffix=".tmp"
    ) as f:
        tmp_path = Path(f.name)
        try:
            f.write(json_str)
            f.flush()
            tmp_path.replace(path)
        except Exception:
            tmp_path.unlink(missing_ok=True)
            raise


def parse_extension_id(ext_id: str) -> Tuple[str, str]:
    if "." not in ext_id or ext_id.count(".") != 1:
        raise ValueError(f"Expected extension id in form publisher.name (got: {ext_id})")
    publisher, name = ext_id.split(".", 1)
    if not publisher or not name:
        raise ValueError(f"Invalid extension id: {ext_id}")
    return publisher, name


def semver_key(version: str) -> Tuple[int, int, int, str]:
    """
    Sorts semver-ish strings; non-semver sorts lower.
    """
    m = SEMVER_RE.match(version)
    if not m:
        return (-1, -1, -1, version)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)), version)


def find_installed_dirs(extensions_dir: Path, ext_id: str) -> List[Path]:
    """Find all extension directories matching the extension ID."""
    # Unpacked dirs usually: publisher.name-<version>
    pattern = f"{ext_id}-"
    if not extensions_dir.exists():
        return []
    if not extensions_dir.is_dir():
        return []
    dirs = []
    try:
        for p in extensions_dir.iterdir():
            if p.is_dir() and p.name.startswith(pattern):
                dirs.append(p)
    except PermissionError:
        raise RuntimeError(f"Permission denied reading extensions directory: {extensions_dir}")
    except Exception as ex:
        raise RuntimeError(f"Error reading extensions directory {extensions_dir}: {ex}")
    return dirs


def pick_latest_dir(dirs: List[Path], ext_id: str) -> Optional[Path]:
    if not dirs:
        return None

    def dir_version(p: Path) -> str:
        # folder: publisher.name-1.2.3
        prefix = f"{ext_id}-"
        return p.name[len(prefix):] if p.name.startswith(prefix) else ""

    dirs_sorted = sorted(dirs, key=lambda p: semver_key(dir_version(p)))
    return dirs_sorted[-1]


def read_extensions_manifest(manifest_path: Path) -> List[Dict[str, Any]]:
    data = load_json(manifest_path, default=[])
    if isinstance(data, list):
        return data
    # Some builds could store an object wrapper; handle minimal.
    if isinstance(data, dict) and "extensions" in data and isinstance(data["extensions"], list):
        return data["extensions"]
    raise RuntimeError(f"Unexpected extensions.json format in {manifest_path}")


def write_extensions_manifest(manifest_path: Path, arr: List[Dict[str, Any]]) -> None:
    # Write as a plain list to match typical VS Code layout.
    save_json(manifest_path, arr)


def manifest_find_node(nodes: List[Dict[str, Any]], ext_id: str) -> Optional[Dict[str, Any]]:
    for n in nodes:
        ident = n.get("identifier")
        if isinstance(ident, dict) and ident.get("id") == ext_id:
            return n
    return None


def normalize_location_path(node: Dict[str, Any], new_path: str) -> Dict[str, Any]:
    # VS Code uses:
    # "location": {"$mid": 1, "path": "/Users/.../.vscode/extensions/publisher.name-1.2.3"}
    loc = node.get("location")
    if not isinstance(loc, dict):
        loc = {"$mid": 1, "path": new_path}
    else:
        loc["path"] = new_path
        loc.setdefault("$mid", 1)
    node["location"] = loc
    return node


def upsert_manifest_node(codium_nodes: List[Dict[str, Any]], node: Dict[str, Any], ext_id: str) -> None:
    for i, n in enumerate(codium_nodes):
        ident = n.get("identifier")
        if isinstance(ident, dict) and ident.get("id") == ext_id:
            codium_nodes[i] = node
            return
    codium_nodes.append(node)


@dataclass
class TempInstallState:
    did_install: bool
    created_dirs: List[Path]


def snapshot_dirs(extensions_dir: Path, ext_id: str) -> List[Path]:
    return sorted(find_installed_dirs(extensions_dir, ext_id))


def diff_new_dirs(before: List[Path], after: List[Path]) -> List[Path]:
    b = set(before)
    return [p for p in after if p not in b]


def copy_extension_dir(src: Path, dst_dir: Path) -> Path:
    """Copy extension directory, overwriting if it exists. Returns destination path."""
    if not src.exists():
        raise RuntimeError(f"Source extension directory does not exist: {src}")
    if not src.is_dir():
        raise RuntimeError(f"Source is not a directory: {src}")
    
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / src.name
    
    # Remove existing destination if present (idempotent operation)
    if dst.exists():
        try:
            shutil.rmtree(dst)
        except Exception as ex:
            raise RuntimeError(f"Failed to remove existing extension directory {dst}: {ex}")
    
    try:
        shutil.copytree(src, dst, symlinks=True)
    except Exception as ex:
        # Clean up partial copy on failure
        if dst.exists():
            try:
                shutil.rmtree(dst)
            except Exception:
                pass
        raise RuntimeError(f"Failed to copy extension directory from {src} to {dst}: {ex}")
    
    return dst


def validate_code_bin(code_bin: str) -> None:
    """Validate that the code binary exists and is executable."""
    rc, _ = run([code_bin, "--version"])
    if rc != 0:
        raise RuntimeError(
            f"VS Code binary '{code_bin}' not found or not executable. "
            f"Install VS Code or specify correct path with --code-bin."
        )


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Mirror a VS Code extension into VSCodium by copying files and manifest entries."
    )
    ap.add_argument("--extension", required=True, help="Extension ID in form publisher.name")
    ap.add_argument("--code-bin", default="code", help="VS Code CLI binary (default: code)")
    ap.add_argument("--vscode-dir", default=str(Path.home() / ".vscode"), help="VS Code user dir (~/.vscode)")
    ap.add_argument("--vscodium-dir", default=str(Path.home() / ".vscode-oss"), help="VSCodium user dir (~/.vscode-oss)")
    args = ap.parse_args()

    ext_id = args.extension.strip()
    try:
        parse_extension_id(ext_id)  # validates form
    except ValueError as ex:
        eprint(f"[helper] ERROR: {ex}")
        return 1

    # Validate VS Code binary before proceeding
    try:
        validate_code_bin(args.code_bin)
    except RuntimeError as ex:
        eprint(f"[helper] ERROR: {ex}")
        return 2

    vscode_user_dir = Path(args.vscode_dir).expanduser()
    vscodium_user_dir = Path(args.vscodium_dir).expanduser()

    vscode_ext_dir = vscode_user_dir / "extensions"
    vscodium_ext_dir = vscodium_user_dir / "extensions"

    vscode_manifest = vscode_user_dir / "extensions" / "extensions.json"
    vscodium_manifest = vscodium_user_dir / "extensions" / "extensions.json"

    # 1) Find in VS Code cache; else temp install in VS Code
    temp_state = TempInstallState(did_install=False, created_dirs=[])

    try:
        try:
            dirs = find_installed_dirs(vscode_ext_dir, ext_id)
        except RuntimeError as ex:
            eprint(f"[helper] ERROR: {ex}")
            return 10

        if not dirs:
            eprint(f"[helper] {ext_id} not found under {vscode_ext_dir}. Temporarily installing via VS Code...")

            before_dirs = snapshot_dirs(vscode_ext_dir, ext_id)
            rc, out = run([args.code_bin, "--force", "--install-extension", ext_id])
            eprint(out.rstrip())
            if rc != 0:
                eprint(f"[helper] ERROR: VS Code install failed (exit code {rc}); cannot fetch local copy.")
                return 10

            after_dirs = snapshot_dirs(vscode_ext_dir, ext_id)
            created = diff_new_dirs(before_dirs, after_dirs)
            temp_state = TempInstallState(did_install=True, created_dirs=created)

            try:
                dirs = find_installed_dirs(vscode_ext_dir, ext_id)
            except RuntimeError as ex:
                eprint(f"[helper] ERROR: {ex}")
                return 11
            if not dirs:
                eprint("[helper] ERROR: VS Code reported install success but no extension dir appeared.")
                return 11

        latest_dir = pick_latest_dir(dirs, ext_id)
        if latest_dir is None:
            eprint("[helper] ERROR: could not pick latest extension directory.")
            return 12

        eprint(f"[helper] Using VS Code extension dir: {latest_dir}")

        # 2) Copy extension directory into VSCodium
        try:
            copied_dir = copy_extension_dir(latest_dir, vscodium_ext_dir)
        except RuntimeError as ex:
            eprint(f"[helper] ERROR: {ex}")
            return 13
        eprint(f"[helper] Copied to VSCodium: {copied_dir}")

        # 3) Merge manifest node from VS Code extensions.json into VSCodium extensions.json
        try:
            vscode_nodes = read_extensions_manifest(vscode_manifest)
        except RuntimeError as ex:
            eprint(f"[helper] ERROR: {ex}")
            return 14

        node = manifest_find_node(vscode_nodes, ext_id)
        if node is None:
            eprint(f"[helper] ERROR: {ext_id} not found in VS Code manifest {vscode_manifest}")
            return 15

        # adjust manifest node location path to point to VSCodium folder
        node = copy.deepcopy(node)  # deep copy to avoid mutating original
        node = normalize_location_path(node, str(copied_dir))

        try:
            codium_nodes = read_extensions_manifest(vscodium_manifest) if vscodium_manifest.exists() else []
        except RuntimeError as ex:
            eprint(f"[helper] ERROR: Failed to read VSCodium manifest: {ex}")
            return 16

        upsert_manifest_node(codium_nodes, node, ext_id)
        try:
            write_extensions_manifest(vscodium_manifest, codium_nodes)
        except RuntimeError as ex:
            eprint(f"[helper] ERROR: Failed to write VSCodium manifest: {ex}")
            return 17
        eprint(f"[helper] Updated VSCodium manifest: {vscodium_manifest}")

        eprint(f"[helper] Done: {ext_id}")
        return 0

    finally:
        # 4) If temp-installed in VS Code, uninstall + remove created dirs
        # Always attempt cleanup, even if previous steps failed
        if temp_state.did_install:
            eprint(f"[helper] Cleaning up temporary VS Code install: {ext_id}")
            rc, out = run([args.code_bin, "--uninstall-extension", ext_id])
            if rc != 0:
                eprint(f"[helper] WARN: VS Code uninstall returned exit code {rc}")
            eprint(out.rstrip())

            # VS Code uninstall usually removes the dirs, but be explicit for ones we created
            for d in temp_state.created_dirs:
                try:
                    if d.exists():
                        shutil.rmtree(d)
                        eprint(f"[helper] Removed temp dir: {d}")
                except Exception as ex:
                    eprint(f"[helper] WARN: failed to remove temp dir {d}: {ex}")


if __name__ == "__main__":
    raise SystemExit(main())
