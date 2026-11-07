# wingrate

Ansible playbooks for setting up a fresh Windows machine via internal control node in WSL.

> [!CAUTION]
> Run your terminal as Administrator.
> Most tasks need it,
> such as the ones that manage sshd, install packages, or change the Windows Registry.

## Prerequisites

- Windows 10 1903+ or later
- WSL with your distro of choice (Debian recommended for minimal footprint)

```powershell
wsl --install -d Debian
```

## Setup

### 1. Enable OpenSSH Server on Windows

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

uv tool install ansible-core

cd ansible
uv tool run --from ansible-core ansible-galaxy collection install -r requirements.yml

uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml -e profile=work -e ansible_user=$USER
```

## Usage

### Profiles

Edit `inventory/group_vars/work.yml` or `home.yml` to customize settings per profile.

### Tasks

```bash
# Packages only
uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml --tags packages -e profile=work -e ansible_user=$USER

# Registry only
uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml --tags registry -e profile=work -e ansible_user=$USER
```

### Dry run

```bash
uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml --check --diff -e profile=work -e ansible_user=$USER
```

### Elevation

If your SSH user is not an administrator,
install packages over a separate connection as an administrator,
then apply the rest as yourself:

```bash
sudo apt install sshpass

uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml -e profile=work \
  --tags packages --skip-tags uv_tools -e ansible_user='<domain>\<admin>' --ask-pass

uv tool run --from ansible-core ansible-playbook playbooks/main.yml -i inventory/hosts.yml -e profile=work \
  --tags registry,uv_tools -e ansible_user=$USER
```

Omit `<domain>\` for a local account.

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

Settings go to the SSH user's registry hive.
To change another user's settings, add `-e target_user=<user>`.

Restart Explorer or log out/in after registry changes:

```powershell
Stop-Process -Name explorer -Force
```
