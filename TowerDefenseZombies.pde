// TOWER DEFENSE ZOMBIES - Facundo Vattino & Santiago Villarroel
// Main: estados, bucle, colisiones globales, HUD y menu.
final int MENU = 0, JUEGO = 1, PAUSA = 2, FIN = 3, TIENDA = 4, IDENTIDAD = 5, SELECCION = 6, EDITOR = 7;
final int CENTRO_Y = 343;   // centro del area jugable (debajo del HUD)
int estado = MENU;
Jugador jugador;
ArrayList<Zombie> zombies = new ArrayList<Zombie>();
ArrayList<Bala> balas = new ArrayList<Bala>();
ArrayList<Torre> torres = new ArrayList<Torre>();
ArrayList<Drop> drops = new ArrayList<Drop>();
ArrayList<Barrera> barreras = new ArrayList<Barrera>();
boolean modoBarrera = false, oleadaConJefe = false;
float madera = 300;   // largo de barrera disponible (px)
TorreCentral torre;   // null cuando fue destruida
Tienda tienda;
SistemaParticulas particulas = new SistemaParticulas();
HashMap<Character, Boolean> teclas = new HashMap<Character, Boolean>();
PGraphics fondo;
int oleada = 0, monedas = 0, materiales = 0, puntaje = 0, cuentaAtras = 0, bannerT = 0, avisoT = 0, remapIdx = -1;
float shake = 0;
String[] acciones = {"arriba", "abajo", "izquierda", "derecha", "torre", "tienda", "barrera"};
BaseDatos baseDatos = new BaseDatos();
String entradaJugador = "";
ArrayList<JSONObject> partidasDisponibles = new ArrayList<JSONObject>();
int partidaSeleccionada = 0;

void setup() {
  size(960, 640);
  noSmooth();
  baseDatos.cargar();
  iniciarCampo();
  textFont(createFont("Monospaced.bold", 16));
  crearFondo();
  crearCatalogo();
  torre = new TorreCentral(width/2, CENTRO_Y);
  jugador = new Jugador(width/2, CENTRO_Y + 70);
  tienda = new Tienda();
}

void nuevaPartida() {
  zombies.clear(); balas.clear(); torres.clear(); drops.clear(); barreras.clear(); particulas.lista.clear();
  trazoActual = null; modoBarrera = false; esperarSoltar = false; madera = 300; oleadaConJefe = false;
  iniciarCampo();
  crearFondo();
  torre = new TorreCentral(width/2, CENTRO_Y);
  jugador.reiniciar(width/2, CENTRO_Y + 70);
  baseDatos.agregarArmasCreadas();
  oleada = 0; puntaje = 0; monedas = 150; materiales = 0; cuentaAtras = 200; bannerT = 0; avisoT = 0;
  estado = JUEGO;
  baseDatos.crearNuevaPartida();
}

void draw() {
  background(0);
  if (estado == MENU) { dibujarMenu(); return; }
  if (estado == IDENTIDAD) { dibujarIdentidad(); return; }
  if (estado == SELECCION) { dibujarSelectorPartidas(); return; }
  if (estado == EDITOR) { dibujarEditor(); return; }
  if (estado == JUEGO) actualizarJuego();
  dibujarJuego();
  if (estado == PAUSA) overlay("PAUSA", "P para continuar");
  if (estado == TIENDA) tienda.mostrar();
  if (estado == FIN) overlay("GAME OVER", "Oleada " + oleada + "   Puntaje " + puntaje + "\nENTER para reiniciar");
}

