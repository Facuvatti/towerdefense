// Tienda dentro de la torre central: solo se abre estando arriba. Pausa el juego mientras esta abierta.
final int T_ARMA = 0, T_MUNICION = 1, T_CURA = 2, T_REPARAR = 3, T_MEJORAR = 4, T_MADERA = 5;
final int TORRE_NIVEL_MAX = 5;

class ItemTienda {
  int tipo; Arma arma;

  ItemTienda(int tipo, Arma arma) { this.tipo = tipo; this.arma = arma; }

  String nombre() {
    if (tipo == T_ARMA) return arma.nombre;
    if (tipo == T_MUNICION) return "Municion +30";
    if (tipo == T_CURA) return "Botiquin +50 vida";
    if (tipo == T_REPARAR) return "Reparar torre +150";
    if (tipo == T_MADERA) return "Madera +150";
    return torre.nivel >= TORRE_NIVEL_MAX ? "Torre al maximo" : "Mejorar torre a nivel " + (torre.nivel + 1);
  }

  String detalle() {
    if (tipo == T_ARMA) return arma.detalle();
    if (tipo == T_MUNICION) return "Balas " + jugador.municion + "/" + jugador.municionMax;
    if (tipo == T_CURA) return "Vida " + jugador.vida + "/" + jugador.vidaMax;
    if (tipo == T_REPARAR) return "Torre " + torre.vida + "/" + torre.vidaMax;
    if (tipo == T_MADERA) return "Para barreras (B). Tenes " + round(madera);
    return "+200 vida maxima y la repara 200";
  }

  int precio() {
    if (tipo == T_ARMA) return jugador.armas.contains(arma) ? 0 : arma.precio;
    if (tipo == T_MUNICION) return 40;
    if (tipo == T_CURA) return 50;
    if (tipo == T_REPARAR) return 60;
    if (tipo == T_MADERA) return 40;
    return 120 * torre.nivel;
  }

  int precioMateriales() { return tipo == T_MEJORAR ? torre.nivel : 0; }

  boolean disponible() {   // tiene sentido comprarlo ahora
    if (tipo == T_ARMA) return jugador.arma != arma;
    if (tipo == T_MUNICION) return jugador.municion < jugador.municionMax;
    if (tipo == T_CURA) return jugador.vida < jugador.vidaMax;
    if (tipo == T_REPARAR) return torre.vida < torre.vidaMax;
    if (tipo == T_MADERA) return true;
    return torre.nivel < TORRE_NIVEL_MAX;
  }

  boolean alcanza() { return monedas >= precio() && materiales >= precioMateriales(); }

  String boton() {
    if (tipo == T_ARMA && jugador.armas.contains(arma)) return jugador.arma == arma ? "EQUIPADA" : "EQUIPAR";
    if (!disponible()) return "---";
    String b = "$" + precio();
    if (precioMateriales() > 0) b += " + " + precioMateriales() + " MAT";
    return b;
  }

  void comprar() {
    monedas -= precio(); materiales -= precioMateriales();
    if (tipo == T_ARMA) {
      if (!jugador.armas.contains(arma)) jugador.armas.add(arma);
      jugador.equipar(jugador.armas.indexOf(arma));
    }
    else if (tipo == T_MUNICION) jugador.municion = min(jugador.municionMax, jugador.municion + 30);
    else if (tipo == T_CURA) jugador.vida = min(jugador.vidaMax, jugador.vida + 50);
    else if (tipo == T_REPARAR) torre.vida = min(torre.vidaMax, torre.vida + 150);
    else if (tipo == T_MADERA) madera += 150;
    else torre.mejorar();
  }
}

class Tienda {
  ArrayList<ItemTienda> items = new ArrayList<ItemTienda>();
  float px = 180, py = 80, pw = 600, alto = 42;   // panel y alto de cada fila
  String mensaje = ""; int mensajeT = 0;

  Tienda() {
    for (int i = 1; i < catalogo.size(); i++) items.add(new ItemTienda(T_ARMA, catalogo.get(i)));
    items.add(new ItemTienda(T_ARMA, catalogo.get(0)));   // para volver a la pistola
    items.add(new ItemTienda(T_MUNICION, null));
    items.add(new ItemTienda(T_CURA, null));
    items.add(new ItemTienda(T_REPARAR, null));
    items.add(new ItemTienda(T_MADERA, null));
    items.add(new ItemTienda(T_MEJORAR, null));
  }

  float filaY(int i) { return py + 70 + i * alto; }

  int filaBajoMouse() {
    for (int i = 0; i < items.size(); i++)
      if (mouseX > px + 12 && mouseX < px + pw - 12 && mouseY > filaY(i) && mouseY < filaY(i) + alto - 6) return i;
    return -1;
  }

  void click() {
    int i = filaBajoMouse();
    if (i < 0) return;
    ItemTienda it = items.get(i);
    if (!it.disponible()) return;
    if (!it.alcanza()) { mensaje = it.precioMateriales() > materiales ? "Faltan materiales" : "Falta plata"; mensajeT = 90; return; }
    it.comprar();
    mensaje = it.tipo == T_ARMA ? it.arma.nombre + " equipada" : "Comprado"; mensajeT = 60;
  }

  void mostrar() {
    float ph = 70 + items.size() * alto + 40;
    rectMode(CORNER); noStroke();
    fill(0, 140); rect(0, 46, width, height - 46);
    fill(28, 24, 22); rect(px, py, pw, ph);
    fill(70, 58, 48); rect(px, py, pw, 4); rect(px, py + ph - 4, pw, 4);
    texto("TIENDA DE LA TORRE", width/2, py + 26, 24, color(255, 220, 80), CENTER);
    texto("Nivel de torre " + torre.nivel + "   |   $ " + monedas + "   |   MAT " + materiales, width/2, py + 52, 13, color(200), CENTER);
    int hover = filaBajoMouse();
    for (int i = 0; i < items.size(); i++) {
      ItemTienda it = items.get(i);
      float y = filaY(i);
      boolean activo = it.disponible() && it.alcanza();
      fill(i == hover && it.disponible() ? color(70, 62, 52) : color(44, 38, 34)); rect(px + 12, y, pw - 24, alto - 6);
      texto(it.nombre(), px + 26, y + 13, 15, it.disponible() ? color(240) : color(130), LEFT);
      texto(it.detalle(), px + 26, y + 29, 11, color(160), LEFT);
      color cb = !it.disponible() ? color(110) : (activo ? color(120, 240, 130) : color(230, 90, 80));
      texto(it.boton(), px + pw - 26, y + 20, 15, cb, RIGHT);
    }
    String pie = mensajeT > 0 ? mensaje : Character.toUpperCase(jugador.controles.get("tienda")) + ": cerrar   |   1-" + jugador.armas.size() + ": cambiar arma";
    texto(pie, width/2, py + ph - 22, 13, mensajeT > 0 ? color(255, 220, 80) : color(170), CENTER);
    if (mensajeT > 0) mensajeT--;
    rectMode(CENTER);
  }
}
