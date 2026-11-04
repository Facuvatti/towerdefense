// Torre central: estructura fija que el jugador defiende y a la que se puede subir.
// Si cae, el jugador baja y ya no puede volver a subir.
class TorreCentral extends Entidad {
  int nivel = 1;
  color[] banderas = {color(200, 60, 60), color(60, 110, 200), color(230, 200, 60), color(120, 200, 90)};

  TorreCentral(float x, float y) { super(x, y, 42, 600, 0, 0); }

  void mover() {}   // estructura fija: no se mueve

  void mejorar() {   // cada nivel: +200 vida maxima y la repara 200
    nivel++; vidaMax += 200; vida = min(vidaMax, vida + 200);
    particulas.emitir(pos, 30, color(255, 220, 80), 1, 4, 5, 40, 0, PI);
  }

  void mostrar() {
    float d = 1 - vida / (float) vidaMax;   // deterioro de 0 (nueva) a 1 (destruida)
    color piedra = lerpColor(color(124, 116, 104), color(62, 54, 48), d);
    pushMatrix(); translate(pos.x, pos.y); noStroke();
    scale(radio / 34.0);   // el dibujo esta hecho para radio 34
    fill(0, 80); rect(5, 7, 66, 66);
    fill(flash > 0 ? color(255) : piedra); rect(0, 0, 62, 62);
    fill(lerpColor(piedra, color(0), 0.3));   // almenas
    for (int i = -1; i <= 1; i++) {
      rect(i*22, -27, 10, 8); rect(i*22, 27, 10, 8);
      rect(-27, i*22, 8, 10); rect(27, i*22, 8, 10);
    }
    for (int i = 0; i < nivel - 1 && i < banderas.length; i++) {   // una bandera por cada mejora
      float sx = (i == 0 || i == 3) ? -27 : 27, sy = i < 2 ? -27 : 27;
      fill(40); rect(sx, sy - 8, 2, 16);
      fill(banderas[i]); rect(sx + 5, sy - 13, 9, 6);
    }
    fill(nivel >= TORRE_NIVEL_MAX ? color(220, 180, 60) : lerpColor(piedra, color(255), 0.12));   // borde dorado al maximo
    rect(0, 0, 42, 42);   // plataforma
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
