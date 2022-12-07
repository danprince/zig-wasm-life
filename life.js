export {};

let canvas = document.createElement("canvas");
let ctx = canvas.getContext("2d");
let imports = { env: { render, debug } };
let wasm = await WebAssembly.instantiateStreaming(fetch("life.wasm"), imports);
let clock = 0;
let time = 0;
let scale = 5;

function init() {
  let cols = window.innerWidth / scale;
  let rows = window.innerHeight / scale;
  wasm.instance.exports.init(cols, rows);
  canvas.width = cols;
  canvas.height = rows;
  canvas.style.width = `${cols * scale}px`;
  canvas.style.height = `${rows * scale}px`;
  canvas.style.imageRendering = "pixelated";
  ctx.imageSmoothingEnabled = false;
  onkeydown = e => wasm.instance.exports.onKeyDown(e.which) || console.log(e.which);
  onpointerdown = () => wasm.instance.exports.onPointerDown();
  onpointerup = () => wasm.instance.exports.onPointerUp();
  onpointermove = e => {
    let p = screenToGrid(e.clientX, e.clientY);
    wasm.instance.exports.onPointerMove(p.x, p.y);
  };
  document.body.append(canvas);
  loop(performance.now());
}

function screenToGrid(x, y) {
  let rect = canvas.getBoundingClientRect();
  let gridX = (x - rect.x) / (rect.width / canvas.width);
  let gridY = (y - rect.y) / (rect.height / canvas.height);
  return { x: gridX, y: gridY };
}

function loop(now) {
  requestAnimationFrame(loop);

  clock += now - time;
  time = now;

  if (clock > 100) {
    clock = 0;
    wasm.instance.exports.update();
  }
}

function render(pointer, size, cols, rows) {
  let memory = wasm.instance.exports.memory;
  let pixels = new Uint8ClampedArray(memory.buffer, pointer, size);
  let imageData = new ImageData(pixels, cols, rows);
  ctx.putImageData(imageData, 0, 0);
}

function debug(pointer, size) {
  let memory = wasm.instance.exports.memory;
  let buffer = new Uint8Array(memory.buffer, pointer, size);
  let decoder = new TextDecoder();
  let string = decoder.decode(buffer);
  console.log(string);
}

init();
