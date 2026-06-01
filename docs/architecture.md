# Architecture

**Project:** devenv-extras
**Type:** Devenv Nix Module Library
**Architecture Pattern:** Modular plugin library
**Generated:** 2026-06-01

---

## Executive Summary

`devenv-extras` is a reusable [Nix](https://nixos.org/) module library for [devenv.sh](https://devenv.sh/) — a Nix-based development environment manager. The project provides plug-and-play modules that downstream projects import via `devenv.yaml` to automatically generate IDE-specific configuration files.

The first (and currently only) module, `mcp`, solves a real pain point: declaring MCP (Model Context Protocol) server configurations once and having them automatically written to the three major AI-augmented IDEs — Roo Code, VS Code, and Cursor — each with their own format conventions.

## Technology Stack

| Category | Technology | Version / Details |
|----------|-----------|-------------------|
| **Language** | Nix | Devenv module system |
| **Framework** | [devenv.sh](https://devenv.sh/) | 1.0+ (per README) |
| **Package inputs** | nixpkgs | `nixpkgs-unstable` branch |
| **Devenv source** | cachix/devenv | Pinned in `devenv.lock` |
| **Lock format** | devenv.lock | Version 7 (Nix flake lock) |
| **Dev tooling** | Node.js 24 + pnpm | JavaScript/TypeScript tooling |
| **Dev tooling** | Python 3 + venv | Scripting and BMad workflows |
| **Secrets** | Bitwarden Secrets (bws) | Injected via `enterShell` |
| **Distribution** | GitHub | `github:keith/devenv-extras` |

## Architecture Pattern

### Modular Plugin Library

The project follows the **devenv module system** pattern — the same pattern used by devenv.sh itself and its ecosystem. Each module is a self-contained Nix expression that:

1. **Declares options** via `lib.mkOption` with full type safety
2. **Implements config** that generates output files based on option values
3. **Supports composition** — modules can be imported individually or together

```
┌─────────────────────────────────────────────┐
│  Downstream Project                         │
│                                             │
│  devenv.yaml                                │
│    inputs:                                  │
│      devenv-extras:                         │
│        url: github:keith/devenv-extras      │
│    imports:                                 │
│      - devenv-extras/modules/mcp            │
│                                             │
│  devenv.nix                                 │
│    mcp.servers = { ... };                   │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │  Generated Outputs                    │  │
│  │  ├── .roo/mcp.json     (if mcp.roo.enable)   │  │
│  │  ├── .vscode/mcp.json  (if mcp.vscode.enable)│  │
│  │  └── .cursor/mcp.json  (if mcp.cursor.enable)│  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Module Internal Architecture (MCP Module)

The MCP module follows a **declare → validate → transform → generate** pipeline:

```
options.mcp
├── roo.enable           config.files.*.json
├── vscode.enable               ▲
├── cursor.enable               │
├── inputs (opt)                │
└── servers                     │
       │                        │
       ▼                        │
┌──────────────┐    ┌──────────────────────────┐
│  mkOption    │───▶│  mkServerEntry (shared)   │
│  declarations│    │  ├─ filterEnv             │
│  - command   │    │  ├─ stdio fields          │
│  - args      │    │  ├─ HTTP/SSE fields       │
│  - env       │    │  ├─ transportType         │
│  - url       │    │  └─ common guards         │
│  - headers   │    └──────────┬───────────────┘
│  - alwaysAllow│              │
│  - envFile    │              ▼
│  - disabled   │    ┌──────────────────────────┐
│  - disabledToo│    │  Target-specific merge    │
│  - cwd        │    │  (gated by roo/vscode/   │
│  - timeout    │    │   cursor.enable)          │
│  - watchPaths │    │  ├─ .roo/mcp.json        │
│  - oauth      │    │  ├─ .vscode/mcp.json     │
│  - sandboxEnab│    │  └─ .cursor/mcp.json     │
│  - sandbox    │    └──────────────────────────┘
│  - dev        │
│  - auth       │
│  - transportTy│
└──────────────┘
```

**Key design decisions:**

1. **Shared builder** (`mkServerEntry`) — constructs the common JSON fields once, avoiding duplication across targets
2. **Conditional field inclusion** — empty/null/`[]` fields are omitted via `lib.optionalAttrs` guards, keeping output minimal
3. **Mutual exclusivity assertion** — `command` and `url` cannot both be set (stdio vs HTTP transport)
4. **Environment filtering** (`filterEnv`) — strips empty/null env values to prevent shadowing shell-inherited variables
5. **Target-specific extensions** — each IDE adds its own fields (e.g., `alwaysAllow`, `cwd`, `timeout` for Roo Code; `oauth`, `sandbox`, `dev` for VS Code; `auth` for Cursor)
6. **Opt-in IDE targeting** — `mcp.roo.enable`, `mcp.vscode.enable`, `mcp.cursor.enable` flags gate which config files are generated (all default `true`)
7. **Transport type override** — `transportType` option allows explicit `"sse"` selection for legacy servers across all targets

## Data Architecture

No databases or persistent data stores. The module operates purely as a configuration transformer:

- **Input:** Nix attribute set (`config.mcp.servers`) + enable flags (`config.mcp.roo.enable`, etc.)
- **Output:** Up to three JSON files written to the consuming project's file tree, filtered by enable flags

## Configuration Management

| File | Purpose |
|------|---------|
| [`devenv.yaml`](../devenv.yaml) | Input pinning — locks nixpkgs and devenv versions |
| [`devenv.lock`](../devenv.lock) | Reproducible lock file (Nix flake lock v7) |
| [`devenv.nix`](../devenv.nix) | Development environment for this repo |
| [`.envrc`](../.envrc) | direnv integration — auto-activates devenv on `cd` |

## Testing Strategy

Currently no automated tests. The module is validated by:
- **Nix evaluation** — type errors surface at build time
- **Assertions** — the `serverAssertions` list catches invalid configurations (both `command` and `url` set)
- **Manual verification** — generated JSON files can be inspected directly

## Deployment / Distribution

No build or deployment pipeline. Distribution is via direct Git reference:

```yaml
# Consumer's devenv.yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
```

The `flake: false` flag is required because this is a devenv module library, not a Nix flake. Consumers import modules by path.
