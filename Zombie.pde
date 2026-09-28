// Zombie: persigue a la entidad herible mas cercana (jugador o torre).
class Zombie extends Entidad {
  int tipo, puntos, botin;
  float acel, fase = random(TWO_PI);
  color cuerpo;

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

  Entidad objetivo() {
    Entidad m = jugador; float md = PVector.dist(pos, jugador.pos);
    for (Torre t : torres) { float d = PVector.dist(pos, t.pos); if (d < md) { md = d; m = t; } }
    return m;
  }

  void actualizar() {
    Entidad obj = objetivo();
    PVector d = PVector.sub(obj.pos, pos);
    angulo = d.heading();
    acc.add(d.setMag(acel));
    for (Zombie o : zombies) if (o != this) {   // separacion entre zombies
      PVector e = PVector.sub(pos, o.pos); float m = e.mag();
      if (m > 0 && m < radio + o.radio) acc.add(e.setMag(0.25));
    }
    super.actualizar();
    if (colision(obj)) {
      separarDe(obj);
      if (puedeAtacar()) {
        ultimoAtaque = millis(); obj.herir(dano); particulas.sangre(obj.pos, 6);
        shake += (obj == jugador) ? 4 : 1;
      }
    }
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
