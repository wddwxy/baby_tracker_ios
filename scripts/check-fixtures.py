#!/usr/bin/env python3
"""Validate the synthetic fixtures under ``ios/Tests/Fixtures``.

Runs without Xcode, so the fixtures can be checked on the same machine that edits them
(plan test 01-06 also relies on fixtures being synthetic and self-contained).

Checks, per dataset:

* the JSON parses and carries exactly the expected top-level keys,
* ``id`` matches the file name,
* ``capturedAt`` is an ISO 8601 UTC instant,
* ``profile`` is either null or a complete profile,
* ``settings.volumeUnit`` is one of the units the app knows,
* every entry has the required fields, a known ``kind``, a unique id, an instant before
  the capture instant, and the list is sorted newest first,
* the expected entry count and activity coverage for that dataset.

Exit code is 0 when every fixture is valid.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
FIXTURES_DIR = REPO_ROOT / "Tests" / "Fixtures"

TOP_LEVEL_KEYS = {"id", "capturedAt", "timeZoneIdentifier", "profile", "settings", "recentEntries"}
ENTRY_KEYS = {"id", "kind", "occurredAt", "title", "detail"}
VOLUME_UNITS = {"millilitre", "fluidOunce"}
ENTRY_KINDS = {
    "bottle",
    "breastfeeding",
    "diaper",
    "sleep",
    "pump",
    "solids",
    "growth",
    "health",
}

# What each dataset is supposed to contain. Keep in sync with
# ios/Sources/Domain/Demo/DemoFixtures.swift and ios/Tests/Fixtures/README.md.
EXPECTED = {
    "f0": {"entries": 0, "profile": False},
    "f1": {"entries": 8, "profile": True},
}

ISO_UTC = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


def parse_instant(value: object, where: str, problems: list[str]) -> datetime | None:
    if not isinstance(value, str) or not ISO_UTC.match(value):
        problems.append(f"{where}: expected an ISO 8601 UTC instant, got {value!r}")
        return None
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")


def validate(path: Path) -> list[str]:
    problems: list[str] = []
    dataset_id = path.stem.lower()

    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return [f"{path.name}: not valid JSON ({error})"]

    if not isinstance(document, dict):
        return [f"{path.name}: expected a JSON object"]

    keys = set(document)
    if keys != TOP_LEVEL_KEYS:
        problems.append(f"{path.name}: top-level keys are {sorted(keys)}, expected {sorted(TOP_LEVEL_KEYS)}")

    if document.get("id") != dataset_id:
        problems.append(f"{path.name}: id is {document.get('id')!r}, expected {dataset_id!r}")

    captured_at = parse_instant(document.get("capturedAt"), f"{path.name}.capturedAt", problems)

    if not isinstance(document.get("timeZoneIdentifier"), str) or not document["timeZoneIdentifier"]:
        problems.append(f"{path.name}: timeZoneIdentifier must be a non-empty string")

    profile = document.get("profile")
    if profile is not None:
        if not isinstance(profile, dict) or set(profile) != {"name", "dateOfBirth"}:
            problems.append(f"{path.name}: profile must be null or {{name, dateOfBirth}}")
        else:
            if not profile["name"]:
                problems.append(f"{path.name}.profile: name must not be empty")
            parse_instant(profile["dateOfBirth"], f"{path.name}.profile.dateOfBirth", problems)

    settings = document.get("settings")
    if not isinstance(settings, dict) or set(settings) != {"volumeUnit", "caregiverName"}:
        problems.append(f"{path.name}: settings must be {{volumeUnit, caregiverName}}")
    elif settings["volumeUnit"] not in VOLUME_UNITS:
        problems.append(f"{path.name}.settings.volumeUnit is {settings['volumeUnit']!r}, expected one of {sorted(VOLUME_UNITS)}")

    entries = document.get("recentEntries")
    if not isinstance(entries, list):
        problems.append(f"{path.name}: recentEntries must be an array")
        entries = []

    seen_ids: set[str] = set()
    instants: list[datetime] = []
    for index, entry in enumerate(entries):
        where = f"{path.name}.recentEntries[{index}]"
        if not isinstance(entry, dict) or set(entry) != ENTRY_KEYS:
            problems.append(f"{where}: expected exactly {sorted(ENTRY_KEYS)}")
            continue
        if not isinstance(entry["id"], str) or not entry["id"]:
            problems.append(f"{where}: id must be a non-empty string")
        elif entry["id"] in seen_ids:
            problems.append(f"{where}: duplicate id {entry['id']!r}")
        else:
            seen_ids.add(entry["id"])
        if entry["kind"] not in ENTRY_KINDS:
            problems.append(f"{where}: unknown kind {entry['kind']!r}")
        if not entry["title"]:
            problems.append(f"{where}: title must not be empty")
        if not isinstance(entry["detail"], str):
            problems.append(f"{where}: detail must be a string")
        instant = parse_instant(entry["occurredAt"], f"{where}.occurredAt", problems)
        if instant is not None:
            instants.append(instant)
            if captured_at is not None and instant >= captured_at:
                problems.append(f"{where}: occurredAt is not before capturedAt")

    if instants and instants != sorted(instants, reverse=True):
        problems.append(f"{path.name}: recentEntries must be sorted newest first")

    expected = EXPECTED.get(dataset_id)
    if expected is None:
        problems.append(f"{path.name}: no expectation declared for dataset {dataset_id!r}")
    else:
        if len(entries) != expected["entries"]:
            problems.append(f"{path.name}: has {len(entries)} entries, expected {expected['entries']}")
        if (profile is not None) != expected["profile"]:
            problems.append(f"{path.name}: profile presence does not match the dataset contract")
        if dataset_id == "f1":
            kinds = {entry.get("kind") for entry in entries if isinstance(entry, dict)}
            if kinds != ENTRY_KINDS:
                problems.append(f"{path.name}: activity coverage is {sorted(kinds)}, expected every family")

    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--fixtures", default=str(FIXTURES_DIR))
    args = parser.parse_args()

    directory = Path(args.fixtures)
    files = sorted(directory.glob("*.json"))
    if not files:
        print(f"no fixtures found in {directory}", file=sys.stderr)
        return 1

    all_problems: list[str] = []
    for path in files:
        problems = validate(path)
        status = "PASS" if not problems else "FAIL"
        print(f"{status} {path.name}")
        for problem in problems:
            print(f"     {problem}")
        all_problems.extend(problems)

    print(f"\n{len(files)} fixture file(s), {len(all_problems)} problem(s)")
    return 1 if all_problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
