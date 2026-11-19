// Persistencia SQLite: jugadores, partidas, puntajes y creaciones.
import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

class BaseDatos {
  final String archivo = "data/towerdefense.sqlite";
  Connection conexion;
  JSONObject datos;
  String jugadorActual = "", partidaActualId = "";

  void cargar() {
    try {
      File carpeta = new File(sketchPath("data"));
      if (!carpeta.exists()) carpeta.mkdirs();
      Class.forName("org.sqlite.JDBC");
      conexion = DriverManager.getConnection("jdbc:sqlite:" + sketchPath(archivo));
      Statement st = conexion.createStatement();
      st.execute("PRAGMA foreign_keys = ON");
      st.execute("PRAGMA journal_mode = WAL");
      st.execute("PRAGMA busy_timeout = 5000");
      st.execute("CREATE TABLE IF NOT EXISTS jugadores (nombre TEXT PRIMARY KEY COLLATE NOCASE, ultima_actividad TEXT NOT NULL)");
      st.execute("CREATE TABLE IF NOT EXISTS partidas (id TEXT PRIMARY KEY, jugador TEXT NOT NULL COLLATE NOCASE, estado TEXT NOT NULL, actualizada TEXT NOT NULL, oleada INTEGER NOT NULL, puntaje INTEGER NOT NULL, snapshot TEXT NOT NULL, FOREIGN KEY(jugador) REFERENCES jugadores(nombre))");
      st.execute("CREATE INDEX IF NOT EXISTS idx_partidas_jugador_estado ON partidas(jugador, estado)");
      st.execute("CREATE TABLE IF NOT EXISTS puntajes (id INTEGER PRIMARY KEY AUTOINCREMENT, partida_id TEXT NOT NULL UNIQUE, jugador TEXT NOT NULL COLLATE NOCASE, puntaje INTEGER NOT NULL, oleada INTEGER NOT NULL, fecha TEXT NOT NULL, FOREIGN KEY(partida_id) REFERENCES partidas(id) ON DELETE CASCADE)");
      st.execute("CREATE INDEX IF NOT EXISTS idx_puntajes_ranking ON puntajes(puntaje DESC)");
      st.execute("CREATE TABLE IF NOT EXISTS creaciones (id TEXT PRIMARY KEY, tipo TEXT NOT NULL, nombre TEXT NOT NULL, definicion TEXT NOT NULL)");
      st.execute("CREATE INDEX IF NOT EXISTS idx_creaciones_tipo ON creaciones(tipo)");
      st.close();
      cargarCache();
    } catch(Exception e) {
      throw new RuntimeException("No se pudo abrir la base SQLite: " + e.getMessage(), e);
    }
  }

  void cargarCache() throws Exception {
    datos = new JSONObject();
    JSONArray jugadores = new JSONArray(), partidas = new JSONArray();
    JSONArray puntajes = new JSONArray(), creaciones = new JSONArray();
    Statement st = conexion.createStatement();
    ResultSet rs = st.executeQuery("SELECT nombre, ultima_actividad FROM jugadores ORDER BY nombre");
    while(rs.next()) {
      JSONObject o = new JSONObject(); o.setString("nombre",rs.getString("nombre"));
      o.setString("ultimaActividad",rs.getString("ultima_actividad")); jugadores.append(o);
    }
    rs.close();
    rs = st.executeQuery("SELECT snapshot FROM partidas ORDER BY actualizada DESC");
    while(rs.next()) partidas.append(parseJSON(rs.getString("snapshot")));
    rs.close();
    rs = st.executeQuery("SELECT partida_id, jugador, puntaje, oleada, fecha FROM puntajes ORDER BY id");
    while(rs.next()) {
      JSONObject o = new JSONObject(); o.setString("partidaId",rs.getString("partida_id"));
      o.setString("jugador",rs.getString("jugador")); o.setInt("puntaje",rs.getInt("puntaje"));
      o.setInt("oleada",rs.getInt("oleada")); o.setString("fecha",rs.getString("fecha")); puntajes.append(o);
    }
    rs.close();
    rs = st.executeQuery("SELECT definicion FROM creaciones ORDER BY rowid");
    while(rs.next()) creaciones.append(parseJSON(rs.getString("definicion")));
    rs.close(); st.close();
    datos.setJSONArray("jugadores",jugadores); datos.setJSONArray("partidas",partidas);
    datos.setJSONArray("puntajes",puntajes); datos.setJSONArray("creaciones",creaciones);
  }

