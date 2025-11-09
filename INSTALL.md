# PohLang Installation Guide

PohLang ships as self-contained binaries for Windows, Linux, and macOS (both Intel and Apple Silicon). The official install scripts now fetch the latest published release automatically and take care of placing the binary on your system.

## Quick Install (Recommended)

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/AlhaqGH/PohLang/main/install/install.ps1 | iex
```
> Tip: set `$env:POHLANG_VERSION='v0.6.7'` (or any tag) to install a specific release. Use `$env:POHLANG_INSTALL_DIR='C:\Tools\PohLang'` to override the destination before running the script.

### Linux / macOS (bash)
```bash
curl -sSL https://raw.githubusercontent.com/AlhaqGH/PohLang/main/install/install.sh | bash
```
> Tip: export `POHLANG_VERSION=v0.6.7` or `POHLANG_INSTALL_DIR=$HOME/.local/bin` before running the installer to customise version or install location.

## Manual Downloads

Grab binaries directly from the [GitHub releases](https://github.com/AlhaqGH/PohLang/releases) page. Asset names follow the pattern `pohlang-<tag>-<platform>.<ext>`.

| Platform              | Asset extension | Example asset                          |
|-----------------------|-----------------|----------------------------------------|
| Windows x64           | `.zip`          | `pohlang-v0.6.7-windows-x64.zip`       |
| Linux x64             | `.tar.gz`       | `pohlang-v0.6.7-linux-x64.tar.gz`      |
| macOS Intel (x64)     | `.tar.gz`       | `pohlang-v0.6.7-macos-x64.tar.gz`      |
| macOS Apple Silicon   | `.tar.gz`       | `pohlang-v0.6.7-macos-arm64.tar.gz`    |

After downloading, extract the archive and move the `pohlang` binary somewhere on your `PATH` (for example `/usr/local/bin` on Unix-like systems or `C:\Program Files\PohLang` on Windows).

## Environment Overrides

The installers recognise two optional environment variables:

- `POHLANG_VERSION` - install a specific tagged release (for example `v0.6.6`).
- `POHLANG_INSTALL_DIR` - choose a custom install directory.

If unset, the scripts install the most recent release into `/usr/local/bin` (Linux/macOS) or `C:\Program Files\PohLang` / `%LOCALAPPDATA%\PohLang` (Windows, depending on privileges).

## Verify Installation

```bash
pohlang --version

echo 'Start Program
Write "Hello from PohLang!"
End Program' > hello.poh
pohlang --run hello.poh
```

## VS Code Extension (Optional)

1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Search for **PohLang Hub** in the marketplace and install it.
3. Open any `.poh` file and press `Ctrl+F5` to run.

The extension bundles the runtime, provides IntelliSense, snippets, and works offline once installed.

## Uninstallation

### Windows
Remove the install directory (`%LOCALAPPDATA%\PohLang` for user installs or `C:\Program Files\PohLang` for system installs) and delete the PATH entry if you added one manually.

### Linux/macOS
Delete the installed binary (default `/usr/local/bin/pohlang`) and remove any optional install directory you configured.

## Building from Source

1. Install [Rust](https://rustup.rs/).
2. Clone the repository: `git clone https://github.com/AlhaqGH/PohLang.git`.
3. Build and test:
   ```bash
   cargo build --release --manifest-path runtime/Cargo.toml
   cargo test --manifest-path runtime/Cargo.toml
   ```
4. The binary is written to `runtime/target/release/pohlang` (or the target-specific directory when cross-compiling).

For detailed cross-platform build, test, debug, and release workflows see `doc/CROSS_PLATFORM_DEV.md`.

## Troubleshooting

- **Binary not found after install** - ensure the install directory is on your `PATH`, then open a new shell.
- **Permission denied** - run the installer with `sudo` (Linux/macOS) or an elevated PowerShell window (Windows) if installing to a system directory.
- **macOS Gatekeeper warning** - run `xattr -d com.apple.quarantine /path/to/pohlang` or allow the binary via System Settings -> Privacy & Security.
- **Need older versions** - set `POHLANG_VERSION` before running the install scripts or download the desired archive from the releases page.
