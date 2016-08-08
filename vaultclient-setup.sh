#!/bin/bash

VAULT_VERSION="0.6.0"
HWUNAME=$(uname -m)
OSUNAME=$(uname -s)

if [ "$HWUNAME" != "x86_64" ]; then
  PLATFORM=386
else
  PLATFORM=amd64
fi

if [ "$OSUNAME" = "Linux" ]; then
  OS=linux
else
  OS=darwin
fi

if [ "$(id -u)" != "0" ]; then
    echo "Installation must be done as root or under sudo"
    exit 1
fi


echo "Downloading Vault and install..."
curl -L "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip" > /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip
unzip /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip -d /usr/bin
#rm /tmp/vault_${VAULT_VERSION}_${OS}_${PLATFORM}.zip
chmod 0755 /usr/bin/vault
chown root:wheel /usr/bin/vault
echo "Done"

echo "Setting VAULT_ADDR variable to .bashrc...."
echo "export VAULT_ADDR='https://vault.moveaws.com'" >> ~/.bashrc
export VAULT_ADDR="https://vault.moveaws.com"
echo "INFO: Run the command: export VAULT_ADDR='https://vault.moveaws.com' "
echo "INFO: Run the command: export VAULT_TOKEN=<xxxx-xxxxx-xxxxx> to set the token" 
