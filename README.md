# APT repository

Peercoin APT repository for Debian Buster (10).

Supported architectures: amd64, arm64 and armhf.

```
sudo apt-get update
sudo apt-get install apt-transport-https

sudo sh -c "echo 'deb https://peercoin.github.io/deb-repo/ buster main' >> /etc/apt/sources.list.d/peercoin.list"
wget -O - https://peercoin.github.io/deb-repo/peercoin.apt.key | sudo apt-key add -

sudo apt-get update
sudo apt-get install peercoin-qt # to install QT client
sudo apt-get install peercoind # to install daemon
sudo apt-get install peercoin-tx # to install tx utility
```

## Available Packages

peercoind
peercoin-qt
peercoin-tx
