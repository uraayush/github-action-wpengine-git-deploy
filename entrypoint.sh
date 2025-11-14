#!/bin/sh -l

set -ex
if [ "$ENABLE_POST_DEPLOY_SCRIPT" = "true" ]; then
    # Required env vars
    : ${WPENGINE_ENVIRONMENT_NAME?Required environment name variable not set.}
    : ${POST_DEPLOY_SSH_PRIVATE?Required secret not set.}

    SSH_PATH="$HOME/.ssh"
    KNOWN_HOSTS_PATH="$SSH_PATH/known_hosts"
    WPENGINE_SSH_KEY_PRIVATE_PATH="$SSH_PATH/wpengine_key"

    # Derive SSH host/user + remote script path from environment name
    REMOTE_HOST="${WPENGINE_ENVIRONMENT_NAME}.ssh.wpengine.net"
    REMOTE_USER="${WPENGINE_ENVIRONMENT_NAME}"
    REMOTE_SCRIPT_PATH="/home/wpe-user/sites/${WPENGINE_ENVIRONMENT_NAME}/post-deploy.sh"

    # Create SSH dir + known_hosts
    mkdir -p "$SSH_PATH"
    touch "$KNOWN_HOSTS_PATH"

    chmod 700 "$SSH_PATH"
    chmod 600 "$KNOWN_HOSTS_PATH"

    # Save private key
    echo "$POST_DEPLOY_SSH_PRIVATE" > "$WPENGINE_SSH_KEY_PRIVATE_PATH"
    chmod 600 "$WPENGINE_SSH_KEY_PRIVATE_PATH"

    # Add SSH gateway host to known_hosts (all key types, hostname hashed)
    ssh-keyscan -H "$REMOTE_HOST" >> "$KNOWN_HOSTS_PATH"


  echo "Running post-deploy script on ${REMOTE_USER}@${REMOTE_HOST}"
  echo "Remote script: ${REMOTE_SCRIPT_PATH}"

  ssh \
    -i "$WPENGINE_SSH_KEY_PRIVATE_PATH" \
    -o IdentitiesOnly=yes \
    -o UserKnownHostsFile="$KNOWN_HOSTS_PATH" \
    "$REMOTE_USER@$REMOTE_HOST" \
    "bash $REMOTE_SCRIPT_PATH"
else
  echo "Post deploy script not enabled (ENABLE_POST_DEPLOY_SCRIPT != true)"
fi

# Cleanup
rm -rf "$SSH_PATH"
