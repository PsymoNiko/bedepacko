# bedepacko

![Build](https://github.com/PsymoNiko/bedepacko/actions/workflows/main.yml/badge.svg)
![GitHub release](https://img.shields.io/github/v/release/PsymoNiko/bedepacko)
![License](https://img.shields.io/github/license/PsymoNiko/bedepacko)
![Issues](https://img.shields.io/github/issues/PsymoNiko/bedepacko)
![Pull Requests](https://img.shields.io/github/issues-pr/PsymoNiko/bedepacko)
![Contributors](https://img.shields.io/github/contributors/PsymoNiko/bedepacko)

# bede - Mono Repo for Bede Package Manager

<p align="center">
  <img src="https://github.com/user-attachments/assets/9b14993a-9481-414e-9dd4-8c0d6465a9d2" alt="Bede Package Manager" width="200">
</p>

## Overview

Bede is a cutting-edge package manager designed to simplify the installation and management of custom packages across diverse Linux distributions. This monorepo contains the Bede package manager along with its curated packages, ensuring a streamlined experience whether you're on a standard Linux distribution or running Termux.

## Features

- **Custom Package Management:** Easily install and manage packages tailored for your Linux environment.
- **Intelligent Fallback:** If a package is not available in our custom index, Bede automatically attempts to install it using your system’s native package manager.
- **Cross-Platform Compatibility:** Optimized to work on both standard Linux distributions and Termux environments.
- **Dependency Resolution:** Automatically handles dependencies, ensuring a smooth installation process.
- **User-Friendly Commands:** Simple command-line interface that empowers users to manage packages effortlessly.

## Installation

### Standard Linux

To install Bede on your standard Linux system, run the following commands in your terminal:

```bash
sudo curl -sSL "https://raw.githubusercontent.com/PsymoNiko/bedepacko/main/bede.sh" -o /usr/local/bin/bede
sudo chmod +x /usr/local/bin/bede
```

### Termux

For Termux users, the installation directory is set to `$PREFIX/bin` and elevated permissions are not required. Use these commands:

```bash
curl -sSL "https://raw.githubusercontent.com/PsymoNiko/bedepacko/main/bede.sh" -o "$PREFIX/bin/bede"
chmod +x "$PREFIX/bin/bede"
```

## Usage

Bede simplifies package management with intuitive commands:

- **List Available Packages:**

  ```bash
  bede list
  ```

- **Install a Package:**

  ```bash
  sudo bede install <package>
  ```

- **Remove a Package:**

  ```bash
  sudo bede remove <package>
  ```

> **Note:** In Termux, simply omit `sudo` since elevated privileges are not necessary.

## Documentation

For detailed instructions on package creation, dependency management, troubleshooting, and advanced usage, please visit our [Wiki](https://github.com/PsymoNiko/bedepacko/wiki). The Wiki is a living resource, continuously updated to help you get the most out of Bede.

## Collaboration

We are committed to continuous improvement and warmly welcome contributions from the community. If you’d like to help enhance Bede:

- Review our [Contribution Guidelines](https://github.com/PsymoNiko/bedepacko/wiki/Contributing)
- Submit issues and feature requests through GitHub Issues
- Fork the repository and submit pull requests with your enhancements

Your collaboration is instrumental in shaping a robust and innovative package management solution.

## License

Bede is distributed under the [MIT License](LICENSE). We encourage you to explore, modify, and share this software, keeping in line with the open-source spirit.

## Support

For support, please reach out via:

- **GitHub Issues:** Report bugs or suggest new features directly on our GitHub repository.
- **Community Discussions:** Join our community on the Wiki and share your insights with fellow users.

---

*Empowering users with a seamless package management experience, one installation at a time.*

```

This README.md is designed to provide clear guidance, encourage collaboration, and showcase the innovative aspects of the Bede package manager. Feel free to further customize it to align with any additional project requirements or stylistic preferences.
