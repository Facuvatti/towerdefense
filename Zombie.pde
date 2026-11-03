// Zombie: persigue a la entidad herible mas cercana (jugador, torre central o torretas).
// Stats por tipo: 0 normal, 1 rapido, 2 tanque, 3 jefe
final int JEFE = 3;
final float[] Z_RADIO   = {10, 8, 15, 22};
final int[]   Z_VIDA    = {55, 30, 160, 700};
final int[]   Z_DANO    = {9, 6, 18, 30};
final int[]   Z_COOLDOWN = {800, 800, 800, 1000};
final float[] Z_VEL     = {1.0, 2.1, 0.7, 0.55};
final int[]   Z_PUNTOS  = {10, 15, 50, 300};
final int[]   Z_BOTIN   = {10, 15, 40, 150};

class Zombie extends Entidad {
  int tipo, puntos, botin;
  float acel, fase = random(TWO_PI), lado = random(1) < 0.5 ? -1 : 1;   // lado: hacia donde rodea las barreras
  color cuerpo;

  Zombie(float x, float y, int tipo) {
    super(x, y, Z_RADIO[tipo], Z_VIDA[tipo], Z_DANO[tipo], Z_COOLDOWN[tipo]);
    this.tipo = tipo;
    vida = vidaMax = round(vida * (1 + 0.07 * oleada));
    velMax = Z_VEL[tipo] * random(0.85, 1.15);
    acel = velMax * 0.2;
    puntos = Z_PUNTOS[tipo]; botin = Z_BOTIN[tipo];
    color[] cuerpos = {color(98, 142, 86), color(150, 128, 76), color(74, 104, 98), color(120, 56, 78)};
    cuerpo = cuerpos[tipo];
  }

  Entidad objetivo() {
    Entidad m = null; float md = Float.MAX_VALUE;
    if (!jugador.enTorre) { m = jugador; md = PVector.dist(pos, jugador.pos); }   // arriba de la torre no lo alcanzan
    if (torre != null) { float d = PVector.dist(pos, torre.pos); if (d < md) { md = d; m = torre; } }
    for (Torre t : torres) { float d = PVector.dist(pos, t.pos); if (d < md) { md = d; m = t; } }
    return m != null ? m : jugador;
  }

  void actualizar() {
    Entidad obj = objetivo();
    PVector d = PVector.sub(obj.pos, pos);
    angulo = d.heading();
    PVector deseo = d.copy().normalize();
    acc.add(d.setMag(acel));
    for (Zombie o : zombies) if (o != this) {   // separacion entre zombies
      PVector e = PVector.sub(pos, o.pos); float m = e.mag();
      if (m > 0 && m < radio + o.radio) acc.add(e.setMag(0.25));
    }
    super.actualizar();
    if (torre != null && obj != torre && colision(torre)) separarDe(torre);   // la rodean, no la atraviesan
    for (Barrera b : barreras) {
      if (!b.empujar(this)) continue;
      if (tipo == JEFE) {   // el jefe no entra por los huecos: rompe la barrera a golpes
        if (puedeAtacar()) { ultimoAtaque = millis(); b.herir(dano); astillas(b.puntoCercano(pos)); shake += 2; }
      } else {              // los demas la rodean: se deslizan a lo largo del muro
        PVector t = b.tangente.copy(); float dt = t.dot(deseo);
        if (abs(dt) < 0.2) t.mult(lado); else if (dt < 0) t.mult(-1);
        acc.add(t.mult(acel * 1.5));
      }
    }
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
    if (tipo == JEFE) {   // cuernos
      fill(225, 205, 170); rect(s*0.2, -s*0.75, s*0.7, s*0.22); rect(s*0.2, s*0.75, s*0.7, s*0.22);
    }
    popMatrix();
    barraVida();
  }
}