  JSONObject parseJSON(String contenido) {
    return parseJSONObject(contenido);
  }

  void guardarArchivo() {
    if(conexion==null || datos==null) return;
    try {
      conexion.setAutoCommit(false);
      Statement st=conexion.createStatement();
      st.executeUpdate("DELETE FROM puntajes");
      st.executeUpdate("DELETE FROM partidas");
      st.executeUpdate("DELETE FROM jugadores");
      st.executeUpdate("DELETE FROM creaciones");
      st.close();

      PreparedStatement ps=conexion.prepareStatement("INSERT INTO jugadores(nombre,ultima_actividad) VALUES(?,?)");
      JSONArray arr=datos.getJSONArray("jugadores");
      for(int i=0;i<arr.size();i++) { JSONObject o=arr.getJSONObject(i); ps.setString(1,o.getString("nombre")); ps.setString(2,o.getString("ultimaActividad")); ps.addBatch(); }
      ps.executeBatch(); ps.close();

      ps=conexion.prepareStatement("INSERT INTO partidas(id,jugador,estado,actualizada,oleada,puntaje,snapshot) VALUES(?,?,?,?,?,?,?)");
      arr=datos.getJSONArray("partidas");
      for(int i=0;i<arr.size();i++) { JSONObject o=arr.getJSONObject(i); ps.setString(1,o.getString("id")); ps.setString(2,o.getString("jugador")); ps.setString(3,o.getString("estado")); ps.setString(4,o.getString("actualizada")); ps.setInt(5,o.getInt("oleada")); ps.setInt(6,o.getInt("puntaje")); ps.setString(7,o.toString()); ps.addBatch(); }
      ps.executeBatch(); ps.close();

      ps=conexion.prepareStatement("INSERT INTO puntajes(partida_id,jugador,puntaje,oleada,fecha) VALUES(?,?,?,?,?)");
      arr=datos.getJSONArray("puntajes");
      for(int i=0;i<arr.size();i++) { JSONObject o=arr.getJSONObject(i); ps.setString(1,o.getString("partidaId")); ps.setString(2,o.getString("jugador")); ps.setInt(3,o.getInt("puntaje")); ps.setInt(4,o.getInt("oleada")); ps.setString(5,o.getString("fecha")); ps.addBatch(); }
      ps.executeBatch(); ps.close();

      ps=conexion.prepareStatement("INSERT INTO creaciones(id,tipo,nombre,definicion) VALUES(?,?,?,?)");
      arr=datos.getJSONArray("creaciones");
      for(int i=0;i<arr.size();i++) { JSONObject o=arr.getJSONObject(i); ps.setString(1,o.getString("id")); ps.setString(2,o.getString("tipo")); ps.setString(3,o.getString("nombre")); ps.setString(4,o.toString()); ps.addBatch(); }
      ps.executeBatch(); ps.close();
      conexion.commit();
    } catch(Exception e) {
      try { conexion.rollback(); } catch(Exception ignored) {}
      throw new RuntimeException("Error guardando datos en SQLite: " + e.getMessage(), e);
    } finally {
      try { conexion.setAutoCommit(true); } catch(Exception ignored) {}
    }
  }

  void guardarCreacion(JSONObject creacion) {
    datos.getJSONArray("creaciones").append(creacion);
    guardarArchivo();
  }

  void cerrar() {
    try { if(conexion!=null && !conexion.isClosed()) conexion.close(); }
    catch(Exception e) { println("Error cerrando SQLite: " + e.getMessage()); }
  }

  String fecha() {
    return nf(year(),4)+"-"+nf(month(),2)+"-"+nf(day(),2)+" "+nf(hour(),2)+":"+nf(minute(),2)+":"+nf(second(),2);
  }

