"""Khoi phuc backup nguoi vao volume moi; giu nguyen Keycloak dang chay."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


VOLUME = "n07-keycloak-data"
HELPER = "myminicloud-minio:RELEASE.2025-10-15T17-29-55Z"


def run(*command):
    return subprocess.run(command, capture_output=True, text=True, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("backup", type=Path, help="Backup directory containing manifest.json and data/")
    parser.add_argument("--helper-image", default=HELPER,
                        help="Existing local image with sh/cp/chown/find/sha256sum; never pulled")
    args = parser.parse_args()
    backup = args.backup.resolve()
    manifest = json.loads((backup / "manifest.json").read_text())
    data = backup / "data"
    expected = {}
    for entry in manifest["files"]:
        source = data / entry["path"]
        path = source.resolve()
        if not path.is_relative_to(data.resolve()) or source.is_symlink():
            raise ValueError("Unexpected backup path")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != entry["sha256"] or path.stat().st_size != entry["bytes"]:
            raise ValueError("Backup integrity mismatch")
        expected["/target/" + entry["path"]] = digest
    if not any(name.endswith(".mv.db") and name.startswith("/target/h2/") for name in expected):
        raise ValueError("Expected H2 database in backup")
    # Lay ID co dinh cua image ho tro da co tren may.
    helper = run("docker", "image", "inspect", args.helper_image, "--format", "{{.Id}}").stdout.strip()
    names = run("docker", "volume", "ls", "--format", "{{.Name}}").stdout.splitlines()
    if VOLUME in names:
        raise ValueError("Target volume already exists; left untouched. Inspect it before retrying.")
    run("docker", "volume", "create", "--label", "n07.module=authentication", VOLUME)
    # Chay container ho tro voi mang tat de copy file va tinh hash.
    result = run(
        "docker", "run", "--rm", "--network", "none", "--user", "0:0",
        "--mount", f"type=bind,source={data},target=/backup,readonly",
        "--mount", f"type=volume,source={VOLUME},target=/target",
        "--entrypoint", "/bin/sh", helper, "-ec",
        'test -z "$(ls -A /target)"; cp -a /backup/. /target/; '
        'chown -R 1000:0 /target; chmod 700 /target; '
        'find /target -type f -exec sha256sum {} \\;',
    )
    actual = {}
    for line in result.stdout.splitlines():
        digest, name = line.split("  ", 1)
        actual[name] = digest
    if actual != expected:
        raise ValueError("Restored volume hashes differ; do not attach it to Keycloak")
    print(f"PASS restored volume: {VOLUME}; {len(actual)} file hashes match backup")
    print("PASS data ownership set to Keycloak UID 1000")
    print("Live Keycloak unchanged. Do not apply persistence Compose until the next step.")
    print("This restores the backup snapshot; later runtime changes are not included.")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
    except (OSError, KeyError, subprocess.SubprocessError):
        print("FAIL: check Docker, backup and helper image. Keep any created volume for inspection; do not switch live Keycloak.")
        sys.exit(1)
