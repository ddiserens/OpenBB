# Use a slim Python image as a base
FROM python:3.10-slim-bookworm

# Set the working directory
WORKDIR /app

# Install system dependencies (wget for downloading gotty)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Install the OpenBB package, which includes the interactive CLI
RUN pip install openbb-cli

# Download and install gotty, a tool to share terminals as a web app
RUN wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz && \
    tar -xzf gotty_linux_amd64.tar.gz && \
    mv gotty /usr/local/bin/ && \
    rm gotty_linux_amd64.tar.gz

# Expose the default port for gotty
EXPOSE 8080

# The command to run when the container starts:
# gotty will launch the 'openbb terminal' command and serve it over HTTP.
CMD ["gotty", "openbb"]
    
