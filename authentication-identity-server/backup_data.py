"""Sao luu nguoi du lieu Keycloak local.

Tam dung authentication-identity-server va khoi dong lai trong finally.
--output phai tro den thu muc da duoc loai tru khoi Git.
Du lieu backup duoc giu rieng tren may local."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys


CONTAINER = "authentication-identity-server"


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    parent = args.output.resolve()
    relative = parent.relative_to(root)
    # Kiem tra thu muc backup duoc loai tru khoi Git.
    run("git", "-C", str(root), "check-ignore", "--", str(relative / "probe"))
    tracked = run("git", "-C", str(root), "ls-files", "--", str(relative)).stdout
    if tracked.strip():
        raise ValueError("Backup location contains tracked files")
    inspect = json.loads(run("docker", "inspect", CONTAINER).stdout)[0]
    if not inspect["State"]["Running"]:
        raise ValueError("Expected running Keycloak; no state was changed")
    # Xac nhan Keycloak dang dung database nhung cua lab.
    env = dict(item.split("=", 1) for item in inspect["Config"]["Env"] if "=" in item)
    if env.get("KC_DB", "dev-file") != "dev-file":
        raise ValueError("This backup is only for the local dev-file database")
    parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    destination = parent / datetime.now(timezone.utc).strftime("keycloak-%Y%m%dT%H%M%S%fZ")
    destination.mkdir(mode=0o700)
    data = destination / "data"
    data.mkdir(mode=0o700)
    try:
        run("docker", "stop", "--time", "60", CONTAINER)
        state = json.loads(run("docker", "inspect", CONTAINER).stdout)[0]["State"]
        if state["Running"] or state.get("OOMKilled") or state["ExitCode"] not in (0, 143):
            raise ValueError("Keycloak did not stop cleanly; backup not marked complete")
        run("docker", "cp", f"{CONTAINER}:/opt/keycloak/data/.", str(data))
        databases = list((data / "h2").glob("*.mv.db"))
        if not databases or any(p.stat().st_size == 0 for p in databases):
            raise ValueError("No nonempty H2 database found; backup not marked complete")
        files = []
        for path in sorted(data.rglob("*")):
            if path.is_symlink():
                raise ValueError("Unexpected symlink; inspect backup manually")
            if path.is_file():
                path.chmod(0o600)
                files.append({"path": str(path.relative_to(data)),
                              "bytes": path.stat().st_size,
                              "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
            elif path.is_dir():
                path.chmod(0o700)
        manifest = {"created_utc": datetime.now(timezone.utc).isoformat(),
                    "container": CONTAINER, "image_id": inspect["Image"],
                    "backup_type": "cold-dev-file-data", "files": files}
        manifest_path = destination / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        manifest_path.chmod(0o600)
        print(f"PASS cold backup: {destination}")
        print(f"PASS H2 database present; {len(files)} file(s) hashed")
        print("Backup includes sensitive database contents; do not upload or commit it.")
    finally:
        run("docker", "start", CONTAINER)
        print("Existing Keycloak container started; readiness still needs verification.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        # An bien moi truong va output tien trinh co thong tin bi mat.
        print("FAIL: backup incomplete or restart failed; keep existing container and inspect its state.")
        sys.exit(1)