  void registrarJugador(String nombre) {
    jugadorActual=nombre.trim();
    if(jugadorActual.length()==0) return;
    JSONArray jugadores=datos.getJSONArray("jugadores");
    boolean existe=false;
    for(int i=0;i<jugadores.size();i++) {
      JSONObject j=jugadores.getJSONObject(i);
      if(j.getString("nombre","").equalsIgnoreCase(jugadorActual)) {
        j.setString("ultimaActividad",fecha()); existe=true; break;
      }
    }
    if(!existe) {
      JSONObject j=new JSONObject(); j.setString("nombre",jugadorActual);
      j.setString("ultimaActividad",fecha()); jugadores.append(j);
    }
    guardarArchivo();
  }

  ArrayList<JSONObject> partidasActivas(String nombre) {
    ArrayList<JSONObject> r=new ArrayList<JSONObject>();
    JSONArray ps=datos.getJSONArray("partidas");
    for(int i=0;i<ps.size();i++) {
      JSONObject p=ps.getJSONObject(i);
      if(p.getString("jugador","").equalsIgnoreCase(nombre) && p.getString("estado","").equals("ACTIVA")) r.add(p);
    }
    return r;
  }

  ArrayList<JSONObject> creaciones(String tipo) {
    ArrayList<JSONObject> r=new ArrayList<JSONObject>();
    JSONArray cs=datos.getJSONArray("creaciones");
    for(int i=0;i<cs.size();i++) {
      JSONObject c=cs.getJSONObject(i);
      if(c.getString("tipo","").equals(tipo)) r.add(c);
    }
    return r;
  }

  JSONObject creacionAleatoria(String tipo) {
    ArrayList<JSONObject> cs=creaciones(tipo);
    return cs.size()==0 ? null : cs.get((int)random(cs.size()));
  }

  JSONObject buscarCreacion(String id) {
    if(id==null || id.length()==0) return null;
    JSONArray cs=datos.getJSONArray("creaciones");
    for(int i=0;i<cs.size();i++) {
      JSONObject c=cs.getJSONObject(i);
      if(c.getString("id","").equals(id)) return c;
    }
    return null;
  }

  Arma armaPorRegistro(JSONObject reg) {
    String id=reg.getString("creacionId","");
    if(id.length()>0) {
      JSONObject def=buscarCreacion(id);
      if(def!=null) return new Arma(def);
    }
    String nombre=reg.getString("nombre","Pistola");
    for(Arma a:catalogo) if(a.nombre.equals(nombre)) return a;
    return catalogo.get(0);
  }

  void agregarArmasCreadas() {
    if(jugador==null) return;
    for(JSONObject c:creaciones("ARMA")) {
      String id=c.getString("id","");
      boolean existe=false;
      for(Arma a:jugador.armas) if(a.creacionId.equals(id)) { existe=true; break; }
      if(!existe) jugador.armas.add(new Arma(c));
    }
  }

  void crearNuevaPartida() {
    partidaActualId=Long.toString(System.currentTimeMillis())+"-"+str((int)random(100000,999999));
    guardarPartida(false);
  }

