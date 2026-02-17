# wingrate

Ansible playbooks for setting up a fresh Windows machine via internal control node in WSL.

## Prerequisites

- Windows 10 1903+ or later
- WSL with your distro of choice (Debian recommended for minimal footprint)

```powershell
wsl --install -d Debian
```

## Setup

### 1. Enable OpenSSH Server on Windows

Run in PowerShell as Administrator:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

### 2. Setup SSH Key Authentication

In WSL, generate your SSH key if you don't have one:

```bash
[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

Then add the key to Windows. From PowerShell:

```powershell
mkdir "$env:USERPROFILE\.ssh" -Force

Add-Content -Path "$env:USERPROFILE\.ssh\authorized_keys" -Value "<your-key>"
```

If you'd like to test it:

```bash
ssh $USER@127.0.0.1 "echo Connected!"
```

### 3. Clone and Run

From WSL:

```bash
git clone https://github.com/j-alencar/wingrate.git
cd wingrate

curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.local/bin/env

uv pip install --system ansible

cd ansible
ansible-galaxy collection install -r requirements.yml

ansible-playbook playbooks/main.yml -i inventory/hosts.yml -e profile=work -e ansible_user=$USER
```

## Usage

### Profiles

Edit `inventory/group_vars/work.yml` or `home.yml` to customize settings per profile.

### Tasks

```bash
# Packages only
ansible-playbook playbooks/main.yml -i inventory/hosts.yml --tags packages -e profile=work -e ansible_user=$USER

# Registry only
ansible-playbook playbooks/main.yml -i inventory/hosts.yml --tags registry -e profile=work -e ansible_user=$USER
```

### Dry run

```bash
ansible-playbook playbooks/main.yml -i inventory/hosts.yml --check --diff -e profile=work -e ansible_user=$USER
```

## Customization

### Packages

Edit `ansible/roles/packages/vars/packages.yml`:

```yaml
packages:
  - name: MyApp
    choco: myapp
    profile_tags: [work]  # or [home], or [work, home]
```

### Registry settings

Edit `ansible/roles/registry/vars/fallback_settings.yml`:

```yaml
registry_settings:
  - path: HKCU:\Software\SomeApp
    name: SomeSetting
    data: 1
    type: dword
```

## Troubleshooting

### SSH Connection Refused

Make sure OpenSSH Server is running:

```powershell
Get-Service sshd
Start-Service sshd
```

### Permission Denied (SSH)

Either your public key isn't in authorized_keys, or file permissions are wrong:

```powershell
type "$env:USERPROFILE\.ssh\authorized_keys" # Check the file exists and has your key
```

### Registry Settings Not Applying

Settings are written to the specific user's registry hive (via SID lookup). Make sure `ansible_user` matches the Windows user whose settings you want to change.

Restart Explorer or log out/in after registry changes:

```powershell
Stop-Process -Name explorer -Force
```
