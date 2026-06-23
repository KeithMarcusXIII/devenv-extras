{ pkgs, lib, config, ... }:

let
  # Filter out empty and null env values (e.g. when secretspec refs
  # resolve to "" or null). This prevents IDE config `env` fields from
  # shadowing shell-inherited environment variables with empty/blank values.
  filterEnv = env: lib.filterAttrs (name: value: value != "" && value != null) env;

  # Build a server entry with fields common to all IDE targets.
  # Guards are designed to omit empty/noop fields so the JSON output
  # is minimal and correct for each target.
  mkServerEntry = server:
    { }
    # Stdio fields — only when command is a non-empty string
    // lib.optionalAttrs (server.command != null && server.command != "") {
      inherit (server) command;
    }
    // lib.optionalAttrs (server.args != [ ]) {
      args = server.args;
    }
    # Environment variables (omitted entirely if empty after filtering)
    // lib.optionalAttrs (filterEnv server.env != { }) {
      env = filterEnv server.env;
    }
    # HTTP/SSE fields — only when url is a non-empty string
    // lib.optionalAttrs (server.url != null && server.url != "") {
      inherit (server) url;
    }
    # Headers — only when non-empty (consistent with env/args handling)
    // lib.optionalAttrs (server.headers != { }) {
      headers = server.headers;
    }
    # Transport type override — when set, used by all targets
    // lib.optionalAttrs (server.transportType != null) {
      type = server.transportType;
    }
    # Working directory (Roo Code only)
    // lib.optionalAttrs (server.cwd != null) {
      cwd = server.cwd;
    }
    # Per-server timeout in seconds (Roo Code only, 1-3600)
    // lib.optionalAttrs (server.timeout != null) {
      timeout = server.timeout;
    }
    # Watch paths for auto-restart on change (Roo Code only)
    // lib.optionalAttrs (server.watchPaths != [ ]) {
      watchPaths = server.watchPaths;
    };

  # Validate transports: mutually exclusive (not both) and at least one non-empty
  serverAssertions =
    # At-most-one assertion: command and url cannot both be set
    (lib.mapAttrsToList (name: server: {
      assertion = server.command == null || server.url == null;
      message = "Server '${name}': set exactly one of `command` or `url`, not both";
    }) config.mcp.servers)
    # At-least-one assertion: command or url (or both for streamable-http+stdio) must be non-empty
    ++ (lib.mapAttrsToList (name: server: {
      assertion = (server.command != null && server.command != "") || (server.url != null && server.url != "");
      message = "Server '${name}': at least one of `command` or `url` must be a non-empty string";
    }) config.mcp.servers);