void actualizarJuego() {
  jugador.actualizar();
  if (modoBarrera) construirBarrera();   // en modo construccion el click dibuja en vez de disparar
  else if (mousePressed && mouseButton == LEFT) jugador.disparar();
  for (Barrera b : barreras) b.actualizar();   // descuenta el flash de golpe
  actualizarCampo();
  for (Zombie z : zombies) z.actualizar();
  for (Bala b : balas) b.actualizar();
  for (Torre t : torres) t.actualizar();
  if (torre != null) torre.actualizar();
  for (Drop d : drops) d.actualizar();

  // Impactos bala -> zombie
  for (Bala b : balas)
    for (Zombie z : zombies)
      if (b.vida > 0 && !b.golpeados.contains(z) && b.colision(z)) {
        z.herir(b.dano); particulas.sangre(b.pos, 5);
        if (b.perfora > 0) { b.perfora--; b.golpeados.add(z); }   // atraviesa y sigue
        else { b.vida = 0; break; }
      }

  // Limpieza de listas (recorrido inverso: sin fugas ni saltos)
  for (int i = zombies.size()-1; i >= 0; i--) {
    Zombie z = zombies.get(i);
    if (z.murio()) { puntaje += z.puntos; soltarDrops(z); particulas.sangre(z.pos, 24); mancha(z.pos); zombies.remove(i); }
  }
  for (int i = balas.size()-1; i >= 0; i--) if (balas.get(i).murio()) balas.remove(i);
  for (int i = barreras.size()-1; i >= 0; i--) {
    Barrera b = barreras.get(i);
    if (b.murio()) {
      for (int k = 0; k < b.puntos.size(); k += 2) astillas(b.puntos.get(k));
      if (b == trazoActual) trazoActual = null;
      barreras.remove(i); campoSucio = true;
    }
  }
  for (int i = drops.size()-1; i >= 0; i--) {   // recoleccion al pasar por arriba
    Drop d = drops.get(i);
    if (d.alcanzable() && d.colision(jugador)) { recoger(d); drops.remove(i); }
    else if (d.murio()) drops.remove(i);
  }
  for (int i = torres.size()-1; i >= 0; i--) {
    if (torres.get(i).murio()) { particulas.explosion(torres.get(i).pos); shake = 8; torres.remove(i); }
  }
  if (torre != null && torre.murio()) {   // cae la torre central: el jugador baja y no puede volver
    if (jugador.enTorre) jugador.bajar();
    particulas.explosion(torre.pos); particulas.explosion(torre.pos);
    escombros(torre.pos); shake = 14; avisoT = 180;
    torre = null;
  }
  particulas.actualizar();
  if (jugador.murio() && estado != FIN) { estado = FIN; particulas.explosion(jugador.pos); shake = 12; baseDatos.guardarPartida(true); }
  if (estado == JUEGO && frameCount % 120 == 0) baseDatos.guardarPartida(false);

  // Flujo de oleadas
  if (zombies.isEmpty()) {
    if (cuentaAtras <= 0 && oleada >= 0) {
      if (oleada > 0) {
        monedas += 20*oleada; jugador.vida = min(jugador.vidaMax, jugador.vida + 25);
        jugador.municion = min(jugador.municionMax, jugador.municion + 20);   // para no quedar trabado sin balas
      }
      cuentaAtras = 210;
    } else if (--cuentaAtras <= 0) { iniciar_oleada(); }
  }
  if (bannerT > 0) bannerT--;
  if (avisoT > 0) avisoT--;
}

void mancha(PVector p) {
  fondo.beginDraw(); fondo.noStroke(); fondo.fill(100, 10, 20, 110);
  fondo.rect(p.x - 6, p.y - 4, random(6, 14), random(5, 10)); fondo.endDraw();
}

void escombros(PVector p) {
  fondo.beginDraw(); fondo.noStroke();
  for (int i = 0; i < 26; i++) {
    fondo.fill(random(50, 110), random(46, 100), random(40, 90));
    fondo.rect(p.x + random(-40, 40), p.y + random(-40, 40), random(4, 12), random(4, 10));
  }
  fondo.endDraw();
}

void dibujarJuego() {
  rectMode(CENTER);
  pushMatrix();
  translate(random(-shake, shake), random(-shake, shake)); shake *= 0.85;
  image(fondo, 0, 0);
  for (Drop d : drops) d.mostrar();
  for (Barrera b : barreras) b.mostrar();
  if (torre != null) torre.mostrar();
  for (Torre t : torres) t.mostrar();
  for (Zombie z : zombies) z.mostrar();
  for (Bala b : balas) b.mostrar();
  if (estado != FIN) jugador.mostrar();
  particulas.mostrar();
  if (estado == JUEGO) { if (modoBarrera) previsualizarBarrera(); else previsualizarTorre(); indicadorTorre(); }
  popMatrix();
  dibujarHUD();
}

