# mcpport

mcpport — A lightweight gateway &amp; registry for Model Context Protocol (MCP), enabling standardized connectivity for AI applications.

## Quick Start

1. Start your MCP Gateway

```bash
uvx mcpport gateway
```

It will start the gateway on port 8765 by default. And the common access points are:

- `ws://localhost:8765/mcp/register` is the registration endpoint.
- `http://localhost:8765/sse` is the event stream endpoint(`SSE`).
- `http://localhost:8765/messages` is the message endpoint(`HTTP`).

2. Register your MCP Server to the Gateway

```bash
uvx mcpport register \
--stdio "npx -y @modelcontextprotocol/server-filesystem ./" \
--gateway-url="ws://localhost:8765/mcp/register" \
--server-name "file"
```

It will register a MCP server named `file` to the gateway. The server is a simple file system server, which is implemented by `@modelcontextprotocol/server-filesystem`.


## Advanced Usage

1. Start Your MCP Gateway With `ipv6` Support

```bash
uvx mcpport gateway --host "::" --ipv6
```

Other options are also available, you can use `uvx mcpport gateway --help` to get more information.

There are some options for the gateway:

- `--host` is the host of the gateway.
- `--port` is the port of the gateway, default is `8765`.
- `--ipv6` is to enable `ipv6` support, default is `false`.
- `--log-level` is the log level of the gateway, default is `INFO`.
- `--timeout-rpc` is the timeout of communication with the MCP server, default is `10s`.
- `--timeout-run-tool` is the timeout to run the tool, default is `120s`.
- `--sse-path` is the path of the event stream endpoint, default is `/sse`.
- `--messages-path` is the path of the message endpoint, default is `/messages`.
