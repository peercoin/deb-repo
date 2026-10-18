#!/usr/bin/env bash
set -euo pipefail

# Called with sudo by Actions; local builds can keep using pbuilder directly.
if (( EUID != 0 )); then
    echo "This script needs root to create and run the pbuilder chroot." >&2
    exit 1
fi
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/packaging/pbuilderrc"
result_dir="$repo_dir/.build/$DIST-$ARCH"
key_dir="$repo_dir/.build/keyrings"
mkdir -p "$result_dir" "$key_dir/gnupg" "$APTCACHE"
chmod 700 "$key_dir/gnupg"
export GNUPGHOME="$key_dir/gnupg"
export PBUILDER_KEYRING="$key_dir/$OS-$DIST.gpg"

case "$OS" in
    debian)
        case "$DIST" in
            bullseye) release=11; fingerprint=1F89983E0081FDE018F3CC9673A4F27B8DD47936 ;;
            bookworm) release=12; fingerprint=B8B80B5B623EAB6AD8775C45B7C5D7D6350947F8 ;;
            trixie) release=13; fingerprint=04B54C3CDCA79751B16BC6B5225629DF75B188BD ;;
        esac
        key_url="https://ftp-master.debian.org/keys/archive-key-$release.asc"
        ;;
    raspbian)
        key_url=https://archive.raspbian.org/raspbian.public.key
        fingerprint=A0DA38D0D76E8B5D638872819165938D90FDDD2E
        ;;
    ubuntu)
        cp /usr/share/keyrings/ubuntu-archive-keyring.gpg "$PBUILDER_KEYRING"
        ;;
esac

if [[ "$OS" != ubuntu ]]; then
    curl --fail --location --retry 3 "$key_url" --output "$key_dir/archive.asc"
    actual_fingerprint=$(gpg --batch --show-keys --with-colons "$key_dir/archive.asc" |
        awk -F: '$1 == "fpr" { print $10; exit }')
    if [[ "$actual_fingerprint" != "$fingerprint" ]]; then
        echo "Unexpected $OS archive signing key: $actual_fingerprint" >&2
        exit 1
    fi
    gpg --batch --yes --dearmor --output "$PBUILDER_KEYRING" "$key_dir/archive.asc"
fi

pbuilder create --configfile "$repo_dir/packaging/pbuilderrc" \
    --logfile "$result_dir/create.log"
debian_version=$(dpkg-parsechangelog -l "$repo_dir/packaging/debian/changelog" -S Version)
pbuilder build --configfile "$repo_dir/packaging/pbuilderrc" \
    --buildresult "$result_dir" --logfile "$result_dir/build.log" \
    "$repo_dir/.build/source/peercoin_${debian_version}.dsc"

shopt -s nullglob
debs=("$result_dir"/peercoind_*.deb "$result_dir"/peercoin-qt_*.deb "$result_dir"/peercoin-tx_*.deb)
if (( ${#debs[@]} != 3 )); then
    echo "Expected three binary packages, found ${#debs[@]}." >&2
    exit 1
fi
for deb in "${debs[@]}"; do
    [[ $(dpkg-deb -f "$deb" Architecture) == "$ARCH" ]]
    [[ $(dpkg-deb -f "$deb" Version) == "$debian_version" ]]
done
