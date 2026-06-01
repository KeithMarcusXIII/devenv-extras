# Project Documentation Index

**Project:** devenv-extras
**Generated:** 2026-06-01
**Scan Level:** Exhaustive

---

## Project Overview

- **Type:** Monolith — Devenv Nix Module Library
- **Primary Language:** Nix
- **Architecture:** Modular plugin library (devenv module system)

## Quick Reference

- **Framework:** [devenv.sh](https://devenv.sh/) 1.0+
- **Distribution:** GitHub (`github:keith/devenv-extras`, `flake: false`)
- **Entry Point:** [`modules/<name>/devenv.nix`](../modules/) — each module is self-contained
- **Architecture Pattern:** Declare options → validate → transform → generate IDE config files

## Generated Documentation

- [Project Overview](./project-overview.md) — Purpose, tech stack, quick start
- [Architecture](./architecture.md) — Technical architecture, design decisions, data flow
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure
- [Development Guide](./development-guide.md) — Prerequisites, setup, contributing

## Existing Documentation

- [README.md](../README.md) — Project overview, module listing, usage examples, requirements
- [LICENSE](../LICENSE) — MIT License (Copyright © 2026 Keith)

## Getting Started

### For consumers (importing into your project):

```yaml
# devenv.yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
imports:
  - devenv-extras/modules/mcp
```

```nix
# devenv.nix
{ pkgs, lib, config, ... }:
{
  mcp.servers = {
    "my-server" = {
      command = "npx";
      args = [ "-y" "my-mcp-server" ];
    };
  };
}
```

### For contributors (developing this library):

See [Development Guide](./development-guide.md) for prerequisites, setup, and how to add new modules.
