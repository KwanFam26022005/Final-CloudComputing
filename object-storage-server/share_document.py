"""Read-only local demo: temporarily share an existing private PDF.

Does not upload objects, change policies, or save signed URLs/credentials.
"""

import argparse
from datetime import timedelta
import json
import os
from pathlib import Path
import subprocess
import sys
from urllib.error import HTTPError
from urllib.parse import quote, parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import urlopen

from minio import Minio
from minio.error import S3Error
import urllib3


def fetch(url):
    try:
        with urlopen(url, timeout=15) as response:
            return response.status, response.read()
    except HTTPError as error:
        try:
            return error.code, error.read()
        finally:
            error.close()


def local_service():
    root = Path(__file__).resolve().parent.parent
    result = subprocess.run(
        ["docker", "compose", "-f", str(root / "docker-compose.yml"),
         "config", "--format", "json"],
        cwd=root, capture_output=True, text=True, check=True,
    )
    service = json.loads(result.stdout)["services"]["object-storage-server"]
    ports = [p for p in service["ports"] if p["target"] == 9000]
    if len(ports) != 1 or str(ports[0]["published"]) != "9000":
        raise ValueError("This local demo expects API host port 9000")
    return service


def local_client():
    access = os.environ.get("N07_MINIO_ACCESS_KEY")
    secret = os.environ.get("N07_MINIO_SECRET_KEY")
    if access is not None or secret is not None:
        if not access or not secret:
            raise ValueError("Set both N07_MINIO_ACCESS_KEY and N07_MINIO_SECRET_KEY")
    else:
        env = local_service()["environment"]
        access, secret = env["MINIO_ROOT_USER"], env["MINIO_ROOT_PASSWORD"]
    return Minio(
        "localhost:9000", access_key=access,
        secret_key=secret, secure=False,
        http_client=urllib3.PoolManager(
            timeout=urllib3.Timeout(connect=5, read=15), retries=False),
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("object", help="Exact PDF object name inside documents")
    parser.add_argument("--minutes", type=int, default=5, help="Validity: 1–60 minutes")
    parser.add_argument("--show-url", action="store_true", help="Print temporary download link; do not share logs containing it")
    args = parser.parse_args()
    if not 1 <= args.minutes <= 60:
        raise ValueError("Validity must be between 1 and 60 minutes")
    client = local_client()
    response = client.get_object("documents", args.object)
    try:
        original = response.read()
    finally:
        response.close()
        response.release_conn()
    if not original.startswith(b"%PDF-"):
        raise ValueError("Selected object is not a PDF")
    unsigned = "http://localhost:9000/documents/" + quote(args.object, safe="/")
    if fetch(unsigned)[0] != 403:
        raise ValueError("Unsigned GET must be denied with HTTP 403")
    print("PASS unsigned GET: HTTP 403")
    signed = client.presigned_get_object(
        "documents", args.object, expires=timedelta(minutes=args.minutes))
    status, body = fetch(signed)
    if status != 200 or body != original:
        raise ValueError("Signed GET must return HTTP 200 and identical PDF bytes")
    print("PASS signed GET: HTTP 200; PDF bytes match")
    parts = urlsplit(signed)
    query = parse_qsl(parts.query, keep_blank_values=True)
    changed = False
    for index, (key, value) in enumerate(query):
        if key == "X-Amz-Signature" and value:
            query[index] = (key, ("0" if value[0] != "0" else "1") + value[1:])
            changed = True
            break
    if not changed:
        raise ValueError("Signed URL has no signature")
    tampered = urlunsplit(parts._replace(query=urlencode(query)))
    if fetch(tampered)[0] != 403:
        raise ValueError("Tampered signature must be denied with HTTP 403")
    print("PASS tampered signature: HTTP 403")
    print(f"Validity configured: {args.minutes} minute(s); expiry after waiting NOT TESTED.")
    print("No objects or policies changed. No credentials or links saved.")
    if args.show_url:
        print("Temporary download URL (any holder can download until expiry):")
        print(signed)


if __name__ == "__main__":
    try:
        main()
    except S3Error as error:
        print(f"FAIL S3: {error.code}")
        sys.exit(1)
    except ValueError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
    except (OSError, KeyError, subprocess.SubprocessError, urllib3.exceptions.HTTPError):
        print("FAIL: check local Compose, MinIO connectivity and credentials")
        sys.exit(1)
