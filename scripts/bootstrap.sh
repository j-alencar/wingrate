#!/bin/bash
# Bootstrap script for Windows migration
set -e

# Ensure running from WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "ERROR: This script must be run from within WSL"
    exit 1
fi

PROFILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--profile work|home]"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "Migration Bootstrap"
echo "========================================="
echo ""

# Get Windows username
WIN_USER=$(whoami.exe 2>/dev/null | tr -d '\r' | sed 's/.*\\//')
if [[ -z "$WIN_USER" ]]; then
    read -p "Windows username: " WIN_USER
else
    echo "Detected Windows user: $WIN_USER"
fi

# Check SSH connectivity
echo ""
echo "Checking SSH connection to Windows..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$WIN_USER@127.0.0.1" "echo ok" &>/dev/null; then
    echo "SSH connection working!"
else
    echo ""
    echo "SSH key authentication not set up. Let's fix that."
    echo ""

    # Generate key if needed
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi

    echo "Your public key:"
    echo ""
    cat ~/.ssh/id_rsa.pub
    echo ""
    echo "Add this key to Windows. Run in PowerShell:"
    echo ""
    echo '  mkdir "$env:USERPROFILE\.ssh" -Force'
    echo '  Add-Content -Path "$env:USERPROFILE\.ssh\authorized_keys" -Value "PASTE_KEY_HERE"'
    echo ""
    read -p "Press Enter once you've added the key..."

    # Test again
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$WIN_USER@127.0.0.1" "echo ok" &>/dev/null; then
        echo "ERROR: SSH still not working. Check the key was added correctly."
        exit 1
    fi
    echo "SSH connection working!"
fi

echo ""
if ! command -v ansible-playbook &>/dev/null; then
    echo "Installing Ansible via uv..."
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    uv pip install --system ansible
fi
echo "Ansible: $(ansible --version | head -1)"

# Install collections
echo ""
echo "Installing Ansible collections..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../ansible"
ansible-galaxy collection install -r requirements.yml

# Get profile
echo ""
if [[ -z "$PROFILE" ]]; then
    read -p "Profile [work/home, default: home]: " PROFILE
    PROFILE="${PROFILE:-home}"
fi

echo ""
echo "========================================="
echo "Starting Migration"
echo "  Profile: $PROFILE"
echo "  User: $WIN_USER"
echo "========================================="
echo ""

read -p "Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

ansible-playbook playbooks/main.yml \
    -i inventory/hosts.yml \
    -e "profile=$PROFILE" \
    -e "ansible_user=$WIN_USER" \
    -e "ansible_port=22"

echo ""
echo "========================================="
echo "Migration Complete!"
echo "========================================="
echo "Restart Windows to apply all changes."
