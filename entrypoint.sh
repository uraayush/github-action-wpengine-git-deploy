#!/bin/sh -l

set -ex

: ${WPENGINE_ENVIRONMENT_NAME?Required environment name variable not set.}
: ${WPENGINE_SSH_KEY_PRIVATE?Required secret not set.}
: ${WPENGINE_SSH_KEY_PUBLIC?Required secret not set.}

SSH_PATH="$HOME/.ssh"
WPENGINE_HOST="git.wpengine.com"
KNOWN_HOSTS_PATH="$SSH_PATH/known_hosts"
WPENGINE_SSH_KEY_PRIVATE_PATH="$SSH_PATH/wpengine_key"
WPENGINE_SSH_KEY_PUBLIC_PATH="$SSH_PATH/wpengine_key.pub"
WPENGINE_ENVIRONMENT_DEFAULT="production"
WPENGINE_ENV=${WPENGINE_ENVIRONMENT:-$WPENGINE_ENVIRONMENT_DEFAULT}
LOCAL_BRANCH_DEFAULT="master"
BRANCH=${LOCAL_BRANCH:-$LOCAL_BRANCH_DEFAULT}

mkdir "$SSH_PATH"

ssh-keyscan -t rsa "$WPENGINE_HOST" >> "$KNOWN_HOSTS_PATH"

echo "$WPENGINE_SSH_KEY_PRIVATE" > "$WPENGINE_SSH_KEY_PRIVATE_PATH"
echo "$WPENGINE_SSH_KEY_PUBLIC" > "$WPENGINE_SSH_KEY_PUBLIC_PATH"

chmod 700 "$SSH_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"
chmod 600 "$WPENGINE_SSH_KEY_PRIVATE_PATH"
chmod 644 "$WPENGINE_SSH_KEY_PUBLIC_PATH"

# git config --global --add safe.directory /github/workspace
# git config core.sshCommand "ssh -i $WPENGINE_SSH_KEY_PRIVATE_PATH -o UserKnownHostsFile=$KNOWN_HOSTS_PATH"
# git remote add $WPENGINE_ENV git@$WPENGINE_HOST:$WPENGINE_ENV/$WPENGINE_ENVIRONMENT_NAME.git
# git push -fu $WPENGINE_ENV $BRANCH:master

if [ "$ENABLE_POST_DEPLOY_SCRIPT" = "true" ]; then
    # Commands to execute if the condition is true
    #post deploy start
    REMOTE_HOST="wakemanagendev.ssh.wpengine.net"
    REMOTE_USER="wakemanagendev"
    REMOTE_SCRIPT_PATH="/home/wpe-user/sites/wakemanagendev/post-deploy.sh"


    # 1) Add WP Engine host to known_hosts (prevent “Host key verification failed”)
    ssh-keyscan -H "$REMOTE_HOST" >> "$KNOWN_HOSTS_PATH"

    # 2) Execute remote script
    ssh \
        -i "$WPENGINE_SSH_KEY_PRIVATE_PATH" \
        -o IdentitiesOnly=yes \
        "$REMOTE_USER@$REMOTE_HOST" \
        "bash $REMOTE_SCRIPT_PATH"
else
    # Commands to execute if the condition is false
    echo "Post deploy script not enabled"
fi



#cleanup
rm -r "${SSH_PATH}"
git remote rm $WPENGINE_ENV
