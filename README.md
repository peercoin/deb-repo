# APT repository

Peercoin APT repository for Debian Buster (10) and Debian Bullseye (11).

Supported architectures: amd64, arm64 and armhf.

```
sudo apt-get update
sudo apt-get install apt-transport-https wget

sh -c "echo 'deb https://peercoin.github.io/deb-repo/ `lsb_release -c | cut -f2-` main-`lsb_release -c | cut -f2-`' > peercoin.list"
wget -O - https://peercoin.github.io/deb-repo/peercoin.apt.key | sudo apt-key add -

sudo apt-get update
sudo apt-get install peercoin-qt # to install QT client
sudo apt-get install peercoind # to install daemon
sudo apt-get install peercoin-tx # to install tx utility
```

If something goes wrong, try this:

```
apt-get --allow-releaseinfo-change update
```

## Available Packages

peercoind
peercoin-qt
peercoin-tx


## How to set up Debian repo

https://blog.packagecloud.io/eng/2017/03/23/create-debian-repository-reprepro/
