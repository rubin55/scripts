#!/usr/bin/env python3
"""Log harbor-cli and docker in to Harbor, with a personal or robot account."""

import argparse
import base64
import configparser
import json
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from http.cookiejar import Cookie, CookieJar
from pathlib import Path

FIREFOX = Path("~/.mozilla/firefox").expanduser()
CONFIG = Path("~/.harbor-login.ini").expanduser()
MODES = ("personal", "robot")
# "Open external links in a container", it opens ext+container: URLs.
EXTENSION = "{f069aec0-43c5-4bbf-b6b4-df95c4326b98}"
WAIT = 300
POLL = 5
TIMEOUT = 10


class LoginError(Exception):
    pass


class NoSession(LoginError):
    pass


def default_profile():
    # Use the install default, then the first profile.
    ini = configparser.ConfigParser()
    ini.read(FIREFOX / "profiles.ini")
    sections = [ini[name] for name in ini.sections()]
    paths = [
        s["Default"]
        for s in sections
        if s.name.startswith("Install") and "Default" in s
    ]
    paths += [
        s["Path"] for s in sections if s.name.startswith("Profile") and "Path" in s
    ]
    if not paths:
        raise LoginError(f"no profile in {FIREFOX / 'profiles.ini'}")
    return FIREFOX / paths[0]


def lz4_block(src):
    # Decompress one LZ4 block, the format of mozLz4 files.
    out = bytearray()
    i = 0
    while True:
        token = src[i]
        i += 1
        n, i = lz4_length(src, i, token >> 4)
        out += src[i : i + n]
        i += n
        if i >= len(src):
            return bytes(out)
        offset = int.from_bytes(src[i : i + 2], "little")
        i += 2
        n, i = lz4_length(src, i, token & 15)
        start = len(out) - offset
        for k in range(n + 4):
            out.append(out[start + k])


def lz4_length(src, i, n):
    # A length of 15 continues in the next bytes, until a byte below 255.
    if n == 15:
        while True:
            n += src[i]
            i += 1
            if src[i - 1] != 255:
                return n, i
    return n, i


def make_cookie(host, name, value, path, secure):
    dot = host.startswith(".")
    return Cookie(
        version=0,
        name=name,
        value=value,
        port=None,
        port_specified=False,
        domain=host,
        domain_specified=dot,
        domain_initial_dot=dot,
        path=path,
        path_specified=True,
        secure=secure,
        expires=None,
        discard=True,
        comment=None,
        comment_url=None,
        rest={},
    )


