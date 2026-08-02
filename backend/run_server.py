"""Launcher script for FastAPI backend on Windows with socketpair patch."""
import sys
import socket
import asyncio

# Monkey-patch socket.socketpair to use explicit port binding (bypassing WinError 10013 port 0 error on Windows)
def _patched_socketpair(family=socket.AF_INET, type=socket.SOCK_STREAM, proto=0):
    for port in range(54321, 54400):
        try:
            lsock = socket.socket(family, type, proto)
            lsock.bind(('127.0.0.1', port))
            lsock.listen(1)
            csock = socket.socket(family, type, proto)
            csock.connect(('127.0.0.1', port))
            ssock, _ = lsock.accept()
            lsock.close()
            return ssock, csock
        except Exception:
            try:
                lsock.close()
            except Exception:
                pass
    raise OSError("Could not bind socketpair on Windows")

socket.socketpair = _patched_socketpair

if sys.platform == "win32":
    try:
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    except Exception:
        pass

import uvicorn

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, loop="asyncio")
