#!/usr/bin/env bash
set -euo pipefail

# Optionally accept an already downloaded upstream source archive.
if (( $# > 1 )); then
    echo "Usage: $0 [source-archive.tar.gz]" >&2
    exit 1
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
debian_version=$(dpkg-parsechangelog -l "$repo_dir/packaging/debian/changelog" -S Version)
version=${debian_version%-*}
archive_name="peercoin_${version}.orig.tar.gz"
build_dir="$repo_dir/.build/source"
archive="$build_dir/$archive_name"
mkdir -p "$build_dir"

if (( $# == 1 )); then
    cp -- "$1" "$archive"
elif [[ ! -f "$archive" ]]; then
    curl --fail --location --retry 3 \
        "https://github.com/peercoin/peercoin/archive/refs/tags/v${version}ppc.tar.gz" \
        --output "$archive.part"
    mv -- "$archive.part" "$archive"
fi

(cd "$build_dir" && sha256sum --check "$repo_dir/packaging/SHA256SUMS")

work_dir=$(mktemp -d "$build_dir/.prepare.XXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT
ln -s -- "$archive" "$work_dir/$archive_name"
tar -xzf "$archive" -C "$work_dir"
source_dir="$work_dir/peercoin-${version}ppc"
cp -a -- "$repo_dir/packaging/debian" "$source_dir/debian"

(cd "$work_dir" && dpkg-source -b "peercoin-${version}ppc")
cp -- "$work_dir/peercoin_${debian_version}.dsc" \
    "$work_dir/peercoin_${debian_version}.debian.tar.xz" "$build_dir/"
printf '\nSource package ready: %s/peercoin_%s.dsc\n' "$build_dir" "$debian_version"
