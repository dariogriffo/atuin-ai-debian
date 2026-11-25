<div align="center">

# Atuin AI

**The Atuin shell agent: press `?` at an empty prompt to chat with your own Atuin AI server.**

![GitHub License](https://img.shields.io/github/license/atuinsh/atuin-ai)

</div>

## About

`atuin-ai` is the shell agent Atuin shipped up to 18.24, now a standalone
binary. It suggests commands and answers questions, and with your permission
it can search your Atuin history, read and edit files, and run commands.

It talks to an Atuin AI server that you host yourself, backed by any
OpenAI-compatible endpoint (Ollama, vLLM, a hosted API...). Upstream publishes
the server as a Docker image, `ghcr.io/atuinsh/atuin-ai-server`; see
https://github.com/atuinsh/atuin-ai#self-hosting.

## Set up

1. Point the client at your server in `~/.atuin/ai.toml`
   (`/usr/share/doc/atuin-ai/examples/ai.example.toml` lists every setting):

   ```toml
   endpoint = "http://localhost:8080"
   # api_token = "..."   # when the server sets AUTH_TOKEN
   ```

2. Bind `?` in your shell, after Atuin's own init:

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

Upstream has no releases yet: this package is a weekly snapshot of its main
branch. `/usr/share/doc/atuin-ai/changelog.Debian` names the commit it was
built from.

**[Read the documentation](https://github.com/atuinsh/atuin-ai/tree/main/client)**
