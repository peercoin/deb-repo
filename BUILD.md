# Building

The repository now includes the Debian packaging previously maintained in
[peercoin/packaging](https://github.com/peercoin/packaging), based on the
packaging used for the 0.15.0 builds. It produces `peercoind`, `peercoin-qt` and
`peercoin-tx` version `0.15.2-3`, retaining the existing system-library build
options, including Berkeley DB 5.3 on Debian Bookworm.

Install `curl`, `dpkg-dev` and `xz` on the host for source preparation. From
this repository's root, run this as your regular user:

```bash
./scripts/prepare-source.sh
```

This downloads the [v0.15.2ppc source](https://github.com/peercoin/peercoin/releases/tag/v0.15.2ppc),
checks it against `packaging/SHA256SUMS`, and creates the unsigned source package
`.build/source/peercoin_0.15.2-3.dsc`. To use an existing source download, pass
its path as the script's only argument. Generated source and binary packages
are ignored by Git under `.build/` until deliberately imported into the APT
repository.

`pbuilder` runs on the host and uses the existing base environments under
`/var/cache/pbuilder`. Start with Bookworm amd64:

```bash
mkdir -p .build/bookworm-amd64
sudo env OS=debian DIST=bookworm ARCH=amd64 \
  pbuilder build \
  --configfile "$PWD/packaging/pbuilderrc" \
  --buildresult "$PWD/.build/bookworm-amd64" \
  "$PWD/.build/source/peercoin_0.15.2-3.dsc"
```

This uses the repository's configuration rather than `~/.pbuilderrc`.
Select the other targets using the following environment variables, and use a
separate result directory for each target:

| OS | DIST | ARCH | Base archive in `/var/cache/pbuilder/` |
| --- | --- | --- | --- |
| debian | trixie | amd64 | `debian-trixie-amd64-base.tgz` |
| debian | trixie | arm64 | `debian-trixie-arm64-base.tgz` |
| raspbian | trixie | armhf | `raspbian-trixie-armhf-base.tgz` |
| debian | trixie | riscv64 | `debian-trixie-riscv64-base.tgz` |
| debian | bookworm | amd64 | `debian-bookworm-amd64-base.tgz` |
| debian | bookworm | arm64 | `debian-bookworm-arm64-base.tgz` |
| debian | bookworm | i386 | `debian-bookworm-i386-base.tgz` |
| raspbian | bookworm | armhf | `raspbian-bookworm-armhf-base.tgz` |
| debian | bullseye | amd64 | `debian-bullseye-amd64-base.tgz` |
| raspbian | bullseye | armhf | `raspbian-bullseye-armhf-base.tgz` |
| raspbian | buster | armhf | `raspbian-buster-armhf-base.tgz` |
| ubuntu | jammy | riscv64 | `ubuntu-jammy-riscv64-base.tgz` |

The `armhf` targets use Raspbian to retain compatibility with 32-bit Raspberry
Pi OS.

ARM and RISC-V builds require QEMU user emulation with the corresponding
binfmt handlers registered on the host. Existing base environments may need
their APT sources refreshed before building, particularly for legacy releases.
Source preparation does not check those privileged build prerequisites or run
the binary build. The packaging retains the previous configuration that skips
upstream tests during package builds.

After building and reviewing the packages, import them and regenerate the signed
APT indexes as your regular user (Bookworm amd64 example):

```bash
reprepro --export=never includedeb bookworm \
  .build/bookworm-amd64/peercoind_*.deb \
  .build/bookworm-amd64/peercoin-qt_*.deb \
  .build/bookworm-amd64/peercoin-tx_*.deb
reprepro export bookworm
reprepro check bookworm
reprepro list bookworm
git diff --stat
```

Exporting requires access to the signing key configured in `conf/distributions`.
Building packages does not update or publish the APT repository automatically.

The CI signing stage creates a fresh reprepro database from the downloaded
packages for every configured distro and architecture. It retains the existing
pool and indexes, but does not copy the checked-in `db/` files, which may be
incompatible with the runner's Berkeley DB version. Each attempt uses a new
staging directory so a partial database cannot be reused accidentally.

To publish existing build artifacts with an updated signing script, manually
run **Build and publish APT packages** on the branch containing the fix and set
`packages_run_id` to the original build run ID (for example `39137979293`).
Manual runs skip source preparation and all package builds. The packages must
match the version in that branch's Debian changelog, and the branch must be
allowed to deploy to the `github-pages` environment. The manual trigger becomes
available once the workflow change is on the default branch.
