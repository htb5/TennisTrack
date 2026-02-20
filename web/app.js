const video = document.getElementById("camera");
const overlay = document.getElementById("overlay");
const statusChip = document.getElementById("statusChip");
const startBtn = document.getElementById("startBtn");
const replayBtn = document.getElementById("replayBtn");
const replayModal = document.getElementById("replayModal");
const replayCanvas = document.getElementById("replayCanvas");
const closeReplayBtn = document.getElementById("closeReplayBtn");

const overlayCtx = overlay.getContext("2d");
const replayCtx = replayCanvas.getContext("2d");
const processingCanvas = document.createElement("canvas");
const processingCtx = processingCanvas.getContext("2d", { willReadFrequently: true });

const state = {
  running: false,
  stream: null,
  rafId: null,
  history: [],
  replayFrames: [],
  lastReplayFrameTime: 0,
  lastBounceTime: -Infinity,
  lastOutAlertTime: -Infinity
};

const SETTINGS = {
  processWidth: 360,
  processHeight: 640,
  minMatches: 20,
  sampleStep: 2,
  replayBufferMs: 8000,
  replayWindowMs: 5000,
  minBounceIntervalMs: 350,
  minOutAlertIntervalMs: 800
};

const COURT_POLYGON = [
  { x: 0.16, y: 0.2 },
  { x: 0.84, y: 0.2 },
  { x: 0.92, y: 0.88 },
  { x: 0.08, y: 0.88 }
];

startBtn.addEventListener("click", async () => {
  if (state.running) {
    stopCamera();
    return;
  }
  await startCamera();
});

replayBtn.addEventListener("click", () => {
  playReplay();
});

closeReplayBtn.addEventListener("click", () => replayModal.close());

window.addEventListener("resize", resizeCanvas);
document.addEventListener("visibilitychange", () => {
  if (document.hidden && state.running) {
    stopCamera();
  }
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}

async function startCamera() {
  try {
    state.stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: "environment" },
        width: { ideal: 1280 },
        height: { ideal: 720 }
      },
      audio: false
    });

    video.srcObject = state.stream;
    await video.play();

    processingCanvas.width = SETTINGS.processWidth;
    processingCanvas.height = SETTINGS.processHeight;
    resizeCanvas();

    state.running = true;
    startBtn.textContent = "Stop Camera";
    setStatus("Searching", "searching");
    requestNotificationPermission();
    loop();
  } catch (error) {
    alert("Could not access camera. Check Safari camera permission.");
  }
}

function stopCamera() {
  state.running = false;
  startBtn.textContent = "Start Camera";
  if (state.rafId) {
    cancelAnimationFrame(state.rafId);
    state.rafId = null;
  }
  if (state.stream) {
    state.stream.getTracks().forEach((track) => track.stop());
    state.stream = null;
  }
  video.srcObject = null;
}

function resizeCanvas() {
  const rect = overlay.getBoundingClientRect();
  overlay.width = Math.max(1, Math.floor(rect.width));
  overlay.height = Math.max(1, Math.floor(rect.height));
}

function loop() {
  if (!state.running) {
    return;
  }

  processingCtx.drawImage(video, 0, 0, processingCanvas.width, processingCanvas.height);
  const imageData = processingCtx.getImageData(0, 0, processingCanvas.width, processingCanvas.height);
  const now = performance.now();

  maybeStoreReplayFrame(imageData, now);

  const detection = detectBall(imageData, processingCanvas.width, processingCanvas.height);
  drawOverlay(detection);

  if (detection) {
    state.history.push({ x: detection.x, y: detection.y, t: now });
    if (state.history.length > 8) {
      state.history.shift();
    }

    const bounce = detectBounce(state.history);
    if (bounce) {
      const inBounds = pointInPolygon(bounce, COURT_POLYGON);
      if (inBounds) {
        setStatus("IN", "in");
      } else {
        setStatus("OUT", "out");
        triggerOutAlert(now);
      }
    }
  }

  state.rafId = requestAnimationFrame(loop);
}

function maybeStoreReplayFrame(imageData, now) {
  if (now - state.lastReplayFrameTime < 66) {
    return;
  }
  state.lastReplayFrameTime = now;
  state.replayFrames.push({
    t: now,
    imageData: new ImageData(
      new Uint8ClampedArray(imageData.data),
      imageData.width,
      imageData.height
    )
  });

  const cutoff = now - SETTINGS.replayBufferMs;
  while (state.replayFrames.length && state.replayFrames[0].t < cutoff) {
    state.replayFrames.shift();
  }
}

