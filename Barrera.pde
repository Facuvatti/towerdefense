// Barreras: se dibujan con el mouse en modo construccion. Gastan madera segun su largo.
// Cada pedazo tiene un largo maximo y entre pedazos queda un hueco por el que pasan los zombies comunes.
// Solo los jefes (mas anchos que el hueco) las rompen a golpes.
final float GROSOR_BARRERA = 8;    // ancho del muro
final float LARGO_MAX = 130;       // largo maximo de cada pedazo
final float HUECO = 32;            // espacio minimo entre barreras (un tanque mide 30, un jefe 44)
final float PASO = 8;              // distancia entre puntos del trazo
final float SEPARACION = HUECO + GROSOR_BARRERA;   // distancia minima entre ejes de dos barreras
final int PUNTOS_VECINOS = ceil(SEPARACION / PASO) + 1;   // puntos del propio trazo que no cuentan para el hueco

class Barrera extends Entidad {
  ArrayList<PVector> puntos = new ArrayList<PVector>();
  float largo = 0;
  float minX, minY, maxX, maxY;            // caja que la contiene (descarte rapido de colisiones)
  float cx, cy;                            // ultimo punto cercano calculado
  PVector tangente = new PVector(1, 0);    // direccion del segmento mas cercano

  Barrera(PVector inicio) {
    super(inicio.x, inicio.y, 14, 40, 0, 0);
    puntos.add(inicio.copy());
    minX = maxX = inicio.x; minY = maxY = inicio.y;
  }

  void mover() {}   // fija (actualizar solo descuenta el flash de golpe)

  boolean solida() { return puntos.size() >= 2; }   // un click solo no es barrera

  void agregar(PVector p) {
    largo += PVector.dist(puntos.get(puntos.size()-1), p);
    puntos.add(p.copy());
    minX = min(minX, p.x); maxX = max(maxX, p.x); minY = min(minY, p.y); maxY = max(maxY, p.y);
    vidaMax += 3 * PASO; vida += 3 * PASO;   // la vida crece con el largo
    pos.set(puntos.get(puntos.size()/2));     // la barra de vida va en el medio
    campoSucio = true;
  }

  boolean lejos(PVector p, float margen) {   // fuera de la caja agrandada: seguro no toca
    return p.x < minX - margen || p.x > maxX + margen || p.y < minY - margen || p.y > maxY + margen;
  }

  // Distancia de p al trazo, usando solo los segmentos hasta el punto 'hasta'. Deja el punto cercano en cx, cy.
  float distancia(PVector p, int hasta) {
    float md = Float.MAX_VALUE;
    cx = puntos.get(0).x; cy = puntos.get(0).y;
    if (hasta < 1) return dist(p.x, p.y, cx, cy);
    for (int i = 0; i < hasta; i++) {
      PVector a = puntos.get(i), b = puntos.get(i+1);
      float abx = b.x - a.x, aby = b.y - a.y, l2 = abx*abx + aby*aby;
      float t = l2 > 0 ? constrain(((p.x - a.x)*abx + (p.y - a.y)*aby) / l2, 0, 1) : 0;
      float qx = a.x + abx*t, qy = a.y + aby*t;
      float d = dist(p.x, p.y, qx, qy);
      if (d < md) { md = d; cx = qx; cy = qy; if (l2 > 0) tangente.set(abx, aby).normalize(); }
    }
    return md;
  }

  float distancia(PVector p) { return distancia(p, puntos.size() - 1); }

  // Resuelve la colision circulo-barrera: empuja la entidad afuera. Devuelve si chocaban.
  boolean empujar(Entidad e) {
    float minimo = e.radio + GROSOR_BARRERA/2;
    if (!solida() || lejos(e.pos, minimo)) return false;
    float d = distancia(e.pos);
    if (d >= minimo) return false;
    float nx = e.pos.x - cx, ny = e.pos.y - cy;
    if (d < 0.001) { nx = -tangente.y; ny = tangente.x; d = 1; }
    e.pos.add(nx / d * (minimo - d), ny / d * (minimo - d));
    return true;
  }

  void trazo(float grosor) {
    strokeWeight(grosor);
    for (int i = 0; i < puntos.size() - 1; i++)
      line(puntos.get(i).x, puntos.get(i).y, puntos.get(i+1).x, puntos.get(i+1).y);
  }

