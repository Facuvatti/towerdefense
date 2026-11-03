// Barreras: se dibujan con el mouse en modo construccion. Gastan madera segun su largo.
// Cada pedazo tiene un largo maximo y entre pedazos queda un hueco por el que pasan los zombies comunes.
// Solo los jefes (mas anchos que el hueco) las rompen a golpes.
final float GROSOR_BARRERA = 8;    // ancho del muro
final float LARGO_MAX = 130;       // largo maximo de cada pedazo
final float HUECO = 32;            // espacio minimo entre barreras (un tanque mide 30, un jefe 44)
final float PASO = 8;              // distancia entre puntos del trazo

class Barrera extends Entidad {
  ArrayList<PVector> puntos = new ArrayList<PVector>();
  float largo = 0;
  PVector tangente = new PVector(1, 0);   // direccion del segmento mas cercano (lo usa puntoCercano)

  Barrera(PVector inicio) {
    super(inicio.x, inicio.y, 14, 40, 0, 0);
    puntos.add(inicio.copy());
  }

  void mover() {}   // fija

  void agregar(PVector p) {
    largo += PVector.dist(puntos.get(puntos.size()-1), p);
    puntos.add(p.copy());
    vidaMax += 3 * PASO; vida += 3 * PASO;   // la vida crece con el largo
    pos.set(puntos.get(puntos.size()/2));     // la barra de vida va en el medio
  }

  // Punto del trazo mas cercano a p (proyeccion sobre cada segmento)
  PVector puntoCercano(PVector p) {
    PVector mejor = puntos.get(0).copy(); float md = Float.MAX_VALUE;
    for (int i = 0; i < puntos.size() - 1; i++) {
      PVector a = puntos.get(i), b = puntos.get(i+1);
      PVector ab = PVector.sub(b, a);
      float t = ab.magSq() > 0 ? constrain(PVector.sub(p, a).dot(ab) / ab.magSq(), 0, 1) : 0;
      PVector q = PVector.add(a, PVector.mult(ab, t));
      float d = PVector.dist(p, q);
      if (d < md) { md = d; mejor = q; if (ab.magSq() > 0) tangente = ab.normalize(); }
    }
    return mejor;
  }

  float distancia(PVector p) { return PVector.dist(p, puntoCercano(p)); }

  // Resuelve la colision circulo-barrera: empuja la entidad afuera. Devuelve si chocaban.
  boolean empujar(Entidad e) {
    PVector q = puntoCercano(e.pos);
    PVector n = PVector.sub(e.pos, q);
    float d = n.mag(), minimo = e.radio + GROSOR_BARRERA/2;
    if (d >= minimo) return false;
    if (d < 0.001) n = new PVector(-tangente.y, tangente.x);
    e.pos.add(n.setMag(minimo - d));
    return true;
  }

  void trazo(float grosor) {
    strokeWeight(grosor);
    for (int i = 0; i < puntos.size() - 1; i++)
      line(puntos.get(i).x, puntos.get(i).y, puntos.get(i+1).x, puntos.get(i+1).y);
  }

  void mostrar() {
    if (puntos.size() < 2) return;
    float d = 1 - vida / (float) vidaMax;   // deterioro
    color madera = lerpColor(color(150, 106, 62), color(70, 48, 30), d);
    strokeCap(ROUND);
    pushMatrix(); translate(2, 3); stroke(0, 70); trazo(GROSOR_BARRERA); popMatrix();   // sombra
    stroke(flash > 0 ? color(255) : madera); trazo(GROSOR_BARRERA);
    stroke(lerpColor(madera, color(255), 0.2)); trazo(2);
    noStroke(); fill(lerpColor(madera, color(0), 0.35));   // postes
    for (int i = 0; i < puntos.size(); i += 3) rect(puntos.get(i).x, puntos.get(i).y, 6, 6);
    strokeWeight(1); strokeCap(ROUND);
    barraVida();
  }
}

// --- Construccion con el mouse ---
Barrera trazoActual = null;
boolean esperarSoltar = false;   // tras cortar un pedazo, hay que soltar el mouse para empezar otro
String avisoBarrera = ""; int avisoBarreraT = 0;

// Devuelve por que no se puede poner un punto ahi, o null si se puede
String motivoInvalido(PVector p, Barrera propia) {
  if (p.x < GROSOR_BARRERA || p.x > width - GROSOR_BARRERA || p.y < 46 + GROSOR_BARRERA || p.y > height - GROSOR_BARRERA)
    return "Fuera del mapa";
  if (torre != null && PVector.dist(p, torre.pos) < torre.radio + HUECO + GROSOR_BARRERA/2) return "Muy cerca de la torre";
  for (Barrera b : barreras)
    if (b != propia && b.distancia(p) < HUECO + GROSOR_BARRERA) return "Deja espacio entre barreras";
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
  if (trazoActual != null && trazoActual.puntos.size() < 2) barreras.remove(trazoActual);   // un click solo no es barrera
  trazoActual = null;
}

void previsualizarBarrera() {   // zonas prohibidas y cursor de construccion
  noFill(); stroke(255, 80, 80, 30); strokeCap(ROUND);
  for (Barrera b : barreras) if (b != trazoActual) b.trazo(2 * (HUECO + GROSOR_BARRERA));
  if (torre != null) { strokeWeight(1); float r = 2 * (torre.radio + HUECO + GROSOR_BARRERA/2); ellipse(torre.pos.x, torre.pos.y, r, r); }
  strokeWeight(1);
  boolean ok = madera >= PASO && motivoInvalido(new PVector(mouseX, mouseY), trazoActual) == null;
  stroke(ok ? color(120, 255, 140, 200) : color(255, 80, 80, 200)); noFill();
  rect(mouseX, mouseY, 10, 10); noStroke();
  String info = trazoActual != null ? round(trazoActual.largo) + " / " + round(LARGO_MAX) : "MADERA " + round(madera);
  texto(info, mouseX, mouseY + 20, 12, color(255, 230), CENTER);
  if (avisoBarreraT > 0) texto(avisoBarrera, mouseX, mouseY - 20, 12, color(255, 120, 100), CENTER);
}

void astillas(PVector p) { particulas.emitir(p, 6, color(150, 105, 60), 0.5, 3, 4, 25, 0, PI); }
