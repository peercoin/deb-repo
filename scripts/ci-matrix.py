#!/usr/bin/env python3
"""Select APT targets for releases, manual builds, or test tags."""

import json
import os
from pathlib import Path

targets = []
config = Path(__file__).resolve().parents[1] / "conf/distributions"
for line in config.read_text().splitlines():
    if line.startswith("Codename:"):
        distro = line.split()[1]
    elif line.startswith("Architectures:"):
        for arch in line.split()[1:]:
            targets.append({
                "os": "ubuntu" if distro == "jammy" else "raspbian" if arch == "armhf" else "debian",
                "dist": distro,
                "arch": arch,
                "runner": "ubuntu-26.04-arm" if arch == "arm64" else "ubuntu-26.04",
                "qemu": {"armhf": "arm", "riscv64": "riscv64"}.get(arch, ""),
            })

tag = os.environ["GITHUB_REF_NAME"]
if tag.startswith("test/"):
    parts = tag.split("/", 3)
    if len(parts) != 4 or not parts[3]:
        raise SystemExit("Use a test tag in the form test/<distro>/<arch>/<label>.")
    targets = [target for target in targets if (target["dist"], target["arch"]) == tuple(parts[1:3])]
    if not targets:
        raise SystemExit(f"Unsupported test target: {parts[1]}/{parts[2]}")
elif os.environ.get("GITHUB_EVENT_NAME") != "workflow_dispatch":
    changelog = config.parents[1] / "packaging/debian/changelog"
    version = changelog.read_text().splitlines()[0].split("(", 1)[1].split(")", 1)[0]
    if tag != f"v{version}":
        raise SystemExit(f"Release tag must be v{version}; use test/<distro>/<arch>/<label> for a build-only test.")

print("matrix=" + json.dumps({"include": targets}, separators=(",", ":")))