class Firefox:
    """A Firefox profile and one container in it, empty for none."""

    def __init__(self, profile, container):
        self.profile = profile
        self.container = container
        self.container_id = 0
        if container:
            path = profile / "containers.json"
            ids = {
                i.get("name"): i["userContextId"]
                for i in json.loads(path.read_text())["identities"]
            }
            if container not in ids:
                raise LoginError(f"no container {container!r} in {path}")
            self.container_id = ids[container]

    def check(self):
        # Opening a page needs firefox, and in a container the extension.
        if not shutil.which("firefox"):
            raise LoginError("firefox not found in PATH")
        if self.container:
            addons = json.loads((self.profile / "extensions.json").read_text())[
                "addons"
            ]
            if not any(a["id"] == EXTENSION and a.get("active") for a in addons):
                raise LoginError(
                    'install the Firefox extension "Open external links in a container"'
                )

    def cookies(self):
        # Persistent cookies are in cookies.sqlite, session cookies are only
        # in the session store. Use the cookies of the container only.
        attrs = f"^userContextId={self.container_id}" if self.container_id else ""
        with tempfile.TemporaryDirectory() as tmp:
            for name in ("cookies.sqlite", "cookies.sqlite-wal"):
                if (self.profile / name).is_file():
                    shutil.copy(self.profile / name, tmp)
            db = sqlite3.connect(Path(tmp) / "cookies.sqlite")
            try:
                rows = db.execute(
                    "SELECT host, name, value, path, isSecure FROM moz_cookies WHERE originAttributes = ?",
                    (attrs,),
                ).fetchall()
            finally:
                db.close()

        jar = CookieJar()
        for host, name, value, path, secure in rows + self.session_cookies():
            jar.set_cookie(make_cookie(host, name, value, path, bool(secure)))
        return jar

    def session_cookies(self):
        # Without a running Firefox, there can be no session store.
        path = self.profile / "sessionstore-backups" / "recovery.jsonlz4"
        if not path.is_file():
            return []
        raw = path.read_bytes()
        if raw[:8] != b"mozLz40\0":
            raise LoginError(f"{path} is not a mozLz4 file")
        rows = []
        for c in json.loads(lz4_block(raw[12:])).get("cookies", []):
            other = dict(c.get("originAttributes", {}))
            if other.pop("userContextId", 0) == self.container_id and not any(
                other.values()
            ):
                rows.append(
                    (
                        c["host"],
                        c["name"],
                        c.get("value", ""),
                        c.get("path", "/"),
                        c.get("secure"),
                    )
                )
        return rows

    def open(self, url):
        if self.container:
            url = "ext+container:" + urllib.parse.urlencode(
                {"name": self.container, "url": url}
            )
        subprocess.Popen(
            ["firefox", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )


def run(args, stdin=None):
    # Report a failure without the arguments, they can hold a password.
    result = subprocess.run(
        args, check=False, input=stdin, capture_output=True, text=True
    )
    if result.returncode:
        raise LoginError(f"{' '.join(args[:2])} failed: {result.stderr.strip()}")
    return result.stdout


def cli_secret(jar, host):
    # Harbor logs in through its OIDC provider. With an SSO session, the
    # redirects end in Harbor, which then shows the CLI secret.
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    with opener.open(f"https://{host}/c/oidc/login", timeout=TIMEOUT) as response:
        response.read()
    try:
        with opener.open(
            f"https://{host}/api/v2.0/users/current", timeout=TIMEOUT
        ) as response:
            user = json.load(response)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            raise NoSession(f"no SSO session for {host}") from None
        raise
    secret = (user.get("oidc_user_meta") or {}).get("secret")
    if not secret:
        raise LoginError(
            f"no CLI secret for {user.get('username')}, is Harbor in OIDC mode?"
        )
    return user["username"], secret


def personal_credentials(firefox, host):
    # Without a session, open the login page and wait for the cookies.
    # Firefox writes session cookies to disk every 15 seconds.
    try:
        return cli_secret(firefox.cookies(), host)
    except NoSession:
        pass
    print(f"{host}: log in with Firefox, waiting up to {WAIT} seconds", file=sys.stderr)
    firefox.open(f"https://{host}/c/oidc/login")
    deadline = time.monotonic() + WAIT
    while time.monotonic() < deadline:
        time.sleep(POLL)
        try:
            return cli_secret(firefox.cookies(), host)
        except NoSession:
            pass
    raise LoginError(f"no login within {WAIT} seconds")


def robot_credentials(context, secret):
    # Map each registry host in a dockerconfigjson Secret to its login.
    out = run(["kubectl", "--context", context, "get", "secret", secret, "-o", "json"])
    auths = json.loads(base64.b64decode(json.loads(out)["data"][".dockerconfigjson"]))[
        "auths"
    ]
    logins = {}
    for host, entry in auths.items():
        if "auth" in entry:
            user, _, password = base64.b64decode(entry["auth"]).decode().partition(":")
        else:
            user, password = entry["username"], entry["password"]
        logins[host.removeprefix("https://").rstrip("/")] = (user, password)
    return logins


def verify(host, user, password):
    # The registry API rejects a wrong login, the Harbor API not always.
    auth = base64.b64encode(f"{user}:{password}".encode()).decode()
    request = urllib.request.Request(
        f"https://{host}/v2/", headers={"Authorization": f"Basic {auth}"}
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT):
            pass
    except urllib.error.HTTPError as e:
        raise LoginError(
            f"{host} rejected the login of {user}: HTTP {e.code}"
        ) from None


def store(name, host, user, password):
    # harbor-cli validates a login with an API that refuses CLI secrets,
    # and its --password-stdin needs a terminal.
    run(
        [
            "harbor-cli",
            "login",
            f"https://{host}",
            "-u",
            user,
            "-p",
            password,
            "-n",
            name,
            "--skip-verify-client",
        ]
    )
    run(["docker", "login", host, "-u", user, "--password-stdin"], stdin=password)


def current_context():
    return json.loads(run(["harbor-cli", "context", "list", "-o", "json"])).get(
        "CurrentCredentialName", ""
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=CONFIG,
        help=f"configuration file (default: {CONFIG})",
    )
    parser.add_argument(
        "-m",
        "--mode",
        choices=MODES,
        help="account to log in with (default: mode in the configuration)",
    )
    args = parser.parse_args()

    try:
        config = configparser.ConfigParser()
        if not config.read(args.config):
            raise LoginError(f"no configuration file: {args.config}")
        mode = args.mode or config.get("harbor", "mode", fallback="")
        if mode not in MODES:
            raise LoginError(
                f"no mode {' or '.join(MODES)} in section [harbor] of {args.config}"
            )
        registries = (
            dict(config["registries"]) if config.has_section("registries") else {}
        )
        if not registries:
            raise LoginError(f"no registries in section [registries] of {args.config}")
        for tool in ("harbor-cli", "docker"):
            if not shutil.which(tool):
                raise LoginError(f"{tool} not found in PATH")

        firefox, logins = None, {}
        if mode == "personal":
            if not config.has_option("firefox", "container"):
                raise LoginError(f"no container in section [firefox] of {args.config}")
            profile = config.get("firefox", "profile", fallback="")
            firefox = Firefox(
                Path(profile).expanduser() if profile else default_profile(),
                config["firefox"]["container"],
            )
            firefox.check()
        else:
            if not (
                config.has_option("robot", "context")
                and config.has_option("robot", "secret")
            ):
                raise LoginError(
                    f"no context and secret in section [robot] of {args.config}"
                )
            if not shutil.which("kubectl"):
                raise LoginError("kubectl not found in PATH")
            logins = robot_credentials(
                config["robot"]["context"], config["robot"]["secret"]
            )
        context = current_context()
    except (configparser.Error, LoginError, OSError, ValueError, KeyError) as e:
        sys.exit(f"error: {e}")

    failed = False
    for name, host in registries.items():
        try:
            if mode == "personal":
                user, password = personal_credentials(firefox, host)
            elif host in logins:
                user, password = logins[host]
            else:
                raise LoginError(
                    f"no login for {host} in Secret {config['robot']['secret']}"
                )
            verify(host, user, password)
            store(name, host, user, password)
            print(f"{name}: logged in to {host} as {user}", flush=True)
        except (LoginError, OSError, ValueError, KeyError, sqlite3.Error) as e:
            print(f"{name}: error: {e}", file=sys.stderr)
            failed = True

    # harbor-cli login switches the context, so switch it back.
    if context:
        subprocess.run(
            ["harbor-cli", "context", "switch", context],
            check=False,
            capture_output=True,
        )
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
