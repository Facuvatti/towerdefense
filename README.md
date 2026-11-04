# Tower defense zombies

# Integrantes 
## Facundo Vattino
Roles:
- Game designer
- Developer
- Project manager
## Santiago Villaroel
Roles:
- Game designer
- Developer
- QA testing

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
Con `E` (configurable) el jugador se sube o se baja de la torre central, estando cerca de ella. Hay un cooldown entre subir y bajar.
Con `B` (configurable) entra o sale del modo construcción: arrastrando el click izquierdo dibuja barreras en vez de disparar.
Estando arriba de la torre, con `Q` (configurable) abre la tienda. Con las teclas `1` a `9` cambia entre las armas compradas.

## Assets

### Gráficos

- Se utilizaran sprites y sonidos distintos al caminar, hacer daño, recolectar, morirse, reposo, reaparición y cuando es herido.
  Tanto para enemigos y el jugador. Cada clase tendrá su sonido particular, algunos sonidos pueden ser iguales para una misma acción.
- El deterioro y destrucción de estructuras también tendrá animación.
- Los objetos estando en el suelo, su aparición y el ser recolectados van a tener una animación (no necesariamente con imagenes distintas, pero se mueven)
- La estetica va a ser pixel art, con perspectiva satelital.

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
  Por lo tanto tengo que usar **procedimientos** con la función `random()` y matemática para esta mecánica que intenta hacer ver natural la llegada de los enemigos.

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

### TorreCentral

Estructura fija en el centro del mapa que el jugador defiende. Los zombies la atacan si es lo más cercano que tienen.
Mientras el jugador está arriba, no puede caminar ni ser atacado, pero sigue disparando; los zombies van por la torre.
Si la torre cae, el jugador baja automáticamente y no puede volver a subir. El juego sigue hasta que muere el jugador.

#### Metodos

- `mover()`: vacío, la torre no se mueve.
- `mostrar()`: dibuja la torre con deterioro visual (color y grietas) según la vida que le queda.

#### Atributos

Hereda todos los atributos de `Entidad` (vida 600).

### Jugador: subir y bajar de la torre

- `alternarTorre()`: sube o baja respetando el cooldown (`cooldownTorre`, 700 ms). Solo sube si está cerca de la torre y la torre sigue en pie.
- `subir()` / `bajar()`: al bajar sale hacia donde apunta el mouse.
- `cargaTorre()`: progreso del cooldown (0 a 1), se dibuja como un arco alrededor del jugador.

### Drop

Objeto en el suelo que sueltan los zombies al morir. Se recoge al pasar por arriba (no desde arriba de la torre) y desaparece a los 15 segundos, parpadeando antes.
Tipos: munición, cura instantánea, monedas y material (solo de los zombies tanque, y pocos).
La munición y la cura solo se recogen si al jugador le faltan, y salen con más probabilidad cuando le quedan pocas balas o poca vida.

#### Metodos

- `util()`: si al jugador le sirve recogerlo.
- `actualizar()`: movimiento desacelerado al salir del zombie e imán hacia el jugador cuando está cerca.
- `mostrar()`: dibuja el objeto según su tipo, flotando; la moneda gira.

#### Funciones (`Drop.pde`)

- `soltarDrops(Zombie z)`: reparte el botín en monedas (1 a 2, 3 los tanques, 5 los jefes) y tira al azar munición, cura y material (los jefes sueltan 3 materiales seguros).
- `recoger(Drop d)`: aplica el efecto del drop al jugador.

### Barrera (`Barrera.pde`)

Muro dibujado a mano con el mouse. Es una polilínea (`ArrayList<PVector>`) con vida, que crece con su largo.

- **Madera:** cada píxel dibujado gasta madera. Se empieza con 300 y se compra más en la tienda (+150 por $40).
- **Largo máximo:** cada pedazo mide como mucho 130 px. Al llegar al límite el trazo se corta y hay que soltar el mouse para empezar otro.
- **Hueco obligatorio:** entre una barrera y otra (y entre una barrera y la torre) tiene que quedar al menos 32 px. Así nunca se puede cerrar la torre: los zombies comunes (y los tanques, de 30 px) pasan por los huecos. Si el trazo se acerca demasiado a otra barrera, se corta ahí. En modo construcción las zonas prohibidas se ven en rojo.
- **Zombies:** chocan con las barreras y las rodean siguiendo un campo de flujo (ver `Camino.pde`). Las balas pasan por encima.
- **Sin encierros:** el hueco también se exige contra el propio trazo (no se puede cerrar sobre sí mismo), contra los bordes del mapa, la torre y las torretas.
- **Jefes:** son más anchos que el hueco, así que no pasan: golpean la barrera hasta romperla. La barrera muestra su deterioro y una barra de vida.

#### Metodos

