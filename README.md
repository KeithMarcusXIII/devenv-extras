# devenv-extras

A collection of reusable [devenv](https://devenv.sh/) modules for common development setup tasks.

## Modules

| Module | Description |
|--------|-------------|
| [`ide-mcp`](./modules/ide-mcp/devenv.nix) | Declare MCP server configurations once, generate config files for Roo Code (`.roo/mcp.json`), VS Code (`.vscode/mcp.json`), and Cursor (`.cursor/mcp.json`) automatically. |

## Usage

### Selective import — only `ide-mcp` (recommended)

```yaml
# devenv.yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
imports:
  - devenv-extras/modules/ide-mcp
```

```nix
# devenv.nix
{ pkgs, lib, config, ... }:
{
  ide-mcp.servers = {
    "my-server" = {
      command = "npx";
      args = [ "-y" "my-mcp-server" ];
      alwaysAllow = [ "tool_one" "tool_two" ];
    };
  };
}
```

### Import everything

```yaml
# devenv.yaml
inputs:
  devenv-extras:
    url: github:keith/devenv-extras
    flake: false
imports:
  - devenv-extras
```

## Requirements

- [devenv](https://devenv.sh/getting-started/) 1.0+
- The importing project must NOT have a `flake.nix` (standard devenv setup)

## License

MIT
