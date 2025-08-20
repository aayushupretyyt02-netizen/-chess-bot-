FROM node:20-slim
WORKDIR /usr/src/app

# Install necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Download Stockfish binary from Google Drive
RUN curl -c /tmp/cookies "https://drive.google.com/uc?export=download&id=1TKTUccmC1ubinn4X9UBScv2pEjFlNhL1" > /dev/null && \
    curl -Lb /tmp/cookies "https://drive.google.com/uc?export=download&confirm=$(awk '/download/ {print $NF}' /tmp/cookies)id=1TKTUccmC1ubinn4X9UBScv2pEjFlNhL1" -o stockfish.tar && \
    tar -xvf stockfish.tar && \
    mv stockfish-*/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*/ /tmp/cookies

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
