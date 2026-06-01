# Project Overview

**Project:** devenv-extras
**License:** MIT (Copyright © 2026 Keith)
**Repository:** github:keith/devenv-extras

---

## Purpose

`devenv-extras` is a collection of reusable [devenv.sh](https://devenv.sh/) modules for common development setup tasks. It aims to reduce boilerplate when configuring development environments by providing plug-and-play modules that generate IDE-specific configuration files from a single source of truth.

## Problem Statement

Modern AI-augmented IDEs (Roo Code, VS Code, Cursor) each have their own MCP (Model Context Protocol) server configuration format. Developers must manually maintain separate config files for each IDE, leading to drift and duplication. `devenv-extras` solves this by letting you declare your MCP servers once in Nix and having the correct config generated for every IDE automatically.

## Tech Stack Summary

| Category | Technology |
|----------|-----------|
| Language | Nix |
| Framework | [devenv.sh](https://devenv.sh/) 1.0+ |
| Package inputs | nixpkgs (unstable), cachix/devenv |
| Dev tooling | Node.js 24, pnpm, Python 3 |
| Secrets | Bitwarden Secrets Manager |
| Distribution | GitHub |

## Architecture Type

**Modular plugin library** — each module under `modules/` is a self-contained devenv module that can be imported independently by downstream projects.

## Repository Structure

Single-part monolith. All modules live under `modules/` and share the same repository infrastructure (devenv.yaml, devenv.lock, etc.).

## Available Modules

| Module | Description |
|--------|-------------|
| [`mcp`](../modules/mcp/devenv.nix) | Declare MCP server configs once → generates `.roo/mcp.json`, `.vscode/mcp.json`, `.cursor/mcp.json` (each gated by `mcp.<ide>.enable`) |

## Quick Start

### 1. Add as a devenv input

```yaml
# devenv.yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
imports:
  - devenv-extras/modules/mcp
```

### 2. Configure your MCP servers

```nix
# devenv.nix
{ pkgs, lib, config, ... }:
{
  mcp.servers = {
    "my-server" = {
      command = "npx";
      args = [ "-y" "my-mcp-server" ];
      alwaysAllow = [ "tool_one" "tool_two" ];
    };
  };
}
```

### 3. (Optional) Disable specific IDE targets

```nix
{
  mcp.roo.enable = false;    # Skip .roo/mcp.json
  mcp.cursor.enable = false; # Skip .cursor/mcp.json
}
```

All targets default to `true`.

### 4. Rebuild your devenv

```sh
devenv shell
```

IDE config files are generated automatically at `.roo/mcp.json`, `.vscode/mcp.json`, and `.cursor/mcp.json`, filtered by enable flags.

## Links

- [Architecture](./architecture.md) — Detailed technical architecture
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure
- [Development Guide](./development-guide.md) — How to contribute
