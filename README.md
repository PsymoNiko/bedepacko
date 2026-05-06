
<!-- Logo - keep as is -->
<p align="center">
  <img src="https://github.com/user-attachments/assets/9b14993a-9481-414e-9dd4-8c0d6465a9d2" alt="bedepacko logo" width="200"/>
</p>

# bedepacko – fast, safe, modern package manager

[![Rust](https://img.shields.io/badge/built%20with-Rust-orange?style=for-the-badge&logo=rust)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/PsymoNiko/bedepacko/ci.yml?branch=main&label=tests&style=for-the-badge)](https://github.com/PsymoNiko/bedepacko/actions)
[![GitHub release](https://img.shields.io/github/v/release/PsymoNiko/bedepacko?style=for-the-badge)](https://github.com/PsymoNiko/bedepacko/releases)
![Lines of Code](https://img.shields.io/tokei/lines/github/PsymoNiko/bedepacko?style=for-the-badge&label=bedepacko%20LoC)
![bedepacko](https://img.shields.io/badge/bedepacko-0A5C8E?style=for-the-badge&logo=package&logoColor=white)
![Package Manager](https://img.shields.io/badge/Package%20Manager-bedepacko-2C5F2D?style=for-the-badge&logo=homebrew&logoColor=white)

**bedepacko** is a next‑generation package manager that combines the speed of Rust with the convenience of shell scripting. After a complete rewrite, the core engine (`bede-engine`) delivers **parallel downloads**, **memory safety**, and **true concurrency** – no more slow shell loops or fragile error handling.

> ⚠️ **Status**: The Rust engine is feature‑complete and ready for **testing**. You are invited to try it out and report any issues. The APT, Snap, and curl installers are being finalised – for now, use the manual build method below.

---

## ✨ What’s new (Rust rewrite)

- **🚀 10x faster** – parallel async downloads with `tokio` + `reqwest`
- **🛡️ Memory‑safe** – eliminates entire classes of security bugs
- **⚡ True concurrency** – data‑race free by design
- **🔁 Reproducible** – lockfile support for deterministic installations
- **🌍 Cross‑platform** – same experience on Linux, macOS, and Windows (WSL)

---

## 📦 Installation (for testing)

Choose the method that suits your environment.

### 🧪 Manual build from source (recommended for testing)

```bash
git clone https://github.com/PsymoNiko/bedepacko.git
cd bedepacko/bede-engine
cargo build --release
sudo cp ../bede.sh /usr/local/bin/bede
sudo cp target/release/bede-engine /usr/local/bin/
```

Then verify:

```bash
bede chi
```

🐧 APT (coming soon – preview)

```bash
sudo add-apt-repository ppa:psymoniko/bedepacko
sudo apt update
sudo apt install bede
```

🧩 Snap (coming soon – preview)

```bash
sudo snap install bedepacko
```

🦀 cargo install (when published on crates.io)

```bash
cargo install bede-engine
```

🌐 Universal one‑liner (when install.sh is ready)

```bash
curl -fsSL https://raw.githubusercontent.com/PsymoNiko/bedepacko/main/install.sh | bash
```

---

🎮 Basic usage (your custom commands)

Command Alias What it does
bede biad nmap bede install nmap Install a package
bede chi bede list List installed packages
bede bere nmap bede remove nmap Remove a package
bede resolve nmap – Show dependencies without installing
bede lock nmap – Generate a lockfile

---

🧰 How it works (architecture)

· bede.sh – thin wrapper script, stays in /usr/local/bin
· bede-engine – Rust binary that does all heavy lifting:
  · Parallel downloads with progress bars
  · Dependency resolution using petgraph
  · Lockfile generation (bede.lock)
  · Safe file operations

All state lives in ~/.local/share/bedepacko/ – no root required after install.

---

🤝 Contributing

Testing is the most valuable contribution right now!
Try bede biad on your favourite packages and open an issue if something unexpected happens.

---

📄 License

MIT © PsymoNiko

---

<p align="center">
  <i>Built with Rust – because package managers should be fast and fearless.</i>
</p>