  void guardarPartida(boolean finalizada) {
    if(datos==null || jugadorActual.length()==0 || jugador==null) return;
    if(partidaActualId.length()==0)
      partidaActualId=Long.toString(System.currentTimeMillis())+"-"+str((int)random(100000,999999));

    JSONObject p=new JSONObject();
    p.setString("id",partidaActualId); p.setString("jugador",jugadorActual);
    p.setString("estado",finalizada?"FINALIZADA":"ACTIVA"); p.setString("actualizada",fecha());
    p.setInt("oleada",oleada); p.setInt("puntaje",puntaje); p.setInt("monedas",monedas);
    p.setInt("materiales",materiales); p.setFloat("madera",madera);
    p.setInt("cuentaAtras",cuentaAtras); p.setBoolean("oleadaConJefe",oleadaConJefe);

    JSONObject j=new JSONObject();
    j.setFloat("x",jugador.pos.x); j.setFloat("y",jugador.pos.y);
    j.setFloat("vx",jugador.vel.x); j.setFloat("vy",jugador.vel.y);
    j.setFloat("ax",jugador.acc.x); j.setFloat("ay",jugador.acc.y);
    j.setInt("vida",jugador.vida); j.setInt("vidaMax",jugador.vidaMax);
    j.setFloat("velMax",jugador.velMax); j.setFloat("radio",jugador.radio);
    j.setBoolean("enTorre",jugador.enTorre);
    j.setInt("municion",jugador.municion); j.setInt("municionMax",jugador.municionMax);
    j.setInt("sinBalasT",jugador.sinBalasT);
    j.setInt("ataqueHaceMs",max(0,millis()-jugador.ultimoAtaque));
    j.setInt("cambioTorreHaceMs",max(0,millis()-jugador.ultimoCambioTorre));
    for(String accion:acciones) if(jugador.controles.containsKey(accion))
      j.setString("control_"+accion,String.valueOf(jugador.controles.get(accion)));
    JSONArray inv=new JSONArray();
    for(Arma a:jugador.armas) {
      JSONObject ar=new JSONObject(); ar.setString("nombre",a.nombre); ar.setString("creacionId",a.creacionId); inv.append(ar);
    }
    j.setJSONArray("armas",inv); j.setInt("armaEquipada",max(0,jugador.armas.indexOf(jugador.arma)));
    p.setJSONObject("jugadorEstado",j);

    JSONArray zs=new JSONArray();
    for(Zombie z:zombies) {
      JSONObject o=new JSONObject();
      o.setFloat("x",z.pos.x); o.setFloat("y",z.pos.y); o.setFloat("vx",z.vel.x); o.setFloat("vy",z.vel.y);
      o.setFloat("ax",z.acc.x); o.setFloat("ay",z.acc.y); o.setFloat("radio",z.radio); o.setFloat("velMax",z.velMax);
      o.setInt("vida",z.vida); o.setInt("vidaMax",z.vidaMax); o.setInt("dano",z.dano); o.setInt("cooldown",z.cooldown);
      o.setInt("tipo",z.tipo); o.setInt("puntos",z.puntos); o.setInt("botin",z.botin);
      o.setInt("ataqueHaceMs",max(0,millis()-z.ultimoAtaque)); o.setString("creacionId",z.creacionId);
      zs.append(o);
    }
    p.setJSONArray("zombies",zs);

    JSONArray bs=new JSONArray();
    for(Bala b:balas) {
      JSONObject o=new JSONObject();
      o.setFloat("x",b.pos.x); o.setFloat("y",b.pos.y); o.setFloat("vx",b.vel.x); o.setFloat("vy",b.vel.y);
      o.setInt("dano",b.dano); o.setInt("edad",b.edad); o.setInt("alcance",b.alcance); o.setInt("perfora",b.perfora);
      JSONArray hits=new JSONArray(); for(Zombie z:b.golpeados) hits.append(zombies.indexOf(z));
      o.setJSONArray("golpeados",hits); bs.append(o);
    }
    p.setJSONArray("balas",bs);

    JSONArray ts=new JSONArray();
    for(Torre t:torres) {
      JSONObject o=new JSONObject(); o.setFloat("x",t.pos.x); o.setFloat("y",t.pos.y);
      o.setInt("vida",t.vida); o.setInt("vidaMax",t.vidaMax); o.setInt("desgaste",t.desgaste);
      o.setFloat("alcance",t.alcance); o.setInt("ataqueHaceMs",max(0,millis()-t.ultimoAtaque)); ts.append(o);
    }
    p.setJSONArray("torres",ts);

    JSONArray ds=new JSONArray();
    for(Drop d:drops) {
      JSONObject o=new JSONObject(); o.setFloat("x",d.pos.x); o.setFloat("y",d.pos.y);
      o.setFloat("vx",d.vel.x); o.setFloat("vy",d.vel.y);
      o.setInt("tipo",d.tipo); o.setInt("cantidad",d.cantidad); o.setInt("edad",d.edad); o.setInt("duracion",d.duracion);
      ds.append(o);
    }
    p.setJSONArray("drops",ds);

    JSONArray walls=new JSONArray();
    for(Barrera b:barreras) {
      JSONObject o=new JSONObject(); JSONArray pts=new JSONArray();
      for(PVector v:b.puntos) { JSONArray xy=new JSONArray(); xy.append(v.x); xy.append(v.y); pts.append(xy); }
      o.setJSONArray("puntos",pts); o.setInt("vida",b.vida); o.setInt("vidaMax",b.vidaMax); walls.append(o);
    }
    p.setJSONArray("barreras",walls);

    if(torre!=null) {
      JSONObject tc=new JSONObject(); tc.setFloat("x",torre.pos.x); tc.setFloat("y",torre.pos.y);
      tc.setInt("vida",torre.vida); tc.setInt("vidaMax",torre.vidaMax); tc.setInt("nivel",torre.nivel);
      p.setJSONObject("torreCentral",tc);
    } else p.setBoolean("torreCentralDestruida",true);

    JSONArray partidas=datos.getJSONArray("partidas");
    boolean reemplazada=false; String estadoAnterior="";
    for(int i=0;i<partidas.size();i++) {
      JSONObject vieja=partidas.getJSONObject(i);
      if(vieja.getString("id","").equals(partidaActualId)) {
        estadoAnterior=vieja.getString("estado",""); partidas.setJSONObject(i,p); reemplazada=true; break;
      }
    }
    if(!reemplazada) partidas.append(p);
    if(finalizada && !estadoAnterior.equals("FINALIZADA")) {
      JSONObject score=new JSONObject(); score.setString("partidaId",partidaActualId);
      score.setString("jugador",jugadorActual); score.setInt("puntaje",puntaje);
      score.setInt("oleada",oleada); score.setString("fecha",p.getString("actualizada"));
      datos.getJSONArray("puntajes").append(score);
    }
    guardarArchivo();
  }

