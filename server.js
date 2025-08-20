const express = require("express");
const { spawn } = require("child_process");
const app = express();
app.use(express.json());

app.use((req, res, next) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    next();
});

// routes yahan define karo
app.post("/best-move", (req, res) => {
    const { fen, movetime } = req.body;
    const engine = spawn("./stockfish-linux");
    engine.stdin.write(`position fen ${fen}\n`);
    engine.stdin.write(`go movetime ${movetime || 1000}\n`);
    engine.stdout.on("data", (data) => {
        const match = data.toString().match(/bestmove\s([a-h][1-8][a-h][1-8][qrbn]?)/);
        if (match) {
            res.json({ bestmove: match[1] });
            engine.kill();
        }
    });
});

app.listen(process.env.PORT || 3000, () => console.log("Server running"));


// --- CORS + JSON ---
app.use(cors({ origin: true, credentials: false }));
app.use(express.json());

// --- Stockfish path resolution ---
const LOCAL_EXE = path.join(__dirname, "stockfish-linux");
const STOCKFISH_PATH = fs.existsSync(LOCAL_EXE) ? LOCAL_EXE : "stockfish";

console.log("Using engine at:", STOCKFISH_PATH);

// --- Validate Stockfish binary ---
try {
  const version = execSync(`${STOCKFISH_PATH} -v`).toString();
  console.log("Stockfish version:", version.trim());
} catch (err) {
  console.error("Stockfish binary is invalid or not executable!", err);
  process.exit(1); // Stop server to avoid repeated 500 errors
}

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
    try { res.status(status).json(payload); } catch (_) {}
    try { engine.kill(); } catch (_) {}
  };

  const killTimer = setTimeout(() => {
    safeRespond(504, { error: "Engine timeout", info: infoLines });
  }, Math.max(1500, Number(movetime) + 2500));

  engine.stdout.on("data", (chunk) => {
    buffer += chunk.toString();
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop();

    for (const line of lines) {
      if (!line.trim()) continue;
      console.log("Engine:", line);
      if (line.startsWith("info")) infoLines.push(line);

      if (line.startsWith("readyok")) {
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

// --- Health check endpoint ---
app.get("/", (_, res) => {
  res.send("✅ Chess bot API running");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Chess bot API running on http://localhost:${PORT}`);
});



