#!/bin/bash

VAULT_VERSION="0.9.1"
HWUNAME=$(uname -m)
OSUNAME=$(uname -s)

if [ "$HWUNAME" != "x86_64" ]; then
  PLATFORM=386
else
  PLATFORM=amd64
fi

if [ "$OSUNAME" = "Linux" ]; then
  OS=linux
  BINDIR=/usr/bin
else
  OS=darwin
  BINDIR=/usr/local/bin
fi

if [ "$(id -u)" != "0" ]; then
    echo "Installation must be done as root or under sudo"
    exit 1
fi

echo "Downloading Vault and install..."
curl -L "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip" > /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip
unzip /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip -d $BINDIR
rm -f /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip
chmod 0755 $BINDIR/vault
chown root:wheel $BINDIR/vault
echo "Done"

echo "Setting VAULT_ADDR variable to .bashrc...."
echo "export VAULT_ADDR='https://vault.moveaws.com'" >> ~/.bashrc
export VAULT_ADDR="https://vault.moveaws.com"
echo "INFO: Run the command: export VAULT_ADDR='https://vault.moveaws.com' "
echo "INFO: Run the command: export VAULT_AUTH_GITHUB_TOKEN=<xxxx-xxxxx-xxxxx> to set the github token"
