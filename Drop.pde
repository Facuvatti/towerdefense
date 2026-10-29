// Drops: objetos que sueltan los zombies y el jugador recoge al pasar por arriba.
final int D_MUNICION = 0, D_CURA = 1, D_MONEDA = 2, D_MATERIAL = 3;

class Drop extends Entidad {
  int tipo, cantidad, edad = 0, duracion;
  float fase = random(TWO_PI);

  Drop(PVector p, int tipo, int cantidad) {
    super(p.x, p.y, 7, 1, 0, 0);
    this.tipo = tipo; this.cantidad = cantidad;
    duracion = tipo == D_MATERIAL ? 1500 : 900;   // frames hasta desaparecer
    vel = PVector.random2D().mult(random(1.5, 3.5));   // salen desparramados
    friccion = 0.88; velMax = 5;
  }

  // Solo se recoge (y lo atrae el jugador) si le sirve
  boolean util() {
    if (tipo == D_MUNICION) return jugador.municion < jugador.municionMax;
    if (tipo == D_CURA) return jugador.vida < jugador.vidaMax;
    return true;
  }

  boolean alcanzable() { return !jugador.enTorre && util(); }

  void actualizar() {
    edad++;
    if (alcanzable()) {   // iman: se acerca al jugador cuando esta cerca
      PVector a = PVector.sub(jugador.pos, pos); float d = a.mag();
      if (d > 0 && d < 70) acc.add(a.setMag(0.6));
    }
    super.actualizar();
    if (torre != null && colision(torre)) separarDe(torre);   // no quedan escondidos bajo la torre
    pos.x = constrain(pos.x, radio, width - radio); pos.y = constrain(pos.y, radio + 46, height - radio);
  }

  boolean murio() { return edad > duracion; }

  color colorTipo() {
    if (tipo == D_MUNICION) return color(220, 180, 70);
    if (tipo == D_CURA) return color(230, 60, 70);
    if (tipo == D_MONEDA) return color(255, 220, 80);
    return color(150, 200, 230);
  }

  void mostrar() {
    if (duracion - edad < 180 && (frameCount / 6) % 2 == 0) return;   // parpadea antes de desaparecer
    float bob = sin(edad * 0.12 + fase) * 2;
    pushMatrix(); translate(pos.x, pos.y); noStroke();
    fill(0, 60); ellipse(0, 6, 12, 5);
    translate(0, bob - 2);
    if (tipo == D_MUNICION) {        // caja de balas
      fill(70, 80, 50); rect(0, 0, 12, 9);
      fill(220, 180, 70); rect(-3, -2, 2, 5); rect(0, -2, 2, 5); rect(3, -2, 2, 5);
    } else if (tipo == D_CURA) {     // botiquin
      fill(240); rect(0, 0, 11, 11);
      fill(210, 40, 50); rect(0, 0, 7, 2); rect(0, 0, 2, 7);
    } else if (tipo == D_MONEDA) {   // moneda girando
      float w = abs(cos(edad * 0.1 + fase)) * 9 + 1;
      fill(200, 150, 30); rect(0, 0, w, 10);
      fill(255, 220, 80); rect(0, 0, max(1, w - 3), 7);
    } else {                         // material
      fill(90, 130, 170); rect(0, 0, 10, 8);
      fill(150, 200, 230); rect(-1, -1, 5, 4);
    }
    popMatrix();
  }
}

// Reparte lo que suelta un zombie al morir. Mas probabilidad de balas/cura si al jugador le faltan.
void soltarDrops(Zombie z) {
  int n = z.tipo == 2 ? 3 : (random(1) < 0.5 ? 1 : 2);   // el botin se divide en 1-3 monedas
  int resto = z.botin;
  for (int i = 0; i < n; i++) {
    int v = (i == n - 1) ? resto : resto / n;
    resto -= v;
    drops.add(new Drop(z.pos, D_MONEDA, v));
  }
  float pMunicion = jugador.municion < 20 ? 0.6 : 0.3;
  if (random(1) < pMunicion) drops.add(new Drop(z.pos, D_MUNICION, (int) random(10, 21)));
  float pCura = jugador.vida < jugador.vidaMax * 0.4 ? 0.16 : 0.06;
  if (random(1) < pCura) drops.add(new Drop(z.pos, D_CURA, 25));
  if (z.tipo == 2 && random(1) < 0.5) drops.add(new Drop(z.pos, D_MATERIAL, 1));   // solo los tanques, y pocos
}

void recoger(Drop d) {
  if (d.tipo == D_MUNICION) jugador.municion = min(jugador.municionMax, jugador.municion + d.cantidad);
  else if (d.tipo == D_CURA) jugador.vida = min(jugador.vidaMax, jugador.vida + d.cantidad);
  else if (d.tipo == D_MONEDA) monedas += d.cantidad;
  else materiales += d.cantidad;
  particulas.emitir(d.pos, 8, d.colorTipo(), 0.5, 2, 3, 18, 0, PI);
}
