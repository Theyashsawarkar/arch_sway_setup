# 🏔️ Arch Sway Setup

A minimal, keyboard-driven Arch Linux desktop built around Wayland, Sway, and modern terminal-based development tools.

This repository contains the complete configuration for my daily development environment, managed with GNU Stow for reproducible setup and easy maintenance.

---

## ✨ Features

* ⚡ Lightweight Wayland desktop
* ⌨️ Keyboard-first workflow
* 🖥️ Sway window manager
* 📊 Waybar status bar
* 🚀 Wofi application launcher
* 🔔 Mako notifications
* 🐱 Kitty terminal
* 📝 Neovim development environment
* 🔀 Tmux session management
* 🧠 Zed editor
* 🔗 GNU Stow-powered dotfile management

---

## 🖼️ Desktop Stack

### Wayland Environment

| Component            | Software |
| -------------------- | -------- |
| Window Manager       | Sway     |
| Status Bar           | Waybar   |
| Application Launcher | Wofi     |
| Notifications        | Mako     |
| Lock Screen          | swaylock |
| Wallpaper            | swaybg   |

### Development Environment

| Component       | Software |
| --------------- | -------- |
| Terminal        | Kitty    |
| Multiplexer     | Tmux     |
| Terminal Editor | Neovim   |
| GUI Editor      | Zed      |
| Shell           | Zsh      |

---

## 📂 Repository Structure

Each directory represents an independent package managed by GNU Stow.

```text
.
├── kitty/
├── mako/
├── nvim/
├── sway/
├── tmux/
├── waybar/
├── wofi/
└── zed/
```

The internal structure mirrors the target layout inside `$HOME`, allowing Stow to create symlinks automatically.

---

## 📦 Prerequisites

Install the required packages before bootstrapping the configuration.

```bash
sudo pacman -S git stow
```

---

## 🚀 Installation

### Clone the Repository

```bash
git clone https://github.com/Theyashsawarkar/arch_sway_setup.git ~/dotfiles
cd ~/dotfiles
```

### Stow Packages

Install individual packages:

```bash
stow kitty tmux nvim zed
stow sway waybar mako wofi
```

Or install everything:

```bash
stow */
```

### Tmux Setup

The tmux config needs one thing Stow can't set up for you, and one plugin manager bootstrap:

* **Nerd Font** — the status bar's rounded separators and icons (session, docker) are
  Nerd Font glyphs. Install one (e.g. `ZedMono Nerd Font`, `JetBrainsMono Nerd Font`) and
  set it as your terminal's font. Without it, those glyphs render as blank boxes.
* **TPM (Tmux Plugin Manager)** — installs `tmux-resurrect` and `tmux-continuum`:

  ```bash
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```

  Then inside a tmux session, press `prefix + I` (`Ctrl-a` then `Shift-i`) to install the plugins.

---

## 🔧 Managing Configurations

### Add a New Package

Create a package:

```bash
mkdir -p newpkg/.config/newpkg
```

Move the configuration:

```bash
mv ~/.config/newpkg/* newpkg/.config/newpkg/
```

Create symlinks:

```bash
stow newpkg
```

### Remove a Package

```bash
stow -D <package-name>
```

Example:

```bash
stow -D nvim
```

---

## 🔒 Local Configuration

Machine-specific settings, secrets, API tokens, and private paths should never be committed.

Create local override files and source them from the main configuration.

Examples:

```text
~/.zshrc.local
~/.gitconfig.local
~/.config/nvim/lua/local.lua
```

Add these files to `.gitignore`.

---

## 🎯 Goals

This setup prioritizes:

* Simplicity
* Performance
* Reproducibility
* Maintainability
* Keyboard-centric workflows

---

## 📸 Screenshots

Add screenshots here to showcase the desktop environment.

```markdown
![Desktop](./assets/desktop.png)
![Neovim](./assets/nvim.png)
```

---

## 🤝 Contributing

This repository is primarily maintained for personal use, but ideas, suggestions, and improvements are always welcome.

---

## 📄 License

MIT License
