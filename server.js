// server.js
const express = require("express");
const cors = require("cors");
const { spawn, spawnSync } = require("child_process");
const path = require("path");
const fs = require("fs");

// --- New Detailed Debugging: List files with permissions ---
try {
  const ls = spawnSync("ls", ["-la", __dirname]);
  console.log(`Directory listing with permissions:\n${ls.stdout.toString()}`);
} catch (e) {
  console.error("Could not run ls command:", e);
}
// -----------------------------------------------------------

const app = express();

// --- CORS + JSON ---
app.use(cors({ origin: true, credentials: false }));
app.use(express.json());

// --- Stockfish path resolution (Simplified and Forced) ---
// We will now FORCE the app to use the local path.
// This will give us a better error if spawning fails.
const STOCKFISH_PATH = path.join(__dirname, "stockfish-linux");
console.log("Forcing use of engine at:", STOCKFISH_PATH);

// --- Helper: clamp elo to engine limits ---
function clampElo(elo) {
  const n = parseInt(elo, 10);
  if (Number.isNaN(n)) return 1400;
  return Math.max(1320, Math.min(3190, n));
}

// --- Create and prime engine ---
function createEngine(elo = 1400) {
  const engine = spawn(STOCKFISH_PATH, [], { stdio: "pipe" });

  engine.on("error", (err) => {
    // This is now the most important error log
    console.error("Failed to start Stockfish process. Spawn error:", err);
  });

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
        const parts = line.split(/\s+/);
        const bestmove = parts[1];
        clearTimeout(killTimer);
        safeRespond(200, { bestmove, info: infoLines });
      }
    }
  });

  engine.stderr?.on("data", (e) => {
    console.error("Engine STDERR:", e.toString());
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Chess bot API running on http://localhost:${PORT}`);
});
