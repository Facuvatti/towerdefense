// Jugador: WASD reconfigurable (HashMap), apunta al mouse con PVector.
class Jugador extends Entidad {
  HashMap<String, Character> controles = new HashMap<String, Character>();
  PVector apuntado = new PVector(1, 0);
  boolean enTorre = false;
  int municion = 60, municionMax = 150, sinBalasT = 0;
  ArrayList<Arma> armas = new ArrayList<Arma>();   // armas compradas
  Arma arma;                                       // arma equipada
  int cooldownTorre = 700, ultimoCambioTorre = -10000;   // cooldown para subir/bajar (ms)

  Jugador(float x, float y) {
    super(x, y, 11, 100, 0, 140);
    velMax = 3.4;
    controles.put("arriba", 'w'); controles.put("abajo", 's');
    controles.put("izquierda", 'a'); controles.put("derecha", 'd');
    controles.put("torre", 'e'); controles.put("tienda", 'q'); controles.put("barrera", 'b');
    armas.add(catalogo.get(0)); equipar(0);
  }

  void equipar(int i) {
    if (i < 0 || i >= armas.size()) return;
    arma = armas.get(i); cooldown = arma.cooldown;
  }

  void reiniciar(float x, float y) {
    pos.set(x, y); vel.mult(0); vida = vidaMax; ultimoAtaque = 0;
    enTorre = false; ultimoCambioTorre = -10000;
    municion = 60; sinBalasT = 0;
    armas.clear(); armas.add(catalogo.get(0)); equipar(0);
  }

  // --- Subir y bajar de la torre central ---
  boolean puedeCambiarTorre() { return millis() - ultimoCambioTorre >= cooldownTorre; }
  float cargaTorre() { return constrain((millis() - ultimoCambioTorre) / (float) cooldownTorre, 0, 1); }
  boolean cercaDeTorre() { return torre != null && PVector.dist(pos, torre.pos) < torre.radio + radio + 18; }

  void alternarTorre() {
    if (!puedeCambiarTorre()) return;
    if (enTorre) bajar();
    else if (cercaDeTorre()) subir();
  }

  void subir() {
    enTorre = true; vel.mult(0); acc.mult(0); pos.set(torre.pos);
    ultimoCambioTorre = millis();
  }

  void bajar() {   // sale de la torre hacia donde apunta
    enTorre = false;
    pos.set(PVector.add(torre.pos, PVector.mult(apuntado, torre.radio + radio + 4)));
    ultimoCambioTorre = millis();
  }

  int entrada(String accion) {
    Boolean b = teclas.get(controles.get(accion));
    return (b != null && b) ? 1 : 0;
  }

  void actualizar() {
    if (sinBalasT > 0) sinBalasT--;
    if (!enTorre) {   // arriba de la torre no se camina
      PVector dir = new PVector(entrada("derecha") - entrada("izquierda"), entrada("abajo") - entrada("arriba"));
      if (dir.magSq() > 0) { dir.normalize().mult(0.75); acc.add(dir); }
    }
    apuntado = PVector.sub(new PVector(mouseX, mouseY), pos);   // vector jugador -> mouse
    if (apuntado.magSq() == 0) apuntado.set(1, 0);
    angulo = apuntado.heading();
    apuntado.normalize();
    super.actualizar();
    if (enTorre) { pos.set(torre.pos); return; }
    pos.x = constrain(pos.x, radio, width - radio); pos.y = constrain(pos.y, radio + 46, height - radio);
    if (torre != null && colision(torre)) separarDe(torre);   // la torre es un obstaculo
    for (Barrera b : barreras) b.empujar(this);
  }

  void disparar() {
    if (!puedeAtacar()) return;
    ultimoAtaque = millis();
    if (municion <= 0) { sinBalasT = 40; return; }   // sin balas: no dispara
    municion--;
    PVector boca = PVector.add(pos, PVector.mult(apuntado, (radio + arma.largo - 4) * (enTorre ? 1.2 : 1)));
    arma.disparar(boca, apuntado);
    particulas.chispas(boca, angulo);
    vel.sub(PVector.mult(apuntado, arma.retroceso));   // retroceso
    shake += arma.retroceso * 2;
  }

  void mostrar() {
    if (cargaTorre() < 1) {   // indicador del cooldown de subir/bajar
      noFill(); stroke(255, 220, 80, 200); strokeWeight(2);
      arc(pos.x, pos.y, radio*3.4, radio*3.4, -HALF_PI, -HALF_PI + TWO_PI*cargaTorre());
      noStroke(); strokeWeight(1);
    }
    pushMatrix(); translate(pos.x, pos.y);
    if (enTorre) scale(1.2);   // arriba de la torre se ve mas grande (altura)
    noStroke(); fill(0, 70); ellipse(0, 4, radio*2.4, radio*1.6);
    rotate(angulo);
    color c = flash > 0 ? color(255) : color(60, 110, 200);
    fill(arma.c); rect(radio - 5 + arma.largo/2, 0, arma.largo, arma.perdigones > 1 ? 6 : 5);
    fill(230, 190, 150); rect(radio*0.8, -radio*0.75, 7, 5); rect(radio + 4, radio*0.5, 7, 5);
    fill(c); rect(0, 0, radio*1.7, radio*2.2);
    fill(lerpColor(c, color(0), 0.4)); rect(-radio*0.4, 0, radio*0.6, radio*1.6);
    fill(90, 70, 45); rect(radio*0.15, 0, radio*1.2, radio*1.2);
    fill(120, 95, 60); rect(radio*0.3, 0, radio*0.6, radio*0.7);
    popMatrix();
  }
}
