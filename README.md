# APT repository

Peercoin APT repository for the following distributions and architectures:

| Distribution | amd64 | arm64 | armhf | i386 | riscv64 |
| --- | :---: | :---: | :---: | :---: | :---: |
| Ubuntu Jammy (22.04) | — | — | — | — | ✓ |
| Debian Trixie (13) | ✓ | ✓ | ✓ | — | ✓ |
| Debian Bookworm (12) | ✓ | ✓ | ✓ | ✓ | — |
| Debian Bullseye (11) | ✓ | — | ✓ | — | — |
| Debian Buster (10, legacy) | — | — | ✓ | — | — |

```
sudo apt-get update
sudo apt-get install apt-transport-https wget

sudo wget -O /usr/share/keyrings/peercoin-archive-keyring.gpg https://peercoin.github.io/deb-repo/peercoin.apt.key
sudo chmod 0644 /usr/share/keyrings/peercoin-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/peercoin-archive-keyring.gpg] https://peercoin.github.io/deb-repo/ $(lsb_release -cs) main-$(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/peercoin.list

sudo apt-get update
sudo apt-get install peercoin-qt # to install QT client
sudo apt-get install peercoind # to install daemon
sudo apt-get install peercoin-tx # to install tx utility
```

## Troubleshooting

If APT reports `Missing key 18B7790F9518DDD5B9166804B8276C0F851AAD7E` or
`EXPKEYSIG B8276C0F851AAD7E`, refresh the published key and update the source entry:

```
sudo wget -O /usr/share/keyrings/peercoin-archive-keyring.gpg https://peercoin.github.io/deb-repo/peercoin.apt.key
sudo chmod 0644 /usr/share/keyrings/peercoin-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/peercoin-archive-keyring.gpg] https://peercoin.github.io/deb-repo/ $(lsb_release -cs) main-$(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/peercoin.list
sudo apt-get update
```

APT does not automatically trust keys saved under `/usr/share/keyrings`; the
`signed-by` option tells it which key to use. Ensure any Peercoin entries in
other `.list` or `.sources` files reference the same keyring using `signed-by`
or `Signed-By`, respectively.

If APT instead asks you to accept a change to the repository's release information,
review the reported change before running:

```
sudo apt-get --allow-releaseinfo-change update
```

This option does not resolve missing-key or invalid-signature errors.

## Available Packages

peercoind
peercoin-qt
peercoin-tx

## Migration to multi-distro

This repository used to support only Debian 10, and it is multi-distro now.
To migrate and keep recieving updates, execute this command again:

```
echo "deb [signed-by=/usr/share/keyrings/peercoin-archive-keyring.gpg] https://peercoin.github.io/deb-repo/ $(lsb_release -cs) main-$(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/peercoin.list
```

If the keyring is missing or outdated, follow the key refresh instructions above.

## How to set up Debian repo

https://blog.packagecloud.io/eng/2017/03/23/create-debian-repository-reprepro/

## Building packages

See [BUILD.md](BUILD.md) for source preparation, package builds and repository updates.
