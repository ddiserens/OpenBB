# ---- Base Python ----
FROM python:3.11-slim-bullseye AS base

WORKDIR /openbb
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies & upgrade pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential openssh-client curl git \
    && pip install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---- Build Stage ----
FROM base AS builder
WORKDIR /openbb

# Install Rust for dependency compilation (required for v4.7.0)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy your forked v4.7.0 repository
COPY . .

# 1. Install the core Platform (Avoid [all] to bypass the CFTC version bug)
RUN pip install ./openbb_platform

# 2. Install stable providers manually
# Note: Polygon was removed in v4.7.0, so we use yfinance/fmp for options
RUN pip install \
    openbb-yfinance \
    openbb-benzinga \
    openbb-fmp \
    openbb-fred \
    openbb-sec

# 3. Install the MCP Server component from source
RUN pip install ./openbb_platform/extensions/mcp

# 4. CRITICAL: Rebuild static assets
# This prevents the "ImportError: cannot import name OBBject_*" error
RUN openbb-build

# ---- Final Production Stage ----
FROM base
COPY --from=builder /usr/local /usr/local
WORKDIR /openbb

# Copy necessary files from builder
COPY --from=builder /openbb/openbb_platform /openbb/openbb_platform

EXPOSE 8000
EXPOSE 8080

# Default to REST API
CMD ["uvicorn", "openbb_core.api.rest_api:app", "--host", "0.0.0.0", "--port", "8000"]
