FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    OPENBB_USER_DATA_DIRECTORY=/root/OpenBBUserData

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install OpenBB Platform + MCP Extension
RUN pip install --no-cache-dir "openbb[all]" mcp

# This command starts the MCP server using the SSE (Server-Sent Events) transport
# which is better for remote/containerized use than standard input/output.
EXPOSE 8000
CMD ["python", "-m", "openbb_platform.mcp.server", "--host", "0.0.0.0", "--port", "8000"]
