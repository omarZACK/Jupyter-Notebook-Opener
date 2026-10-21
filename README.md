<p align="center">
  <img src="https://github.com/user-attachments/assets/61663781-a7a1-4551-8566-8e9dbe752e04" width="150" alt="Jupyter Notebook Launcher Logo">
  <br><br>
  <strong>A seamless way to open Jupyter Notebooks from your file manager using the system browser.</strong>
  <br><br>
  <a href="#-features"><strong>✨ Explore Features »</strong></a>
  <br><br>
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/bash-script-blue" alt="Script Type">
  <img src="https://img.shields.io/badge/status-in%20development-yellow" alt="Project Status">
</p>

---

## 📚 Table of Contents

- [📖 About](#-about)
- [✨ Features](#-features)
- [🛠 Tech Stack](#-tech-stack)
- [🚀 Installation](#-installation)
- [🪪 License](#-license)
- [🤝 Contact & Contribution](#-contact--contribution)

---

## 📖 About

This repository provides a **desktop-integrated launcher** for `.ipynb` files on Linux. It allows users to open Jupyter Notebooks in their **default web browser** simply by double-clicking the file in a file manager like Nautilus or Dolphin.

It ensures:
- A Jupyter server starts if not already running
- The selected notebook opens in the browser automatically
- Uses your system's **default browser**, not hardcoded to any
- Works with common Linux distributions, including Debian-based, RPM-based,
  Arch, openSUSE/SUSE, Gentoo, and other distributions that provide Python 3
  and the XDG desktop utilities

---

## ✨ Features

- ✅ Automatically opens selected `.ipynb` in the browser  
- 🚀 Starts a Jupyter server in the background (if none is running)  
- 🌐 Opens in the system default browser  
- 📂 Respects notebook location and file structure  
- 🖱️ Integrated via a desktop entry (`.desktop`)  
- 🧠 URL-safe encoding and robust edge-case handling  

---

## 🛠 Tech Stack

- 🐧 Bash  
- 📓 Jupyter Notebook  
- 🧠 `readlink`, `realpath`, `grep`, `nohup`, `xdg-open`  
- 🖥️ Linux Desktop Environments (GNOME, KDE, etc.)  
- 🧪 Compatible with Anaconda / Python venv  

---

## 🚀 Installation

1. **Clone the repo**:
   ```bash
   git clone https://github.com/omarZACK/Jupyter-Notebook-Opener.git
   cd Jupyter-Notebook-Opener
   ```

2. **Make the installation script executable**:
   ```bash
   chmod +x scripts/install.sh
   ```

3. **Run the installation script to configure the Notebook Opener**:
   ```bash
   ./scripts/install.sh
   ```

The installer uses a Python virtual environment and does not require
administrator privileges. If the virtual environment cannot be created, install
Python 3 and its virtual-environment support using your distribution's package
manager. For example:

| Distribution family | Packages or command |
| --- | --- |
| Debian / Ubuntu | `sudo apt install python3 python3-venv` |
| Fedora / RHEL | `sudo dnf install python3` |
| Arch | `sudo pacman -S python` |
| openSUSE / SUSE | `sudo zypper install python311` |
| Gentoo | `sudo emerge dev-lang/python` |

The optional `update-desktop-database`, `update-mime-database`, and `xdg-mime`
utilities are used when available. If they are missing, the launcher is still
installed and the script prints the manual follow-up needed for desktop
integration.
   
---

## 🪪 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Contact & Contribution

Have a suggestion, bug report, or feature request? Feel free to open an issue or PR!

**Created by [omarZACK](https://github.com/omarZACK)** — contributions are welcome and appreciated.  
Please ⭐ the repo if you found it helpful!