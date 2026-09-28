// Sistema de particulas: sangre, chispas y explosiones.
class Particula {
  PVector pos, vel; float vida, vidaMax, tam; color c;
  Particula(PVector p, PVector v, float vida, float tam, color c) {
    pos = p; vel = v; this.vida = vidaMax = vida; this.tam = tam; this.c = c;
  }
  void actualizar() { pos.add(vel); vel.mult(0.92); vida--; }
  boolean murio() { return vida <= 0; }
  void mostrar() {
    float a = vida / vidaMax, t = tam * (0.5 + a*0.5);
    noStroke(); fill(red(c), green(c), blue(c), 255*a); rect(pos.x, pos.y, t, t);
  }
}

class SistemaParticulas {
  ArrayList<Particula> lista = new ArrayList<Particula>();

  void emitir(PVector p, int n, color c, float vmin, float vmax, float tam, float vida, float ang, float apertura) {
    for (int i = 0; i < n && lista.size() < 800; i++) {
      PVector v = PVector.fromAngle(ang + random(-apertura, apertura)).mult(random(vmin, vmax));
      lista.add(new Particula(p.copy(), v, random(vida*0.5, vida), tam * random(0.6, 1.2), c));
    }
  }
  void sangre(PVector p, int n) { emitir(p, n, color(150, 15, 25), 0.5, 3.5, 4, 30, 0, PI); }
  void chispas(PVector p, float ang) { emitir(p, 4, color(255, 210, 90), 2, 5, 3, 10, ang, 0.5); }
  void explosion(PVector p) {
    emitir(p, 40, color(255, 140, 30), 1, 6, 6, 40, 0, PI);
    emitir(p, 20, color(80), 1, 3, 5, 50, 0, PI);
  }
  void actualizar() {
    for (int i = lista.size()-1; i >= 0; i--) { Particula q = lista.get(i); q.actualizar(); if (q.murio()) lista.remove(i); }
  }
  void mostrar() { for (Particula q : lista) q.mostrar(); }
}
