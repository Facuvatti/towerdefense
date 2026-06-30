PVector apuntar(PVector desde, PVector hasta){
    PVector direccion = PVector.sub(hasta,desde);
    direccion.normalize();
    return direccion
}

class Entidad {
    PVector posicion;
    int diametro;
    int alto;
    ing ancho;
    int vida;
    int damage;
    int ultimo_golpe;
    int cooldown;
    PVector velocidad;
    Entidad(PVector pos, int diametro, int vida, PVector velocidad, int damage,int cooldown=1000){
        this.posicion = pos;
        this.diametro = diametro;
        this.vida = vida;
        this.velocidad = velocidad;
        this.damage = damage;
        this.cooldown = cooldown;
    }
    Entidad(PVector pos, int ancho, int alto, int vida, PVector velocidad, int damage, int cooldown=1000){
        this.posicion = pos;
        this.alto = alto;
        this.ancho = ancho;
        this.vida = vida;
        this.velocidad = velocidad;
        this.damage = damage;
        this.cooldown = cooldown;
    }
    boolean colision(Entidad otro){
        if(this.diametro > 0 && otro.diametro > 0) return dist(this.posicion.x, this.posicion.y,otro.posicion.x,otro.posicion.y) < this.diametro/2+otro.diametro/2;
        else if(this.alto > 0 && otro.alto > 0) return this.posicion.x < otro.posicion.x + otro.ancho && this.posicion.x + this.ancho > otro.posicion.x && this.posicion.y < otro.posicion.y + otro.alto && this.posicion.y + this.alto > otro.posicion.y;
        else if(this.alto > 0 && otro.diametro > 0) return dist(constrain(otro.posicion.x, this.posicion.x, this.posicion.x + this.ancho), constrain(otro.posicion.y, this.posicion.y, this.posicion.y + this.alto), otro.posicion.x, otro.posicion.y) < (otro.diametro / 2);
        else if(this.diametro > 0 && otro.alto > 0) return dist(constrain(this.posicion.x, otro.posicion.x, otro.posicion.x + otro.ancho), constrain(this.posicion.y, otro.posicion.y, otro.posicion.y + otro.alto), this.posicion.x, this.posicion.y) < (this.diametro / 2);
    }
    void herir(Entidad enemigo, boolean fue_golpeado){
        boolean esta_listo = millis() - this.ultimo_golpe >= this.cooldown;
        if(fue_golpeado && esta_listo){
            enemigo.vida = enemigo.vida - this.damage;
            this.ultimo_golpe = millis();
        }
    }
}
class Bala extends Entidad{
    Bala(PVector posicion, PVector velocidad, int damage){
        super(posicion,5,null,velocidad,damage);
    }
}
enum controles_jugador = {Arriba,izquierda,abajo,derecha,disparo};
class Jugador extends Entidad {
    Jugador(PVector pos, int diametro, int vida, PVector velocidad, int damage, HashMap<controles_jugador,String> controles)
        super(pos,diametro,vida,velocidad,damage);
    }
    void mover(){
        int x = 0;
        int y = 0;
        if(teclado[controles["izquierda"]]) x = -1;
        if(teclado[controles["derecha"]]) x=1;
        if(teclado[controles["arriba"]]) y=1;
        if(teclado[controles["abajo"]]) y=-1;
        PVector movimiento = new PVector(x,y);
        movimiento.mult(this.velocidad);
        this.posicion.add(movimiento);
    }
    PVector apuntar_arma(){
        PVector mouse = new PVector(mouseX,mouseY);
        PVector arma = apuntar(this.position,mouse);
        arma.mult(5) // tamaño del arma
        return arma
    }
    void mostrar_arma(){
        PVector arma = this.apuntar_arma();
        strokeWeight(3);
        line(this.posicion.x,this.posicion.y,arma.x,arma.y);
        strokeWeight(1);
    }
    void disparar(){
        PVector arma = this.apuntar_arma()
        PVector disparo = arma.add(arma.setMag(2)); // longitud del disparo
        line(arma.x,arma.y,disparo.x,disparo.y);
    }
}

class Zombie extends Entidad {
    Zombie(PVector pos, int diametro, int vida, PVector velocidad, int damage)
        super(pos,diametro,vida,velocidad,damage);
    }
    void perseguir(Entidad enemigo){
        if(!this.colision(jugador)){
            PVector direccion = apuntar(this.posicion,enemigo.posicion)
            direccion.mult(this.velocidad);
            this.posicion.add(direccion);
        }
    }
    @Override
    void herir(Entidad enemigo){
        super.herir(enemigo,this.colision());
    }
    
}
