FROM node:20-slim

WORKDIR /usr/src/app

# Install wget
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish from Mediafire, ignore certificate, and set executable
RUN wget --no-check-certificate "https://download1509.mediafire.com/d0w6s1etxrsgLI3J9FrCPiJrCaCCdFfS9KwuviwXPQaBR9Ax0itdU8G87dBllmb0vhlo-ni9OsxIGpiqfTmUoj3YlcjG1Kskodf-TKPPicAYGPOlXz8IrjUyOfRet9khO7wy35U5k1NhTZZP8J1PgHmHK4X33plL_5Ra3Km8K4qneg/yatywf3vxch7b87/stockfish-ubuntu-x86-64-avx2" -O stockfish-linux && \
    chmod +x stockfish-linux

# Copy Node.js dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# Use Render port
ENV PORT 10000
EXPOSE 10000

# Run server
CMD ["node", "server.js"]
