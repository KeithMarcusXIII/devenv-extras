# Development Guide

**Project:** devenv-extras
**Generated:** 2026-06-01

---

## Prerequisites

- [devenv](https://devenv.sh/getting-started/) 1.0+
- [Nix](https://nixos.org/download.html) package manager
- [direnv](https://direnv.net/) (optional, for automatic environment activation)
- macOS or Linux

## Getting Started

### 1. Clone the repository

```sh
git clone https://github.com/keith/devenv-extras.git
cd devenv-extras
```

### 2. Activate the development environment

**With direnv (recommended):**

```sh
direnv allow
```

The environment activates automatically on `cd`.

**Without direnv:**

```sh
devenv shell
```

### 3. What the dev environment provides

The development environment (defined in [`devenv.nix`](../devenv.nix)) includes:

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 24 | JavaScript/TypeScript runtime |
| pnpm | (latest) | Node.js package manager |
| Python 3 | (system) | Scripting and BMad workflows |
| mcp-nixos | (latest) | NixOS MCP server |
| secretspec | (latest) | Secret specification tool |
| bws | (latest) | Bitwarden Secrets Manager CLI |

**Secret injection:** On shell entry, secrets are automatically fetched from Bitwarden Secrets Manager via `bws secret list` and exported as environment variables.

## Project Structure for Contributors

```
devenv-extras/
├── modules/            # ★ Add new modules here
│   └── mcp/            # Each module = one directory with devenv.nix
│       └── devenv.nix
├── devenv.nix          # Dev environment (modify for new tooling)
├── devenv.yaml         # Input pinning (modify for new dependencies)
├── devenv.lock         # Auto-generated lock file (do not edit)
├── devenv.entry.nix    # Entry point shim (temporary — see note)
└── README.md           # Public documentation
```

> **Note on `devenv.entry.nix`:** This file exists because `devenv.nix` was reserved for the development environment. It imports `modules/mcp/devenv.nix` for local testing. It will be renamed back to `devenv.nix` once the dev environment setup is finalized.

## Adding a New Module

1. Create a new directory under `modules/`:
   ```
   modules/my-module/devenv.nix
   ```

2. Follow the devenv module pattern:
   ```nix
   { pkgs, lib, config, ... }:
   {
     options.my-module = {
       # Declare options with lib.mkOption
     };

     config = {
       # Generate outputs
     };
   }
   ```

3. Test locally by importing in `devenv.entry.nix`:
   ```nix
   { ... }:
   {
     imports = [
       ./modules/mcp/devenv.nix
       ./modules/my-module/devenv.nix
     ];
   }
   ```

4. Update [`README.md`](../README.md) with the new module's documentation.

## Testing

Currently no automated test suite. Validate modules by:

1. **Nix evaluation check:**
   ```sh
   devenv build
   ```
   Type errors and assertion failures surface at build time.

2. **Inspect generated output:**
   ```sh
   cat .roo/mcp.json
   cat .vscode/mcp.json
   cat .cursor/mcp.json
   ```

3. **Assertion testing:** The MCP module includes built-in assertions (e.g., mutual exclusivity of `command` and `url`). Invalid configurations will fail at evaluation time.

## Distribution

Modules are distributed via direct GitHub reference. No build step, publish step, or package registry is involved.

Consumers add to their `devenv.yaml`:
```yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
```

## Code Conventions

- Follow standard Nix formatting conventions
- Use `lib.optionalAttrs` for conditional field inclusion (keep JSON output minimal)
- Add assertions for configuration validation where appropriate
- Document all `mkOption` declarations with descriptions
