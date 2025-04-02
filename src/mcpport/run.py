import argparse
import asyncio

from mcpport.gateway import MCPGateway
from mcpport.types import ServerSettings, StdioToWsArgs
from mcpport.utils import setup_logger


def setup_server_parser(parser):
    """Set up gateway command arguments."""
    # Server configuration
    parser.add_argument(
        "--host",
        type=str,
        default="0.0.0.0",
        help="Host address to bind (default: '0.0.0.0'), You can set '::' for both IPv6"
        " and IPv4",
    )
    parser.add_argument(
        "--port", type=int, default=8765, help="Port to bind (default: 8765)"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        default=True,
        help="Enable debug mode (default: True)",
    )
    parser.add_argument(
        "--log-level",
        type=str,
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Logging level (default: INFO)",
    )

    parser.add_argument(
        "--ipv6",
        action="store_true",
        default=True,
        help="Enable dual-stack IPv6/IPv4 support (default: True)",
    )

    parser.add_argument(
        "--timeout-rpc",
        type=int,
        default=10,
        help="Timeout for RPC calls in seconds (default: 10)",
    )
    parser.add_argument(
        "--timeout-run-tool",
        type=int,
        default=120,
        help="Timeout for tool execution in seconds (default: 120)",
    )

    # Path configuration
    parser.add_argument(
        "--sse-path", type=str, default="/sse", help="SSE endpoint path (default: /sse)"
    )
    parser.add_argument(
        "--message-path",
        type=str,
        default="/messages/",
        help="Message endpoint path (default: /messages/)",
    )


def setup_client_parser(parser):
    """Set up register command arguments."""
    parser.add_argument("--stdio", required=True, help="Subprocess command to start")
    parser.add_argument(
        "--gateway-url", required=True, help="Gateway URL to connect to"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=0,
        help="Local HTTP port, 0 means don't start local server",
    )
    parser.add_argument("--message-path", default="/ws", help="Local WebSocket path")
    parser.add_argument("--enable-cors", action="store_true", help="Enable CORS")
    parser.add_argument(
        "--health-endpoint", action="append", default=[], help="Health check endpoint"
    )
    parser.add_argument(
        "--server-name", default="local", help="Server name for registration"
    )
    parser.add_argument("--server-id", help="Server ID for registration (optional)")
    parser.add_argument(
        "--require-gateway",
        action="store_true",
        default=True,
        help="Exit if unable to connect to gateway",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Logging level",
    )


def run_server(args):
    """Run MCP gateway server (gateway command)."""
    # Create server settings from arguments
    settings = ServerSettings(
        host=args.host,
        port=args.port,
        debug=args.debug,
        log_level=args.log_level,
        sse_path=args.sse_path,
        message_path=args.message_path,
        ipv6=args.ipv6,
        timeout_rpc=args.timeout_rpc,
        timeout_run_tool=args.timeout_run_tool,
    )

    # Setup logging
    setup_logger(settings.log_level)

    # Create the MCP gateway
    gateway = MCPGateway(
        gateway_host=settings.host, gateway_port=settings.port, settings=settings
    )

    # Start the server (supports both SSE and WebSocket)
    asyncio.run(gateway.run_server())


def run_client(args):
    """Run MCP stdio-to-ws client (register command)."""
    from mcpport.client import main as client_main

    setup_logger(level=args.log_level)

    # Create arguments object
    ws_args = StdioToWsArgs(
        stdio_cmd=args.stdio,
        gateway_url=args.gateway_url,
        port=args.port,
        message_path=args.message_path,
        enable_cors=args.enable_cors,
        health_endpoints=args.health_endpoint,
        server_name=args.server_name,
        server_id=args.server_id,
        require_gateway=args.require_gateway,
    )
    client_main(ws_args)


def main():
    """Main entry point with subcommands for gateway and register."""
    parser = argparse.ArgumentParser(description="MCP Gateway Tool")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Create gateway subcommand (former server)
    gateway_parser = subparsers.add_parser(
        "gateway", aliases=["g"], help="Run MCP gateway server"
    )
    setup_server_parser(gateway_parser)
    gateway_parser.set_defaults(func=run_server)

    # Create register subcommand (former client)
    register_parser = subparsers.add_parser(
        "register", aliases=["r"], help="Run MCP stdio-to-ws client for registration"
    )
    setup_client_parser(register_parser)
    register_parser.set_defaults(func=run_client)

    # Parse arguments and run appropriate function
    args = parser.parse_args()

    if not hasattr(args, "func"):
        parser.print_help()
        return

    args.func(args)


if __name__ == "__main__":
    main()