in
{
  options.mcp = {
    # IDE target enable flags — opt-in per IDE
    roo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to generate .roo/mcp.json for Roo Code";
      };
    };

    vscode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to generate .vscode/mcp.json for VS Code";
      };
    };

    cursor = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to generate .cursor/mcp.json for Cursor";
      };
    };

    cline = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to generate .cline/mcp.json for Cline";
      };
    };

    # Input variable definitions for sensitive data (VS Code only)
    inputs = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.enum [ "promptString" ];
            default = "promptString";
            description = "Input prompt type";
          };
          id = lib.mkOption {
            type = lib.types.str;
            description = "Unique identifier referenced by \${input:variable-id}";
          };
          description = lib.mkOption {
            type = lib.types.str;
            description = "User-friendly prompt text";
          };
          password = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Hide typed input (for API keys and passwords)";
          };
        };
      });
      default = [ ];
      description = ''
        Input variable definitions for sensitive data.
        Referenced via ''${input:variable-id} in server env values (VS Code only).
      '';
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Executable command for stdio MCP server (mutually exclusive with `url`)";
          };

          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Arguments for the command";
          };

          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Environment variables for the server process";
          };

          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "URL for HTTP/SSE MCP server (mutually exclusive with `command`)";
          };

          headers = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "HTTP headers for HTTP/SSE MCP server";
          };

          # Transport type override (shared — all targets)
          transportType = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "stdio" "streamable-http" "sse" ]);
            default = null;
            description = ''
              Override transport type. Defaults to 'stdio' for command,
              'streamable-http' for url (Roo Code), or 'http' for url (VS Code).
              Required for Roo Code URL-based servers to specify streamable-http vs sse.
            '';
          };

          # Roo Code only
          alwaysAllow = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Tools to auto-approve (Roo Code only)";
          };

          # Cline only
          autoApprove = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Tools to auto-approve (Cline only)";
          };

          disabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Disable this server (Roo Code / Cline)";
          };

          disabledTools = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Tools to disable (Roo Code only)";
          };

          cwd = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Working directory for server process (Roo Code only)";
          };

          timeout = lib.mkOption {
            type = lib.types.nullOr (lib.types.ints.between 1 3600);
            default = null;
            description = "Per-server timeout in seconds, 1-3600 (Roo Code only)";
          };

          watchPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "File paths to watch for changes; triggers restart (Roo Code only)";
          };

          # VS Code / Cursor
          envFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Path to .env file (VS Code / Cursor only)";
          };

          # VS Code only
          oauth = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options.clientId = lib.mkOption {
                type = lib.types.str;
                description = "OAuth client ID for authenticating with the server (VS Code only)";
              };
            });
            default = null;
            description = "OAuth configuration for HTTP servers (VS Code only)";
          };

          sandboxEnabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Run server in sandboxed environment (VS Code only, macOS/Linux)";
          };

          sandbox = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = ''
              Sandbox filesystem/network rules (VS Code only).
              Supports filesystem.allowWrite, filesystem.denyRead, filesystem.denyWrite,
              network.allowedDomains, network.deniedDomains.
            '';
          };

          dev = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                watch = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "File glob pattern to watch for changes (VS Code dev mode)";
                };
                debug = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  default = null;
                  description = "Enable debugger attachment (VS Code dev mode)";
                };
              };
            });
            default = null;
            description = "Development mode settings (VS Code only)";
          };

          # Cursor only
          auth = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = ''
              Static OAuth credentials for remote servers (Cursor only).
              Supports CLIENT_ID, CLIENT_SECRET, scopes.
            '';
          };
        };
      });
      default = { };
      description = ''
        IDE MCP server configurations. Each server is written to
        `.roo/mcp.json`, `.vscode/mcp.json`, `.cursor/mcp.json`,
        and `.cline/mcp.json` with target-appropriate field filtering
        and key conventions.
      '';
    };
  };

  config = lib.mkMerge [
    # Mutual exclusivity assertion: command and url cannot both be set
    { assertions = serverAssertions; }

    # Roo Code — top-level key: mcpServers
    (lib.mkIf config.mcp.roo.enable {
      files.".roo/mcp.json".json = {
        mcpServers = lib.mapAttrs (name: server:
          (mkServerEntry server)
          # Inject type for URL-based servers when no explicit transportType
          // lib.optionalAttrs (server.url != null && server.url != "" && server.transportType == null) {
            type = "streamable-http";
          }
          // lib.optionalAttrs (server.alwaysAllow != [ ]) {
            alwaysAllow = server.alwaysAllow;
          }
          // lib.optionalAttrs server.disabled {
            disabled = true;
          }
          // lib.optionalAttrs (server.disabledTools != [ ]) {
            disabledTools = server.disabledTools;
          }
        ) config.mcp.servers;
      };
    })

    # VS Code — top-level key: servers, type field required
    (lib.mkIf config.mcp.vscode.enable {
      files.".vscode/mcp.json".json =
        # Top-level inputs block (only when non-empty)
        (lib.optionalAttrs (config.mcp.inputs != [ ]) {
          inputs = config.mcp.inputs;
        })
        // {
          servers = lib.mapAttrs (name: server:
            (mkServerEntry server)
            # Type injection (required by VS Code for all servers)
            // lib.optionalAttrs (server.command != null || server.url != null) {
              type =
                if server.transportType != null then
                  # Map Roo-specific type to VS Code equivalent
                  if server.transportType == "streamable-http" then "http"
                  else server.transportType
                else if server.url != null && server.url != "" then "http"
                else "stdio";
            }
            // lib.optionalAttrs (server.envFile != null) {
              envFile = server.envFile;
            }
            // lib.optionalAttrs (server.oauth != null) {
              oauth = server.oauth;
            }
            // lib.optionalAttrs server.sandboxEnabled {
              inherit (server) sandboxEnabled sandbox;
            }
            // lib.optionalAttrs (server.dev != null) (
              let filteredDev = lib.filterAttrs (n: v: v != null) server.dev;
              in lib.optionalAttrs (filteredDev != { }) { dev = filteredDev; }
            )
          ) config.mcp.servers;
        };
    })

    # Cline — top-level key: mcpServers
    (lib.mkIf config.mcp.cline.enable {
      files.".cline/mcp.json".json = {
        mcpServers = lib.mapAttrs (name: server:
          (mkServerEntry server)
          // lib.optionalAttrs server.disabled {
            disabled = true;
          }
          // lib.optionalAttrs (server.autoApprove != [ ]) {
            autoApprove = server.autoApprove;
          }
        ) config.mcp.servers;
      };
    })

    # Cursor — top-level key: mcpServers, type required for STDIO
    (lib.mkIf config.mcp.cursor.enable {
      files.".cursor/mcp.json".json = {
        mcpServers = lib.mapAttrs (name: server:
          (mkServerEntry server)
          # Type injection for command-based servers (required by Cursor docs)
          // lib.optionalAttrs (server.command != null && server.command != "") {
            type = if server.transportType != null then server.transportType else "stdio";
          }
          // lib.optionalAttrs (server.envFile != null) {
            envFile = server.envFile;
          }
          // lib.optionalAttrs (server.auth != { }) {
            auth = server.auth;
          }
        ) config.mcp.servers;
      };
    })
  ];
}
