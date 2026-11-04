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
  float acel, fase = random(TWO_PI);
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
    PVector deseo = PVector.sub(obj.pos, pos).normalize();
    boolean rompe = tipo == JEFE;   // el jefe va derecho y rompe lo que se le cruce
    if (!rompe) { PVector c = direccionCampo(pos); if (c != null) deseo = c; }   // rodea las barreras por el campo de flujo
    acc.add(PVector.mult(deseo, acel));
    for (Zombie o : zombies) if (o != this) {   // separacion entre zombies
      PVector e = PVector.sub(pos, o.pos); float m = e.mag();
      if (m > 0 && m < radio + o.radio) acc.add(e.setMag(0.25));
    }
    super.actualizar();
    if (vel.magSq() > 0.04) angulo = vel.heading();
    for (Barrera b : barreras) {
      if (!b.empujar(this)) continue;
      boolean bloquea = (pos.x - b.cx) * deseo.x + (pos.y - b.cy) * deseo.y < 0;   // va contra el muro, no lo roza
      if (rompe && bloquea && puedeAtacar()) {
        ultimoAtaque = millis(); b.herir(dano); astillas(new PVector(b.cx, b.cy)); shake += 2;
      }
    }
    if (!jugador.enTorre) contacto(jugador);   // pega a lo que toque (torre y torretas tambien son obstaculos)
    if (torre != null) contacto(torre);
    for (Torre t : torres) contacto(t);
  }

  void contacto(Entidad e) {
    if (!colision(e)) return;
    separarDe(e);
    if (!puedeAtacar()) return;
    ultimoAtaque = millis(); e.herir(dano);
    if (e == jugador) { particulas.sangre(e.pos, 6); shake += 4; }
    else { particulas.emitir(pos, 5, color(120, 115, 105), 0.5, 2.5, 4, 20, 0, PI); shake += 1; }
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
