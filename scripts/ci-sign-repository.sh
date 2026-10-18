#!/usr/bin/env bash
set -euo pipefail

: "${APT_SIGNING_KEY:?Set APT_SIGNING_KEY to the ASCII-armored private signing key}"
: "${APT_SIGNING_PASSPHRASE?Set APT_SIGNING_PASSPHRASE (empty for an unencrypted key)}"
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apt_dir="$repo_dir/.build/apt-repo"
site_dir="$repo_dir/.build/site"
packages_dir="$repo_dir/.build/packages"
debian_version=$(dpkg-parsechangelog -l "$repo_dir/packaging/debian/changelog" -S Version)
export GNUPGHOME
GNUPGHOME=$(mktemp -d)
trap 'gpgconf --kill gpg-agent; rm -rf -- "$GNUPGHOME"' EXIT
printf 'allow-loopback-pinentry\ndefault-cache-ttl 7200\nmax-cache-ttl 7200\n' > "$GNUPGHOME/gpg-agent.conf"
printf '%s' "$APT_SIGNING_KEY" | gpg --batch --import
unset APT_SIGNING_KEY
mapfile -t signing_keys < <(awk '/^SignWith:/ { print $2 }' "$repo_dir/conf/distributions" | sort -u)
if (( ${#signing_keys[@]} != 1 )); then
    echo "Expected one repository signing key in conf/distributions." >&2
    exit 1
fi
signing_key=${signing_keys[0]}
gpg --batch --list-secret-keys "$signing_key" > /dev/null

# Unlock once; reprepro/GPGME then uses the agent's cached passphrase.
printf '%s' "$APT_SIGNING_PASSPHRASE" | gpg --batch --yes \
    --pinentry-mode loopback --passphrase-fd 0 --local-user "$signing_key" \
    --detach-sign --output "$GNUPGHOME/check.sig" "$repo_dir/packaging/SHA256SUMS"
unset APT_SIGNING_PASSPHRASE

mkdir -p "$apt_dir" "$site_dir"
cp -a "$repo_dir/conf" "$repo_dir/db" "$repo_dir/dists" "$repo_dir/pool" "$apt_dir/"
shopt -s nullglob
while read -r distro arch; do
    debs=("$packages_dir/packages-$distro-$arch"/*.deb)
    if (( ${#debs[@]} != 3 )); then
        echo "Expected three packages for $distro/$arch, found ${#debs[@]}." >&2
        exit 1
    fi
    names=()
    for deb in "${debs[@]}"; do
        [[ $(dpkg-deb -f "$deb" Architecture) == "$arch" ]]
        [[ $(dpkg-deb -f "$deb" Version) == "$debian_version" ]]
        names+=("$(dpkg-deb -f "$deb" Package)")
    done
    [[ $(printf '%s\n' "${names[@]}" | sort | tr '\n' ' ') == 'peercoin-qt peercoin-tx peercoind ' ]]
    reprepro --basedir "$apt_dir" --export=never includedeb "$distro" "${debs[@]}"
done < <(awk '/^Codename:/ { distro=$2 } /^Architectures:/ { for (i=2; i<=NF; i++) print distro, $i }' "$repo_dir/conf/distributions")

reprepro --basedir "$apt_dir" export
reprepro --basedir "$apt_dir" check
while read -r distro; do
    gpg --batch --verify "$apt_dir/dists/$distro/InRelease"
    gpg --batch --verify "$apt_dir/dists/$distro/Release.gpg" "$apt_dir/dists/$distro/Release"
done < <(awk '/^Codename:/ { print $2 }' "$repo_dir/conf/distributions")

cp -a "$apt_dir/dists" "$apt_dir/pool" "$site_dir/"
gpg --batch --export "$signing_key" > "$site_dir/peercoin.apt.key"
touch "$site_dir/.nojekyll"
printf '\nSigned APT repository ready in %s\n' "$site_dir"
