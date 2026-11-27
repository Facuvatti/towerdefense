// Camino: campo de flujo (BFS sobre una grilla) para que los zombies rodeen las barreras.
// Cada celda guarda cuantos pasos faltan hasta el objetivo mas cercano (jugador, torre o torretas).
// Los zombies bajan por ese campo; asi salen de huecos y formas en U sin quedar trabados.
final int CELDA = 8;
final float MARGEN_CAMINO = 15;  // margen para que tambien pasen los zombies grandes
int cols, filas;
int[] distCampo, cola;
boolean[] bloqueada;
boolean campoSucio = true;       // las barreras cambiaron: recalcular celdas bloqueadas
int campoT = 0;

void iniciarCampo() {
  cols = ceil(width / (float) CELDA); filas = ceil(height / (float) CELDA);
  distCampo = new int[cols * filas]; cola = new int[cols * filas]; bloqueada = new boolean[cols * filas];
  campoSucio = true; campoT = 0;
}

boolean hayBarreras() {
  for (Barrera b : barreras) if (b.solida()) return true;
  return false;
}

void bloquearCeldas() {
  for (int i = 0; i < bloqueada.length; i++) bloqueada[i] = false;
  float r = GROSOR_BARRERA/2 + MARGEN_CAMINO;
  PVector c = new PVector();
  for (Barrera b : barreras) {
    if (!b.solida()) continue;
    int x0 = max(0, floor((b.minX - r) / CELDA)), x1 = min(cols - 1, floor((b.maxX + r) / CELDA));
    int y0 = max(0, floor((b.minY - r) / CELDA)), y1 = min(filas - 1, floor((b.maxY + r) / CELDA));
    for (int y = y0; y <= y1; y++) for (int x = x0; x <= x1; x++) {
      c.set(x * CELDA + CELDA/2, y * CELDA + CELDA/2);
      if (b.distancia(c) < r) bloqueada[y * cols + x] = true;
    }
  }
  campoSucio = false;
}

void sembrar(PVector p, float radio, int[] fin) {   // marca como destino las celdas que tocan al objetivo
  int x0 = max(0, floor((p.x - radio) / CELDA)), x1 = min(cols - 1, floor((p.x + radio) / CELDA));
  int y0 = max(0, floor((p.y - radio) / CELDA)), y1 = min(filas - 1, floor((p.y + radio) / CELDA));
  for (int y = y0; y <= y1; y++) for (int x = x0; x <= x1; x++) {
    int i = y * cols + x;
    if (distCampo[i] < 0 && !bloqueada[i]) { distCampo[i] = 0; cola[fin[0]++] = i; }
  }
}

void actualizarCampo() {
  if (!hayBarreras()) return;              // sin barreras los zombies van derecho
  if (campoSucio) bloquearCeldas();
  else if (campoT-- > 0) return;           // el jugador se mueve: se recalcula cada pocos frames
  campoT = 6;
  for (int i = 0; i < distCampo.length; i++) distCampo[i] = -1;
  int[] fin = {0};
  if (!jugador.enTorre) sembrar(jugador.pos, jugador.radio + CELDA, fin);
  if (torre != null) sembrar(torre.pos, torre.radio + CELDA, fin);
  for (Torre t : torres) sembrar(t.pos, t.radio + CELDA, fin);
  int ini = 0;
  while (ini < fin[0]) {                   // BFS con 8 vecinos, sin cortar esquinas de barreras
    int i = cola[ini++], x = i % cols, y = i / cols;
    for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
      if (dx == 0 && dy == 0) continue;
      int nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= cols || ny >= filas) continue;
      int j = ny * cols + nx;
      if (distCampo[j] >= 0 || bloqueada[j]) continue;
      if (dx != 0 && dy != 0 && (bloqueada[y * cols + nx] || bloqueada[ny * cols + x])) continue;
      distCampo[j] = distCampo[i] + 1;
      cola[fin[0]++] = j;
    }
  }
}

// Direccion a seguir desde p, o null si conviene ir derecho (sin barreras, ya llego o celda sin camino)
PVector direccionCampo(PVector p) {
  if (!hayBarreras()) return null;
  int x = constrain(floor(p.x / CELDA), 0, cols - 1), y = constrain(floor(p.y / CELDA), 0, filas - 1);
  int d = distCampo[y * cols + x];
  if (d == 0) return null;
  int mejor = -1, md = d > 0 ? d : Integer.MAX_VALUE;   // celda propia bloqueada: igual busca salida por los vecinos
  for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
    int nx = x + dx, ny = y + dy;
    if (nx < 0 || ny < 0 || nx >= cols || ny >= filas) continue;
    int j = ny * cols + nx, dj = distCampo[j];
    if (dj >= 0 && dj < md) { md = dj; mejor = j; }
  }
  if (mejor < 0) return null;
  return new PVector((mejor % cols) * CELDA + CELDA/2 - p.x, (mejor / cols) * CELDA + CELDA/2 - p.y).normalize();
}
