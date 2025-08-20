FROM node:20-slim

WORKDIR /usr/src/app

# Install wget
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish from Mediafire, ignore certificate, and set executable
RUN wget --no-check-certificate "https://download1509.mediafire.com/39emeh0ivbxgG--9pit8z4b1vUCAMMJD74vBJoi3HlDwWObtsONOKohCK9XlWpc7YWW_aDdM5tjviU8cmiwoP71lHJ7_YSniwMBvUQiOCgwT8yFyn7MGXLnknVpmdBRXnHVCDT2xuQ6m91YhSe7WipDVdksNJRk82PTMmyRbXUWfTw/yatywf3vxch7b87/stockfish-ubuntu-x86-64-avx2" -O stockfish-linux && \
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

