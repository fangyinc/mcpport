from dataclasses import dataclass
from typing import List, Optional


class StdioToWsArgs:
    """Data class for command line arguments"""

    def __init__(
        self,
        stdio_cmd: str,
        gateway_url: str,
        port: int = 0,  # 0 means don't start local WebSocket server
        message_path: str = "/ws",
        enable_cors: bool = False,
        health_endpoints: List[str] = None,
        server_name: str = "mcp-stdio-gateway",
        server_id: Optional[str] = None,
        require_gateway: bool = True,
    ):
        self.stdio_cmd = stdio_cmd
        self.port = port
        self.message_path = message_path
        self.enable_cors = enable_cors
        self.health_endpoints = health_endpoints or []
        self.gateway_url = gateway_url
        self.server_name = server_name
        self.server_id = server_id
        self.require_gateway = require_gateway


@dataclass
class ServerSettings:
    host: str
    port: int
    debug: bool
    log_level: str
    sse_path: str
    message_path: str
    ipv6: bool = False  # Added IPv6 support flag
    timeout_rpc: int = 10
    timeout_run_tool: int = 120
