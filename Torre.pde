// Torreta automatica: dispara al zombie mas cercano dentro de su alcance. Se gasta con el tiempo.
final int COSTO_TORRE = 100;
final float DIST_TORRETAS = 90;    // distancia minima entre torretas
final int DESGASTE_FRAMES = 40;    // pierde 1 de vida cada tantos frames (~100 s de vida sin ataques)

class Torre extends Entidad {
  float alcance = 220;
  int desgaste = 0;

  Torre(float x, float y) { super(x, y, 14, 150, 0, 400); }

  void actualizar() {
    super.actualizar();
    if (++desgaste >= DESGASTE_FRAMES) { desgaste = 0; vida--; }   // deterioro con el tiempo
    Zombie objetivo = null; float mejor = alcance;
    for (Zombie z : zombies) { float d = PVector.dist(pos, z.pos); if (d < mejor) { mejor = d; objetivo = z; } }
    if (objetivo == null) return;
    angulo = PVector.sub(objetivo.pos, pos).heading();
    if (puedeAtacar()) {
      ultimoAtaque = millis();
      PVector dir = PVector.fromAngle(angulo);
      PVector boca = PVector.add(pos, PVector.mult(dir, 20));
      balas.add(new Bala(boca.x, boca.y, PVector.mult(dir, 9), 16));
      particulas.chispas(boca, angulo);
    }
  }

  void mostrar() {
    float d = 1 - vida / (float) vidaMax;   // deterioro de 0 a 1
    color base = lerpColor(color(70, 74, 84), color(46, 40, 36), d);
    pushMatrix(); translate(pos.x, pos.y); noStroke();
    fill(0, 70); rect(2, 4, 32, 32);
    fill(flash > 0 ? color(255) : base); rect(0, 0, 30, 30);
    fill(lerpColor(color(100, 106, 120), color(70, 62, 56), d)); rect(0, 0, 22, 22);
    stroke(24); strokeWeight(1);   // grietas
    if (d > 0.3) line(-14, -8, -6, -2);
    if (d > 0.6) { line(8, 6, 14, 13); line(4, -14, 9, -7); }
    noStroke();
    rotate(angulo);
    fill(40); rect(12, 0, 22, 6);
    fill(lerpColor(color(200, 70, 60), color(110, 60, 50), d)); rect(0, 0, 10, 10);
    popMatrix();
    barraVida();
  }
}

// Por que no se puede poner una torreta en (x, y), o null si se puede
String motivoTorreta(float x, float y) {
  if (monedas < COSTO_TORRE) return "Falta plata";
  if (y < 46 + 16) return "Fuera del mapa";
  if (dist(x, y, jugador.pos.x, jugador.pos.y) < 30) return "Muy cerca tuyo";
  if (torre != null && dist(x, y, torre.pos.x, torre.pos.y) < torre.radio + 26) return "Muy cerca de la torre";
  for (Torre t : torres) if (dist(x, y, t.pos.x, t.pos.y) < DIST_TORRETAS) return "Muy cerca de otra torreta";
  PVector p = new PVector(x, y);
  for (Barrera b : barreras) if (b.solida() && b.distancia(p) < 14 + HUECO + GROSOR_BARRERA/2) return "Muy cerca de una barrera";
  return null;
}
