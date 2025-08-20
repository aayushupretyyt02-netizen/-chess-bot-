res.setHeader("Access-Control-Allow-Origin", "*");
res.setHeader("Access-Control-Allow-Methods", "POST");
res.setHeader("Access-Control-Allow-Headers", "Content-Type");

# Use Node.js official slim image
FROM node:20-slim

# Set working directory
WORKDIR /usr/src/app

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download Stockfish directly (executable, no tar)
RUN curl -L -o stockfish-linux "https://drive.google.com/uc?export=download&id=1TKTUccmC1ubinn4X9UBScv2pEjFlNhL1" \
    && chmod +x stockfish-linux

# Copy your app files
COPY package*.json ./
COPY . .

# Install Node dependencies
RUN npm install

# Expose the port your app runs on (change if needed)
EXPOSE 3000

# Start your app
CMD ["node", "server.js"]