function drawOverlay(detection) {
  const w = overlay.width;
  const h = overlay.height;
  overlayCtx.clearRect(0, 0, w, h);

  overlayCtx.strokeStyle = "rgba(255,255,255,0.9)";
  overlayCtx.lineWidth = 2;
  overlayCtx.beginPath();
  COURT_POLYGON.forEach((point, idx) => {
    const x = point.x * w;
    const y = point.y * h;
    if (idx === 0) {
      overlayCtx.moveTo(x, y);
    } else {
      overlayCtx.lineTo(x, y);
    }
  });
  overlayCtx.closePath();
  overlayCtx.stroke();

  if (!detection) {
    return;
  }

  const bx = detection.x * w;
  const by = detection.y * h;
  overlayCtx.strokeStyle = "#f8f35b";
  overlayCtx.lineWidth = 3;
  overlayCtx.beginPath();
  overlayCtx.arc(bx, by, 13, 0, Math.PI * 2);
  overlayCtx.stroke();
}

function detectBall(imageData, width, height) {
  const data = imageData.data;
  const step = SETTINGS.sampleStep;
  let matched = 0;
  let sumX = 0;
  let sumY = 0;
  let minX = width;
  let minY = height;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < height; y += step) {
    for (let x = 0; x < width; x += step) {
      const i = (y * width + x) * 4;
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];

      if (!isBallLikeColor(r, g, b)) {
        continue;
      }
      matched += 1;
      sumX += x;
      sumY += y;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }

  if (matched < SETTINGS.minMatches) {
    return null;
  }

  const boxWidth = Math.max(1, maxX - minX);
  const boxHeight = Math.max(1, maxY - minY);
  const area = Math.max(1, boxWidth * boxHeight);
  const effectiveMatches = matched * step * step;
  const fillRatio = effectiveMatches / area;

  if (fillRatio < 0.12 || fillRatio > 0.9) {
    return null;
  }

  return {
    x: (sumX / matched) / width,
    y: (sumY / matched) / height
  };
}

function isBallLikeColor(r, g, b) {
  const bright = r > 110 && g > 110;
  const greenYellowBand = b < 150 && Math.abs(r - g) < 55;
  const highContrast = (r + g) - b > 170;
  return bright && greenYellowBand && highContrast;
}

function detectBounce(history) {
  if (history.length < 3) {
    return null;
  }

  const a = history[history.length - 3];
  const b = history[history.length - 2];
  const c = history[history.length - 1];

  const dt1 = Math.max(1, b.t - a.t);
  const dt2 = Math.max(1, c.t - b.t);
  const v1 = (b.y - a.y) / dt1;
  const v2 = (c.y - b.y) / dt2;
  const rebound = Math.abs(c.y - b.y);

  if (v1 <= 0.0013) {
    return null;
  }
  if (v2 >= -0.0013) {
    return null;
  }
  if (rebound < 0.008) {
    return null;
  }
  if (b.t - state.lastBounceTime < SETTINGS.minBounceIntervalMs) {
    return null;
  }

  state.lastBounceTime = b.t;
  return b;
}

function pointInPolygon(point, polygon) {
  let inside = false;
  let j = polygon.length - 1;

  for (let i = 0; i < polygon.length; i += 1) {
    const pi = polygon[i];
    const pj = polygon[j];
    const intersect =
      ((pi.y > point.y) !== (pj.y > point.y)) &&
      point.x < ((pj.x - pi.x) * (point.y - pi.y)) / ((pj.y - pi.y) + 1e-6) + pi.x;
    if (intersect) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

function setStatus(text, stateClass) {
  statusChip.textContent = text;
  statusChip.classList.remove("searching", "in", "out");
  statusChip.classList.add(stateClass);
}

function triggerOutAlert(now) {
  if (now - state.lastOutAlertTime < SETTINGS.minOutAlertIntervalMs) {
    return;
  }
  state.lastOutAlertTime = now;

  if ("vibrate" in navigator) {
    navigator.vibrate([90, 60, 90]);
  }
  playBeep();
  notifyOut();
}

function playBeep() {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  if (!AudioContextClass) {
    return;
  }
  const ctx = new AudioContextClass();
  const oscillator = ctx.createOscillator();
  const gain = ctx.createGain();
  oscillator.type = "square";
  oscillator.frequency.value = 950;
  gain.gain.value = 0.045;
  oscillator.connect(gain);
  gain.connect(ctx.destination);
  oscillator.start();
  oscillator.stop(ctx.currentTime + 0.12);
  oscillator.onended = () => ctx.close();
}

function requestNotificationPermission() {
  if (!("Notification" in window)) {
    return;
  }
  if (Notification.permission === "default") {
    Notification.requestPermission().catch(() => {});
  }
}

function notifyOut() {
  if (!("Notification" in window)) {
    return;
  }
  if (Notification.permission !== "granted") {
    return;
  }
  new Notification("OUT", { body: "Ball landed out of bounds." });
}

async function playReplay() {
  const now = performance.now();
  const frames = state.replayFrames.filter((frame) => frame.t >= now - SETTINGS.replayWindowMs);

  if (!frames.length) {
    alert("No replay captured yet.");
    return;
  }

  replayCanvas.width = frames[0].imageData.width;
  replayCanvas.height = frames[0].imageData.height;
  replayModal.showModal();

  for (let i = 0; i < frames.length; i += 1) {
    if (!replayModal.open) {
      break;
    }
    replayCtx.putImageData(frames[i].imageData, 0, 0);
    await sleep(66);
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

