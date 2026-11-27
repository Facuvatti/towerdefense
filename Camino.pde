// Camino: calcula por donde tienen que avanzar los zombies para rodear las barreras.
// Divide el mapa en celdas y calcula la distancia desde cada celda hasta los objetivos.
// Cada zombie elige una celda vecina que esté mas cerca de un objetivo.

final int CELDA = 8;                 // ancho y alto de cada celda, en pixeles
final float MARGEN_CAMINO = 15;      // espacio extra alrededor de las barreras

int cols, filas;                     // cantidad de columnas y filas del mapa
int[] distCampo, cola;               // distancia al objetivo y cola usada por el recorrido BFS
boolean[] bloqueada;                 // indica si una celda está ocupada por una barrera
boolean campoSucio = true;           // indica que hay que volver a calcular las celdas bloqueadas
int campoT = 0;                      // espera entre actualizaciones del camino

// Ocho direcciones posibles: incluye diagonales para que los zombies puedan moverse libremente.
final int[] DIR_X = {0, 1, 1, 1, 0, -1, -1, -1};
final int[] DIR_Y = {-1, -1, 0, 1, 1, 1, 0, -1};

// Prepara los arreglos según el tamaño de la ventana.
void iniciarCampo() {
  cols = ceil(width / (float) CELDA);                 // calcula cuántas columnas entran
  filas = ceil(height / (float) CELDA);               // calcula cuántas filas entran
  distCampo = new int[cols * filas];                  // reserva una distancia por celda
  cola = new int[cols * filas];                       // reserva espacio para recorrer las celdas
  bloqueada = new boolean[cols * filas];              // reserva el estado de bloqueo de cada celda
  campoSucio = true;                                  // fuerza el primer cálculo
  campoT = 0;                                         // permite actualizar inmediatamente
}

// Devuelve true si existe al menos una barrera que todavía esté en el mapa.
boolean hayBarreras() {
  for (Barrera b : barreras) {                        // revisa todas las barreras
    if (b.solida()) return true;                      // alcanza con encontrar una sólida
  }
  return false;                                       // no hay obstáculos que rodear
}

// Marca como bloqueadas las celdas que están demasiado cerca de una barrera.
void bloquearCeldas() {
  for (int i = 0; i < bloqueada.length; i++) {        // recorre todas las celdas
    bloqueada[i] = false;                             // empieza suponiendo que están libres
  }

  float margen = GROSOR_BARRERA / 2 + MARGEN_CAMINO;  // grosor de la barrera más espacio de seguridad
  PVector centroCelda = new PVector();                // punto reutilizable para medir distancias

  for (Barrera b : barreras) {                        // revisa cada barrera
    if (!b.solida()) continue;                        // ignora las barreras destruidas

    // Limita el cálculo al rectángulo cercano a la barrera para no revisar todo el mapa.
    int xMin = max(0, floor((b.minX - margen) / CELDA));
    int xMax = min(cols - 1, floor((b.maxX + margen) / CELDA));
    int yMin = max(0, floor((b.minY - margen) / CELDA));
    int yMax = min(filas - 1, floor((b.maxY + margen) / CELDA));

    for (int y = yMin; y <= yMax; y++) {              // recorre las filas cercanas
      for (int x = xMin; x <= xMax; x++) {            // recorre las columnas cercanas
        centroCelda.set(x * CELDA + CELDA / 2, y * CELDA + CELDA / 2); // obtiene el centro de la celda
        if (b.distancia(centroCelda) < margen) {      // comprueba si está demasiado cerca
          bloqueada[y * cols + x] = true;             // impide que el camino pase por ahí
        }
      }
    }
  }

  campoSucio = false;                                 // las celdas bloqueadas ya están actualizadas
}

// Agrega a la cola las celdas que forman parte del objetivo.
void sembrar(PVector objetivo, float radio, int[] fin) {
  // Calcula qué celdas están dentro del área aproximada del objetivo.
  int xMin = max(0, floor((objetivo.x - radio) / CELDA));
  int xMax = min(cols - 1, floor((objetivo.x + radio) / CELDA));
  int yMin = max(0, floor((objetivo.y - radio) / CELDA));
  int yMax = min(filas - 1, floor((objetivo.y + radio) / CELDA));

  for (int y = yMin; y <= yMax; y++) {                // recorre las filas del área
    for (int x = xMin; x <= xMax; x++) {              // recorre las columnas del área
      int i = y * cols + x;                           // convierte coordenadas de grilla en índice

      if (distCampo[i] == -1 && !bloqueada[i]) {      // evita repetir celdas y evita objetivos bloqueados
        distCampo[i] = 0;                             // el objetivo tiene distancia cero
        cola[fin[0]++] = i;                           // agrega la celda a la cola del BFS
      }
    }
  }
}

