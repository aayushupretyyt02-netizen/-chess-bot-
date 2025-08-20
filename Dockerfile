# Stage 1: Use a Node.js base image
FROM node:20-slim

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install wget to download Stockfish
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

#
# WARNING: The Mediafire link below is temporary and will likely expire,
# which can cause future builds to fail. The official, stable link is recommended.
#
RUN wget "https://download1509.mediafire.com/7jd9jywh44sgn6_f8wTv53NJPEj2MkH4358MlX0RiP_SgSTSY07h90qJSPW5L_iGZ0oSLUmvAIwtlZSURcs9IrSO0JcxNB7I1PCJgwpzMpWSKmI9FoC0liqoWUyAryUMF1m47Dgb6PrHJkYWPtaFK1OKwEpxdD_DLNLJ1RpEKBXzSg/yatywf3vxch7b87/stockfish-ubuntu-x86-64-avx2" -O stockfish-linux && \
    # Make the downloaded binary executable
    chmod +x ./stockfish-linux

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