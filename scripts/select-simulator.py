#!/usr/bin/env python3
"""Select an installed iPhone, avoiding a CI dependency on one device name."""
import json
import subprocess


def main():
    sdk = subprocess.run(
        ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    runtime_suffix = ".iOS-" + sdk.replace(".", "-")
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        check=True, capture_output=True, text=True,
    )
    candidates = [
        device
        for runtime, devices in sorted(json.loads(result.stdout)["devices"].items(), reverse=True)
        if runtime.endswith(runtime_suffix)
        for device in devices
        if device.get("isAvailable") and device["name"].startswith("iPhone")
    ]
    if not candidates:
        raise SystemExit(f"No available iPhone simulator matching iOS SDK {sdk}")
    device = candidates[0]
    print(f"SIMULATOR_UDID={device['udid']}")
    print(f"SIMULATOR_DEVICE={device['name']}")


if __name__ == "__main__":
    main()
