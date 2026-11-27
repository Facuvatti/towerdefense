// TOWER DEFENSE ZOMBIES - Facundo Vattino & Santiago Villarroel
// Main: estados, bucle, colisiones globales, HUD y menu.
final int MENU = 0, JUEGO = 1, PAUSA = 2, FIN = 3;
final int COSTO_TORRE = 100;
int estado = MENU;
Jugador jugador;
ArrayList<Zombie> zombies = new ArrayList<Zombie>();
ArrayList<Bala> balas = new ArrayList<Bala>();
ArrayList<Torre> torres = new ArrayList<Torre>();
SistemaParticulas particulas = new SistemaParticulas();
HashMap<Character, Boolean> teclas = new HashMap<Character, Boolean>();
PGraphics fondo;
int oleada = 0, monedas = 0, puntaje = 0, cuentaAtras = 0, bannerT = 0, remapIdx = -1;
float shake = 0;
String[] acciones = {"arriba", "abajo", "izquierda", "derecha"};

void setup() {
  size(960, 640);
  noSmooth();
  textFont(createFont("Monospaced.bold", 16));
  crearFondo();
  jugador = new Jugador(width/2, height/2);
}

void nuevaPartida() {
  zombies.clear(); balas.clear(); torres.clear(); particulas.lista.clear();
  crearFondo();
  jugador.reiniciar(width/2, height/2);
  oleada = 0; puntaje = 0; monedas = 150; cuentaAtras = 200; bannerT = 0;
  estado = JUEGO;
}

void draw() {
  background(0);
  if (estado == MENU) { dibujarMenu(); return; }
  if (estado == JUEGO) actualizarJuego();
  dibujarJuego();
  if (estado == PAUSA) overlay("PAUSA", "P para continuar");
  if (estado == FIN) overlay("GAME OVER", "Oleada " + oleada + "   Puntaje " + puntaje + "\\nENTER para reiniciar");
}

void actualizarJuego() {
  jugador.actualizar();
  if (mousePressed && mouseButton == LEFT) jugador.disparar();
  for (Zombie z : zombies) z.actualizar();
  for (Bala b : balas) b.actualizar();
  for (Torre t : torres) t.actualizar();

  // Impactos bala -> zombie
  for (Bala b : balas)
    for (Zombie z : zombies)
      if (b.colision(z)) { z.herir(b.dano); particulas.sangre(b.pos, 5); b.vida = 0; break; }

  // Limpieza de listas (recorrido inverso: sin fugas ni saltos)
  for (int i = zombies.size()-1; i >= 0; i--) {
    Zombie z = zombies.get(i);
    if (z.murio()) { puntaje += z.puntos; monedas += z.botin; particulas.sangre(z.pos, 24); mancha(z.pos); zombies.remove(i); }
  }
  for (int i = balas.size()-1; i >= 0; i--) if (balas.get(i).murio()) balas.remove(i);
  for (int i = torres.size()-1; i >= 0; i--) {
    if (torres.get(i).murio()) { particulas.explosion(torres.get(i).pos); shake = 8; torres.remove(i); }
  }
  particulas.actualizar();
  if (jugador.murio()) { estado = FIN; particulas.explosion(jugador.pos); shake = 12; }

  // Flujo de oleadas
  if (zombies.isEmpty()) {
    if (cuentaAtras <= 0 && oleada >= 0) {
      if (oleada > 0) { monedas += 20*oleada; jugador.vida = min(jugador.vidaMax, jugador.vida + 25); }
      cuentaAtras = 210;
    } else if (--cuentaAtras <= 0) { iniciar_oleada(); }
  }
  if (bannerT > 0) bannerT--;
}

void mancha(PVector p) {
  fondo.beginDraw(); fondo.noStroke(); fondo.fill(100, 10, 20, 110);
  fondo.rect(p.x - 6, p.y - 4, random(6, 14), random(5, 10)); fondo.endDraw();
}

void dibujarJuego() {
  rectMode(CENTER);
  pushMatrix();
  translate(random(-shake, shake), random(-shake, shake)); shake *= 0.85;
  image(fondo, 0, 0);
  for (Zombie z : zombies) z.mostrarCamino();
  for (Torre t : torres) t.mostrar();
  for (Zombie z : zombies) z.mostrar();
  for (Bala b : balas) b.mostrar();
  if (estado != FIN) jugador.mostrar();
  particulas.mostrar();
  if (estado == JUEGO) previsualizarTorre();
  popMatrix();
  dibujarHUD();
}

void previsualizarTorre() {
  boolean ok = monedas >= COSTO_TORRE;
  noFill(); stroke(ok ? color(120, 255, 140, 90) : color(255, 80, 80, 90));
  ellipse(mouseX, mouseY, 440, 440);
  noStroke(); fill(ok ? color(120, 255, 140, 120) : color(255, 80, 80, 120));
  rect(mouseX, mouseY, 28, 28);
}

