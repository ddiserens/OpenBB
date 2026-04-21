# ---- Base Python ----
FROM python:3.11-slim-bullseye AS base

WORKDIR /openbb

# Fix legacy ENV format
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Update pip and install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    openssh-client \
    curl \
    && pip install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---- Build Stage ----
FROM base AS builder

WORKDIR /openbb

# Install Rust for some of the wheel builds (like cryptography or specific providers)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install OpenBB and MCP directly from PyPI for stability
# This bypasses the local version mismatch you encountered
RUN pip install --no-cache-dir "openbb[all]" "openbb-mcp" "openbb-devtools"

# ---- Final Production Stage ----
FROM base

# Copy only the installed site-packages
COPY --from=builder /usr/local /usr/local

# Create a config directory for your API keys
RUN mkdir -p /root/.openbb_platform

EXPOSE 8000

# Default to REST API, but can be overridden in Talos/K8s to run MCP
CMD ["uvicorn", "openbb_core.api.rest_api:app", "--host", "0.0.0.0", "--port", "8000"]
