"""GV-MR04: kiem tra Flask /secure voi tai khoan Keycloak demo.

Token duoc giu trong bo nho; giu nguyen App, user, realm va policy.
Cac ca sai issuer/audience va token het han can kiem tra rieng."""

import argparse
import json
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from verify_oidc import read_json, verify_user


def call_secure(url, token=None):
    """Goi API va tra ve HTTP status cung JSON."""
    headers = {} if token is None else {"Authorization": "Bearer " + token}
    try:
        with urlopen(Request(url, headers=headers), timeout=15) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        with error:
            return error.code, json.load(error)


def main():
    """Doc tham so va chay cac buoc kiem thu."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app-url", default="http://localhost:8085/secure")
    parser.add_argument("--auth-url", default="http://localhost:8081", help="Public Keycloak base URL; may include /auth")
    parser.add_argument("--audience", default="myapp")
    args = parser.parse_args()

    realm = json.loads(
        (Path(__file__).resolve().parent / "import/realm-export.json").read_text(encoding="utf-8")
    )

    # Tao issuer tu realm va dia chi Keycloak.
    issuer = args.auth_url.rstrip("/") + "/realms/" + realm["realm"]
    if read_json(issuer + "/.well-known/openid-configuration").get("issuer") != issuer:
        raise ValueError("OIDC issuer mismatch")
    print("Realm:", realm["realm"])
    print("API:", args.app_url)

    checks = []

    def record(label, passed, detail):
        checks.append(passed)
        print(("PASS " if passed else "FAIL ") + label + ": " + detail)

    print("\n--- Tu choi token thieu / sai dinh dang ---", flush=True)
    for label, token in [("missing token", None), ("malformed token", "invalid-token")]:
        status, _ = call_secure(args.app_url, token)
        record(label, status == 401, f"HTTP {status} (expected 401)")

    # Kiem tra tung tai khoan demo.
    for username in ("sv01", "sv02"):
        print(f"\n--- Tai khoan {username} ---", flush=True)
        users = [u for u in realm.get("users", []) if u.get("username") == username]
        if len(users) != 1:
            raise ValueError("Expected exactly one demo user in realm import")
        token = verify_user(issuer, users[0], args.audience)
        status, payload = call_secure(args.app_url, token)
        correct_user = payload.get("preferred_username") == username
        record(username, status == 200 and correct_user, f"HTTP {status}; identity matches={correct_user}")
        if username == "sv01":
            print("\n--- Tu choi chu ky bi sua ---", flush=True)
            parts = token.split(".")
            signature = parts[2]
            if not signature:
                raise ValueError("Missing JWT signature")
            parts[2] = ("A" if signature[0] != "A" else "B") + signature[1:]
            status, _ = call_secure(args.app_url, ".".join(parts))
            record("tampered signature", status == 401, f"HTTP {status} (expected 401)")

    print(f"\nAPI SUMMARY: {sum(checks)}/{len(checks)} PASS", flush=True)
    print("Tokens/passwords were not printed or saved to files.")
    print("Wrong issuer/audience, expiry and browser login redirects are not covered by this test.")
    return 0 if all(checks) else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except HTTPError as error:
        print(f"FAIL upstream request: HTTP {error.code}")
        sys.exit(1)
    except (OSError, ValueError, KeyError, TypeError, URLError, TimeoutError) as error:
        print(f"FAIL: {type(error).__name__}; check local Auth/App configuration")
        sys.exit(1)
