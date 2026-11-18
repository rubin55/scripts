#!/usr/bin/env python3
"""Get OpenShift tokens with the Firefox SSO session, set them in kubeconfig."""

import argparse
import configparser
import html.parser
import json
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from http.cookiejar import Cookie, CookieJar
from pathlib import Path

FIREFOX = Path("~/.mozilla/firefox").expanduser()
CONFIG = Path("~/.openshift-login.ini").expanduser()
CLIENT = "openshift-browser-client"
# "Open external links in a container", it opens ext+container: URLs.
EXTENSION = "{f069aec0-43c5-4bbf-b6b4-df95c4326b98}"
WAIT = 300
POLL = 5
TIMEOUT = 10


class TokenError(Exception):
    pass


class NoSession(TokenError):
    pass


class Form(html.parser.HTMLParser):
    """Collect the action and the input fields of an HTML form."""

    def __init__(self):
        super().__init__()
        self.action = ""
        self.fields = {}

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "form":
            self.action = attrs.get("action") or ""
        elif tag == "input" and attrs.get("name"):
            self.fields[attrs["name"]] = attrs.get("value") or ""


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
        raise TokenError(f"no profile in {FIREFOX / 'profiles.ini'}")
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
                raise TokenError(f"no container {container!r} in {path}")
            self.container_id = ids[container]

    def check(self):
        # Opening a page needs firefox, and in a container the extension.
        if not shutil.which("firefox"):
            raise TokenError("firefox not found in PATH")
        if self.container:
            addons = json.loads((self.profile / "extensions.json").read_text())[
                "addons"
            ]
            if not any(a["id"] == EXTENSION and a.get("active") for a in addons):
                raise TokenError(
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
            raise TokenError(f"{path} is not a mozLz4 file")
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


def kube_contexts():
    # Map each context name to its user and API server.
    out = subprocess.run(
        ["kubectl", "config", "view", "-o", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    config = json.loads(out.stdout)
    servers = {c["name"]: c["cluster"]["server"] for c in config.get("clusters") or []}
    return {
        c["name"]: (c["context"]["user"], servers[c["context"]["cluster"]])
        for c in config.get("contexts") or []
    }


def oauth_issuer(server):
    url = f"{server}/.well-known/oauth-authorization-server"
    with urllib.request.urlopen(url, timeout=TIMEOUT) as response:
        return json.load(response)["issuer"]


def list_contexts(kube, configured):
    # An API server with an OAuth server is an OpenShift cluster.
    rows = [("CONTEXT", "USER", "OPENSHIFT", "CONFIGURED")]
    for name, (user, server) in sorted(kube.items()):
        try:
            oauth_issuer(server)
            openshift = "yes"
        except (OSError, ValueError, KeyError):
            openshift = "no"
        rows.append((name, user, openshift, "yes" if name in configured else "no"))
    rows += [
        (name, "-", "-", "yes, not in kubeconfig")
        for name in configured
        if name not in kube
    ]
    widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]
    for row in rows:
        print("  ".join(cell.ljust(width) for cell, width in zip(row, widths)).rstrip())


def authorize_url(issuer, idp):
    params = {
        "client_id": CLIENT,
        "redirect_uri": f"{issuer}/oauth/token/display",
        "response_type": "code",
    }
    if idp:
        params["idp"] = idp
    return f"{issuer}/oauth/authorize?{urllib.parse.urlencode(params)}"


def get_token(jar, issuer, idp):
    # With a valid SSO session, the redirects end on the display page.
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    with opener.open(authorize_url(issuer, idp)) as response:
        url = response.url
        page = response.read().decode()
    if urllib.parse.urlsplit(url).path != "/oauth/token/display":
        if not idp and "idp=" in page:
            raise TokenError(
                "more than one identity provider, set idp in the configuration"
            )
        raise NoSession(f"no SSO session for {issuer}")

    form = Form()
    form.feed(page)
    data = urllib.parse.urlencode(form.fields).encode()
    with opener.open(urllib.parse.urljoin(url, form.action), data) as response:
        page = response.read().decode()
    match = re.search(r"sha256~[\w-]+", page)
    if not match:
        raise TokenError(f"no token on {url}")
    return match.group()


def login(firefox, context, issuer, idp):
    # Without a session, open the login page and wait for the cookies.
    # Firefox writes session cookies to disk every 15 seconds.
    try:
        return get_token(firefox.cookies(), issuer, idp)
    except NoSession:
        pass
    print(
        f"{context}: log in with Firefox, waiting up to {WAIT} seconds", file=sys.stderr
    )
    firefox.open(authorize_url(issuer, idp))
    deadline = time.monotonic() + WAIT
    while time.monotonic() < deadline:
        time.sleep(POLL)
        try:
            return get_token(firefox.cookies(), issuer, idp)
        except NoSession:
            pass
    raise TokenError(f"no login within {WAIT} seconds")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "contexts",
        nargs="*",
        help="kubectl contexts (default: contexts in the configuration)",
    )
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=CONFIG,
        help=f"configuration file (default: {CONFIG})",
    )
    parser.add_argument(
        "-l", "--list", action="store_true", help="list the kubectl contexts and exit"
    )
    args = parser.parse_args()

    try:
        config = configparser.ConfigParser()
        if not config.read(args.config):
            raise TokenError(f"no configuration file: {args.config}")
        configured = config.get("openshift", "contexts", fallback="").split()
        if not shutil.which("kubectl"):
            raise TokenError("kubectl not found in PATH")
        kube = kube_contexts()
        if args.list:
            list_contexts(kube, configured)
            return
        if not config.has_option("firefox", "container"):
            raise TokenError(f"no container in section [firefox] of {args.config}")
        profile = config.get("firefox", "profile", fallback="")
        firefox = Firefox(
            Path(profile).expanduser() if profile else default_profile(),
            config["firefox"]["container"],
        )
        firefox.check()
        idp = config.get("openshift", "idp", fallback="")
        contexts = args.contexts or configured
        if not contexts:
            raise TokenError(
                f"no contexts on the command line or in section [openshift] of {args.config}"
            )
    except (
        configparser.Error,
        TokenError,
        OSError,
        ValueError,
        KeyError,
        subprocess.CalledProcessError,
    ) as e:
        sys.exit(f"error: {e}")

    failed = False
    for context in contexts:
        try:
            if context not in kube:
                raise TokenError("no such context in kubeconfig")
            user, server = kube[context]
            token = login(firefox, context, oauth_issuer(server), idp)
            subprocess.run(
                ["kubectl", "config", "set-credentials", user, f"--token={token}"],
                check=True,
                capture_output=True,
            )
            whoami = subprocess.run(
                [
                    "kubectl",
                    "--context",
                    context,
                    "auth",
                    "whoami",
                    "-o",
                    "jsonpath={.status.userInfo.username}",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            print(
                f"{context}: set token for {user}, logged in as {whoami.stdout}",
                flush=True,
            )
        except (
            TokenError,
            OSError,
            ValueError,
            sqlite3.Error,
            subprocess.CalledProcessError,
        ) as e:
            print(f"{context}: error: {e}", file=sys.stderr)
            failed = True
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
