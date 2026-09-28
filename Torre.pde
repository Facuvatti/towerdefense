// Torre automatica: dispara al zombie mas cercano dentro de su alcance.
class Torre extends Entidad {
  float alcance = 220;

  Torre(float x, float y) { super(x, y, 14, 150, 0, 400); }

  void actualizar() {
    super.actualizar();
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
    pushMatrix(); translate(pos.x, pos.y); noStroke();
    fill(0, 70); rect(2, 4, 32, 32);
    fill(flash > 0 ? color(255) : color(70, 74, 84)); rect(0, 0, 30, 30);
    fill(100, 106, 120); rect(0, 0, 22, 22);
    rotate(angulo);
    fill(40); rect(12, 0, 22, 6);
    fill(200, 70, 60); rect(0, 0, 10, 10);
    popMatrix();
    barraVida();
  }
}
