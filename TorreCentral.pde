// Torre central: estructura fija que el jugador defiende y a la que se puede subir.
// Si cae, el jugador baja y ya no puede volver a subir.
class TorreCentral extends Entidad {

  TorreCentral(float x, float y) { super(x, y, 34, 600, 0, 0); }

  void mover() {}   // estructura fija: no se mueve

  void mostrar() {
    float d = 1 - vida / (float) vidaMax;   // deterioro de 0 (nueva) a 1 (destruida)
    color piedra = lerpColor(color(124, 116, 104), color(62, 54, 48), d);
    pushMatrix(); translate(pos.x, pos.y); noStroke();
    fill(0, 80); rect(5, 7, 66, 66);
    fill(flash > 0 ? color(255) : piedra); rect(0, 0, 62, 62);
    fill(lerpColor(piedra, color(0), 0.3));   // almenas
    for (int i = -1; i <= 1; i++) {
      rect(i*22, -27, 10, 8); rect(i*22, 27, 10, 8);
      rect(-27, i*22, 8, 10); rect(27, i*22, 8, 10);
    }
    fill(lerpColor(piedra, color(255), 0.12)); rect(0, 0, 42, 42);   // plataforma
    fill(84, 62, 42); rect(0, 0, 30, 30);                             // piso de madera
    fill(66, 48, 32); rect(0, -7, 30, 2); rect(0, 7, 30, 2);
    stroke(28); strokeWeight(2);                                      // grietas segun deterioro
    if (d > 0.25) { line(-24, -14, -12, -2); line(-12, -2, -16, 8); }
    if (d > 0.5)  { line(14, 10, 24, 22); line(18, -24, 10, -14); }
    if (d > 0.75) { line(-8, 18, 4, 26); line(22, -4, 28, 4); }
    noStroke(); strokeWeight(1);
    popMatrix();
    barraVida();
  }
}
