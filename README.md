# Tower defense zombies

Integrante: Facundo Vattino
Roles:

- Game designer
- Developer
- QA testing
- Project manager

# Especificaciones técnicas

- **Paradigma POO:** Implementación estructurada mediante clases y objetos.
- **Físicas y Matemáticas:** Es obligatorio el uso de la clase `PVector` para la resolución del movimiento. Se deben implementar:
  - Movimientos (acelerados y uniformes).
  - Detección y resolución de colisiones.
  - Uso de aleatoriedad (randomness).
- **Sistemas de Partículas:** El juego debe incluir al menos una clase dedicada a la generación de partículas, utilizando arrays de objetos, con el fin de aportar dinamismo a la visualización.

# Game design

## Introducción

La temática es un juego de zombies a oleadas. La idea es que los mates antes de que lleguen a la torre y te la destruyan. Defenderte con el arma que tenés y las barreras.
Recolectar materiales para mejorar el nivel de la torre, procurando que no te hagan daño.
Si la destruyen todavia tenes chance, pero es más dificil sobrevivir.

## Bucle del juego

- Si te matan morís.
- Si se rompe la torre, no podes volver a subirte a ella
- El juego nunca termina, no ganás. Pero podés superar tu record anterior.
  El ciclo principal que se repite son las oleadas. Que spawneen los enemigos, y matarlos a todos. Eso es lo que se repite.

## Controles: Interacción del usuario

El usuario mueve al personaje con las teclas `W` `A` `S` `D`, por defecto. Pero puede cambiar los controles.
El cursor apunta el arma.
Desde la ubicación del jugador hacia el mouse es la dirección y sentido en el que van a ir las balas que salgan de su arma.

## Assets

### Gráficos

- Se utilizaran sprites y sonidos distintos al caminar, hacer daño, recolectar, morirse, reposo, reaparición y cuando es herido.
  Tanto para enemigos y el jugador. Cada clase tendrá su sonido particular, algunos sonidos pueden ser iguales para una misma acción.
- El deterioro y destrucción de estructuras también tendrá animación.
- Los objetos estando en el suelo, su aparición y el ser recolectados van a tener una animación (no necesariamente con imagenes distintas, pero se mueven)
- La estetica va a ser pixel art, con perspectiva satelital.

### Sonoros

La librería de sondio que se va a usar es: **\_\_**

# Planificación y alcance

## Producto mínimo viable

Minimamente tiene que haber:

### Mecánicas y características

- Munición que se gasta y se recolecta del suelo (lo dropean los zombies)
- Cura instantanea al pasar por arriba, la dropean los zombies
- Los zombies con mas stats dropean los materiales, pero pocos.
- Entrar y salir de la torre
- Comprar armas con diferentes caracteristicas, agarrables del suelo en una tienda dentro de la torre (con monedas que suelten los zombies)
- Mejora de la torre, con al menos un material
- Zombies de distintas caracteristicas (stats y visuales)

### Interfaz gráfica

- Barra de vida del jugador de la torre y su munición

## Deseable

Estaría muy bueno que tuviera:

### Mecánicas

- La curación es un objeto consumible que dropean los zombies. Cura con efecto incremental.
- Multijugador
- Minijefes y jefes
- Armas aparecen con muy poca probabilidad o cuando el jugador o su torre tiene poca vida y pocas rondas
- Más de un recurso para subir de nivel (y distintas cantidades para cada uno)
- Cámara que sigue al jugador + mapa de mundo abierto + minimapa

#### Minimapa

- Que aparezcan los materiales a recolectar

#### Multijugador

En la tienda puede comprar zombies con las monedas e invocarlos con el mouse para atacar al otro jugador

### Estética y animaciones

- Distinta estética con cada mejora de la torre (incremental programaticamente, que siempre haya uno distinto por la cantidad de combinaciones de posiblidades o, que el jugador dibuje su torre y en cada nivel le agrega algo)
- Estructuras y cuerpos muestran deterioro visual.

### Interfaz gráfica

- Barra de vida restante del útlimo enemigo (o de todos, con una barra pequeña)
- Aparición numerica de daño infligido que desvanece
- Puntaje incremental que se guarda como record para comparar con las siguientes partidas

# Arquitectura y código (aspectos técnicos)

## Estrategia de implementación

Hay cosas que les "pasa" o "hacen" (metodos) y cosas que "tienen" (caracteristicas/atributos) todos los objetos que aparecen en el juego.
Entonces creé la clase _entidad_, de la cuál **heredan** todas. Usando **polimorfismo** me ahorro mucho código en el `draw`.

La **aparición de enemigos** tiene que ser aleatoria.

- No vienen todos desde un mismo lado, ni tampoco es una repartición precisa entre todos los lados.
- No se incrementa exactamente la misma cantidad de enemigos, respecto a la anterior oleada.
- No se repite de un mismo lado la misma cantidad de enemgios, "pero esta vez con uno más".
- No vienen más enemigos de la ronda siguiente, antes de que terminen de matarse todos los enemigos de la ronda actual [al menos que pase X cantidad de tiempo, en ese caso la oleada terminaría igual (configurable)]
  Por lo tanto tengo que usar **procedimientos** con la libreria **random** y matemática para esta mecánica que intenta hacer ver natural la llegada de los enemigos.

Misma aleatoreidad va a estar en la aparición de los recursos del suelo.

Dependiendo de la cantidad de vida que le quede a la torre, se cargará una imagen distinta. Misma situación con el deterioro de los cuerpos.

