// Zombie: persigue al objetivo mas cercano sin cambiar de rumbo por pequenas variaciones.
class Zombie extends Entidad {
  int tipo, puntos, botin;
  float acel, fase = random(TWO_PI);
  color cuerpo;
  Entidad objetivoActual;

  Zombie(float x, float y, int tipo) {   // 0 normal, 1 rapido, 2 tanque
    super(x, y, tipo == 2 ? 15 : (tipo == 1 ? 8 : 10), tipo == 2 ? 160 : (tipo == 1 ? 30 : 55),
          tipo == 2 ? 18 : (tipo == 1 ? 6 : 9), 800);
    this.tipo = tipo;
    vida = vidaMax = round(vida * (1 + 0.07 * oleada));
    velMax = (tipo == 1 ? 2.1 : (tipo == 2 ? 0.7 : 1.0)) * random(0.85, 1.15);
    acel = velMax * 0.2;
    puntos = tipo == 2 ? 50 : (tipo == 1 ? 15 : 10); botin = tipo == 2 ? 40 : (tipo == 1 ? 15 : 10);
    cuerpo = tipo == 2 ? color(74, 104, 98) : (tipo == 1 ? color(150, 128, 76) : color(98, 142, 86));
  }

  Entidad objetivoMasCercano() {
    Entidad mejor = jugador;
    float mejorDistancia = PVector.dist(pos, jugador.pos);
    for (Torre t : torres) {
      if (t.murio()) continue;
      float d = PVector.dist(pos, t.pos);
      if (d < mejorDistancia) {
        mejorDistancia = d;
        mejor = t;
      }
    }
    return mejor;
  }

  Entidad objetivo() {
    Entidad candidato = objetivoMasCercano();

    // Solo cambia si el objetivo actual desaparecio o si otro esta claramente mas cerca.
    if (objetivoActual == null || objetivoActual.murio()
        || (objetivoActual instanceof Torre && !torres.contains((Torre) objetivoActual))) {
      objetivoActual = candidato;
    } else if (candidato != objetivoActual) {
      float distanciaActual = PVector.dist(pos, objetivoActual.pos);
      float distanciaNueva = PVector.dist(pos, candidato.pos);
      if (distanciaNueva + 36 < distanciaActual) objetivoActual = candidato;
    }
    return objetivoActual;
  }

  void actualizar() {
    Entidad obj = objetivo();
    PVector d = PVector.sub(obj.pos, pos);
    if (d.magSq() > 0.001) {
      angulo = d.heading();
      acc.add(d.normalize().mult(acel));
    }

    // Separacion gradual: evita que los grupos se amontonen o se empujen bruscamente.
    for (Zombie o : zombies) {
      if (o == this || o.murio()) continue;
      PVector e = PVector.sub(pos, o.pos);
      float m = e.mag();
      float limite = radio + o.radio + 8;
      if (m < limite) {
        if (m < 0.001) e.set(cos(fase - o.fase), sin(fase - o.fase));
        e.normalize().mult(map(m, 0, limite, 0.35, 0.03));
        acc.add(e);
      }
    }
    acc.limit(acel * 2.5);
    super.actualizar();

    if (colision(obj)) {
      separarDe(obj);
      if (puedeAtacar()) {
        ultimoAtaque = millis(); obj.herir(dano); particulas.sangre(obj.pos, 6);
        shake += (obj == jugador) ? 4 : 1;
      }
    }
  }

  // Ruta punteada hasta el objetivo actual. Amarillo: jugador; celeste: torre.
  void mostrarCamino() {
    if (objetivoActual == null) return;
    PVector hacia = PVector.sub(objetivoActual.pos, pos);
    float distancia = hacia.mag();
    if (distancia < 30) return;

    PVector dir = hacia.div(distancia);
    color ruta = objetivoActual == jugador
      ? color(255, 195, 65, 75)
      : color(75, 210, 255, 75);

    pushStyle();
    stroke(ruta);
    strokeWeight(1.5);
    for (float d = 12; d < distancia - 18; d += 22) {
      float fin = min(d + 9, distancia - 18);
      line(pos.x + dir.x*d, pos.y + dir.y*d,
           pos.x + dir.x*fin, pos.y + dir.y*fin);
    }

    // Punta de flecha para identificar el destino de la ruta.
    float ex = objetivoActual.pos.x - dir.x*17;
    float ey = objetivoActual.pos.y - dir.y*17;
    line(ex, ey, ex - dir.x*7 - dir.y*4, ey - dir.y*7 + dir.x*4);
    line(ex, ey, ex - dir.x*7 + dir.y*4, ey - dir.y*7 - dir.x*4);
    popStyle();
  }

  void mostrar() {
    float s = radio, bob = sin(frameCount*0.25 + fase) * 2;
    pushMatrix(); translate(pos.x, pos.y);
    noStroke(); fill(0, 60); ellipse(0, 4, s*2.2, s*1.4);
    rotate(angulo);
    color c = flash > 0 ? color(255) : cuerpo;
    fill(lerpColor(c, color(0), 0.35));
    rect(s*0.9, -s*0.7 + bob, s*1.1, s*0.5); rect(s*0.9, s*0.7 - bob, s*1.1, s*0.5);
    fill(c); rect(0, 0, s*1.6, s*1.9);
    fill(lerpColor(c, color(255), 0.15)); rect(s*0.3, 0, s*1.1, s*1.1);
    fill(225, 40, 40); rect(s*0.7, -s*0.28, 2, 2); rect(s*0.7, s*0.28, 2, 2);
    popMatrix();
    barraVida();
  }
}
