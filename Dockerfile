# Use Node.js slim image
FROM node:20-slim

WORKDIR /usr/src/app

# Install required packages: curl, tar, xz-utils
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tar xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish, extract, move, and make executable
RUN curl -L -o stockfish.tar "https://github.com/official-stockfish/Stockfish/releases/latest/download/stockfish-ubuntu-x86-64-avx2.tar" && \
    tar -xf stockfish.tar && \
    mv stockfish-*/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*/

# Copy package.json and package-lock.json
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Expose the port
EXPOSE 3000

# Start server
CMD ["node", "server.js"]