## Arquitectura preliminar: Clases, metodos y atributos

### Entidad

Clase base que representa a cualquier elemento presente en el juego

#### Metodos

- `colision()`: detecta colisiones contra el resto de las entidades (circulo-circulo, rectangulo-rectangulo y mixtas), corrige la superposicion y evita que la entidad salga de los limites de la pantalla. Ademas, rellena las listas `colisionandoCon` y `colisionando_heribles`.
- `herir()`: Daña a las entidades heribles con las que esté colisionando, respetando el `cooldown` entre golpes. Devuelve `true` si logró herir.
- `mostrar()`: dibuja la entidad como circulo o rectangulo segun corresponda.
- `mover()`: metodo vacio pensado para ser sobreescrito por las subclases.
- `murio()`: devuelve `true` si la vida es menor o igual a cero.
- `actualizar()`: orquesta el ciclo de vida de la entidad: mover, colisionar, mostrar y herir.

#### Atributos

- `posicion`: Vector de su ubicación en la pantalla.
- `diametro`: Tamaño (si es un circulo)
- `ancho`
- `alto`
- `vida`
- `damage`: Daño que inflige al atacar.
- `ultimo_golpe`: Timestamp del último golpe que hizo (es para el cooldown)
- `cooldown`: Tiempo de espera entre golpes.
- `velocidad`
- `colisionandoCon`: Array de entidades con las que está en contacto.
- `heribles`: Array de clases a las que puede herir.
- `colisionando_heribles`: Array de entidades heribles y con las que está en contacto.

<!--
### Estructura

#### Metodos

#### Atributos

-->

### Zombie

#### Metodos

- `mover()`: persigue a la entidad herible mas cercana (el jugador) y se mueve hacia ella.

#### Atributos

Hereda todos los atributos de `Entidad`.

### Jugador

#### Metodos

- `direccion_movimiento()`: devuelve un `PVector` con la direccion de movimiento segun las teclas presionadas.
- `mover()`: actualiza la posicion segun la direccion de movimiento y la velocidad.
- `mostrar_arma()`: dibuja el arma apuntando hacia el mouse y guarda su posicion en el atributo `arma`.
- `disparar()`: crea una bala hacia la posicion del mouse respetando el cooldown de disparo.
- `actualizar()`: sobreescribe el ciclo para dibujar el arma antes de actualizar la entidad.

#### Atributos

- `ultimo_disparo`: timestamp del ultimo disparo realizado.
- `arma`: Es un vector con la posición actual del arma.
- `controles`: Es un hashmap en el que cada clave es una acción que hace el jugador, que se puede configurar y el valor es un string que representa la tecla. (el modulo `teclado.pde`, prepara el hashmap "teclas", para usar las teclas especiales con strings)

### Balas

#### Metodos

- `mover()`: desplaza la bala en su direccion y la elimina al salir de la pantalla.
- `herir()`: al impactar a un enemigo, elimina la bala.

#### Atributos

- `direccion` : Vector con direccion y sentido del movimiento de la bala.
- Hereda el resto de los atributos de `Entidad`.

## Procedimientos complejos y críticos

### Sistema de oleadas (`oleadas.pde`)

- `elegir_lados(int cantidad_lados)`: selecciona aleatoriamente que lados del mapa (arriba, abajo, izquierda, derecha) tendran enemigos, sin repetir lados.
- `repartir_enemigos(int cantidad_enemigos, boolean[] lados)`: reparte la cantidad total de enemigos entre los lados elegidos de forma aleatoria y acumulativa, de modo que la suma de las proporciones no supere el total.
- `inicializar_enemigos(int[] enemigos, boolean[] lados, int margen)`: instancia los zombies en las posiciones correspondientes a cada lado, distribuyendolos a lo largo del borde del mapa.
- `iniciar_oleada()`: orquesta el inicio de una oleada: calcula la cantidad de lados segun la progresion, elige los lados, calcula la cantidad de enemigos con crecimiento exponencial y los instancia. Tambien controla la condicion de fin de oleada.

# Dependencias

- [PVector](https://processing.org/reference/PVector.html)
- [HashMap](https://processing.org/reference/HashMap.html)
- [ArrayList](https://processing.org/reference/ArrayList.html)
- [JBox2D](https://github.com/jbox2d/jbox2d): Permite crear mundos y cuerpos
  Es un wrapper de `Box2D`, está diseñada para ser mucho más amigable y fácil de usar que la implementación de `Box2D`. Como `Box2D` me parece muy complejo, decidí utilizar `JBox2D`
- [S4P](http://www.lagers.org.uk/s4p/ref/): Sprites for processing
  Permite cargar "hojas de sprites" (spritesheets), gestionar animaciones cuadro por cuadro, y tiene funciones integradas para detectar colisiones simples (cajas o círculos) entre personajes.
- [Ani](https://github.com/b-g/Ani): librería de interpolación (tweening)
  Permite animar valores de forma suave. Por ejemplo, hacer que un menú aparezca deslizándose, o que un enemigo se mueva del punto A al punto B con aceleración y desaceleración fluida sin tener que programar físicas reales.
- [Minim](https://github.com/ddf/Minim): Librería de sonido
- [ControlP5](https://github.com/sojamo/controlp5): Librería de UI
  Permite crear un menú principal, botones de "Pausa", "Reiniciar", o barras deslizantes para ajustar el volumen, etc. Es muy personalizable y ahorra programar botones desde cero.
