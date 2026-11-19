# Rama bd

Esta rama conserva los sistemas de tienda, torre central, torretas, drops, armas comprables, jefes y barreras.

## Base de datos SQLite

La persistencia ahora usa **SQLite real** en `data/towerdefense.sqlite`; ya no crea ni utiliza `towerdefense_db.json`.

El esquema SQL contiene:
- `jugadores`: nombre y última actividad.
- `partidas`: jugador, estado, fecha, oleada y puntaje; el estado completo de la partida se guarda como snapshot asociado al registro.
- `puntajes`: resultados finales relacionados con su partida.
- `creaciones`: armas y zombis personalizados.

Las tablas tienen claves primarias, claves foráneas e índices para consultar partidas por jugador/estado y ordenar puntajes. Las escrituras se realizan dentro de transacciones.

### Dependencia necesaria

El sketch utiliza el driver JDBC de SQLite de Xerial. Descargá [sqlite-jdbc 3.46.1.0 (.jar)](https://repo.maven.apache.org/maven2/org/xerial/sqlite-jdbc/3.46.1.0/sqlite-jdbc-3.46.1.0.jar) y colocá el JAR dentro de la carpeta `code/` del sketch (creala si no existe). Después reiniciá Processing.

Sin ese driver, Processing mostrará un error indicando que no puede cargar `org.sqlite.JDBC`.

El archivo de base de datos se crea automáticamente al iniciar el juego. No hace falta instalar ni ejecutar un servidor de base de datos.

## Jugar y reanudar

1. Elegí **JUGAR** y escribí quién está jugando.
2. Si ese jugador tiene partidas activas, elegí una con las flechas y presioná ENTER.
3. Presioná **N** para crear una partida nueva.
4. Al perder, el puntaje final queda registrado.

El guardado se realiza cada 120 frames, al pausar, al interactuar con la tienda y al cerrar el sketch.

## Taller de creaciones

Entrá por **CREAR ARMAS / ZOMBIS** o presioná **E** desde el menú. Dibujá con el mouse, escribí el nombre, seleccioná atributos con 1 a 4 y ajustalos con las flechas. TAB alterna entre arma y zombi; DELETE borra el dibujo; ENTER guarda y ESC vuelve al menú.

Las armas personalizadas se agregan al inventario y se pueden equipar con las teclas numéricas. Los zombis personalizados pueden aparecer en las oleadas.

## Alcance

SQLite guarda los datos localmente en el equipo donde se ejecuta el sketch. Para sincronizar entre computadoras haría falta una API/servidor compartido; esta implementación no simula esa sincronización.