void previsualizarTorre() {
  String err = motivoTorreta(mouseX, mouseY);
  boolean ok = err == null;
  noFill(); stroke(255, 80, 80, 40);   // zona donde no entra otra torreta
  for (Torre t : torres) ellipse(t.pos.x, t.pos.y, 2 * DIST_TORRETAS, 2 * DIST_TORRETAS);
  stroke(ok ? color(120, 255, 140, 90) : color(255, 80, 80, 90));
  ellipse(mouseX, mouseY, 440, 440);
  noStroke(); fill(ok ? color(120, 255, 140, 120) : color(255, 80, 80, 120));
  rect(mouseX, mouseY, 28, 28);
  if (!ok && !err.equals("Falta plata")) texto(err, mouseX, mouseY - 26, 12, color(255, 120, 100), CENTER);
}

void indicadorTorre() {   // aviso de la tecla para subir/bajar
  if (jugador.sinBalasT > 0) texto("SIN BALAS", jugador.pos.x, jugador.pos.y - 32, 12, color(255, 90, 80), CENTER);
  String tecla = str(Character.toUpperCase(jugador.controles.get("torre")));
  if (jugador.enTorre)
    texto(tecla + ": bajar   " + Character.toUpperCase(jugador.controles.get("tienda")) + ": tienda",
          jugador.pos.x, jugador.pos.y + torre.radio + 16, 12, color(255, 230), CENTER);
  else if (jugador.cercaDeTorre())
    texto(tecla + ": subir", torre.pos.x, torre.pos.y + torre.radio + 18, 12,
          jugador.puedeCambiarTorre() ? color(255, 230) : color(160, 160), CENTER);
}

void dibujarHUD() {
  rectMode(CORNER); noStroke(); fill(0, 150); rect(0, 0, width, 46);
  barra(16, 15, 140, 16, jugador.vida / (float) jugador.vidaMax, color(210, 50, 60));
  texto("HP " + max(0, jugador.vida), 86, 23, 12, color(255), CENTER);
  if (torre != null) {
    barra(170, 15, 140, 16, torre.vida / (float) torre.vidaMax, color(150, 150, 165));
    texto("TORRE " + max(0, torre.vida), 240, 23, 12, color(255), CENTER);
  } else texto("TORRE CAIDA", 240, 23, 12, color(230, 70, 60), CENTER);
  texto("OLEADA " + oleada, 326, 23, 18, color(255, 220, 80), LEFT);
  boolean pocas = jugador.municion < 15;
  if (!(jugador.municion == 0 && (frameCount / 15) % 2 == 0))   // parpadea sin balas
    texto("BALAS " + jugador.municion, 446, 23, 18, pocas ? color(255, 90, 80) : color(220, 180, 70), LEFT);
  texto("$ " + monedas, 580, 23, 18, color(110, 240, 130), LEFT);
  texto("MAT " + materiales, 670, 23, 18, color(150, 200, 230), LEFT);
  texto("PUNTOS " + puntaje, width - 16, 23, 18, color(255), RIGHT);
  texto("WASD mover  |  " + Character.toUpperCase(jugador.controles.get("torre")) + " subir/bajar torre  |  "
        + (modoBarrera ? "Click izq. arrastrar: dibujar barrera" : "Click izq. disparar  |  Click der. torreta ($" + COSTO_TORRE + ")") + "  |  P pausa",
        width/2, height - 16, 12, color(210, 210, 210, 200), CENTER);
  String b = str(Character.toUpperCase(jugador.controles.get("barrera")));
  texto("ARMA: " + jugador.arma.nombre + (jugador.armas.size() > 1 ? "  [1-" + jugador.armas.size() + "]" : "")
        + "     MADERA " + round(madera) + (modoBarrera ? "  [CONSTRUYENDO - " + b + " para salir]" : "  [" + b + " barreras]"),
        16, height - 40, 13, modoBarrera ? color(255, 220, 80) : color(230), LEFT);
  if (avisoT > 0) texto("LA TORRE CAYO", width/2, height*0.42, 40, color(230, 70, 60, min(255, avisoT*4)), CENTER);
  if (bannerT > 0) {
    texto("OLEADA " + oleada, width/2, height*0.3, 56, color(255, 220, 80, min(255, bannerT*4)), CENTER);
    if (oleadaConJefe) texto("JEFE A LA VISTA", width/2, height*0.3 + 50, 24, color(230, 70, 90, min(255, bannerT*4)), CENTER);
  }
  else if (estado == JUEGO && zombies.isEmpty() && oleada > 0)
    texto("Siguiente oleada en " + ceil(cuentaAtras/60.0) + "  (+$" + 20*oleada + "  +20 balas)", width/2, height*0.3, 22, color(255), CENTER);
  rectMode(CENTER);
}

