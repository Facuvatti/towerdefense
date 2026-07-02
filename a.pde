import java.util.ArrayList;
import java.lang.reflect.Method;
boolean[] lados = {false, false, false, false};
int cantidad_lados=1;
int oleadas = 0;
int kills;
boolean oleada_terminada;
int oleadas_para_incrementar_lados = 3;
Jugador jugador;
boolean estaDisparando = false;
int cantidad_enemigos;
int cant_inicial_enemigos = 3;
int incremento_enemigos = 3;
int[] enemigos_por_lado = new int[4];
ArrayList<Zombie> zombies = new ArrayList<Zombie>();
ArrayList<Bala> balas = new ArrayList<Bala>();
ArrayList<Entidad> entidades = new ArrayList<Entidad>(); // para las colisiones
HashMap<ControlesJugador,String> controles = new HashMap<ControlesJugador,String>() {{
  put(ControlesJugador.arriba,"w");
  put(ControlesJugador.izquierda,"a");
  put(ControlesJugador.abajo,"s");
  put(ControlesJugador.derecha,"d");
}};
void actualizarTodo(Jugador personaje,ArrayList<? extends Entidad>... arrays) {
    entidades.clear();
    if (!personaje.murio()) {
        entidades.add(personaje);
    }
    for (ArrayList<? extends Entidad> array : arrays) {
        array.forEach(entidad -> {if( entidad instanceof Zombie && entidad.murio()) {kills++;}});
        array.removeIf(entidad -> entidad.murio());
        entidades.addAll(array);
    }
    entidades.forEach(entidad -> entidad.actualizar());
    
}

void setup(){
    size(1920/2,1080/2);
    fill(255);
    inicializarTeclado();
    entidades.clear();
    oleadas = 0;
    kills = 0;
    cantidad_enemigos = cant_inicial_enemigos;
    jugador = new Jugador(new PVector(width/2,height/2),50,100,10,controles);
    iniciar_oleada();  
}
void draw(){
    background(255);
    actualizarTodo(jugador,zombies,balas);
    if(entidades.stream().anyMatch(e -> e == jugador)){
        if(estaDisparando) jugador.disparar();
        boolean hayZombies = entidades.stream().anyMatch(e -> e.getClass() == Zombie.class);
        if(oleada_terminada){
            iniciar_oleada();
        } else if(!hayZombies){
            oleadas++;
            oleada_terminada = true;
        }
    } else {
        textSize(100);
        fill(0);
        text("Game Over",width/2,height/2);
        text("Oleadas: " + oleadas + "\nkills: "+kills,width/2,(height/3)*2);
        if(keyPressed) setup();
    }
}   
void mousePressed(){
    estaDisparando = true; 
}
void mouseReleased(){
    estaDisparando = false;
}