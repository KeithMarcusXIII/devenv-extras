# Source Tree Analysis

**Project:** devenv-extras
**Type:** Monolith — Devenv Nix Module Library
**Generated:** 2026-06-01

---

## Directory Structure

```
devenv-extras/
├── .agents/                        # AI agent skill definitions (BMad framework)
│   └── skills/
│       └── bmad-*/                 # Various BMad workflow skills
├── .roo/                           # Roo Code IDE configuration
│   └── mcp.json                    # Generated MCP server config (output of modules/mcp)
├── _bmad/                          # BMad framework configuration
│   ├── bmm/                        # BMad Module Manager config
│   │   └── config.yaml             # Project-level BMad config (user, language, paths)
│   ├── core/                       # BMad core config
│   ├── custom/                     # Team/user overrides
│   ├── scripts/                    # BMad utility scripts
│   └── _config/                    # Manifest files
├── _bmad-output/                   # BMad workflow outputs
│   ├── implementation-artifacts/   # Code generation outputs
│   └── planning-artifacts/         # Architecture/planning docs
├── docs/                           # Project documentation (this scan's output)
├── modules/                        # ★ Core library — reusable devenv modules
│   └── mcp/                        # MCP server configuration module
│       └── devenv.nix              # Module definition (options + config generation)
├── devenv.entry.nix                # Dev environment entry point (imports modules)
├── devenv.nix                      # Development environment configuration
├── devenv.yaml                     # Devenv input pinning and project settings
├── devenv.lock                     # Nix flake lock (reproducible builds)
├── .envrc                          # direnv integration (auto-activates devenv)
├── .gitignore                      # Git ignore rules
├── LICENSE                         # MIT License
└── README.md                       # Project documentation and usage guide
```

## Critical Folders

### `modules/` — Library Module Root

The heart of the repository. Each subdirectory is a self-contained [devenv](https://devenv.sh/) module that can be independently imported by downstream projects. Modules follow the devenv module convention: a single `devenv.nix` file that declares `options` and `config`.

| Module | Path | Description |
|--------|------|-------------|
| **mcp** | [`modules/mcp/devenv.nix`](../modules/mcp/devenv.nix) | Generates IDE-specific MCP server configuration files |

### `devenv.nix` / `devenv.entry.nix` — Development Environment

- [`devenv.nix`](../devenv.nix) — The development environment for this repository itself. Configures Node.js 24, pnpm, Python, and injects secrets from Bitwarden Secrets Manager.
- [`devenv.entry.nix`](../devenv.entry.nix) — A shim entry point that imports `modules/mcp/devenv.nix` for local development/testing. **Note:** This file exists because `devenv.nix` was needed for the dev environment; it will be renamed back to `devenv.nix` after setup is complete.

### `.roo/` — Generated IDE Configuration

Contains generated MCP configuration output by the `modules/mcp` module. This is an example of what downstream consumers receive when they import the module.

### `_bmad/` — BMad Framework

Development workflow tooling. Not part of the library's public API — used internally for project management, documentation generation, and development workflows.

## Entry Points

| Entry Point | Purpose |
|-------------|---------|
| [`devenv.yaml`](../devenv.yaml) | Primary import mechanism — downstream projects reference this repo as a flake input |
| [`devenv.nix`](../devenv.nix) | Development environment for contributors to this repo |
| [`modules/mcp/devenv.nix`](../modules/mcp/devenv.nix) | The module's public API — declares `options.mcp` and generates IDE config files |

## Module Architecture Pattern

Each module under `modules/` follows the standard devenv module pattern:

```nix
{ pkgs, lib, config, ... }:
{
  options.<module-name> = {
    # Declare configurable options with types and defaults
  };

  config = {
    # Generate output files based on option values
    files."<path>".json = { ... };
  };
}
```

The MCP module specifically:
1. **Declares** `options.mcp.servers` — an attribute set of MCP server definitions
2. **Validates** mutual exclusivity constraints (stdio vs HTTP transport)
3. **Generates** three IDE-specific config files from the same source of truth:
   - `.roo/mcp.json` (Roo Code)
   - `.vscode/mcp.json` (VS Code)
   - `.cursor/mcp.json` (Cursor)
