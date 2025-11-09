# Cross-Platform Development Guide

This guide captures the day-to-day commands and workflows you need to build, test, debug, and release the PohLang runtime on Windows, Linux, and macOS.

## Toolchains

| OS      | Requirements                                                                                       |
|---------|----------------------------------------------------------------------------------------------------|
| Windows | [Rustup](https://rustup.rs/), Visual C++ Build Tools (bundled with rustup installer), PowerShell   |
| Linux   | Rustup, build essentials (`gcc`, `make`, `pkg-config`), `curl`, `tar`                              |
| macOS   | Rustup, Xcode Command Line Tools (`xcode-select --install`), `curl`, `tar`                         |

```bash
# Install rustup (Linux/macOS)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Update toolchains on any platform
rustup update
```

### Extra targets
To build Apple Silicon binaries from macOS and create release archives that match CI:
```bash
rustup target add aarch64-apple-darwin x86_64-apple-darwin
```

## Build

```bash
# Debug build
cargo build --manifest-path runtime/Cargo.toml

# Release build (native architecture)
cargo build --manifest-path runtime/Cargo.toml --release

# Cross build (examples)
# macOS Intel from Apple Silicon
cargo build --manifest-path runtime/Cargo.toml --release --target x86_64-apple-darwin
# Apple Silicon from Intel
cargo build --manifest-path runtime/Cargo.toml --release --target aarch64-apple-darwin
```

Artifacts are emitted to `runtime/target/<target-triple>/release/`.

## Test

```bash
# Run the full suite
cargo test --manifest-path runtime/Cargo.toml --all

# Run a subset (example)
cargo test --manifest-path runtime/Cargo.toml bytecode_basic

# Keep test output
cargo test --manifest-path runtime/Cargo.toml -- --nocapture
```

CI (`.github/workflows/ci.yml`) runs `cargo fmt`, `cargo clippy`, builds, and tests on Ubuntu, macOS, and Windows for every pull request.

## Debug

### Crash diagnostics
```bash
# Show Rust backtraces
RUST_BACKTRACE=1 cargo run --manifest-path runtime/Cargo.toml -- --run examples/poh/hello.poh

# On Windows PowerShell
$env:RUST_BACKTRACE=1; cargo run --manifest-path runtime/Cargo.toml -- --run examples/poh/hello.poh
```

### Stepping through code
- **Linux:** `rust-gdb target/debug/pohlang`
- **macOS:** `lldb target/debug/pohlang`
- **Windows (VS Code):** use the CodeLLDB extension with the provided `launch.json` in `.vscode/`.

### Logging helpers
Use the existing `log::debug!` or temporary `println!` statements inside the runtime; guard them behind feature flags before committing.

## Release

1. Ensure CI is green.
2. Update `runtime/Cargo.toml` with the new version and run `cargo fmt`.
3. Create a tag (`git tag v0.x.y && git push origin v0.x.y`).
4. GitHub Actions builds cross-platform artefacts:
   - `.github/workflows/simple-release.yml` produces CLI binaries for Linux x64, Windows x64, macOS x64, macOS arm64.
   - `.github/workflows/sdk-release.yml` creates SDK archives with runtime, docs, and examples for the same targets.
5. Verify artefacts locally if needed:
```bash
# Example validation of the macOS arm64 archive
tar -xzf pohlang-v0.x.y-macos-arm64.tar.gz
./pohlang --version
```

## Installers

- `install/install.sh` (bash) and `install/install.ps1` (PowerShell) fetch the latest release automatically.
- Override behaviour with `POHLANG_VERSION` (tag) and `POHLANG_INSTALL_DIR` (destination folder).
- Both scripts verify tool prerequisites and print next steps.

## Troubleshooting

| Symptom                                   | Fix                                                                 |
|-------------------------------------------|----------------------------------------------------------------------|
| `linker not found` on Linux               | Install `build-essential`, `pkg-config`, and `libssl-dev`.          |
| `linker 'cc' not found` on macOS          | Run `xcode-select --install`.                                      |
| `pohlang` not on PATH after install       | Add the install directory manually or relaunch the terminal.       |
| `cargo` cannot find a target              | Run `rustup target add <triple>` before building.                  |
| GitHub Actions release job fails to upload| Ensure the tag matches `v*.*.*` and you have pushed the tag.       |

For day-to-day workflows keep an eye on `INSTALL.md` (distribution) and this document (development tooling). Feedback welcome! 
