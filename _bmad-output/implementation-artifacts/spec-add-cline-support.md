---
title: 'Add Cline IDE Support to MCP Module'
type: 'feature'
created: '2026-06-23'
status: 'done'
route: 'one-shot'
context:
  - 'modules/mcp/devenv.nix'
baseline_commit: 'NO_VCS'
---

# Add Cline IDE Support to MCP Module

## Intent

**Problem:** The MCP module generates config for Roo Code, VS Code, and Cursor, but Cline — another popular AI coding assistant — is not supported. Users who use Cline cannot manage their MCP servers through this module.

**Approach:** Add `mcp.cline.enable` toggle (default `false`), `autoApprove` server-level option, and a config block that generates `.cline/mcp.json` using the `mcpServers` top-level key per Cline's documented format.

## Suggested Review Order

**Option Schema**

- New `mcp.cline.enable` boolean flag and `autoApprove` server option
  [`devenv.nix:90`](../../modules/mcp/devenv.nix#L90)

- `disabled` option description corrected to include Cline
  [`devenv.nix:187`](../../modules/mcp/devenv.nix#L187)

**Cline Config Generator**

- Cline config block: `mcpServers` key, `disabled` + `autoApprove` injection
  [`devenv.nix:355`](../../modules/mcp/devenv.nix#L355)

**Documentation**

- Updated `mcp.servers` description mentioning `.cline/mcp.json`
  [`devenv.nix:284`](../../modules/mcp/devenv.nix#L284)
