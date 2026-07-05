# Toolbox

> A collection of personal Linux scripts to automate, simplify, and fix all those random daily problem on a Linux system.

### Instalasi Arch Linux (Minimal + Btrfs)

A script for a minimal Arch Linux install using the Btrfs filesystem. Perfect for a clean, lightweight, and modern setup.

**Run it using the following command:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/garpra/toolbox/main/archlinux/install.sh)"
```

> **Warning**: This script will format your disk. Make sure to back up your important data before running it..

---

## How to Use

Clone the repository and run the TUI:

```bash
git clone https://github.com/garpra/toolbox.git
cd toolbox
chmod +x script-runner
./script-runner
```

## Script Structure

Scripts are organized into categories. Each folder inside `scripts/` is a category, and each `.sh` file inside is a script.

```
scripts/
├── archlinux/
│   ├── install.sh
│   └── install-refind.sh
├── gaming/
│   └── setup-intel-arch.sh
└── install/
    └── aur-helper.sh
```

Adding a new category is as simple as creating a new folder. Adding a new script is as simple as dropping a `.sh` file into the appropriate folder.
