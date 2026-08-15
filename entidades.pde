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
    ArrayList<Entidad> colisionandoCon = new ArrayList<Entidad>();
    ArrayList<Class<? extends Entidad>> heribles = new ArrayList<Class<? extends Entidad>>();
    ArrayList<Entidad> colisionando_heribles = new ArrayList<Entidad>(); 
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
    void colision(){
        this.colisionandoCon.clear();
        this.colisionando_heribles.clear();
        for(Entidad entidad : entidades){
            boolean hayColision = false;
            if(this == entidad) continue;
            if(this.diametro > 0 && entidad.diametro > 0){// Si es circulo con circulo
                float distancia = dist(this.posicion.x,this.posicion.y,entidad.posicion.x,entidad.posicion.y); // distancia entre sus centros
                float radios = (this.diametro / 2.0) + (entidad.diametro / 2.0); // Si la distancia es igual a la suma de los radios no se superponen, solo se tocan
                if( distancia <= radios ) hayColision = true;
                if( distancia < radios ){
                    if (distancia == 0) return;
                    float superposicion = radios-distancia; // cuantos pixeles esta uno dentro del otro
                    PVector direccion = PVector.sub(this.posicion,entidad.posicion).normalize();
                    direccion.mult(superposicion*0.5); // "superposicion" indica el sentido. y la magnitud. El "* 0.5" es debido a que la otra entidad tambien va a hacer este calculo entonces van a quedar justo separados pero  
                    this.posicion.add(direccion); // correcion de posicion para dejar de estar superpuesto
                }
            }
            else if(
                this.alto > 0 
                && entidad.alto > 0 
                && this.posicion.x < entidad.posicion.x + entidad.ancho 
                && this.posicion.x + this.ancho > entidad.posicion.x 
                && this.posicion.y < entidad.posicion.y + entidad.alto 
                && this.posicion.y + this.alto > entidad.posicion.y
            ) hayColision = true;
            else if(
                this.alto > 0 
                && entidad.diametro > 0 
                && dist(
                    constrain(entidad.posicion.x, this.posicion.x, this.posicion.x + this.ancho), 
                    constrain(entidad.posicion.y, this.posicion.y, this.posicion.y + this.alto), 
                    entidad.posicion.x, 
                    entidad.posicion.y
                ) < (entidad.diametro / 2)
            ) hayColision = true;
            else if(
                this.diametro > 0
                && entidad.alto > 0
                && dist(
                    constrain(this.posicion.x, entidad.posicion.x, entidad.posicion.x + entidad.ancho), 
                    constrain(this.posicion.y, entidad.posicion.y, entidad.posicion.y + entidad.alto), 
                    this.posicion.x,
                    this.posicion.y
                ) < (this.diametro / 2)
            ) hayColision = true;
            if (hayColision) {
                this.colisionandoCon.add(entidad);
                if (this.heribles.contains(entidad.getClass())) this.colisionando_heribles.add(entidad);
            }
        }
        if(this.posicion.x > width) this.posicion.sub(this.posicion.x-width,0);
        else if(this.posicion.x < 0) this.posicion.add(this.posicion.x*-1,0);
        if(this.posicion.y > height) this.posicion.sub(0,this.posicion.y-height);
        else if(this.posicion.y < 0) this.posicion.add(0,this.posicion.y*-1);
  }
    boolean herir(){
        if (this.damage == 0 || this.colisionando_heribles.isEmpty()) return false;
        boolean esta_listo = millis() - this.ultimo_golpe >= this.cooldown;
        if(esta_listo){
            print(this.getClass().getSimpleName() + " GENERO UN IMPACTO a ");
            for(Entidad enemigo : this.colisionando_heribles){
                println(enemigo.getClass().getSimpleName());
                enemigo.vida = enemigo.vida - this.damage;
                println("Vida restante: ",enemigo.vida);
            }
            this.ultimo_golpe = millis();
            return true;
        } else return false;
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
        return vida <= 0;
    }
    void actualizar(){
        this.mover();
        this.colision();
        this.mostrar();
        this.herir();
    }
}
class Bala extends Entidad{
    PVector direccion;
    Bala(PVector posicion, PVector direccion,int velocidad, int damage,int cooldown){
        super(posicion,10,1,velocidad,damage,cooldown);
        this.direccion = direccion;
        this.heribles.add(Zombie.class);
    }
    @Override
    void mover(){
        PVector paso = PVector.mult(this.direccion, this.velocidad);
        this.posicion.add(paso);
        if(this.posicion.x > width || this.posicion.x < 0 || this.posicion.y > height || this.posicion.y < 0) this.vida = -1;
    }
    @Override
    boolean herir(){
        boolean hirio = super.herir();
        if(hirio) this.vida = -1;
        return hirio;
    }
}
enum ControlesJugador {arriba,izquierda,abajo,derecha,disparo};
class Jugador extends Entidad {
    int ultimo_disparo;
    PVector arma;
    HashMap<ControlesJugador,String> controles;
    Jugador(PVector pos, int diametro, int vida, int velocidad, HashMap<ControlesJugador,String> controles){
        super(pos,diametro,vida,velocidad,0,250);
        this.controles = controles;
    }
    PVector direccion_movimiento(){
        int x = 0;
        int y = 0;
        if(teclado.get(this.controles.get(ControlesJugador.izquierda))) x = -1;
        if(teclado.get(this.controles.get(ControlesJugador.derecha))) x =  1;
        if(teclado.get(this.controles.get(ControlesJugador.arriba))) y =  -1;
        if(teclado.get(this.controles.get(ControlesJugador.abajo))) y = 1;
        return new PVector(x,y);
    }
    @Override
    void mover(){
        PVector movimiento = this.direccion_movimiento();
        movimiento.mult(this.velocidad);
        this.posicion.add(movimiento);
    }
    void mostrar_arma(){
        if(mouseX == this.posicion.x && mouseY == this.posicion.y) return;
        PVector mouse = new PVector(mouseX,mouseY);
        PVector direccion = PVector.sub(mouse, this.posicion);
        int longitud = (int) constrain(dist(this.posicion.x,this.posicion.y,mouse.x,mouse.y),this.diametro,this.diametro+7); // tamaño del arma
        direccion.setMag(longitud); 
        this.arma = PVector.add(this.posicion, direccion);
        strokeWeight(7);
        line(this.posicion.x,this.posicion.y,arma.x,arma.y);
        strokeWeight(1);
    }
    void disparar(){
        boolean listo_para_disparar = millis() - this.ultimo_disparo >= this.cooldown;
        if (listo_para_disparar) {
            if(dist(this.posicion.x,this.posicion.y,mouseX,mouseY) == 0) return;
            PVector mouse = new PVector(mouseX,mouseY);
            PVector direccion = apuntar(this.posicion, mouse); 
            Bala disparo = new Bala(this.arma.copy(),direccion,20,5,0);
            balas.add(disparo);
            this.ultimo_disparo = millis(); 
        }
    }
    @Override 
    void actualizar(){
        this.mostrar_arma();
        super.actualizar();
    }
}

class Zombie extends Entidad {
    Zombie(PVector pos, int diametro, int vida, int velocidad, int damage){
        super(pos,diametro,vida,velocidad,damage,1000);
        this.heribles.add(Jugador.class);
    }
    @Override
    void mover(){
        Entidad perseguir = null;
        float min = Float.MAX_VALUE;
        for(Entidad entidad : entidades){
            if (this.heribles.contains(entidad.getClass())) {
                float distancia = dist(this.posicion.x,this.posicion.y,entidad.posicion.x,entidad.posicion.y);
                if( distancia < min && distancia > 0) {
                    min = distancia;
                    perseguir = entidad;
                }
            }
        }
        if (perseguir != null) {
            PVector direccion = apuntar(this.posicion,perseguir.posicion);
            if(dist(this.posicion.x,this.posicion.y,perseguir.posicion.x,perseguir.posicion.y) == 0) return;
            direccion.mult(this.velocidad);
            this.posicion.add(direccion);
        }
    }
    
}
