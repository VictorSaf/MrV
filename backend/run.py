#!/usr/bin/env python3
"""
Development server runner for Rpd Ganis GIU Backend
"""
import socket
import sys
import uvicorn


def is_port_available(port: int, host: str = "0.0.0.0") -> bool:
    """Check if a port is available for binding."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            sock.bind((host, port))
            return True
    except OSError:
        return False


def find_available_port(start_port: int, host: str = "0.0.0.0", max_attempts: int = 10) -> int:
    """Find the next available port starting from start_port."""
    for port in range(start_port, start_port + max_attempts):
        if is_port_available(port, host):
            return port
    raise RuntimeError(
        f"Could not find an available port in range {start_port}-{start_port + max_attempts - 1}"
    )


if __name__ == "__main__":
    host = "0.0.0.0"
    preferred_port = 8000

    # Check if preferred port is available
    if is_port_available(preferred_port, host):
        port = preferred_port
        print(f"✓ Starting server on {host}:{port}")
    else:
        # Find next available port
        try:
            port = find_available_port(preferred_port + 1, host)
            print(f"⚠ Port {preferred_port} is in use")
            print(f"✓ Starting server on {host}:{port} instead")
        except RuntimeError as e:
            print(f"✗ Error: {e}", file=sys.stderr)
            sys.exit(1)

    uvicorn.run(
        "src.api.main:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )
