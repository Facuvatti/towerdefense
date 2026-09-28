// Bala: movimiento uniforme, autodestruccion fuera de limites o por edad.
class Bala extends Entidad {
  int edad = 0;

  Bala(float x, float y, PVector v, int dano) {
    super(x, y, 3, 1, dano, 0);
    vel = v.copy(); angulo = vel.heading();
  }

  void mover() { pos.add(vel); }   // sin friccion: velocidad constante
  void actualizar() { super.actualizar(); edad++; }

  boolean murio() {
    return vida <= 0 || edad > 90 || pos.x < -10 || pos.x > width + 10 || pos.y < -10 || pos.y > height + 10;
  }

  void mostrar() {
    pushMatrix(); translate(pos.x, pos.y); rotate(angulo); noStroke();
    fill(255, 180, 60, 120); rect(-5, 0, 12, 3);
    fill(255, 240, 150); rect(0, 0, 8, 3);
    popMatrix();
  }
}