void dibujarMenu() {
  rectMode(CORNER); image(fondo,0,0); noStroke(); fill(0,175); rect(0,0,width,height);
  float p=sin(frameCount*0.06)*5;
  texto("TOWER DEFENSE",width/2,115+p,58,color(120,220,90),CENTER);
  texto("ZOMBIES",width/2,190-p,74,color(220,60,60),CENTER);
  texto("Facundo Vattino & Santiago Villarroel",width/2,245,14,color(190),CENTER);
  boolean hJ=abs(mouseX-width/2)<130 && abs(mouseY-345)<27;
  rectMode(CENTER); fill(hJ?color(90,190,80):color(50,120,55)); stroke(20); strokeWeight(3);
  rect(width/2,345,260,54); noStroke(); texto("JUGAR",width/2,345,26,color(255),CENTER);
  boolean hE=abs(mouseX-width/2)<145 && abs(mouseY-420)<27;
  fill(hE?color(190,130,55):color(115,85,42)); stroke(20); rect(width/2,420,290,48); noStroke();
  texto("CREAR ARMAS / ZOMBIS",width/2,420,17,color(255),CENTER);
  String c="";
  for(String accion:acciones) c+=accion.toUpperCase()+": "+Character.toUpperCase(jugador.controles.get(accion))+"   ";
  texto(c,width/2,500,13,color(230),CENTER);
  texto(remapIdx>=0?"Presiona la tecla para "+acciones[remapIdx].toUpperCase():"R: reasignar controles | ENTER: jugar | E: editor",
    width/2,530,14,remapIdx>=0?color(255,220,80):color(170),CENTER);
}

void dibujarIdentidad() {
  background(13,20,18);
  texto("¿QUIÉN ESTÁ JUGANDO?",width/2,190,38,color(150,220,120),CENTER);
  texto("Escribí tu nombre y presioná ENTER",width/2,260,19,color(220),CENTER);
  rectMode(CENTER); stroke(130,170,120); fill(30,45,35); rect(width/2,335,420,58); noStroke();
  texto(entradaJugador+"_",width/2,335,25,color(255),CENTER);
  texto("Las partidas y puntajes quedan asociados a este jugador.",width/2,410,15,color(170),CENTER);
  texto("ESC: volver al menú",width/2,500,14,color(150),CENTER);
}

void dibujarSelectorPartidas() {
  background(13,20,18);
  texto("HOLA, "+baseDatos.jugadorActual.toUpperCase(),width/2,90,30,color(150,220,120),CENTER);
  texto("PARTIDAS GUARDADAS",width/2,145,22,color(235),CENTER);
  if(partidasDisponibles.size()==0) texto("No tenés partidas pendientes.",width/2,240,19,color(190),CENTER);
  else {
    int primero=max(0,min(partidaSeleccionada-3,partidasDisponibles.size()-6));
    int ultimo=min(partidasDisponibles.size(),primero+6);
    for(int i=primero;i<ultimo;i++) {
      JSONObject p=partidasDisponibles.get(i); float y=205+(i-primero)*50;
      fill(i==partidaSeleccionada?color(70,110,65):color(35,48,40));
      rectMode(CENTER); rect(width/2,y,660,42);
      texto((i+1)+". Oleada "+p.getInt("oleada",0)+" | Puntaje "+p.getInt("puntaje",0)+
        " | $"+p.getInt("monedas",0)+" | "+p.getString("actualizada",""),width/2,y,13,color(255),CENTER);
    }
  }
  texto("↑ / ↓ elegir | ENTER reanudar | N nueva partida | ESC menú",width/2,555,14,color(210),CENTER);
}
void overlay(String t, String s) {
  rectMode(CORNER); noStroke(); fill(0, 160); rect(0, 0, width, height);
  texto(t, width/2, height/2 - 30, 60, color(230, 70, 60), CENTER);
  texto(s, width/2, height/2 + 40, 18, color(255), CENTER);
  rectMode(CENTER);
}

