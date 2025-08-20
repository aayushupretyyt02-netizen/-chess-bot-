# Use Node.js slim image
FROM node:20-slim

WORKDIR /usr/src/app

# Install required packages: curl, tar, xz-utils, bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tar xz-utils bash && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Stockfish from Google Drive
RUN curl -c /tmp/cookies "https://drive.google.com/uc?export=download&id=1TKTUccmC1ubinn4X9UBScv2pEjFlNhL1" > /dev/null && \
    curl -Lb /tmp/cookies "https://drive.google.com/uc?export=download&confirm=$(awk '/download/ {print $NF}' /tmp/cookies)&id=1TKTUccmC1ubinn4X9UBScv2pEjFlNhL1" -o stockfish.tar && \
    tar -xJf stockfish.tar && \
    mv stockfish-*/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*/ /tmp/cookies

# Copy package.json files and install Node dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port
EXPOSE 3000

# Start server
CMD ["node", "server.js"]
