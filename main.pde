boolean[] lados = {false, false, false, false};
int cantidad_lados=1;
int oleadas_para_incrementar_lados = 3;
int incremento_enemigos_oleada = 3;
int oleada = 0;
int[] enemigos_por_lado = new int[4]
int[] repartir_enemigos(int cantidad_enemigos, boolean[] lados){
    int[] enemigos_por_lado = {0,0,0,0}; 
    int proporcion_ocupada = 0;
    for(i=0;i<4;i++){
        if(lados[i]){
            int proporcion = random(0,1-proporcion_ocupada);
            proporcion_ocupada += proporcion;
            enemigos_por_lado[i] = cantidad_enemigos*proporcion;
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
void setup(){
    
}
void draw(){
    if(oleadas>= oleadas_para_incrementar_lados && cantidad_lados < 4){
        cantidad_lados = int(oleadas/oleadas_para_incrementar_lados);
        if(cantidad_lados > 4) {
            cantidad_lados = 4;
        }
    } 
    lados = elegir_lados(cantidad_lados);
    cantidad_enemigos = Math.floor(10 * Marh.pow(1+1/incremento_enemigos,oleadas));
    enemigos_por_lado = repartir_enemigos(cantidad_enemigos,lados);
    
}
