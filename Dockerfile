FROM node:20-slim
WORKDIR /usr/src/app

# Install bash (required for server scripts)
RUN apt-get update && apt-get install -y --no-install-recommends bash && rm -rf /var/lib/apt/lists/*

# Copy Stockfish binary from your Drive download folder
# (maan ke chalo tumne local folder me download karke rakha hai)
COPY stockfish-ubuntu-x86-64-avx2/stockfish ./stockfish-linux
RUN chmod +x ./stockfish-linux

# Copy Node.js dependencies and install
COPY package*.json ./
RUN npm install

# Copy the rest of your app
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