  void reanudarPartida(JSONObject p) {
    partidaActualId=p.getString("id",""); jugadorActual=p.getString("jugador",jugadorActual);
    oleada=p.getInt("oleada",0); puntaje=p.getInt("puntaje",0); monedas=p.getInt("monedas",150);
    materiales=p.getInt("materiales",0); madera=p.getFloat("madera",300);
    cuentaAtras=p.getInt("cuentaAtras",180); oleadaConJefe=p.getBoolean("oleadaConJefe",false);

    zombies.clear(); balas.clear(); torres.clear(); drops.clear(); barreras.clear(); particulas.lista.clear();
    iniciarCampo(); crearFondo();

    JSONObject tc=p.getJSONObject("torreCentral");
    if(tc==null || p.getBoolean("torreCentralDestruida",false)) torre=null;
    else {
      torre=new TorreCentral(tc.getFloat("x",width/2),tc.getFloat("y",CENTRO_Y));
      torre.vidaMax=tc.getInt("vidaMax",600); torre.vida=tc.getInt("vida",torre.vidaMax); torre.nivel=tc.getInt("nivel",1);
    }

    JSONObject j=p.getJSONObject("jugadorEstado");
    jugador.reiniciar(j.getFloat("x",width/2),j.getFloat("y",CENTRO_Y+70));
    jugador.pos.set(j.getFloat("x",width/2),j.getFloat("y",CENTRO_Y+70));
    jugador.vel.set(j.getFloat("vx",0),j.getFloat("vy",0)); jugador.acc.set(j.getFloat("ax",0),j.getFloat("ay",0));
    jugador.vidaMax=j.getInt("vidaMax",100); jugador.vida=j.getInt("vida",jugador.vidaMax);
    jugador.velMax=j.getFloat("velMax",3.4); jugador.radio=j.getFloat("radio",11);
    jugador.municionMax=j.getInt("municionMax",150); jugador.municion=j.getInt("municion",60);
    jugador.sinBalasT=j.getInt("sinBalasT",0);
    jugador.ultimoAtaque=millis()-j.getInt("ataqueHaceMs",100000);
    jugador.ultimoCambioTorre=millis()-j.getInt("cambioTorreHaceMs",100000);
    for(String accion:acciones) {
      String control=j.getString("control_"+accion,"");
      if(control.length()>0) jugador.controles.put(accion,control.charAt(0));
    }
    jugador.armas.clear();
    JSONArray inv=j.getJSONArray("armas");
    if(inv!=null) for(int i=0;i<inv.size();i++) jugador.armas.add(armaPorRegistro(inv.getJSONObject(i)));
    if(jugador.armas.size()==0) jugador.armas.add(catalogo.get(0));
    jugador.equipar(constrain(j.getInt("armaEquipada",0),0,jugador.armas.size()-1));
    jugador.enTorre=j.getBoolean("enTorre",false) && torre!=null;

    JSONArray zs=p.getJSONArray("zombies");
    for(int i=0;i<zs.size();i++) {
      JSONObject o=zs.getJSONObject(i); JSONObject def=buscarCreacion(o.getString("creacionId",""));
      Zombie z=def==null
        ? new Zombie(o.getFloat("x"),o.getFloat("y"),constrain(o.getInt("tipo",0),0,JEFE))
        : new Zombie(o.getFloat("x"),o.getFloat("y"),def);
      z.pos.set(o.getFloat("x"),o.getFloat("y")); z.vel.set(o.getFloat("vx",0),o.getFloat("vy",0));
      z.acc.set(o.getFloat("ax",0),o.getFloat("ay",0)); z.radio=o.getFloat("radio",z.radio);
      z.velMax=o.getFloat("velMax",z.velMax); z.vidaMax=o.getInt("vidaMax",z.vidaMax); z.vida=o.getInt("vida",z.vidaMax);
      z.dano=o.getInt("dano",z.dano); z.cooldown=o.getInt("cooldown",z.cooldown);
      z.puntos=o.getInt("puntos",z.puntos); z.botin=o.getInt("botin",z.botin);
      z.ultimoAtaque=millis()-o.getInt("ataqueHaceMs",100000); zombies.add(z);
    }

    JSONArray walls=p.getJSONArray("barreras");
    for(int i=0;i<walls.size();i++) {
      JSONObject o=walls.getJSONObject(i); JSONArray pts=o.getJSONArray("puntos");
      if(pts==null || pts.size()==0) continue;
      JSONArray first=pts.getJSONArray(0);
      Barrera b=new Barrera(new PVector(first.getFloat(0),first.getFloat(1)));
      for(int k=1;k<pts.size();k++) {
        JSONArray xy=pts.getJSONArray(k); b.agregar(new PVector(xy.getFloat(0),xy.getFloat(1)));
      }
      b.vidaMax=o.getInt("vidaMax",b.vidaMax); b.vida=o.getInt("vida",b.vidaMax); barreras.add(b);
    }

    JSONArray ts=p.getJSONArray("torres");
    for(int i=0;i<ts.size();i++) {
      JSONObject o=ts.getJSONObject(i); Torre t=new Torre(o.getFloat("x"),o.getFloat("y"));
      t.vidaMax=o.getInt("vidaMax",150); t.vida=o.getInt("vida",t.vidaMax);
      t.desgaste=o.getInt("desgaste",0); t.alcance=o.getFloat("alcance",220);
      t.ultimoAtaque=millis()-o.getInt("ataqueHaceMs",100000); torres.add(t);
    }

    JSONArray ds=p.getJSONArray("drops");
    for(int i=0;i<ds.size();i++) {
      JSONObject o=ds.getJSONObject(i);
      Drop d=new Drop(new PVector(o.getFloat("x"),o.getFloat("y")),o.getInt("tipo",D_MONEDA),o.getInt("cantidad",1));
      d.vel.set(o.getFloat("vx",0),o.getFloat("vy",0));
      d.edad=o.getInt("edad",0); d.duracion=o.getInt("duracion",d.duracion); drops.add(d);
    }

    JSONArray bs=p.getJSONArray("balas"); ArrayList<JSONArray> hitLists=new ArrayList<JSONArray>();
    for(int i=0;i<bs.size();i++) {
      JSONObject o=bs.getJSONObject(i);
      Bala b=new Bala(o.getFloat("x"),o.getFloat("y"),new PVector(o.getFloat("vx"),o.getFloat("vy")),
        o.getInt("dano",25),o.getInt("alcance",90),o.getInt("perfora",0));
      b.edad=o.getInt("edad",0); balas.add(b); hitLists.add(o.getJSONArray("golpeados"));
    }
    for(int i=0;i<balas.size();i++) {
      JSONArray hits=hitLists.get(i); if(hits==null) continue;
      for(int k=0;k<hits.size();k++) {
        int idx=hits.getInt(k);
        if(idx>=0 && idx<zombies.size()) balas.get(i).golpeados.add(zombies.get(idx));
      }
    }

    trazoActual=null; esperarSoltar=false; modoBarrera=false;
    campoSucio=true; campoT=0; teclas.clear(); tienda.mensajeT=0; estado=JUEGO;
  }
}

