#!/bin/bash

set -e

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <HOST> <USER> <SSH_KEY> <PORT>"
    exit 1
fi

# Assign arguments to variables
HOST="$1"
USER="$2"
SSH_KEY="$3"
PORT="$4"

# Check if any of the variables are empty
if [ -z "$PORT" ] || [ -z "$USER" ] || [ -z "$SSH_KEY" ] || [ -z "$HOST" ]; then
    echo "Error: One or more required environment variables are not set"
    echo "HOST is set: $([ -n "$HOST" ] && echo "Yes" || echo "No")"
    echo "USER is set: $([ -n "$USER" ] && echo "Yes" || echo "No")"
    echo "SSH_KEY is set: $([ -n "$SSH_KEY" ] && echo "Yes" || echo "No")"
    echo "PORT is set: $([ -n "$PORT" ] && echo "Yes" || echo "No")"
    exit 1
fi

# Validate PORT
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "Error: PORT must be a number, got '$PORT'"
    exit 1
fi

# Set up SSH
mkdir -p ~/.ssh
echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

if ! ssh-keyscan -p $PORT -H $HOST >> ~/.ssh/known_hosts; then
    echo "Error: ssh-keyscan failed"
    exit 1
fi

# Create directory on remote server and handle existing files
REMOTE_SETUP_COMMAND="
    mkdir -p ~/githubAction
    if [ -e ~/githubAction/main ]; then
        mv ~/githubAction/main ~/githubAction/main.$(date +%Y%m%d%H%M%S).bak
    fi
"

if ! ssh -p $PORT $USER@$HOST "$REMOTE_SETUP_COMMAND"; then
    echo "Error: Failed to set up directory on remote server"
    exit 1
fi

# Copy file to remote server
if ! scp -P $PORT main $USER@$HOST:~/githubAction/main; then
    echo "Error: Failed to copy file to remote server"
    exit 1
fi

# Stop existing process, move new file, and start new process
REMOTE_COMMAND="
    # Find and stop existing process
    PID=\$(pgrep -f './myapp$')
    echo \"Found PID: \$PID\"
    if [ -n \"\$PID\" ]; then
        echo \"Stopping process \$PID\"
        kill \$PID
    else
        echo \"No existing process found\"
    fi

    # Deploy new version
    mv ~/githubAction/main ~/deploy/myapp
    chmod +x ~/deploy/myapp

    # Start new process
    cd ~/deploy
    nohup ./myapp > ./myapp.log 2>&1 &
    echo \$! > ./myapp.pid
"

if ! ssh -p $PORT $USER@$HOST "$REMOTE_COMMAND"; then
    echo "Error: Failed to execute commands on remote server"
    exit 1
fi

echo "Deployment completed successfully"