  void mostrar() {
    if (!solida()) return;
    float d = 1 - vida / (float) vidaMax;   // deterioro
    color madera = lerpColor(color(150, 106, 62), color(70, 48, 30), d);
    strokeCap(ROUND);
    pushMatrix(); translate(2, 3); stroke(0, 70); trazo(GROSOR_BARRERA); popMatrix();   // sombra
    stroke(flash > 0 ? color(255) : madera); trazo(GROSOR_BARRERA);
    stroke(lerpColor(madera, color(255), 0.2)); trazo(2);
    noStroke(); fill(lerpColor(madera, color(0), 0.35));   // postes
    for (int i = 0; i < puntos.size(); i += 3) rect(puntos.get(i).x, puntos.get(i).y, 6, 6);
    strokeWeight(1);
    barraVida();
  }
}

// --- Construccion con el mouse ---
Barrera trazoActual = null;
boolean esperarSoltar = false;   // tras cortar un pedazo, hay que soltar el mouse para empezar otro
String avisoBarrera = ""; int avisoBarreraT = 0;

// Devuelve por que no se puede poner un punto ahi, o null si se puede
String motivoInvalido(PVector p, Barrera propia) {
  float borde = HUECO + GROSOR_BARRERA/2;   // tambien queda paso contra los bordes y el HUD
  if (p.x < borde || p.x > width - borde || p.y < 46 + borde || p.y > height - borde) return "Muy cerca del borde";
  if (torre != null && PVector.dist(p, torre.pos) < torre.radio + borde) return "Muy cerca de la torre";
  for (Torre t : torres) if (PVector.dist(p, t.pos) < t.radio + borde) return "Muy cerca de una torreta";
  for (Barrera b : barreras) {
    if (b == propia) {   // el propio trazo tampoco puede volver sobre si mismo y cerrarse
      int hasta = b.puntos.size() - 1 - PUNTOS_VECINOS;
      if (hasta >= 1 && b.distancia(p, hasta) < SEPARACION) return "No cierres la barrera sobre si misma";
    } else if (!b.lejos(p, SEPARACION) && b.distancia(p) < SEPARACION) return "Deja espacio entre barreras";
  }
  return null;
}

void avisar(String s) { avisoBarrera = s; avisoBarreraT = 70; }

void construirBarrera() {
  if (avisoBarreraT > 0) avisoBarreraT--;
  if (!(mousePressed && mouseButton == LEFT)) { terminarTrazo(); esperarSoltar = false; return; }
  if (esperarSoltar) return;
  PVector m = new PVector(mouseX, mouseY);
  if (trazoActual == null) {   // empezar un pedazo nuevo
    if (madera < PASO) { avisar("Sin madera"); return; }
    String err = motivoInvalido(m, null);
    if (err != null) { avisar(err); return; }
    trazoActual = new Barrera(m);
    barreras.add(trazoActual);
    return;
  }
  PVector ult = trazoActual.puntos.get(trazoActual.puntos.size()-1);
  while (PVector.dist(ult, m) >= PASO) {   // avanza de a PASO para validar todo el recorrido
    PVector sig = PVector.add(ult, PVector.sub(m, ult).setMag(PASO));
    String err = trazoActual.largo + PASO > LARGO_MAX ? "Largo maximo" : (madera < PASO ? "Sin madera" : motivoInvalido(sig, trazoActual));
    if (err != null) { avisar(err); terminarTrazo(); esperarSoltar = true; return; }
    trazoActual.agregar(sig);
    madera -= PASO;
    ult = sig;
  }
}

void terminarTrazo() {
  if (trazoActual != null && !trazoActual.solida()) barreras.remove(trazoActual);
  trazoActual = null;
}

void previsualizarBarrera() {   // zonas prohibidas y cursor de construccion
  noFill(); stroke(255, 80, 80, 30); strokeCap(ROUND);
  for (Barrera b : barreras) if (b != trazoActual) b.trazo(2 * SEPARACION);
  strokeWeight(1);
  float borde = HUECO + GROSOR_BARRERA/2;
  if (torre != null) { float r = 2 * (torre.radio + borde); ellipse(torre.pos.x, torre.pos.y, r, r); }
  for (Torre t : torres) { float r = 2 * (t.radio + borde); ellipse(t.pos.x, t.pos.y, r, r); }
  boolean ok = madera >= PASO && motivoInvalido(new PVector(mouseX, mouseY), trazoActual) == null;
  stroke(ok ? color(120, 255, 140, 200) : color(255, 80, 80, 200)); noFill();
  rect(mouseX, mouseY, 10, 10); noStroke();
  String info = trazoActual != null ? round(trazoActual.largo) + " / " + round(LARGO_MAX) : "MADERA " + round(madera);
  texto(info, mouseX, mouseY + 20, 12, color(255, 230), CENTER);
  if (avisoBarreraT > 0) texto(avisoBarrera, mouseX, mouseY - 20, 12, color(255, 120, 100), CENTER);
}

void astillas(PVector p) { particulas.emitir(p, 6, color(150, 105, 60), 0.5, 3, 4, 25, 0, PI); }
