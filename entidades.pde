PVector apuntar(PVector desde, PVector hasta){
    PVector direccion = PVector.sub(hasta,desde);
    direccion.normalize();
    return direccion;
}

class Entidad {
    PVector posicion;
    int diametro;
    int alto;
    int ancho;
    int vida;
    int damage;
    int ultimo_golpe;
    int cooldown;
    int velocidad;
    Entidad(PVector pos, int diametro, int vida, int velocidad, int damage,int cooldown){
        this.posicion = pos;
        this.diametro = diametro;
        this.vida = vida;
        this.velocidad = velocidad;
        this.damage = damage;
        this.cooldown = cooldown;
    }
    Entidad(PVector pos, int ancho, int alto, int vida, int velocidad, int damage, int cooldown){
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
        else return false;  
  }
    void herir(Entidad enemigo, boolean fue_golpeado){
        boolean esta_listo = millis() - this.ultimo_golpe >= this.cooldown;
        if(fue_golpeado && esta_listo){
            enemigo.vida = enemigo.vida - this.damage;
            this.ultimo_golpe = millis();
        }
    }
    void mostrar(){
      if(this.alto > 0) {
        rectMode(CENTER);
        rect(this.posicion.x,this.posicion.y,this.ancho,this.alto);
      } else if(this.diametro > 0){
        circle(this.posicion.x,this.posicion.y,this.diametro);
      }
    }
    void mover(){}
    boolean murio(){
        return vida > 0;
    }
}
class Bala extends Entidad{
    PVector direccion;
    Bala(PVector posicion, PVector direccion,int velocidad, int damage){
        super(posicion,3,0,velocidad,damage,1000);
        this.direccion = direccion;
    }
    @Override
    void mover(){
      this.posicion.add(this.direccion).mult(this.velocidad);
    }
}
enum ControlesJugador {arriba,izquierda,abajo,derecha,disparo};
class Jugador extends Entidad {
    HashMap<ControlesJugador,String> controles;
    Jugador(PVector pos, int diametro, int vida, int velocidad, int damage, HashMap<ControlesJugador,String> controles){
        super(pos,diametro,vida,velocidad,damage,1000);
        this.controles = controles;
        
    }
    @Override
    void mover(){
        int x = 0;
        int y = 0;
        if(teclado.get(this.controles.get(ControlesJugador.izquierda))) x = -1;
        if(teclado.get(this.controles.get(ControlesJugador.derecha))) x =  1;
        if(teclado.get(this.controles.get(ControlesJugador.arriba))) y =  -1;
        if(teclado.get(this.controles.get(ControlesJugador.abajo))) y = 1;
        PVector movimiento = new PVector(x,y);
        movimiento.mult(this.velocidad);
        this.posicion.add(movimiento);
    }

    void mostrar_arma(){
        PVector mouse = new PVector(mouseX,mouseY);
        PVector direccion = PVector.sub(mouse, this.posicion);
        direccion.setMag(this.diametro+7); // tamaño del arma
        PVector arma = PVector.add(this.posicion, direccion);
        strokeWeight(7);
        line(this.posicion.x,this.posicion.y,arma.x,arma.y);
        strokeWeight(1);
    }
    void disparar(){
        PVector direccion = new PVector(mouseX,mouseY);
        direccion.normalize();
        Bala disparo = new Bala(direccion,direccion,5,this.damage);
        balas.add(disparo);
    }
}

class Zombie extends Entidad {
    Entidad enemigo;
    Zombie(PVector pos, int diametro, int vida, int velocidad, int damage, Entidad enemigo){
        super(pos,diametro,vida,velocidad,damage,1000);
        this.enemigo = enemigo;
    }
    @Override
    void mover(){
        if(!this.colision(this.enemigo)){
            PVector direccion = apuntar(this.posicion,this.enemigo.posicion);
            direccion.mult(this.velocidad);
            this.posicion.add(direccion);
        }
    }
    void herir(){
        super.herir(this.enemigo,this.colision(this.enemigo));
    }
    
}