final float EDITOR_X=270, EDITOR_Y=145, EDITOR_W=410, EDITOR_H=340;
ArrayList<ArrayList<PVector>> trazosEditor=new ArrayList<ArrayList<PVector>>();
ArrayList<PVector> trazoActualEditor=null;
String nombreCreacion="Mi creacion", tipoCreacion="ARMA";
float[] atributosCreacion={25,11,90,140,1,0.05,0,0.6};
int atributoSeleccionado=0;

void abrirEditor() {
  estado=EDITOR; trazosEditor.clear(); trazoActualEditor=null;
  nombreCreacion=tipoCreacion.equals("ARMA")?"Mi arma":"Mi zombie";
  atributoSeleccionado=0;
  if(tipoCreacion.equals("ARMA"))
    atributosCreacion=new float[]{25,11,90,140,1,0.05,0,0.6};
  else
    atributosCreacion=new float[]{70,1.2,12,10,800,10,10,0};
}

String[] etiquetasCreacion() {
  return tipoCreacion.equals("ARMA")
    ? new String[]{"Daño","Vel. proyectil","Alcance","Cadencia ms","Proyectiles","Dispersión","Perfora","Retroceso"}
    : new String[]{"Vida","Velocidad","Radio / tamaño","Daño contacto","Cadencia ms","Puntos","Botín","(reservado)"};
}

