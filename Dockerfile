# Stage 1: Use a Node.js base image
FROM node:20-slim

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install necessary packages to download and unzip Stockfish
RUN apt-get update && apt-get install -y --no-install-recommends wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Download, extract, and set up Stockfish using the OFFICIAL, PERMANENT link
RUN wget https://stockfishchess.org/files/stockfish-ubuntu-x86-64-avx2.zip -O stockfish.zip && \
    unzip stockfish.zip && \
    mv stockfish/stockfish-ubuntu-x86-64-avx2 ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.zip stockfish

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of your application code into the container
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Command to run your application
CMD ["node", "server.js"]
