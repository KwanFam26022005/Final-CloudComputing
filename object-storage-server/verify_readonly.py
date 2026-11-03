"""Kiem tra quyen tai khoan MinIO doc bang object tam co ten UUID.

Doc tai khoan tu N07_MINIO_ACCESS_KEY/N07_MINIO_SECRET_KEY.
Tai khoan quan tri tu Compose dung de tao va don object tam.
Giu nguyen PDF, user va policy hien co."""

import argparse
import io
import json
import os
import subprocess
import sys
from uuid import uuid4

from minio import Minio, MinioAdmin
from minio.credentials import StaticProvider
from minio.error import MinioAdminException, S3Error
import urllib3

from share_document import local_client, local_service


def policy_snapshot(root):
    """Doc policy hien tai cua bucket documents."""
    try:
        return json.loads(root.get_bucket_policy("documents"))
    except S3Error as error:
        if error.code != "NoSuchBucketPolicy":
            raise
        return None


def main():
    """Doc tham so va chay cac buoc kiem thu."""
    argparse.ArgumentParser(description=__doc__).parse_args()
    access = os.environ.get("N07_MINIO_ACCESS_KEY")
    secret = os.environ.get("N07_MINIO_SECRET_KEY")
    if access != "n07-storage-verifier" or not secret:
        raise ValueError("Set verifier credentials in both N07_MINIO environment variables")
    env = local_service()["environment"]
    if access == env["MINIO_ROOT_USER"]:
        raise ValueError("Refusing to test a root account as the verifier")
    transport = urllib3.PoolManager(timeout=urllib3.Timeout(connect=5, read=15), retries=False)
    root = Minio("localhost:9000", access_key=env["MINIO_ROOT_USER"],
                 secret_key=env["MINIO_ROOT_PASSWORD"], secure=False, http_client=transport)
    verifier = local_client()
    admin = MinioAdmin(endpoint="localhost:9000", secure=False,
                       credentials=StaticProvider(access, secret), http_client=transport)
    prefix = "n07-permission-test/" + uuid4().hex
    fixture = prefix + "/read-delete-fixture.txt"
    upload = prefix + "/write-probe.txt"
    content = b"Disposable N07 permission test; contains no private data.\n"
    failures = 0
    before = policy_snapshot(root)
    print(f"Temporary test prefix: documents/{prefix}", flush=True)

    def denied(label, action):
        """Xac nhan thao tac bi tu choi voi HTTP 403."""
        nonlocal failures
        try:
            action()
        except S3Error as error:
            if error.code == "AccessDenied" and error.response.status == 403:
                print(f"PASS {label}: AccessDenied HTTP 403", flush=True)
                return
            raise ValueError("Unexpected S3 response during permission test") from None
        except MinioAdminException as error:
            # SDK 7.2.20 luu HTTP status quan tri tai _code; giu an body.
            if error._code == "403":
                print(f"PASS {label}: HTTP 403", flush=True)
                return
            raise ValueError("Unexpected admin HTTP response") from None
        failures += 1
        print(f"FAIL {label}: operation was permitted", flush=True)

    try:
        root.put_object("documents", fixture, io.BytesIO(content), len(content))
        response = verifier.get_object("documents", fixture)
        try:
            if response.read() != content:
                raise ValueError("Verifier fixture read differs")
        finally:
            response.close()
            response.release_conn()
        print("PASS authenticated verifier read: fixture bytes match", flush=True)
        denied("upload blocked", lambda: verifier.put_object(
            "documents", upload, io.BytesIO(content), len(content)))
        denied("delete blocked", lambda: verifier.remove_object("documents", fixture))
        # Xac nhan object tam van con sau khi lenh xoa bi tu choi.
        root.stat_object("documents", fixture)
        denied("admin user listing blocked", admin.user_list)
        if policy_snapshot(root) != before:
            raise ValueError("Documents bucket policy changed during test; inspect it")
        print("PASS documents bucket policy unchanged", flush=True)
    finally:
        # Don hai key UUID cua phep thu, ke ca khi lenh ghi bat ngo thanh cong.
        for name in (fixture, upload):
            root.remove_object("documents", name)
        print("Temporary test objects cleaned up; existing PDFs untouched.", flush=True)
    print(f"RESULT: {'FAIL' if failures else 'PASS'}; {failures} permission failure(s)")
    print("Tests cover these API calls only; no expiry/EC2/Keycloak integration tests.")
    return 1 if failures else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ValueError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
    except (OSError, KeyError, subprocess.SubprocessError, S3Error,
            MinioAdminException, urllib3.exceptions.HTTPError):
        print("FAIL: check local MinIO and credentials; if cleanup did not complete, inspect only the printed temporary prefix.")
        sys.exit(1)
