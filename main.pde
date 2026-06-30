boolean[] lados = {false, false, false, false};
int cantidad_lados=1;
int oleadas_para_incrementar_lados = 3;
int incremento_enemigos_oleada = 3;
int oleada = 0;
boolean oleada_terminada;
int[] enemigos_por_lado = new int[4];
int[] repartir_enemigos(int cantidad_enemigos, boolean[] lados){
    int[] enemigos_por_lado = {0,0,0,0}; 
    int proporcion_ocupada = 0;
    for(i=0;i<4;i++){
        if(lados[i]){
            int proporcion = random(0,1-proporcion_ocupada);
            proporcion_ocupada += proporcion;
            enemigos_por_lado[i] = int(cantidad_enemigos*proporcion);
        }
    }
    return enemigos_por_lado;
}
int[] borrar_indice(int borrar,int[] array){
    int[] nuevo = new int[array.length-1];
    arrayCopy(array, 0, nuevo, 0, borrar);
    arrayCopy(array, borrar + 1, nuevo, borrar, array.length - borrar - 1);
    return nuevo
}
boolean[] elegir_lados(int cantidad_lados){
    int[] opciones = {0,1,2,3}
    boolean[] lados = {false,false,false,false}
    for(int lado=0;lado<cantidad_lados;lado++){
        int indice = int(random(opciones.length));
        int opcion_elegida = opciones[indice];
        opciones = borrar_indice(indice,opciones);
        lados[opcion_elegida] = true;
    }
    return lados;
}
void inicializar_enemigos(int[] enemigos, boolean[] lados, int margen=20){
    for(lado=0;lado<lados.length;lado++){
        int x;
        int y; 
        int ancho;
        int alto;
        if(lados[i]) {
            switch(lado){
                case 0: // izquierda
                case 1: // arriba
                    x = margen;
                    y = margen;
                    break
                case 2: // derecha
                    x = width - margen;
                    y = margen;
                    break
                case 3: // abajo
                    x = 0;
                    y = height - margen;
                    break
            }
            if(lado == 0 || lado == 2){ // verticales
                ancho=0;
                alto = height/enemigos[lado];
                vertical = 1
            } else if(lado == 1 || lado == 3){ // horizontal
                ancho = width/enemigos[lado];
                alto=0;
                horizontal =1;
            }
            for(int enemigo =0;enemigo<enemigos[lado];enemigo++){
                PVector posicion = new Pvector(x+ancho*enemigo,y+alto*enemigo,10);
            }
        }
    }
}
void iniciar_oleada(){
    if(oleadas>= oleadas_para_incrementar_lados && cantidad_lados < 4){
        cantidad_lados = int(oleadas/oleadas_para_incrementar_lados);
        if(cantidad_lados > 4) {
            cantidad_lados = 4;
        }
    } 
    lados = elegir_lados(cantidad_lados);
    cantidad_enemigos = Math.floor(10 * Marh.pow(1+1/incremento_enemigos,oleadas));
    enemigos_por_lado = repartir_enemigos(cantidad_enemigos,lados);
    inicializar_enemigos(enemigos_por_lado,lados);
    oleada_terminada = false;
}
void setup(){
  iniciar_oleada();  
}
void draw()
    if(oleada_terminada){
        iniciar_oleada();
    } else if(kills >= cantidad_enemigos){
        oleadas++;
        oleada_terminada = true;
    }
}
