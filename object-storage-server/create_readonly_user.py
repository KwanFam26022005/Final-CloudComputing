"""Create a NEW local MinIO verifier account; dry run unless --apply.

Prompts for a new secret without echo. Never changes existing users or policies.
Admin credentials come from local Compose, not the verifier environment variables.
"""

import argparse
import getpass
import json
from pathlib import Path
import sys

from minio import MinioAdmin
from minio.credentials import StaticProvider
from minio.error import MinioAdminException
import subprocess
import urllib3

from share_document import local_service


USER = "n07-storage-verifier"
POLICY = "n07-storage-verifier-readonly"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Create new policy/user after collision checks")
    args = parser.parse_args()
    policy = json.loads((Path(__file__).parent / "policies/storage-verifier-readonly.json").read_text())
    if not args.apply:
        print(f"DRY RUN: new user {USER}; policy {POLICY}")
        print(json.dumps(policy, indent=2))
        print("No server changes. Run with --apply to create this separate account.")
        return
    env = local_service()["environment"]
    admin = MinioAdmin(
        endpoint="localhost:9000", secure=False,
        credentials=StaticProvider(env["MINIO_ROOT_USER"], env["MINIO_ROOT_PASSWORD"]),
        http_client=urllib3.PoolManager(
            timeout=urllib3.Timeout(connect=5, read=15), retries=False),
    )
    users = json.loads(admin.user_list())
    policies = json.loads(admin.policy_list())
    if not isinstance(users, dict) or not isinstance(policies, dict):
        raise ValueError("Unexpected admin response; no changes made")
    if USER == env["MINIO_ROOT_USER"] or USER in users or POLICY in policies:
        raise ValueError("User or policy already exists; left unchanged. Do not delete existing accounts to retry.")
    secret = getpass.getpass("New verifier secret (at least 16 characters; input hidden): ")
    if len(secret) < 16:
        raise ValueError("Use at least 16 characters")
    if getpass.getpass("Confirm new verifier secret (hidden): ") != secret:
        raise ValueError("Secrets do not match; no changes made")
    # Requests are not transactional. Report completed stages; never delete on error.
    admin.policy_add(POLICY, policy=policy)
    print(f"Created new policy: {POLICY}", flush=True)
    admin.user_add(USER, secret)
    print(f"Created new user: {USER}", flush=True)
    admin.policy_set(POLICY, user=USER)
    info = json.loads(admin.user_info(USER))
    if info.get("policyName") != POLICY or info.get("status") != "enabled":
        raise ValueError("Account created, but policy/status verification failed; inspect without rerunning")
    print("PASS new verifier enabled; read-only policy attached")
    print("Secret was not printed/saved. Existing users and bucket policies unchanged.")
    print("Read/write/admin permission tests still pending.")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
    except (OSError, KeyError, subprocess.SubprocessError, MinioAdminException, urllib3.exceptions.HTTPError):
        print("FAIL setup/admin request. Keep any newly created user/policy for inspection; report completed stages without secrets.")
        sys.exit(1)
