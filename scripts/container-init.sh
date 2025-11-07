#!/bin/bash
set -e

echo "[Container Init] Starting initialization..."

# Decode auth files from environment variables
# Format: CODEX_AUTH_FILE_1, CLAUDE_AUTH_FILE_1, etc.

# Create auth directories
mkdir -p ~/.codex
mkdir -p ~/.claude
mkdir -p ~/.config

# Decode and write Codex auth files
for var in $(env | grep '^CODEX_AUTH_FILE_' | cut -d= -f1); do
    index=$(echo $var | sed 's/CODEX_AUTH_FILE_//')
    value=$(eval echo \$$var)

    if [ -n "$value" ]; then
        echo "[Container Init] Writing Codex auth file $index"
        echo "$value" | base64 -d > ~/.codex/auth_$index
    fi
done

# Decode and write Claude auth files
for var in $(env | grep '^CLAUDE_AUTH_FILE_' | cut -d= -f1); do
    index=$(echo $var | sed 's/CLAUDE_AUTH_FILE_//')
    value=$(eval echo \$$var)

    if [ -n "$value" ]; then
        echo "[Container Init] Writing Claude auth file $index"
        echo "$value" | base64 -d > ~/.claude/auth_$index
    fi
done

# Decode and write Droid auth files
for var in $(env | grep '^DROID_AUTH_FILE_' | cut -d= -f1); do
    index=$(echo $var | sed 's/DROID_AUTH_FILE_//')
    value=$(eval echo \$$var)

    if [ -n "$value" ]; then
        echo "[Container Init] Writing Droid auth file $index"
        echo "$value" | base64 -d > ~/.config/droid_auth_$index
    fi
done

# Set permissions
chmod 600 ~/.codex/* 2>/dev/null || true
chmod 600 ~/.claude/* 2>/dev/null || true
chmod 600 ~/.config/droid_* 2>/dev/null || true

# Clone GitHub repository into /workspace if GITHUB_REPO_URL is provided
if [ -n "$GITHUB_REPO_URL" ]; then
    echo "[Container Init] Checking workspace for $GITHUB_REPO_URL"

    # Check if workspace is empty
    if [ -z "$(ls -A /workspace)" ]; then
        echo "[Container Init] Workspace is empty, cloning repository..."
        git clone "$GITHUB_REPO_URL" /workspace

        # Checkout specific branch if provided
        if [ -n "$GITHUB_BRANCH" ]; then
            cd /workspace
            git checkout "$GITHUB_BRANCH"
            echo "[Container Init] Checked out branch: $GITHUB_BRANCH"
        fi

        echo "[Container Init] Repository cloned successfully"
    else
        echo "[Container Init] Workspace has content, checking if it's the right repo..."
        cd /workspace

        if [ -d ".git" ]; then
            current_url=$(git remote get-url origin 2>/dev/null || echo "")

            if [ "$current_url" != "$GITHUB_REPO_URL" ]; then
                echo "[Container Init] WARNING: Workspace contains different repository!"
                echo "[Container Init] Current: $current_url"
                echo "[Container Init] Expected: $GITHUB_REPO_URL"
                echo "[Container Init] Skipping clone to preserve data"
            else
                echo "[Container Init] Correct repository found, pulling latest changes..."
                git pull || echo "[Container Init] WARNING: Failed to pull, continuing anyway"
                echo "[Container Init] Workspace updated"
            fi
        else
            echo "[Container Init] Workspace has files but no .git directory"
            echo "[Container Init] Preserving existing files"
        fi
    fi
else
    echo "[Container Init] No GITHUB_REPO_URL provided, workspace as-is"
fi

echo "[Container Init] Initialization complete"
echo "[Container Init] SESSION_ID: $SESSION_ID"
echo "[Container Init] WORKSPACE_PATH: $WORKSPACE_PATH"
echo "[Container Init] GITHUB_REPO_URL: $GITHUB_REPO_URL"