void dibujarHUD() {
  rectMode(CORNER); noStroke(); fill(0, 150); rect(0, 0, width, 46);
  barra(16, 15, 200, 16, jugador.vida / (float) jugador.vidaMax, color(210, 50, 60));
  texto("HP " + max(0, jugador.vida), 116, 23, 12, color(255), CENTER);
  texto("OLEADA " + oleada, 340, 23, 18, color(255, 220, 80), LEFT);
  texto("$ " + monedas, 520, 23, 18, color(110, 240, 130), LEFT);
  texto("PUNTOS " + puntaje, width - 16, 23, 18, color(255), RIGHT);
  texto("RUTA PUNTEADA: AMARILLO = JUGADOR  |  CELESTE = TORRE", 16, 62, 11, color(230, 230, 230, 210), LEFT);
  texto("WASD mover  |  Click izq. disparar  |  Click der. torre ($" + COSTO_TORRE + ")  |  P pausa",
        width/2, height - 16, 12, color(210, 210, 210, 200), CENTER);
  if (bannerT > 0) texto("OLEADA " + oleada, width/2, height*0.3, 56, color(255, 220, 80, min(255, bannerT*4)), CENTER);
  else if (estado == JUEGO && zombies.isEmpty() && oleada > 0)
    texto("Siguiente oleada en " + ceil(cuentaAtras/60.0) + "  (+$" + 20*oleada + ")", width/2, height*0.3, 22, color(255), CENTER);
  rectMode(CENTER);
}

void dibujarMenu() {
  rectMode(CORNER); image(fondo, 0, 0); noStroke(); fill(0, 175); rect(0, 0, width, height);
  float p = sin(frameCount*0.06) * 5;
  texto("TOWER DEFENSE", width/2, 130 + p, 58, color(120, 220, 90), CENTER);
  texto("ZOMBIES", width/2, 205 - p, 74, color(220, 60, 60), CENTER);
  texto("Facundo Vattino & Santiago Villarroel", width/2, 262, 14, color(190), CENTER);
  boolean hover = abs(mouseX - width/2) < 130 && abs(mouseY - 380) < 27;
  rectMode(CENTER); fill(hover ? color(90, 190, 80) : color(50, 120, 55)); stroke(20); strokeWeight(3);
  rect(width/2, 380, 260, 54); noStroke();
  texto("JUGAR", width/2, 380, 26, color(255), CENTER);
  String c = "";
  for (String a : acciones) c += a.toUpperCase() + ": " + Character.toUpperCase(jugador.controles.get(a)) + "   ";
  texto(c, width/2, 470, 14, color(230), CENTER);
  texto(remapIdx >= 0 ? ">> Presiona la tecla para " + acciones[remapIdx].toUpperCase() + " <<" : "R: reasignar controles   |   ENTER: jugar",
        width/2, 500, 14, remapIdx >= 0 ? color(255, 220, 80) : color(170), CENTER);
}

void overlay(String t, String s) {
  rectMode(CORNER); noStroke(); fill(0, 160); rect(0, 0, width, height);
  texto(t, width/2, height/2 - 30, 60, color(230, 70, 60), CENTER);
  texto(s, width/2, height/2 + 40, 18, color(255), CENTER);
  rectMode(CENTER);
}

void barra(float x, float y, float w, float h, float pct, color c) {
  rectMode(CORNER); noStroke();
  fill(0, 180); rect(x-2, y-2, w+4, h+4);
  fill(60); rect(x, y, w, h);
  fill(c); rect(x, y, w * constrain(pct, 0, 1), h);
  fill(255, 50); rect(x, y, w * constrain(pct, 0, 1), h*0.4);
  rectMode(CENTER);
}

void texto(String s, float x, float y, int sz, color c, int al) {
  textAlign(al, CENTER); textSize(sz);
  fill(0, 190); text(s, x+2, y+2); fill(c); text(s, x, y);
}

void crearFondo() {
  fondo = createGraphics(width, height);
  fondo.beginDraw(); fondo.noStroke(); fondo.noSmooth();
  randomSeed(7); noiseSeed(7);
  int t = 16;
  for (int y = 0; y < height; y += t) for (int x = 0; x < width; x += t) {
    color c = lerpColor(color(38, 84, 46), color(66, 122, 60), noise(x*0.02, y*0.02));
    if (random(1) < 0.15) c = lerpColor(c, color(28, 66, 38), 0.5);
    float d = dist(x, y, width/2, height/2) / (width*0.6);
    c = lerpColor(c, color(8, 16, 12), constrain(d*d*0.75, 0, 0.75));
    fondo.fill(c); fondo.rect(x, y, t, t);
    if (random(1) < 0.08) { fondo.fill(96, 156, 84); fondo.rect(x + (int) random(12), y + (int) random(12), 2, 4); }
    if (random(1) < 0.012) { fondo.fill(90, 92, 100); fondo.rect(x, y+2, 8, 6); fondo.fill(140, 142, 150); fondo.rect(x, y+2, 8, 2); }
  }
  fondo.endDraw();
  randomSeed(millis());
}

void mousePressed() {
  if (estado == MENU) { if (remapIdx < 0 && abs(mouseX - width/2) < 130 && abs(mouseY - 380) < 27) nuevaPartida(); return; }
  if (estado == JUEGO && mouseButton == RIGHT && monedas >= COSTO_TORRE
      && dist(mouseX, mouseY, jugador.pos.x, jugador.pos.y) > 30) {
    monedas -= COSTO_TORRE; torres.add(new Torre(mouseX, mouseY));
  }
}

void keyPressed() {
  if (key == CODED) return;
  char k = Character.toLowerCase(key);
  boolean enter = (key == ENTER || key == RETURN);
  if (estado == MENU) {
    if (remapIdx >= 0 && !enter) { jugador.controles.put(acciones[remapIdx], k); remapIdx = (remapIdx + 1 >= 4) ? -1 : remapIdx + 1; }
    else if (k == 'r') remapIdx = 0;
    else if (enter) nuevaPartida();
    return;
  }
  if (k == 'p' && estado == JUEGO) estado = PAUSA; else if (k == 'p' && estado == PAUSA) estado = JUEGO;
  if (estado == FIN && enter) nuevaPartida();
  teclas.put(k, true);
}

void keyReleased() { if (key != CODED) teclas.put(Character.toLowerCase(key), false); }
