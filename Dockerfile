FROM node:22-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl python3 python3-pip openssh-client ca-certificates default-mysql-client ffmpeg \
    python3-cffi python3-brotli libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz0b libffi-dev libgdk-pixbuf2.0-0 libcairo2 && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install --no-cache-dir --break-system-packages openpyxl weasyprint && \
    npm install -g openclaw@latest

WORKDIR /app

EXPOSE 18790
