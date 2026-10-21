#!/usr/bin/env python3
"""Boot the Little Nest service against an isolated data directory and read /health.

Plan test 01-03: "以 F0 启动后端并读取健康状态 -> 数据目录指向隔离目录，不含生产数据".

This script never touches the Home Assistant app data directory. It:

1. resolves the app package the same way ``scripts/run_local_preview.py`` does
   (``.github-publish/baby_tracker`` when present, otherwise ``baby_tracker``),
2. points ``BABY_TRACKER_DATA`` at ``<repo>/.ios-test-data/<dataset>``,
3. starts the service on loopback,
4. reads ``/health`` and asserts it is 200/ok,
5. asserts the resolved data directory is the isolated one.

It is safe to run on Windows: only the source checkout and the Python service are
involved, no Xcode and no Home Assistant.

Examples
--------
    python scripts/run-isolated-backend.py --reset
    python scripts/run-isolated-backend.py --keep-running --port 8099
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import sys
from pathlib import Path

IOS_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = IOS_DIR
WORKSPACE_ROOT = IOS_DIR.parent
TEST_DATA_ROOT = REPO_ROOT / ".ios-test-data"

# Only F0 exists for now: an empty profile with no records, i.e. a fresh database.
# F1..F6 are seeded by the steps that consume them (see Tests/Fixtures/README.md).
SUPPORTED_DATASETS = ("f0",)


def resolve_candidate(explicit: str | None) -> Path:
    if explicit:
        candidate = Path(explicit).resolve()
        if not (candidate / "app.py").is_file():
            raise SystemExit(f"--candidate does not contain app.py: {candidate}")
        return candidate

    published = WORKSPACE_ROOT / ".github-publish" / "baby_tracker"
    if (published / "app.py").is_file():
        return published

    local = WORKSPACE_ROOT / "baby_tracker"
    if (local / "app.py").is_file():
        return local

    raise SystemExit("Backend is not bundled in this iOS repository. Clone wddwxy/baby_tracker separately and pass --candidate /path/to/baby_tracker/baby_tracker")


def read_app_metadata(candidate: Path) -> dict[str, str]:
    config = (candidate / "config.yaml").read_text(encoding="utf-8")

    def field(name: str) -> str:
        match = re.search(rf'^{name}:\s*"?([^"\n]+)"?', config, re.M)
        return match.group(1).strip() if match else "unknown"

    return {
        "name": field("name"),
        "version": field("version"),
        "slug": field("slug"),
    }


def prepare_data_dir(dataset: str, reset: bool) -> Path:
    data_dir = (TEST_DATA_ROOT / dataset).resolve()
    if data_dir.exists() and reset:
        import shutil

        shutil.rmtree(data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir


def resolve_port(runner, site, requested: int) -> int:
    if requested:
        return requested
    addresses = getattr(runner, "addresses", None)
    if addresses:
        return int(addresses[0][1])
    return int(site._server.sockets[0].getsockname()[1])


async def run(args: argparse.Namespace) -> int:
    candidate = resolve_candidate(args.candidate)
    metadata = read_app_metadata(candidate)
    data_dir = prepare_data_dir(args.dataset, args.reset)

    # The vendored test dependencies are what the repository's own preview launcher uses.
    vendored = WORKSPACE_ROOT / ".testdeps"
    if vendored.is_dir():
        sys.path.insert(0, str(vendored))
    sys.path.insert(0, str(candidate))

    os.environ["BABY_TRACKER_DEV"] = "1"
    os.environ["BABY_TRACKER_DATA"] = str(data_dir)
    os.environ["BABY_TRACKER_VERSION"] = f"{metadata['version']}-ios-test"

    import app  # noqa: E402  (import order matters: the environment must be set first)
    import aiohttp  # noqa: E402
    from aiohttp import web  # noqa: E402

    resolved_data_dir = Path(app.DATA_DIR).resolve()
    problems: list[str] = []
    if resolved_data_dir != data_dir:
        problems.append(f"DATA_DIR is {resolved_data_dir}, expected {data_dir}")
    if not resolved_data_dir.is_relative_to(REPO_ROOT):
        problems.append(f"DATA_DIR {resolved_data_dir} is outside the repository")
    if str(resolved_data_dir) in ("/data", "\\data"):
        problems.append("DATA_DIR points at the Home Assistant app data directory")

    print(f"app package : {candidate}")
    print(f"app         : {metadata['name']} {metadata['version']} (slug={metadata['slug']})")
    print(f"dataset     : {args.dataset.upper()} (isolated, synthetic)")
    print(f"DATA_DIR    : {resolved_data_dir}")
    print(f"DB_PATH     : {Path(app.DB_PATH).resolve()}")

    if problems:
        for problem in problems:
            print(f"ISOLATION FAILURE: {problem}", file=sys.stderr)
        return 1

    application = app.create_app()
    runner = web.AppRunner(application)
    await runner.setup()
    site = web.TCPSite(runner, args.host, args.port)
    await site.start()
    port = resolve_port(runner, site, args.port)
    base_url = f"http://{args.host}:{port}"
    print(f"listening   : {base_url}")

    exit_code = 1
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{base_url}/health", timeout=aiohttp.ClientTimeout(total=30)) as response:
                body = await response.text()
                status = response.status

        print(f"GET /health : {status}")
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            print("health body is not JSON; the service returned something unexpected", file=sys.stderr)
            print(body[:400], file=sys.stderr)
            return 1

        print(f"health      : {json.dumps(payload, ensure_ascii=False)[:200]}")

        if status != 200:
            print(f"/health returned {status}, expected 200", file=sys.stderr)
            return 1
        if payload.get("status") != "ok":
            print(f"/health status is {payload.get('status')!r}, expected 'ok'", file=sys.stderr)
            return 1
        if not payload.get("alive") or not payload.get("ready"):
            print("service is not both alive and ready", file=sys.stderr)
            return 1

        created = sorted(path.name for path in resolved_data_dir.iterdir())
        print(f"data files  : {created}")
        print("RESULT      : PASS (isolated F0 service reachable and healthy)")
        exit_code = 0

        if args.keep_running:
            print("keeping the service running; press Ctrl+C to stop")
            await asyncio.Event().wait()
    finally:
        await runner.cleanup()

    return exit_code


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dataset", default="f0", choices=SUPPORTED_DATASETS, help="synthetic dataset to boot with")
    parser.add_argument("--candidate", help="app package inside the workspace; defaults to the publication checkout")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=0, help="0 picks a free port")
    parser.add_argument("--reset", action="store_true", help="delete the isolated data directory first")
    parser.add_argument("--keep-running", action="store_true", help="serve until interrupted, for manual browsing")
    args = parser.parse_args()

    try:
        return asyncio.run(run(args))
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
