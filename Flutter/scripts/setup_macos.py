#!/usr/bin/env python3
"""Prepare the ignored macOS runners; optionally build every Flutter example."""

import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
MIN_MACOS = "12.0"  # Xcode 27 no longer builds targets below macOS 12.
POD_MARKER = "# Repository minimum macOS version (setup_macos.py)."
POD_SETTINGS = f"""
    {POD_MARKER}
    target.build_configurations.each do |config|
      deployment_target = config.build_settings['MACOSX_DEPLOYMENT_TARGET']
      if deployment_target.nil? || Gem::Version.new(deployment_target) < Gem::Version.new('{MIN_MACOS}')
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '{MIN_MACOS}'
      end
    end"""


def run(*command, cwd):
    print(f"  $ {' '.join(map(str, command))}", flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def write_changed(path, content):
    if not path.exists() or path.read_text() != content:
        path.write_text(content)


def raise_version(match):
    version = tuple(map(int, match[1].split('.')))
    return match[0].replace(match[1], MIN_MACOS) if version < (12, 0) else match[0]


def prepare(project, flutter_root, build):
    macos = project / 'macos'
    xcode = macos / 'Runner.xcodeproj/project.pbxproj'
    if not xcode.exists():
        name = re.search(r'^name:\s*(\w+)', (project / 'pubspec.yaml').read_text(), re.M)[1]
        run('flutter', 'create', '--platforms=macos', '--no-pub',
            f'--project-name={name}', '.', cwd=project)

    run('flutter', 'pub', 'get', cwd=project)
    write_changed(xcode, re.sub(r'MACOSX_DEPLOYMENT_TARGET = ([\d.]+);',
                               raise_version, xcode.read_text()))

    # These examples open network connections or let the user select files.
    relative = project.relative_to(ROOT).as_posix()
    permissions = []
    if relative.startswith(('07 Func calls/', '08 WebSockets/')) or project.name == 'exemple0401':
        permissions.append('com.apple.security.network.client')
    if project.name == 'exemple0400':
        permissions.append('com.apple.security.files.user-selected.read-write')
    for path in (macos / 'Runner').glob('*.entitlements'):
        content = path.read_text()
        existing = plistlib.loads(content.encode())
        for permission in permissions:
            if permission not in existing:
                content = content.replace('</dict>', f'\t<key>{permission}</key>\n\t<true/>\n</dict>')
        write_changed(path, content)

    plugins_file = project / '.flutter-plugins-dependencies'
    plugins = json.loads(plugins_file.read_text()).get('plugins', {}).get('macos', []) if plugins_file.exists() else []
    podfile = macos / 'Podfile'
    if plugins or podfile.exists():
        template = flutter_root / 'packages/flutter_tools/templates/cocoapods/Podfile-macos'
        content = podfile.read_text() if podfile.exists() else template.read_text()
        content = re.sub(r"platform :osx, '([\d.]+)'", raise_version, content)
        if POD_MARKER not in content:
            helper = '    flutter_additional_macos_build_settings(target)'
            if helper not in content:
                raise RuntimeError(f'Cannot locate Flutter post_install hook in {podfile}')
            content = content.replace(helper, helper + POD_SETTINGS)
        write_changed(podfile, content)
        for mode in ('Debug', 'Release'):
            config = macos / f'Flutter/Flutter-{mode}.xcconfig'
            include = f'#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.{mode.lower()}.xcconfig"'
            content = config.read_text()
            if include not in content:
                write_changed(config, include + '\n' + content)
        # Generate the SDK paths and let Flutter install/synchronize CocoaPods.
        run('flutter', 'build', 'macos', '--config-only', '--debug', cwd=project)

    if build:
        run('flutter', 'build', 'macos', '--debug', '--no-pub', cwd=project)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', action='store_true', help='Also verify a debug macOS build of each project')
    parser.add_argument('projects', nargs='*', type=Path, help='Optional project directories (default: all examples)')
    args = parser.parse_args()
    if sys.platform != 'darwin':
        parser.error('Run this script on macOS with Xcode installed.')
    for command in ('flutter', 'pod', 'xcodebuild'):
        if not shutil.which(command):
            parser.error(f'{command} must be available on PATH.')
    # Flutter reports its SDK path even when installed through a shim or wrapper.
    info = json.loads(subprocess.check_output(['flutter', '--version', '--machine'], text=True))
    flutter_root = Path(info['flutterRoot'])
    os.environ.setdefault('COCOAPODS_DISABLE_STATS', 'true')
    projects = [p.resolve() for p in args.projects] if args.projects else sorted(
        p.parent for p in ROOT.rglob('pubspec.yaml')
        if not any(part in {'build', '.dart_tool', '.symlinks', 'ephemeral', '.pub-cache'} for part in p.relative_to(ROOT).parts)
    )
    failures = []
    for index, project in enumerate(projects, 1):
        print(f'\n[{index}/{len(projects)}] {project.relative_to(ROOT)}', flush=True)
        try:
            prepare(project, flutter_root, args.build)
        except (subprocess.CalledProcessError, OSError, RuntimeError) as error:
            failures.append(project)
            print(f'FAILED: {error}', file=sys.stderr, flush=True)
    print(f'\nFinished: {len(projects) - len(failures)}/{len(projects)} successful.', flush=True)
    for project in failures:
        print(f'  FAILED: {project.relative_to(ROOT)}', flush=True)
    return bool(failures)


if __name__ == '__main__':
    sys.exit(main())