// Calcula las distancias desde los objetivos hacia el resto del mapa.
void actualizarCampo() {
  if (!hayBarreras()) return;                         // sin barreras, el zombie puede ir directo al objetivo

  if (campoSucio) {                                   // si cambió alguna barrera
    bloquearCeldas();                                 // actualiza qué celdas no se pueden usar
  } else if (campoT-- > 0) {                          // si no cambió nada y todavía hay espera
    return;                                           // mantiene el cálculo anterior
  }

  campoT = 6;                                         // vuelve a calcular cada seis frames
  for (int i = 0; i < distCampo.length; i++) {
    distCampo[i] = -1;                                // -1 significa que todavía no hay camino conocido
  }

  int[] fin = {0};                                    // posición donde se agregará la próxima celda a la cola

  // Si el jugador está fuera de la torre, es un objetivo.
  // También lo es siempre que la torre ya no exista: así no queda el campo sin destinos.
  if (!jugador.enTorre || torre == null) {
    sembrar(jugador.pos, jugador.radio + CELDA, fin);
  }

  if (torre != null) {                                // si la torre sigue en pie
    sembrar(torre.pos, torre.radio + CELDA, fin);     // los zombies también pueden dirigirse a ella
  }

  for (Torre t : torres) {                             // revisa las torretas construidas
    sembrar(t.pos, t.radio + CELDA, fin);             // cada torreta también es un objetivo
  }

  // BFS: expande el recorrido desde los objetivos hacia las celdas vecinas.
  int inicio = 0;                                     // primera posición pendiente de procesar
  while (inicio < fin[0]) {                           // continúa mientras queden celdas en la cola
    int actual = cola[inicio++];                      // toma la próxima celda
    int x = actual % cols;                            // obtiene su columna
    int y = actual / cols;                            // obtiene su fila

    for (int d = 0; d < 8; d++) {                     // prueba las ocho direcciones, incluidas las diagonales
      int nx = x + DIR_X[d];                          // columna de la celda vecina
      int ny = y + DIR_Y[d];                          // fila de la celda vecina

      if (nx < 0 || ny < 0 || nx >= cols || ny >= filas) continue; // evita salir del mapa

      int vecino = ny * cols + nx;                    // convierte la posición vecina en índice
      if (bloqueada[vecino]) continue;                // no atraviesa barreras
      if (distCampo[vecino] != -1) continue;          // no procesa dos veces la misma celda

      // Evita cruzar en diagonal entre dos celdas bloqueadas (cortar una esquina).
      if (DIR_X[d] != 0 && DIR_Y[d] != 0) {
        int lateralX = y * cols + nx;                 // celda horizontal contigua
        int lateralY = ny * cols + x;                 // celda vertical contigua
        if (bloqueada[lateralX] || bloqueada[lateralY]) continue;
      }

      distCampo[vecino] = distCampo[actual] + 1;      // la vecina está un paso más lejos del objetivo
      cola[fin[0]++] = vecino;                        // agrega la vecina para procesarla después
    }
  }
}

// Devuelve hacia qué lado debe avanzar un zombie según las distancias calculadas.
// Devuelve null si no hay barreras, si ya llegó o si no existe un camino calculado.
PVector direccionCampo(PVector posicion) {
  if (!hayBarreras()) return null;                    // sin barreras se usa el movimiento directo

  int x = constrain(floor(posicion.x / CELDA), 0, cols - 1); // columna donde está el zombie
  int y = constrain(floor(posicion.y / CELDA), 0, filas - 1); // fila donde está el zombie
  int actual = y * cols + x;                          // índice de la celda actual
  int distanciaActual = distCampo[actual];            // distancia de esa celda al objetivo

  if (distanciaActual == 0) return null;              // ya está dentro del área del objetivo

  int mejorDireccion = -1;                            // todavía no encontró una salida
  int menorDistancia = distanciaActual >= 0 ? distanciaActual : Integer.MAX_VALUE;

  for (int d = 0; d < 8; d++) {                       // revisa las ocho celdas vecinas
    int nx = x + DIR_X[d];                            // columna vecina
    int ny = y + DIR_Y[d];                             // fila vecina

    if (nx < 0 || ny < 0 || nx >= cols || ny >= filas) continue; // ignora posiciones fuera del mapa

    int vecino = ny * cols + nx;                      // índice de la celda vecina
    int distanciaVecina = distCampo[vecino];          // distancia de la vecina al objetivo

    if (distanciaVecina >= 0 && distanciaVecina < menorDistancia) {
      menorDistancia = distanciaVecina;               // guarda la nueva distancia más corta
      mejorDireccion = d;                              // guarda qué dirección lleva a esa celda
    }
  }

  if (mejorDireccion == -1) return null;               // no encontró una celda que acerque al objetivo

  // Normaliza el movimiento para que en diagonal no avance más rápido.
  return new PVector(DIR_X[mejorDireccion], DIR_Y[mejorDireccion]).normalize();
}
