# Stage 1: Use Node.js slim image
FROM node:20-slim

WORKDIR /usr/src/app

# Install required packages for downloading and extracting Stockfish
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish from GitHub and extract
RUN curl -L -o stockfish.tar "https://github.com/official-stockfish/Stockfish/releases/latest/download/stockfish-ubuntu-x86-64-avx2.tar" && \
    tar -xJf stockfish.tar && \
    mv stockfish-*/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*/

# Copy package.json files and install Node dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port
EXPOSE 3000

# Run the server
CMD ["node", "server.js"]
