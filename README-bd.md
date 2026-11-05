# Rama bd

Esta rama parte de **tienda-mejoras** y conserva sus sistemas de tienda, torre central, torretas, drops, armas comprables, jefes y barreras.

## Persistencia
Se crea `data/towerdefense_db.json` dentro de la carpeta del sketch. Guarda jugadores, partidas y puntajes, además del estado para reanudar: jugador, inventario de armas, oleada, zombis, proyectiles, torretas, torre central, drops, barreras, monedas, materiales y madera.

El guardado se realiza cada 120 frames, al pausar, al interactuar con la tienda y al cerrar el sketch.

## Jugar y reanudar
1. Elegí **JUGAR** y escribí quién está jugando.
2. Si ese jugador tiene partidas activas, elegí una con las flechas y presioná ENTER.
3. Presioná **N** para crear una partida nueva.
4. Al perder, el puntaje final queda registrado.

## Taller de creaciones
Entrá por **CREAR ARMAS / ZOMBIS** o presioná **E** desde el menú. Dibujá con el mouse, escribí el nombre, seleccioná atributos con 1 a 4 y ajustalos con las flechas. TAB alterna entre arma y zombi; DELETE borra el dibujo; ENTER guarda y ESC vuelve al menú.

Las armas personalizadas se agregan al inventario y se pueden equipar con las teclas numéricas. Los zombis personalizados pueden aparecer en las oleadas.

## Almacenamiento
La base de datos es un archivo JSON local; no sincroniza partidas entre computadoras.
