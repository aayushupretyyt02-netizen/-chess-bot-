# Stage 1: Use a Node.js base image
FROM node:20-slim

# Set working directory
WORKDIR /usr/src/app

# Install wget and tar
RUN apt-get update && apt-get install -y --no-install-recommends wget tar && \
    rm -rf /var/lib/apt/lists/*

# Download official Stockfish Linux tar.gz (adjust version if needed)
RUN wget -q https://stockfishchess.org/files/stockfish-15.1-linux-x64-avx2.zip -O stockfish.zip && \
    apt-get install -y unzip && \
    unzip stockfish.zip && \
    chmod +x stockfish-*-linux-x64-avx2/stockfish && \
    mv stockfish-*-linux-x64-avx2/stockfish ./stockfish-linux && \
    rm -rf stockfish.zip stockfish-*-linux-x64-avx2

# Copy package.json and package-lock.json
COPY package*.json ./

# Install Node dependencies
RUN npm install

# Copy rest of app
COPY . .

# Expose port
EXPOSE 3000

# Run server
CMD ["node", "server.js"]
