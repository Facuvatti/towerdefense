// Jugador: WASD reconfigurable (HashMap), apunta al mouse con PVector.
class Jugador extends Entidad {
  HashMap<String, Character> controles = new HashMap<String, Character>();
  PVector apuntado = new PVector(1, 0);

  Jugador(float x, float y) {
    super(x, y, 11, 100, 0, 140);
    velMax = 3.4;
    controles.put("arriba", 'w'); controles.put("abajo", 's');
    controles.put("izquierda", 'a'); controles.put("derecha", 'd');
  }

  void reiniciar(float x, float y) { pos.set(x, y); vel.mult(0); vida = vidaMax; ultimoAtaque = 0; }

  int entrada(String accion) {
    Boolean b = teclas.get(controles.get(accion));
    return (b != null && b) ? 1 : 0;
  }

  void actualizar() {
    PVector dir = new PVector(entrada("derecha") - entrada("izquierda"), entrada("abajo") - entrada("arriba"));
    if (dir.magSq() > 0) { dir.normalize().mult(0.75); acc.add(dir); }
    apuntado = PVector.sub(new PVector(mouseX, mouseY), pos);   // vector jugador -> mouse
    angulo = apuntado.heading();
    apuntado.normalize();
    super.actualizar();
    pos.x = constrain(pos.x, radio, width - radio); pos.y = constrain(pos.y, radio + 46, height - radio);
  }

  void disparar() {
    if (!puedeAtacar()) return;
    ultimoAtaque = millis();
    PVector boca = PVector.add(pos, PVector.mult(apuntado, 24));
    PVector v = apuntado.copy().rotate(random(-0.05, 0.05)).mult(11);
    balas.add(new Bala(boca.x, boca.y, v, 25));
    particulas.chispas(boca, angulo);
    vel.sub(PVector.mult(apuntado, 0.6));   // retroceso
    shake += 1.2;
  }

  void mostrar() {
    pushMatrix(); translate(pos.x, pos.y);
    noStroke(); fill(0, 70); ellipse(0, 4, radio*2.4, radio*1.6);
    rotate(angulo);
    color c = flash > 0 ? color(255) : color(60, 110, 200);
    fill(35); rect(radio + 6, 0, radio + 12, 5);
    fill(230, 190, 150); rect(radio*0.8, -radio*0.75, 7, 5); rect(radio + 4, radio*0.5, 7, 5);
    fill(c); rect(0, 0, radio*1.7, radio*2.2);
    fill(lerpColor(c, color(0), 0.4)); rect(-radio*0.4, 0, radio*0.6, radio*1.6);
    fill(90, 70, 45); rect(radio*0.15, 0, radio*1.2, radio*1.2);
    fill(120, 95, 60); rect(radio*0.3, 0, radio*0.6, radio*0.7);
    popMatrix();
  }
}