float pasoAtributo(int i) {
  if(tipoCreacion.equals("ARMA")) {
    if(i==1) return 0.1;
    if(i==3) return 10;
    if(i==5) return 0.02;
    if(i==7) return 0.1;
  } else {
    if(i==1) return 0.1;
    if(i==2) return 1;
    if(i==4) return 25;
  }
  return 1;
}

void modificarAtributo(int i,int direccion) {
  if(i<0 || i>=atributosCreacion.length) return;
  float v=atributosCreacion[i]+pasoAtributo(i)*direccion;
  if(tipoCreacion.equals("ARMA")) {
    float[] minimos={1,1,1,50,1,0,0,0};
    float[] maximos={500,40,600,3000,12,1.5,10,10};
    atributosCreacion[i]=constrain(v,minimos[i],maximos[i]);
  } else {
    float[] minimos={1,0.2,4,1,100,0,0,0};
    float[] maximos={5000,6,40,500,5000,10000,10000,0};
    atributosCreacion[i]=constrain(v,minimos[i],maximos[i]);
  }
}

void dibujarEditor() {
  background(17,22,24); rectMode(CORNER);
  fill(230); textAlign(CENTER,CENTER); textSize(28); text("TALLER DE CREACIONES",width/2,42);
  textSize(15); fill(190);
  text("Tipo: "+tipoCreacion+"   |   TAB: cambiar tipo",width/2,80);
  noStroke(); fill(35,44,43); rect(25,112,225,390,8);
  fill(230); textAlign(LEFT,CENTER); textSize(16); text("Nombre",45,137);
  fill(255,220,130); text(nombreCreacion+"_",45,160);
  textSize(13); fill(185); text("ATRIBUTOS",45,190);
  String[] labels=etiquetasCreacion();
  for(int i=0;i<labels.length;i++) {
    float y=220+i*31;
    boolean sel=i==atributoSeleccionado;
    noStroke(); fill(sel?color(76,83,54):color(43,51,48)); rect(38,y-12,199,26,4);
    fill(sel?color(255,225,120):color(205)); textAlign(LEFT,CENTER); textSize(12);
    text((i+1)+". "+labels[i],45,y);
    textAlign(RIGHT,CENTER); fill(255); text(nf(atributosCreacion[i],0,2),205,y);
  }
  fill(165); textAlign(LEFT,CENTER); textSize(11);
  text("↑/↓ o clic en valor para ajustar",38,480);
  fill(35,44,43); stroke(100,125,100); rect(EDITOR_X,EDITOR_Y,EDITOR_W,EDITOR_H);
  stroke(55,72,62); strokeWeight(1);
  for(int x=0;x<=EDITOR_W;x+=20) line(EDITOR_X+x,EDITOR_Y,EDITOR_X+x,EDITOR_Y+EDITOR_H);
  for(int y=0;y<=EDITOR_H;y+=20) line(EDITOR_X,EDITOR_Y+y,EDITOR_X+EDITOR_W,y+EDITOR_Y);
  dibujarTrazosEditor();
  noStroke(); fill(175); textAlign(CENTER,CENTER); textSize(13);
  text("Dibujá la forma dentro del recuadro",EDITOR_X+EDITOR_W/2,510);
  text("DELETE: borrar dibujo   ENTER: guardar   ESC: volver",width/2,548);
  text("TAB: cambiar entre arma y zombie   |   1-8: elegir atributo",width/2,574);
}

