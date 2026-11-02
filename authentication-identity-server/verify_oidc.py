"""GV-MR04: verify local demo token issuance without printing credentials/tokens.

Run on the host: python3 authentication-identity-server/verify_oidc.py
Reads demo credentials from the realm import; keeps tokens in memory only.
Reference: https://www.keycloak.org/securing-apps/oidc-layers
This checks Keycloak Token/UserInfo, not the Flask /secure integration.
JWT claims are inspected for the integration contract; signature verification in
the Flask application is a separate test. Keycloak validates the UserInfo call.
"""

import argparse
import base64
import json
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def read_json(request):
    with urlopen(request, timeout=15) as response:
        if response.status != 200:
            raise ValueError("Expected HTTP 200")
        return json.load(response)


def verify_user(issuer, user, expected_audience):
    passwords = [
        credential["value"]
        for credential in user.get("credentials", [])
        if credential.get("type") == "password" and credential.get("value")
    ]
    if len(passwords) != 1:
        raise ValueError("Expected one demo password in realm import")
    response = read_json(
        Request(
            issuer + "/protocol/openid-connect/token",
            data=urlencode(
                {
                    "client_id": "flask-app",
                    "grant_type": "password",
                    "username": user["username"],
                    "password": passwords[0],
                    "scope": "openid profile",
                }
            ).encode(),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
    )
    token = response.get("access_token")
    if not isinstance(token, str) or not token:
        raise ValueError("Missing access_token")
    if str(response.get("token_type", "")).lower() != "bearer":
        raise ValueError("Expected Bearer token")
    if float(response.get("expires_in", 0)) <= 0:
        raise ValueError("Expected positive token lifetime")
    profile = read_json(
        Request(
            issuer + "/protocol/openid-connect/userinfo",
            headers={"Authorization": "Bearer " + token},
        )
    )
    if not profile.get("sub") or profile.get("preferred_username") != user["username"]:
        raise ValueError("UserInfo identity mismatch")
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Expected JWT access token")
    payload = parts[1] + "=" * (-len(parts[1]) % 4)
    claims = json.loads(base64.urlsafe_b64decode(payload))
    if claims.get("iss") != issuer or claims.get("azp") != "flask-app":
        raise ValueError("Token issuer/client mismatch")
    if claims.get("sub") != profile["sub"]:
        raise ValueError("Token subject differs from UserInfo")
    audience = claims.get("aud", [])
    if isinstance(audience, str):
        audience = [audience]
    if not isinstance(audience, list) or expected_audience not in audience:
        raise ValueError("Token audience does not include the expected API audience")
    return token


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audience", default="myapp", help="Expected API audience")
    args = parser.parse_args()
    realm = json.loads(
        (Path(__file__).parent / "import" / "realm-export.json").read_text(
            encoding="utf-8"
        )
    )
    issuer = "http://localhost:8081/realms/" + realm["realm"]
    discovery = read_json(issuer + "/.well-known/openid-configuration")
    if discovery.get("issuer") != issuer:
        raise ValueError("OIDC issuer mismatch")
    print("Realm:", realm["realm"])
    failed = False
    for username in ("sv01", "sv02"):
        try:
            users = [u for u in realm.get("users", []) if u.get("username") == username]
            if len(users) != 1:
                raise ValueError("Expected exactly one user in realm import")
            verify_user(issuer, users[0], args.audience)
            print(
                f"PASS {username}: Token HTTP 200; UserInfo HTTP 200; "
                f"identity/issuer/client match; aud includes {args.audience}"
            )
        except HTTPError as error:
            print(f"FAIL {username}: HTTP {error.code}; check Keycloak settings/logs")
            failed = True
        except (ValueError, KeyError, TypeError, URLError, TimeoutError) as error:
            print(f"FAIL {username}: {type(error).__name__}; check configuration/connectivity")
            failed = True
    print("Tokens/passwords were not printed or saved to files.")
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except HTTPError as error:
        print(f"FAIL discovery: HTTP {error.code}")
        sys.exit(1)
    except (ValueError, KeyError, TypeError, URLError, TimeoutError, OSError) as error:
        print(f"FAIL: {type(error).__name__}; check local realm file and Keycloak")
        sys.exit(1)