void barra(float x, float y, float w, float h, float pct, color c) {
  rectMode(CORNER); noStroke();
  fill(0, 180); rect(x-2, y-2, w+4, h+4);
  fill(60); rect(x, y, w, h);
  fill(c); rect(x, y, w * constrain(pct, 0, 1), h);
  fill(255, 50); rect(x, y, w * constrain(pct, 0, 1), h*0.4);
  rectMode(CENTER);
}

void texto(String s, float x, float y, int sz, color c, int al) {
  textAlign(al, CENTER); textSize(sz);
  fill(0, 190); text(s, x+2, y+2); fill(c); text(s, x, y);
}

void crearFondo() {
  fondo = createGraphics(width, height);
  fondo.beginDraw(); fondo.noStroke(); fondo.noSmooth();
  randomSeed(7); noiseSeed(7);
  int t = 16;
  for (int y = 0; y < height; y += t) for (int x = 0; x < width; x += t) {
    color c = lerpColor(color(38, 84, 46), color(66, 122, 60), noise(x*0.02, y*0.02));
    if (random(1) < 0.15) c = lerpColor(c, color(28, 66, 38), 0.5);
    float d = dist(x, y, width/2, height/2) / (width*0.6);
    c = lerpColor(c, color(8, 16, 12), constrain(d*d*0.75, 0, 0.75));
    fondo.fill(c); fondo.rect(x, y, t, t);
    if (random(1) < 0.08) { fondo.fill(96, 156, 84); fondo.rect(x + (int) random(12), y + (int) random(12), 2, 4); }
    if (random(1) < 0.012) { fondo.fill(90, 92, 100); fondo.rect(x, y+2, 8, 6); fondo.fill(140, 142, 150); fondo.rect(x, y+2, 8, 2); }
  }
  fondo.endDraw();
  randomSeed(millis());
}

