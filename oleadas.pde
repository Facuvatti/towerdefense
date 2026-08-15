int[] repartir_enemigos(int cantidad_enemigos, boolean[] lados){
    int[] enemigos_por_lado = {0,0,0,0}; 
    float proporcion_ocupada = 0;
    for(int i=0;i<4;i++){
        if(lados[i]){
            float proporcion = random(0,1-proporcion_ocupada);
            proporcion_ocupada += proporcion;
            enemigos_por_lado[i] = (int) Math.ceil(cantidad_enemigos*proporcion);
        }
    }
    return enemigos_por_lado;
}
boolean[] elegir_lados(int cantidad_lados){
    ArrayList<Integer> opciones = new ArrayList<Integer>();
    for (int i = 0; i < 4; i++) opciones.add(i);
    boolean[] lados = {false,false,false,false};
    for(int lado=0;lado<cantidad_lados;lado++){
        int indice = (int) random(opciones.size());
        int opcion_elegida = opciones.get(indice);
        opciones.remove(indice);
        lados[opcion_elegida] = true;
    }
    return lados;
}
void inicializar_enemigos(int[] enemigos, boolean[] lados, int margen){
    for(int lado=0;lado<lados.length;lado++){
        int x=0;
        int y=0; 
        int ancho=0;
        int alto=0;
        if(lados[lado]) {
            switch(lado){
                case 0: // izquierda
                case 1: // arriba
                    x = -margen;
                    y = -margen;
                    break;
                case 2: // derecha
                    x = width + margen;
                    y = -margen;
                    break;
                case 3: // abajo
                    x = -margen;
                    y = height + margen;
                    break;
            }
            if(lado == 0 || lado == 2){ // vertical
                ancho=0;
                alto = height/enemigos[lado];
            } else if(lado == 1 || lado == 3){ // horizontal
                ancho = width/enemigos[lado];
                alto=0;
            }
            for(int enemigo =0;enemigo<enemigos[lado];enemigo++){
                PVector posicion = new PVector(x+ancho*enemigo,y+alto*enemigo,10);
                Zombie zombie = new Zombie(posicion,30,10,(int) random(4,6),5);
                zombies.add(zombie);
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
    cantidad_enemigos = (int)(cant_inicial_enemigos * Math.pow(1+1/incremento_enemigos,oleadas));
    enemigos_por_lado = repartir_enemigos(cantidad_enemigos,lados);
    inicializar_enemigos(enemigos_por_lado,lados,20);
    oleada_terminada = false;
}
