#!/usr/bin/env python3
"""Run isolated World 3 integration scenarios on an already booted iOS simulator."""

import argparse
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='Booted simulator UDID')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--skip-build', action='store_true',
                        help='Reuse the integration app built by a previous run')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    os.chdir(root)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    target = 'integration_test/world3_native_test.dart'
    if not args.skip_build:
        subprocess.run(['flutter', 'build', 'ios', '--simulator', '--debug',
                        '--no-pub', '--target', target], check=True)

    with tempfile.TemporaryDirectory(prefix='sundoku-world3-qa-') as temporary:
        # Keep Runner.app/Runner matching so Flutter can discover the VM logs.
        app = Path(temporary) / 'Runner.app'
        shutil.copytree(root / 'build/ios/iphonesimulator/Runner.app', app)
        plist = app / 'Info.plist'
        with plist.open('rb') as file:
            data = plistlib.load(file)
        data.update(CFBundleIdentifier='com.krabzik.games.sundoku.w3qa',
                    CFBundleDisplayName='SunDoku QA', UIRequiresFullScreen=True)
        with plist.open('wb') as file:
            plistlib.dump(data, file)
        subprocess.run(['codesign', '--force', '--deep', '--sign', '-', str(app)],
                       check=True)
        # The production bundle and its data container are never installed over.
        subprocess.run([
            'flutter', 'drive', '--no-pub',
            '--driver=test_driver/world3_native_driver.dart', '--target', target,
            '--use-application-binary', str(app), '-d', args.device,
            '--timeout=900',
        ], env={**os.environ, 'W3_NATIVE_OUTPUT': str(output)}, check=True)


if __name__ == '__main__':
    main()