void dibujarTrazosEditor() {
  noFill(); strokeWeight(4); stroke(tipoCreacion.equals("ARMA")?color(255,205,95):color(130,205,115));
  for(ArrayList<PVector> trazo:trazosEditor)
    for(int i=1;i<trazo.size();i++) line(trazo.get(i-1).x,trazo.get(i-1).y,trazo.get(i).x,trazo.get(i).y);
}

void dibujarTrazos(JSONArray trazos,float x,float y,float w,float h,int tinte) {
  if(trazos==null) return;
  pushStyle(); noFill(); stroke(tinte); strokeWeight(max(2,w*0.035));
  for(int i=0;i<trazos.size();i++) {
    JSONArray pts=trazos.getJSONArray(i);
    for(int k=1;k<pts.size();k++) {
      JSONArray a=pts.getJSONArray(k-1), b=pts.getJSONArray(k);
      line(x+a.getFloat(0)*w,y+a.getFloat(1)*h,x+b.getFloat(0)*w,y+b.getFloat(1)*h);
    }
  }
  popStyle();
}

void guardarCreacionActual() {
  if(nombreCreacion.trim().length()==0 || trazosEditor.size()==0) return;
  JSONObject c=new JSONObject();
  c.setString("id",Long.toString(System.currentTimeMillis())+"-"+str((int)random(1000,9999)));
  c.setString("tipo",tipoCreacion); c.setString("nombre",nombreCreacion.trim());
  if(tipoCreacion.equals("ARMA")) {
    c.setInt("vida",1);
    c.setInt("dano",round(atributosCreacion[0]));
    c.setFloat("velocidad",atributosCreacion[1]);
    c.setInt("alcance",round(atributosCreacion[2]));
    c.setInt("cadencia",round(atributosCreacion[3]));
    c.setInt("perdigones",round(atributosCreacion[4]));
    c.setFloat("dispersion",atributosCreacion[5]);
    c.setInt("perfora",round(atributosCreacion[6]));
    c.setFloat("retroceso",atributosCreacion[7]);
  } else {
    c.setInt("vida",round(atributosCreacion[0]));
    c.setFloat("velocidad",atributosCreacion[1]);
    c.setFloat("radio",atributosCreacion[2]);
    c.setInt("dano",round(atributosCreacion[3]));
    c.setInt("cadencia",round(atributosCreacion[4]));
    c.setInt("puntos",round(atributosCreacion[5]));
    c.setInt("botin",round(atributosCreacion[6]));
  }
  c.setInt("tinte",tipoCreacion.equals("ARMA")?color(255,205,95):color(130,205,115));
  JSONArray saved=new JSONArray();
  for(ArrayList<PVector> trazo:trazosEditor) {
    if(trazo.size()<2) continue;
    JSONArray pts=new JSONArray();
    for(PVector pt:trazo) {
      JSONArray xy=new JSONArray(); xy.append(constrain((pt.x-EDITOR_X)/EDITOR_W,0,1));
      xy.append(constrain((pt.y-EDITOR_Y)/EDITOR_H,0,1)); pts.append(xy);
    }
    saved.append(pts);
  }
  if(saved.size()==0) return;
  c.setJSONArray("trazos",saved);
  baseDatos.guardarCreacion(c);
  if(tipoCreacion.equals("ARMA")) baseDatos.agregarArmasCreadas();
  estado=MENU;
}
