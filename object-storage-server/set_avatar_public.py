"""GV-MR05: allow anonymous GET of the lab avatar using the official MinIO SDK.

Default: inspect and display the proposed grant. Pass --apply to update policy.
Credentials are read from local Compose configuration and never printed/saved.
Reference: https://github.com/minio/minio-py/blob/master/examples/set_bucket_policy.py
"""

import argparse
import json
from pathlib import Path
import subprocess
import sys
from urllib.request import urlopen

from minio import Minio
from minio.error import S3Error
import urllib3


BUCKET = "profile-pics"
OBJECT = "avatar.jpg"
SID = "N07PublicAvatarRead"
PUBLIC_URL = "http://localhost:9000/profile-pics/avatar.jpg"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Apply the avatar read grant")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    result = subprocess.run(
        [
            "docker", "compose", "-f", str(root / "docker-compose.yml"),
            "config", "--format", "json",
        ],
        cwd=root, capture_output=True, text=True, check=True,
    )
    service = json.loads(result.stdout)["services"]["object-storage-server"]
    environment = service["environment"]
    api_ports = [port for port in service["ports"] if port["target"] == 9000]
    if len(api_ports) != 1 or str(api_ports[0]["published"]) != "9000":
        raise ValueError("This lab check expects MinIO API host port 9000")
    client = Minio(
        "localhost:9000",
        access_key=environment["MINIO_ROOT_USER"],
        secret_key=environment["MINIO_ROOT_PASSWORD"],
        secure=False,
        http_client=urllib3.PoolManager(
            timeout=urllib3.Timeout(connect=5, read=15), retries=False,
        ),
    )
    response = client.get_object(BUCKET, OBJECT)
    try:
        original = response.read()
    finally:
        response.close()
        response.release_conn()
    if not original.startswith(b"\xff\xd8\xff"):
        raise ValueError("avatar.jpg is not a JPEG image; upload a real JPEG first")
    print(f"PASS authenticated read: {BUCKET}/{OBJECT}; JPEG; {len(original)} bytes")

    try:
        policy = json.loads(client.get_bucket_policy(BUCKET))
    except S3Error as error:
        if error.code != "NoSuchBucketPolicy":
            raise
        policy = {"Version": "2012-10-17", "Statement": []}
    statements = policy.get("Statement", [])
    if isinstance(statements, dict):
        statements = [statements]
    if not isinstance(statements, list) or any(not isinstance(s, dict) for s in statements):
        raise ValueError("Unexpected existing policy; no policy was changed")
    grant = {
        "Sid": SID,
        "Effect": "Allow",
        "Principal": {"AWS": ["*"]},
        "Action": ["s3:GetObject"],
        "Resource": [f"arn:aws:s3:::{BUCKET}/{OBJECT}"],
    }
    # Preserve unrelated grants. Re-running updates only this named statement.
    policy["Statement"] = [s for s in statements if s.get("Sid") != SID] + [grant]
    if not args.apply:
        print("Proposed additional grant:")
        print(json.dumps(grant, indent=2))
        print("DRY RUN: no policy changed. Use --apply to grant public avatar read.")
        return

    client.set_bucket_policy(BUCKET, json.dumps(policy))
    print("Applied public GetObject grant for profile-pics/avatar.jpg")
    # A plain, unsigned GET verifies access without Console session or a signed URL.
    with urlopen(PUBLIC_URL, timeout=15) as public:
        if public.status != 200:
            raise ValueError("Anonymous GET did not return HTTP 200")
        if public.headers.get_content_type() != "image/jpeg":
            raise ValueError("Public response Content-Type is not image/jpeg")
        if public.read() != original:
            raise ValueError("Anonymous response differs from authenticated object")
    print("PASS anonymous GET: HTTP 200; image/jpeg; bytes match")
    print("Public URL:", PUBLIC_URL)
    print("Credentials were not printed or saved. Other buckets were not changed.")


if __name__ == "__main__":
    try:
        main()
    except S3Error as error:
        print(f"FAIL S3: {error.code}")
        sys.exit(1)
    except ValueError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
    except (OSError, KeyError, subprocess.SubprocessError, urllib3.exceptions.HTTPError) as error:
        print(f"FAIL: {type(error).__name__}; check Compose config, credentials and MinIO")
        sys.exit(1)
