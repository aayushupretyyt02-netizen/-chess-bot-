# Install curl and tar
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tar && \
    rm -rf /var/lib/apt/lists/*

# Download Stockfish and extract
RUN curl -L -o stockfish.tar "https://github.com/official-stockfish/Stockfish/releases/latest/download/stockfish-ubuntu-x86-64-avx2.tar" && \
    tar -xf stockfish.tar && \
    mv stockfish-*-linux-x86-64-avx2/stockfish ./stockfish-linux && \
    chmod +x ./stockfish-linux && \
    rm -rf stockfish.tar stockfish-*-linux-x86-64-avx2
