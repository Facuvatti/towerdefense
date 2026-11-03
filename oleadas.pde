// Oleadas: bordes aleatorios, reparto no lineal y progresion exponencial.
int[] elegir_lados(int n) {   // n lados distintos (0 arriba, 1 der, 2 abajo, 3 izq)
  ArrayList<Integer> l = new ArrayList<Integer>();
  for (int i = 0; i < 4; i++) l.add(i);
  for (int i = l.size()-1; i > 0; i--) {   // mezcla Fisher-Yates
    int j = (int) random(i + 1);
    int t = l.get(i); l.set(i, l.get(j)); l.set(j, t);
  }
  int[] r = new int[n];
  for (int i = 0; i < n; i++) r[i] = l.get(i);
  return r;
}

int[] repartir_enemigos(int total, int lados) {   // pesos al cuadrado: reparto desigual
  float[] w = new float[lados]; float s = 0;
  for (int i = 0; i < lados; i++) { w[i] = pow(random(0.4, 1), 2) + 0.15; s += w[i]; }
  int[] r = new int[lados]; int asignados = 0;
  for (int i = 0; i < lados; i++) { r[i] = floor(total * w[i] / s); asignados += r[i]; }
  r[0] += total - asignados;
  return r;
}

PVector punto_borde(int lado) {
  float m = 30;
  switch (lado) {
    case 0: return new PVector(random(width), -m);
    case 1: return new PVector(width + m, random(height));
    case 2: return new PVector(random(width), height + m);
    default: return new PVector(-m, random(height));
  }
}

int elegir_tipo() {
  float r = random(1);
  if (oleada >= 4 && r < 0.10) return 2;
  if (oleada >= 2 && r < 0.32) return 1;
  return 0;
}

void inicializar_enemigos(int[] lados, int[] cant) {
  for (int i = 0; i < lados.length; i++)
    for (int k = 0; k < cant[i]; k++) {
      PVector p = punto_borde(lados[i]);
      zombies.add(new Zombie(p.x, p.y, elegir_tipo()));
    }
}

void iniciar_oleada() {
  oleada++;
  int total = min(120, round(5 * pow(1.22, oleada - 1)));   // crecimiento exponencial
  int nLados = constrain(1 + oleada / 2, 1, 4);
  int[] lados = elegir_lados(nLados);
  inicializar_enemigos(lados, repartir_enemigos(total, nLados));
  oleadaConJefe = oleada % 5 == 0;   // cada 5 oleadas vienen jefes (uno mas cada vez)
  if (oleadaConJefe)
    for (int i = 0; i < oleada / 5; i++) { PVector p = punto_borde(lados[i % lados.length]); zombies.add(new Zombie(p.x, p.y, JEFE)); }
  bannerT = 120;
}
