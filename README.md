# ⚙️ System Configurations & Dotfiles

A structured, reproducible dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). 

This repository serves as the single source of truth for my local development environment. The setup optimizes for maintainability, clarity, and separation of concerns—treating system configuration as a structured architecture rather than a collection of ad-hoc scripts.

## 🏗️ Architecture & Stack

The environment is built around a lightweight Wayland stack and high-performance, keyboard-driven developer tools.

### Core Components
* **Window Manager:** [Sway](https://swaywm.org/) (Wayland)
* **Status Bar:** [Waybar](https://github.com/Alexays/Waybar)
* **Launcher:** [Wofi](https://hg.sr.ht/~scoopta/wofi)
* **Notifications:** [Mako](https://wayland.emersion.fr/mako/)

### Terminal & Developer Environment
* **Terminal Emulator:** [Kitty](https://sw.kovidgoyal.net/kitty/)
* **Multiplexer:** [Tmux](https://github.com/tmux/tmux)
* **Editors:** 
  * [Neovim](https://neovim.io/) (Primary terminal editor)
  * [Zed](https://zed.dev/) (High-performance GUI editor)

## 📂 Repository Structure

Configs are isolated into independent packages. The internal structure of each package strictly mirrors the home directory tree, allowing Stow to map symlinks precisely where they belong without manual intervention.

```text
.
├── kitty/
│   └── .config/kitty/
├── mako/
│   └── .config/mako/
├── nvim/
│   └── .config/nvim/
├── sway/
│   └── .config/sway/
├── tmux/
│   └── .config/tmux/
├── waybar/
│   └── .config/waybar/
├── wofi/
│   └── .config/wofi/
└── zed/
    └── .config/zed/
🚀 Installation & Bootstrapping
To reproduce this environment on a new machine, ensure git and stow are installed, then clone and link the packages.

1. Clone the repository:

Bash
git clone [https://github.com/](https://github.com/)<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
2. Stow the packages:
Run stow followed by the package names you want to link.

Bash
# Stow core developer tools
stow nvim zed kitty tmux

# Stow Wayland environment
stow sway waybar mako wofi

# Alternatively, stow everything at once
stow */
Note: If Stow throws a conflict warning, ensure the target directory (e.g., ~/.config/tmux) does not already exist as a physical file or directory on the host machine.

🔧 Managing Packages
Adding a new configuration
Create the package directory and its nested structure: mkdir -p newpkg/.config/newpkg

Move the actual config into the repository: mv ~/.config/newpkg/* newpkg/.config/newpkg/

Link it back: stow newpkg

Removing a configuration
To safely remove the symlinks from your system without deleting the configurations from this repository:

Bash
stow -D <package_name>
🔒 Local Overrides (Ignored Files)
Sensitive information, API tokens, and machine-specific paths should never be committed. Create .local files (e.g., ~/.zshrc.local) and source them at the end of your main configs. These are explicitly ignored via .gitignore.