- `agregar(p)`: suma un punto al trazo, aumenta el largo y la vida.
- `puntoCercano(p)` / `distancia(p)`: proyección de un punto sobre la polilínea; guarda la `tangente` del segmento más cercano.
- `empujar(e)`: resuelve la colisión círculo-barrera empujando a la entidad afuera.

#### Funciones

- `construirBarrera()`: mientras se arrastra el mouse, avanza de a 8 px validando cada punto (largo, madera y huecos).
- `motivoInvalido(p, propia)`: por qué no se puede poner un punto ahí (o `null`).

### Camino (`Camino.pde`)

Campo de flujo: una grilla de celdas de 8 px donde cada celda guarda cuántos pasos faltan hasta el objetivo más cercano (jugador, torre o torretas), calculado con un BFS desde los objetivos. Las celdas pegadas a una barrera quedan bloqueadas. Cada zombie se mueve hacia la celda vecina más cercana al objetivo, así rodea las barreras y sale de formas en U. Si no hay barreras, van derecho. Los jefes no lo usan: van derecho y rompen la barrera que les bloquee el paso.

### Torretas (`Torre.pde`)

Se compran con click derecho ($100). Tiene que haber al menos 90 px entre torretas, y no se pueden poner pegadas a la torre ni a una barrera. El jugador y los zombies chocan con ellas. Se deterioran con el tiempo (1 de vida cada 40 frames, unos 100 segundos) además del daño de los zombies, y se ven cada vez más gastadas.

### Jefe

Zombie tipo 3: aparece cada 5 oleadas (uno más cada vez). Mucha vida, lento, pega fuerte, rompe barreras y suelta 3 materiales.

### Tienda (`Tienda.pde`)

Está dentro de la torre: solo se abre estando arriba, y pausa el juego mientras está abierta. Si la torre cae, no hay más tienda.
Se compra con monedas (y materiales para mejorar la torre):

- Armas: Escopeta ($250), Francotirador ($350), Ametralladora ($450). Las compradas se pueden volver a equipar gratis.
- Munición +30 ($40), botiquín +50 vida ($50), reparar torre +150 ($60).
- Mejorar torre: nivel `n` a `n+1` cuesta `$120·n` y `n` materiales. Cada nivel da +200 de vida máxima, la repara 200 y le agrega una bandera (dorada al nivel máximo, 5).

`ItemTienda` sabe su nombre, detalle, precio, si está disponible y qué hace al comprarse.

### Arma (`Arma.pde`)

Define cómo dispara el jugador: daño, cooldown, cantidad de perdigones, dispersión, velocidad y alcance de la bala, cuántos zombies atraviesa, retroceso y su aspecto.
`disparar(boca, dir)` crea las balas. `catalogo` tiene todas las armas; la primera (Pistola) es la inicial.

| Arma | Daño | Disparos/min | Particularidad |
|---|---|---|---|
| Pistola | 25 | ~430 | Inicial |
| Escopeta | 18 x6 | ~90 | Perdigones abiertos, poco alcance |
| Francotirador | 120 | ~65 | Atraviesa 3 zombies |
| Ametralladora | 14 | ~860 | Gasta munición muy rápido |

### Munición del jugador

El jugador empieza con 60 balas (máximo 150). Cada disparo gasta una; sin balas no dispara y aparece "SIN BALAS".
Entre oleadas recibe +20 balas, para no quedar trabado.

### Balas

#### Metodos

- `mover()`: desplaza la bala en su direccion y la elimina al salir de la pantalla.
- `herir()`: al impactar a un enemigo, elimina la bala.

#### Atributos

- `direccion` : Vector con direccion y sentido del movimiento de la bala.
- `alcance`: frames que vive la bala.
- `perfora`: cuántos zombies más puede atravesar; `golpeados` evita pegarle dos veces al mismo.
- Hereda el resto de los atributos de `Entidad`.

## Procedimientos complejos y críticos

### Sistema de oleadas (`oleadas.pde`)

- `elegir_lados(int cantidad_lados)`: selecciona aleatoriamente que lados del mapa (arriba, abajo, izquierda, derecha) tendran enemigos, sin repetir lados.
- `repartir_enemigos(int cantidad_enemigos, boolean[] lados)`: reparte la cantidad total de enemigos entre los lados elegidos de forma aleatoria y acumulativa, de modo que la suma de las proporciones no supere el total.
- `inicializar_enemigos(int[] enemigos, boolean[] lados, int margen)`: instancia los zombies en las posiciones correspondientes a cada lado, distribuyendolos a lo largo del borde del mapa.
- `iniciar_oleada()`: orquesta el inicio de una oleada: calcula la cantidad de lados segun la progresion, elige los lados, calcula la cantidad de enemigos con crecimiento exponencial y los instancia. Tambien controla la condicion de fin de oleada.
