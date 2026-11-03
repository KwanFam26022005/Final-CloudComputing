"""Kiem tra du lieu Storage GV-07/GV-MR05 va link ky PDF tren local."""

import argparse
from pathlib import Path
import subprocess
import sys

from minio.error import S3Error
import urllib3

from share_document import fetch, local_client


def read_object(client, bucket, name):
    """Doc object va dong ket noi S3."""
    response = client.get_object(bucket, name)
    try:
        return response.read(), response.headers.get("Content-Type", "").split(";")[0]
    finally:
        response.close()
        response.release_conn()


def main():
    """Doc tham so va chay cac buoc kiem thu."""
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--pdf", help="Existing PDF object name in documents")
    selection.add_argument("--all-pdfs", action="store_true", help="Check all .pdf objects in documents, including nested paths")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    client = local_client()
    failures = 0

    def check(label, action):
        nonlocal failures
        try:
            action()
            print(f"PASS {label}", flush=True)
        except S3Error as error:
            failures += 1
            print(f"FAIL {label}: S3 {error.code}", flush=True)
        except (ValueError, OSError, urllib3.exceptions.HTTPError) as error:
            failures += 1
            # An noi dung loi mang vi co the chua link ky.
            detail = str(error) if isinstance(error, ValueError) else type(error).__name__
            print(f"FAIL {label}: {detail}", flush=True)

    def demo():
        """Doi chieu HTML tren MinIO voi source Web."""
        content, _ = read_object(client, "demo", "index.html")
        if content != (root / "web-frontend-server/html/index.html").read_bytes():
            raise ValueError("download differs from local web index.html; check source version")

    def avatar():
        """Kiem tra JPEG va truy cap avatar khong dang nhap."""
        content, content_type = read_object(client, "profile-pics", "avatar.jpg")
        if not content.startswith(b"\xff\xd8\xff") or content_type != "image/jpeg":
            raise ValueError("expected JPEG bytes and image/jpeg metadata")
        status, public = fetch("http://localhost:9000/profile-pics/avatar.jpg")
        if status != 200 or public != content:
            raise ValueError("anonymous GET must return 200 and identical JPEG bytes")

    print("\n--- HTML: demo/index.html ---", flush=True)
    check("demo/index.html: authenticated bytes match local source", demo)
    print("\n--- AVATAR: profile-pics/avatar.jpg ---", flush=True)
    check("avatar: JPEG metadata/bytes; anonymous 200; bytes match", avatar)
    print("\n--- PDF: documents / quyen truy cap / link ky ---", flush=True)
    if args.all_pdfs:
        try:
            pdfs = sorted(
                obj.object_name for obj in client.list_objects("documents", recursive=True)
                if not obj.is_dir and obj.object_name.lower().endswith(".pdf")
            )
        except S3Error as error:
            print(f"FAIL list documents: S3 {error.code}")
            return 1
        print(f"Found {len(pdfs)} PDF object(s) in documents", flush=True)
    else:
        pdfs = [args.pdf]
    if not pdfs:
        failures += 1
        print("FAIL documents: no .pdf objects found; nothing to verify", flush=True)
    passed_pdfs = 0
    for name in pdfs:
        # Dung repr de ten object co ky tu xuong dong khong lam sai output.
        print(f"\nCHECK PDF {name!r}", flush=True)
        result = subprocess.run(
            [sys.executable, str(root / "object-storage-server/share_document.py"), "--", name],
            cwd=root, check=False,
        )
        if result.returncode:
            failures += 1
            print(f"FAIL PDF {name!r}", flush=True)
        else:
            passed_pdfs += 1
            print(f"PASS PDF {name!r}", flush=True)
    print(f"\nPDF SUMMARY: {passed_pdfs}/{len(pdfs)} passed", flush=True)
    print(f"RESULT: {'FAIL' if failures else 'PASS'}; {failures} failed group(s)")
    print("Read-only checks. Real report content, expiry waiting, Console UI and EC2 not tested.")
    return 1 if failures else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, KeyError, ValueError, subprocess.SubprocessError, urllib3.exceptions.HTTPError):
        print("FAIL setup: check Compose, Docker and local credentials")
        sys.exit(1)
