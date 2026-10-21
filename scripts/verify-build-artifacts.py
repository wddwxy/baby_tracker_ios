#!/usr/bin/env python3
"""Check that the prototype checkout (and optionally a built app) leaks nothing.

Plan test 01-06: "检查构建产物、配置和日志 -> 不包含 token、cookie、生产导出".

Three checks:

1. no data files are committed under ``ios/`` (databases, CSV exports, photos,
   provisioning profiles, signing material);
2. build-affecting files carry no personal absolute paths, so a clean checkout builds
   anywhere (plan test 01-01);
3. build-affecting files and Swift sources carry no credential markers.

With ``--app-bundle`` the built product is checked for the same data-file types, which
catches a fixture that accidentally got copied into the bundle as a real export.

Exit code is 0 when nothing is found.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ROOT = REPO_ROOT

FORBIDDEN_SUFFIXES = {
    ".sqlite",
    ".sqlite-wal",
    ".sqlite-shm",
    ".db",
    ".csv",
    ".heic",
    ".heif",
    ".pem",
    ".p12",
    ".mobileprovision",
    ".ipa",
    ".xcarchive",
}

# Files whose content decides how the project builds.
BUILD_SUFFIXES = {
    ".pbxproj",
    ".xcconfig",
    ".plist",
    ".entitlements",
    ".xcscheme",
    ".xcworkspacedata",
    ".swift",
    ".sh",
    ".py",
}

# Absolute home directories of a specific person. A relative path or $(inherited) is fine.
ABSOLUTE_PATH_PATTERNS = [
    re.compile(r"[A-Za-z]:[\\/]Users[\\/][^\\/\s\"']+"),
    re.compile(r"/Users/[A-Za-z0-9._-]+/"),
    re.compile(r"/home/[A-Za-z0-9._-]+/"),
]

# Credential markers that must never be checked in.
SECRET_PATTERNS = [
    re.compile(r"ingress_session"),
    re.compile(r"refresh_token"),
    re.compile(r"access_token"),
    re.compile(r"client_secret"),
    re.compile(r"SUPERVISOR_TOKEN"),
    re.compile(r"Authorization:\s*Bearer"),
]

# Names that look like a production export rather than a synthetic fixture.
EXPORT_NAME_PATTERN = re.compile(r"(export_|narababy|backup-)", re.IGNORECASE)

# Synthetic fixtures are named F0/F1.. and are fine; these are the known-good ones.
ALLOWED_DATA_LIKE_FILES = {"F0.json", "F1.json"}

# This scanner lists the forbidden markers as patterns, so it must not scan itself.
SKIPPED_FILE_NAMES = {"verify-build-artifacts.py"}


def iter_files(root: Path):
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if path.name in SKIPPED_FILE_NAMES:
            continue
        if any(part in {".git", ".ios-test-data", "DerivedData", "build", "xcuserdata", "__pycache__"} for part in path.parts):
            continue
        yield path


def check_tree(root: Path) -> list[str]:
    findings: list[str] = []

    for path in iter_files(root):
        relative = path.relative_to(root)

        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            findings.append(f"{relative}: forbidden data file type ({path.suffix})")
            continue

        if EXPORT_NAME_PATTERN.search(path.name) and path.name not in ALLOWED_DATA_LIKE_FILES:
            findings.append(f"{relative}: file name looks like a production export")

        if path.suffix.lower() not in BUILD_SUFFIXES:
            continue

        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as error:
            findings.append(f"{relative}: unreadable ({error})")
            continue

        for line_number, line in enumerate(text.splitlines(), start=1):
            for pattern in ABSOLUTE_PATH_PATTERNS:
                match = pattern.search(line)
                if match:
                    findings.append(f"{relative}:{line_number}: personal absolute path {match.group(0)!r}")
            for pattern in SECRET_PATTERNS:
                match = pattern.search(line)
                if match:
                    findings.append(f"{relative}:{line_number}: credential marker {match.group(0)!r}")

    return findings


def check_app_bundle(bundle: Path) -> list[str]:
    findings: list[str] = []

    if not bundle.exists():
        return [f"{bundle}: app bundle does not exist"]

    for path in sorted(bundle.rglob("*")):
        if not path.is_file():
            continue
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            findings.append(f"{bundle.name}/{path.relative_to(bundle)}: forbidden data file type ({path.suffix})")
        if EXPORT_NAME_PATTERN.search(path.name):
            findings.append(f"{bundle.name}/{path.relative_to(bundle)}: file name looks like a production export")

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="directory to check (default: ios/)")
    parser.add_argument("--app-bundle", help="optional path to a built .app to check as well")
    args = parser.parse_args()

    findings = check_tree(Path(args.root))
    if args.app_bundle:
        findings.extend(check_app_bundle(Path(args.app_bundle)))

    if findings:
        for finding in findings:
            print(f"FAIL {finding}")
        print(f"\n{len(findings)} problem(s) found", file=sys.stderr)
        return 1

    print(f"PASS no data files, personal absolute paths or credential markers under {args.root}")
    if args.app_bundle:
        print(f"PASS no data files or export-looking names inside {args.app_bundle}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
