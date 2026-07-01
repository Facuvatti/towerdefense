import java.util.ArrayList;
import java.lang.reflect.Method;
boolean[] lados = {false, false, false, false};
int cantidad_lados=1;
int oleadas = 0;
boolean oleada_terminada;
int oleadas_para_incrementar_lados = 3;
Jugador jugador;
int cantidad_enemigos;
int cant_inicial_enemigos = 1;
int incremento_enemigos = 3;
int[] enemigos_por_lado = new int[4];
ArrayList<Zombie> zombies = new ArrayList<Zombie>();
ArrayList<Bala> balas = new ArrayList<Bala>();
HashMap<ControlesJugador,String> controles = new HashMap<ControlesJugador,String>() {{
  put(ControlesJugador.arriba,"w");
  put(ControlesJugador.izquierda,"a");
  put(ControlesJugador.abajo,"s");
  put(ControlesJugador.derecha,"d");
}};
void actualizarTodo(ArrayList<? extends Entidad>... arrays) {
    for (ArrayList<? extends Entidad> array : arrays) {
        array.removeIf(entidad -> entidad.murio());
        for (Entidad entidad : array) {
            entidad.mover();
            entidad.mostrar();
        }
    }
}
void setup(){
    size(1920/2,1080/2);
    inicializarTeclado();
    jugador = new Jugador(new PVector(width/2,height/2),50,100,10,5,controles);
    iniciar_oleada();  
    
}
void draw(){
    background(255);
    jugador.mover();
    jugador.mostrar_arma();
    jugador.mostrar();
    actualizarTodo(zombies,balas);
    
    if(oleada_terminada){
        iniciar_oleada();
    } else if(zombies.isEmpty()){
        oleadas++;
        oleada_terminada = true;
    }
}
