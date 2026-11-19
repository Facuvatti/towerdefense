// Arma: define como dispara el jugador. Se compran en la tienda de la torre.
class Arma {
  String nombre;
  int dano, cooldown, perdigones, alcance, perfora, precio;   // alcance: frames que vive la bala
  float dispersion, velocidad, retroceso, largo;
  color c;
  String creacionId = "";
  JSONArray trazos = null;

  Arma(String nombre, int precio, int dano, int cooldown, int perdigones, float dispersion,
       float velocidad, int alcance, int perfora, float retroceso, float largo, color c) {
    this.nombre = nombre; this.precio = precio; this.dano = dano; this.cooldown = cooldown;
    this.perdigones = perdigones; this.dispersion = dispersion; this.velocidad = velocidad;
    this.alcance = alcance; this.perfora = perfora; this.retroceso = retroceso; this.largo = largo; this.c = c;
  }

  Arma(JSONObject def) {
    this(def.getString("nombre", "Arma creada"), 0, def.getInt("dano", 25),
      def.getInt("cadencia", 140), def.getInt("perdigones", 1), def.getFloat("dispersion", 0.05),
      def.getFloat("velocidad", 11), def.getInt("alcance", 90), def.getInt("perfora", 0),
      def.getFloat("retroceso", 0.6), def.getFloat("largo", 16), def.getInt("tinte", color(255,205,95)));
    creacionId = def.getString("id", "");
    trazos = def.getJSONArray("trazos");
  }

  void disparar(PVector boca, PVector dir) {
    for (int i = 0; i < perdigones; i++) {
      float v = perdigones > 1 ? velocidad * random(0.85, 1.05) : velocidad;
      PVector vel = dir.copy().rotate(random(-dispersion, dispersion)).mult(v);
      balas.add(new Bala(boca.x, boca.y, vel, dano, alcance, perfora));
    }
  }

  String detalle() {
    String d = "Dano " + dano + (perdigones > 1 ? " x" + perdigones : "") + "  |  " + round(60000.0 / cooldown) + " disp/min";
    if (perfora > 0) d += "  |  atraviesa " + perfora;
    return d;
  }
}

ArrayList<Arma> catalogo = new ArrayList<Arma>();   // el indice 0 es el arma inicial

void crearCatalogo() {
  catalogo.clear();
  //                     nombre          precio dano  cd  perd  disp  vel  alc perf retro largo  color
  catalogo.add(new Arma("Pistola",            0,  25, 140,  1, 0.05,  11,  90,  0, 0.6,  16, color(35)));
  catalogo.add(new Arma("Escopeta",         250,  18, 650,  6, 0.35,  10,  28,  0, 2.0,  24, color(90, 60, 40)));
  catalogo.add(new Arma("Francotirador",    350, 120, 900,  1, 0.0,   18,  90,  3, 2.5,  34, color(50, 60, 50)));
  catalogo.add(new Arma("Ametralladora",    450,  14,  70,  1, 0.12,  12,  80,  0, 0.35, 26, color(60, 60, 70)));
}