void mousePressed() {
  if(estado==MENU) {
    if(remapIdx<0 && abs(mouseX-width/2)<130 && abs(mouseY-345)<27) {
      entradaJugador=baseDatos.jugadorActual; estado=IDENTIDAD;
    } else if(abs(mouseX-width/2)<145 && abs(mouseY-420)<27) { tipoCreacion="ARMA"; abrirEditor(); }
    return;
  }
  if(estado==EDITOR) {
    if(mouseX>=EDITOR_X && mouseX<=EDITOR_X+EDITOR_W && mouseY>=EDITOR_Y && mouseY<=EDITOR_Y+EDITOR_H) {
      trazoActualEditor=new ArrayList<PVector>(); trazoActualEditor.add(new PVector(mouseX,mouseY)); trazosEditor.add(trazoActualEditor);
    } else if(mouseX>=38 && mouseX<=237 && mouseY>=205 && mouseY<=205+27*atributosCreacion.length) {
      int idx=constrain(floor((mouseY-205)/27),0,atributosCreacion.length-1);
      atributoSeleccionado=idx;
      if(mouseX>=185) modificarAtributo(idx,mouseButton==RIGHT?-1:1);
    }
    return;
  }
  if(estado==TIENDA) { if(mouseButton==LEFT) { tienda.click(); baseDatos.guardarPartida(false); } return; }
  if(estado==JUEGO && !modoBarrera && mouseButton==RIGHT && motivoTorreta(mouseX,mouseY)==null) {
    monedas-=COSTO_TORRE; torres.add(new Torre(mouseX,mouseY));
  }
}
void mouseDragged() {
  if(estado==EDITOR && trazoActualEditor!=null && mouseX>=EDITOR_X && mouseX<=EDITOR_X+EDITOR_W &&
      mouseY>=EDITOR_Y && mouseY<=EDITOR_Y+EDITOR_H) {
    if(dist(mouseX,mouseY,trazoActualEditor.get(trazoActualEditor.size()-1).x,
      trazoActualEditor.get(trazoActualEditor.size()-1).y)>2) trazoActualEditor.add(new PVector(mouseX,mouseY));
  }
}
void mouseReleased() { if(estado==EDITOR) trazoActualEditor=null; }
void keyPressed() {
  boolean enter=(key==ENTER || key==RETURN); char k=Character.toLowerCase(key);
  if(estado==EDITOR) {
    if(key==CODED) {
      if(keyCode==UP) modificarAtributo(atributoSeleccionado,1);
      if(keyCode==DOWN) modificarAtributo(atributoSeleccionado,-1);
      return;
    }
    if(key==ESC) { key=0; estado=MENU; return; }
    if(key==TAB) { tipoCreacion=tipoCreacion.equals("ARMA")?"ZOMBIE":"ARMA"; abrirEditor(); return; }
    if(key==DELETE) { trazosEditor.clear(); trazoActualEditor=null; return; }
    if(enter) { guardarCreacionActual(); return; }
    if(key>='1' && key<='9' && key-'1'<atributosCreacion.length) { atributoSeleccionado=key-'1'; return; }
    if(key==BACKSPACE) { if(nombreCreacion.length()>0) nombreCreacion=nombreCreacion.substring(0,nombreCreacion.length()-1); }
    else if(key>=32 && key<=126 && nombreCreacion.length()<24) nombreCreacion+=key;
    return;
  }
  if(estado==IDENTIDAD) {
    if(key==ESC) { key=0; estado=MENU; return; }
    if(key==BACKSPACE) { if(entradaJugador.length()>0) entradaJugador=entradaJugador.substring(0,entradaJugador.length()-1); }
    else if(enter) {
      if(entradaJugador.trim().length()>0) {
        baseDatos.registrarJugador(entradaJugador); partidasDisponibles=baseDatos.partidasActivas(baseDatos.jugadorActual);
        partidaSeleccionada=0; if(partidasDisponibles.size()>0) estado=SELECCION; else nuevaPartida();
      }
    } else if(key>=32 && key<=126 && entradaJugador.length()<22) entradaJugador+=key;
    return;
  }
  if(estado==SELECCION) {
    if(key==CODED) {
      if(keyCode==UP && partidasDisponibles.size()>0) partidaSeleccionada=max(0,partidaSeleccionada-1);
      if(keyCode==DOWN && partidasDisponibles.size()>0) partidaSeleccionada=min(partidasDisponibles.size()-1,partidaSeleccionada+1);
      return;
    }
    if(key==ESC) { key=0; estado=MENU; return; }
    if(k=='n') { nuevaPartida(); return; }
    if(enter && partidasDisponibles.size()>0) { baseDatos.reanudarPartida(partidasDisponibles.get(partidaSeleccionada)); return; }
    return;
  }
  if(key==CODED) return;
  if(estado==MENU) {
    if(remapIdx>=0 && !enter) {
      jugador.controles.put(acciones[remapIdx],k); remapIdx=(remapIdx+1>=acciones.length)?-1:remapIdx+1;
    } else if(k=='r') remapIdx=0;
    else if(k=='e') { tipoCreacion="ARMA"; abrirEditor(); }
    else if(enter) { entradaJugador=baseDatos.jugadorActual; estado=IDENTIDAD; }
    return;
  }
  if(k=='p' && estado==JUEGO) { estado=PAUSA; baseDatos.guardarPartida(false); }
  else if(k=='p' && estado==PAUSA) estado=JUEGO;
  if(estado==FIN && enter) { estado=MENU; baseDatos.partidaActualId=""; return; }
  Boolean yaApretada=teclas.get(k); boolean nueva=yaApretada==null || !yaApretada;
  if(estado==JUEGO && k==jugador.controles.get("torre") && nueva) jugador.alternarTorre();
  if(k==jugador.controles.get("tienda") && nueva) {
    if(estado==JUEGO && jugador.enTorre) { estado=TIENDA; tienda.mensajeT=0; baseDatos.guardarPartida(false); }
    else if(estado==TIENDA) { estado=JUEGO; baseDatos.guardarPartida(false); }
  }
  if((estado==JUEGO || estado==TIENDA) && k>='1' && k<='9') {
    jugador.equipar(k-'1');
    if(estado==TIENDA) baseDatos.guardarPartida(false);
  }
  if(estado==JUEGO && k==jugador.controles.get("barrera") && nueva) { modoBarrera=!modoBarrera; terminarTrazo(); esperarSoltar=mousePressed; }
  teclas.put(k,true);
}
void keyReleased() { if (key != CODED) teclas.put(Character.toLowerCase(key), false); }


void exit() {
  if(baseDatos!=null && (estado==JUEGO || estado==PAUSA || estado==TIENDA)) baseDatos.guardarPartida(false);
  if(baseDatos!=null) baseDatos.cerrar();
  super.exit();
}
