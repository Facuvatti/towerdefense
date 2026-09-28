// Clase base abstracta: fisica con PVector, vida, dano, cooldown y colision.
abstract class Entidad {
  PVector pos, vel, acc;
  float radio, velMax = 3, friccion = 0.85, angulo;
  int vida, vidaMax, dano, cooldown, ultimoAtaque, flash;

  Entidad(float x, float y, float radio, int vida, int dano, int cooldown) {
    pos = new PVector(x, y); vel = new PVector(); acc = new PVector();
    this.radio = radio; this.vida = this.vidaMax = vida; this.dano = dano; this.cooldown = cooldown;
  }

  void actualizar() { mover(); if (flash > 0) flash--; }

  // Movimiento acelerado: acc -> vel (con friccion y tope) -> pos
  void mover() {
    vel.add(acc); vel.mult(friccion); vel.limit(velMax);
    pos.add(vel); acc.mult(0);
  }

  abstract void mostrar();

  boolean colision(Entidad o) { return PVector.dist(pos, o.pos) < radio + o.radio; }

  // Resolucion: empuja a esta entidad fuera de la otra
  void separarDe(Entidad o) {
    PVector e = PVector.sub(pos, o.pos);
    float solape = radio + o.radio - e.mag();
    if (solape > 0) { e.setMag(solape); pos.add(e); }
  }

  void herir(int d) { vida -= d; flash = 6; }
  boolean murio() { return vida <= 0; }
  boolean puedeAtacar() { return millis() - ultimoAtaque >= cooldown; }

  void barraVida() {
    if (vida < vidaMax) barra(pos.x - radio, pos.y - radio - 14, radio*2, 4, vida / (float) vidaMax, color(220, 60, 60));
  }
}
