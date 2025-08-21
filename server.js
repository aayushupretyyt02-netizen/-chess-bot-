// server.js
const express = require("express");
const cors = require("cors"); // YEH LINE SABSE ZAROORI HAI, iske na hone se error aa raha tha.
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const app = express();

// --- CORS + JSON ---
app.use(cors({ origin: true, credentials: false }));
app.use(express.json());

// --- Stockfish path resolution ---
// Path updated to point to the Linux binary we will set up in the Dockerfile.
const LOCAL_EXE = path.join(__dirname, "stockfish-linux");
const STOCKFISH_PATH = process.env.STOCKFISH_PATH
  ? process.env.STOCKFISH_PATH
  : (fs.existsSync(LOCAL_EXE) ? LOCAL_EXE : "stockfish");

console.log("Using engine at:", STOCKFISH_PATH);

// --- Helper: clamp elo to engine limits ---
function clampElo(elo) {
  const n = parseInt(elo, 10);
  if (Number.isNaN(n)) return 1400;
  return Math.max(1320, Math.min(3190, n));
}

// --- Create and prime engine ---
function createEngine(elo = 1400) {
  const engine = spawn(STOCKFISH_PATH, [], { stdio: "pipe" });

  engine.stdin.write("uci\n");
  engine.stdin.write("setoption name UCI_LimitStrength value true\n");
  engine.stdin.write(`setoption name UCI_Elo value ${clampElo(elo)}\n`);
  engine.stdin.write("isready\n");

  return engine;
}

// --- Best-move endpoint ---
app.post("/best-move", (req, res) => {
  const { fen, elo = 1400, movetime = 1000, depth = null, nodes = null } = req.body || {};

  if (!fen || typeof fen !== "string") {
    return res.status(400).json({ error: "Missing or invalid FEN" });
  }

  const engine = createEngine(elo);
  let responded = false;
  let buffer = "";
  const infoLines = [];

  const safeRespond = (status, payload) => {
    if (responded) return;
    responded = true;
    try { res.status(status).json(payload); }
    catch (_) {}
    try { engine.kill(); } catch (_) {}
  };

  // Hard timeout so request never hangs
  const killTimer = setTimeout(() => {
    safeRespond(504, { error: "Engine timeout", info: infoLines });
  }, Math.max(1500, Number(movetime) + 2500)); // movetime + cushion

  // Collect stdout lines
  engine.stdout.on("data", (chunk) => {
    buffer += chunk.toString();
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop(); // last partial line stays in buffer

    for (const line of lines) {
      if (!line.trim()) continue;
      // Debug log
      console.log("Engine:", line);
      if (line.startsWith("info")) infoLines.push(line);

      if (line.startsWith("uciok")) {
        // ready later handled by 'isready'
      }

      if (line.startsWith("readyok")) {
        // Once ready, send position + go
        engine.stdin.write(`position fen ${fen}\n`);
        if (nodes) {
          engine.stdin.write(`go nodes ${nodes}\n`);
        } else if (depth) {
          engine.stdin.write(`go depth ${depth}\n`);
        } else {
          engine.stdin.write(`go movetime ${movetime}\n`);
        }
      }

      if (line.startsWith("bestmove")) {
        // Format: "bestmove e7e6 ponder d2d4"
        const parts = line.split(/\s+/);
        const bestmove = parts[1]; // e7e6 or e7e8q etc.
        clearTimeout(killTimer);
        safeRespond(200, { bestmove, info: infoLines });
      }
    }
  });

  engine.stderr?.on("data", (e) => {
    console.error("Engine ERR:", e.toString());
  });

  engine.on("error", (err) => {
    console.error("Spawn error:", err);
    clearTimeout(killTimer);
    safeRespond(500, { error: "Failed to start Stockfish", details: String(err) });
  });

  engine.on("close", (code) => {
    if (!responded) {
      clearTimeout(killTimer);
      safeRespond(500, { error: `Engine exited unexpectedly (code ${code})`, info: infoLines });
    }
  });
});

app.get("/", (_, res) => {
  res.send("✅ Chess bot API running");
});

const PORT = process.env.PORT || 3000; // Use PORT from environment variable for Render
app.listen(PORT, () => {
  console.log(`✅ Chess bot API running on http://localhost:${PORT}`);
});

