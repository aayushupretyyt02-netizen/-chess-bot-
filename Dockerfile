# Stage 1: Use Node.js slim image
FROM node:20-slim

# Set working directory
WORKDIR /usr/src/app

# Install required packages: curl, tar
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tar && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish, extract, move, and set executable permission
RUN curl -L -o stockfish.tar "https://github.com/official-stockfish/Stockfish/releases/latest/download/stockfish-ubuntu-x86-64-avx2.tar" && \
    tar -xf stockfish.tar && \
    mv stockfish-*-linux-x86-64-avx2/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*-linux-x86-64-avx2

# Copy package.json and package-lock.json first for caching
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Expose the port your app will run on
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
