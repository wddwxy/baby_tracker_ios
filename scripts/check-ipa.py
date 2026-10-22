#!/usr/bin/env python3
"""Validate the device platform and executable of our unsigned IPA, without Xcode."""
import argparse
import hashlib
import json
import plistlib
import struct
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


def inspect_ipa(path):
    with ZipFile(path) as archive:
        names = archive.namelist()
        if any(PurePosixPath(name).is_absolute() or '..' in PurePosixPath(name).parts for name in names):
            raise ValueError('Unsafe ZIP path')
        info_name = 'Payload/LittleNest.app/Info.plist'
        info = plistlib.loads(archive.read(info_name))
        if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError('Expected iPhoneOS, not a simulator app')
        executable = info['CFBundleExecutable']
        if PurePosixPath(executable).name != executable:
            raise ValueError('Invalid executable path')
        binary = archive.read('Payload/LittleNest.app/' + executable)
        if len(binary) < 32:
            raise ValueError('Truncated Mach-O')
        magic, cpu, _, _, commands, command_bytes, _, _ = struct.unpack_from('<8I', binary)
        if magic != 0xFEEDFACF or cpu != 0x0100000C:
            raise ValueError('Expected a thin arm64 Mach-O executable')
        end = 32 + command_bytes
        if end > len(binary):
            raise ValueError('Truncated Mach-O load commands')
        offset, platforms = 32, []
        for _ in range(commands):
            if offset + 8 > end:
                raise ValueError('Truncated load command')
            command, size = struct.unpack_from('<2I', binary, offset)
            if size < 8 or offset + size > end:
                raise ValueError('Invalid load command size')
            if command == 0x32:
                if size < 24:
                    raise ValueError('Truncated build-version command')
                platforms.append(struct.unpack_from('<I', binary, offset + 8)[0])
            offset += size
        if platforms != [2]:
            raise ValueError('Executable is not built for the physical iOS platform')
        if any(name.endswith('embedded.mobileprovision') or '/_CodeSignature/' in name for name in names):
            raise ValueError('Expected an unsigned package without signing material')
    return {
        'file': path.name,
        'bundle_id': info['CFBundleIdentifier'],
        'version': info.get('CFBundleShortVersionString'),
        'build': info.get('CFBundleVersion'),
        'minimum_ios': info.get('MinimumOSVersion'),
        'platform': 'iPhoneOS',
        'architecture': 'arm64',
        'signed': False,
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'bytes': path.stat().st_size,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', type=Path)
    parser.add_argument('--metadata', type=Path)
    args = parser.parse_args()
    try:
        result = inspect_ipa(args.ipa)
    except (ValueError, KeyError, struct.error) as error:
        raise SystemExit(f'IPA validation failed: {error}') from None
    rendered = json.dumps(result, indent=2)
    print(rendered)
    if args.metadata:
        args.metadata.write_text(rendered + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
