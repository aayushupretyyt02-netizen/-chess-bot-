# Stage 1: Use a Node.js base image
FROM node:20-slim

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install wget to download Stockfish
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish and set the correct permissions (chmod 755)
RUN wget --no-check-certificate "https://download1509.mediafire.com/d0w6s1etxrsgLI3J9FrCPiJrCaCCdFfS9KwuviwXPQaBR9Ax0itdU8G87dBllmb0vhlo-ni9OsxIGpiqfTmUoj3YlcjG1Kskodf-TKPPicAYGPOlXz8IrjUyOfRet9khO7wy35U5k1NhTZZP8J1PgHmHK4X33plL_5Ra3Km8K4qneg/yatywf3vxch7b87/stockfish-ubuntu-x86-64-avx2" -O stockfish-linux && \
    chmod 755 ./stockfish-linux

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
