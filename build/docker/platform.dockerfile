# ---- Base Python ----
FROM python:3.11-slim-bullseye AS base

WORKDIR /openbb
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential openssh-client curl git \
    && pip install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---- Build Stage ----
FROM base AS builder
WORKDIR /openbb

# Install Rust (needed for some provider dependencies)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy the forked repo files
COPY . .

# 1. Install the core Platform first
RUN pip install ./openbb_platform[all]

# 2. Install the MCP server from the local extensions directory
# Adjust this path if your fork structure differs slightly
RUN pip install ./openbb_platform/extensions/mcp

RUN pip install openbb-devtools

# ---- Final Production Stage ----
FROM base
COPY --from=builder /usr/local /usr/local
WORKDIR /openbb

# Copy necessary config files from your repo
COPY --from=builder /openbb/openbb_platform /openbb/openbb_platform

EXPOSE 8000

# To run the MCP server alongside the API, we use the entry point provided by the extension
# In your Talos/K8s manifest, you can override this CMD for the MCP container
CMD ["uvicorn", "openbb_core.api.rest_api:app", "--host", "0.0.0.0", "--port", "8000"]
