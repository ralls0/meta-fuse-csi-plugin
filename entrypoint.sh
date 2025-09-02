#!/bin/bash
set -e

# Variabili richieste come ENV:
# SSH_USER, SSH_HOST, REMOTE_PATH, MOUNT_PATH
: "${SSH_USER:?SSH_USER must be set}"
: "${SSH_HOST:?SSH_HOST must be set}"
: "${REMOTE_PATH:?REMOTE_PATH must be set}"
: "${MOUNT_PATH:?MOUNT_PATH must be set}"

# Assicurati che /dev/fuse esista
touch /dev/fuse

# Crea la cartella di mount se non esiste
mkdir -p "$MOUNT_PATH"

# Monta la cartella remota via SSHFS
/usr/bin/sshfs -o IdentityFile=/root/.ssh/id_rsa \
               -o StrictHostKeyChecking=no \
               -o allow_other \
               -o reconnect \
               -o sshfs_debug \
               -v \
               "${SSH_USER}@${SSH_HOST}:${REMOTE_PATH}" \
               "${MOUNT_PATH}"


# Mantieni il container in esecuzione
sleep infinity
