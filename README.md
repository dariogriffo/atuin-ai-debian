![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/atuin-ai-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/atuin-ai-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/atuin-ai-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/atuin-ai-debian)

<h1>
   <p align="center">
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/atuin-ai-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104"></a>
     <br>Atuin AI for Debian
   </p>
</h1>
<p align="center">
 The Atuin shell agent: press ? at an empty prompt to chat with your own Atuin AI server.
</p>

# Atuin AI for Debian

This repository contains build scripts to produce the _unofficial_ Debian and
Ubuntu packages (.deb) for the [Atuin AI](https://github.com/atuinsh/atuin-ai)
client, hosted at [deb.griffo.io](https://deb.griffo.io)

`atuin-ai` is the shell agent Atuin shipped up to 18.24, which Atuin 18.25
removed. It needs [Atuin](https://github.com/dariogriffo/atuin-debian) (a
dependency, also on deb.griffo.io) and an Atuin AI server that you host
yourself. Only the client is packaged: upstream publishes the server as a
Docker image (`ghcr.io/atuinsh/atuin-ai-server`), see
[Self-Hosting](https://github.com/atuinsh/atuin-ai#self-hosting).

Currently supported distros are:
- Debian Bookworm (v12), Trixie (v13), Forky (v14), Sid
- Ubuntu Jammy (22.04), Noble (24.04), Questing (25.10), Resolute (26.04), Stonking (26.10)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions

The same two architectures as the Atuin package it depends on.

## Weekly snapshots

Upstream publishes no releases, tags or binaries, so this repository compiles
the client itself. Every Friday, `check-upstream.yml` looks at upstream's
`main` branch and, if it moved since the last release, dispatches
`release.yml` to build that commit. Nothing is released in a week without
upstream changes.

- **Version:** `<client version>.<YYYYMMDD>`, e.g. `0.1.0.20261127`: the
  version in upstream's `client/Cargo.toml` at that commit, then the build
  date. Each snapshot sorts above the previous one.
- **Release tag:** `<version>+<build>`, e.g. `0.1.0.20261127+1`. The release
  notes and `/usr/share/doc/atuin-ai/changelog.Debian` name the upstream commit.
- **Build:** natively on GitHub's amd64 and arm64 runners, in Ubuntu 22.04
  (glibc 2.35, OpenSSL 3.0) so the one binary runs on every suite, with the
  current stable Rust and upstream's `Cargo.lock`.

One package per architecture is built and shared by every suite
(`atuin-ai_<version>-<build>~griffo_<arch>.deb`), plus one source package.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the Atuin AI source code, see
[atuin-ai](https://github.com/atuinsh/atuin-ai).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-atuin-ai-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-atuin-ai-in-ubuntu.html)

### The Debian way

> ⚠️ **apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/atuin-ai-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y atuin-ai
```

Then point it at your server in `~/.atuin/ai.toml`:

```toml
endpoint = "http://localhost:8080"
# api_token = "..."   # when the server sets AUTH_TOKEN
```

and bind `?` in your shell, after Atuin's own init:

```bash
# ~/.bashrc
eval "$(atuin init bash)"
eval "$(atuin-ai init bash)"

# ~/.zshrc
eval "$(atuin init zsh)"
eval "$(atuin-ai init zsh)"

# ~/.config/fish/config.fish
atuin init fish | source
atuin-ai init fish | source
```

### Manual Installation

1. Download the .deb package for your architecture from
   the [Releases](https://github.com/dariogriffo/atuin-ai-debian/releases) page.
2. Install it with apt, so the dependencies are pulled in. `atuin` comes from
   deb.griffo.io or your distribution's archive.

```sh
sudo apt install ./<filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

The build is native: on an amd64 host it builds amd64, on an arm64 host arm64.
Without a commit, upstream's current `main` is built.

```sh
./build.sh <atuin_ai_version> <build_version> <architecture> [upstream_commit]
# Example: ./build.sh 0.1.0.20261127 1 amd64 c1514876b950a915656592d7fe555f994db1b7e4
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64)
- [x] Weekly snapshots of upstream's main branch

## Disclaimer

- This repo is not open for issues related to Atuin AI. This repo is only for _unofficial_ Debian packaging.
