import java.util.HashMap;
import java.util.Map;
// 1. VARIABLES BOOLEANAS INDIVIDUALES (Inicializadas en false por defecto en Java)
boolean a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z;
boolean n0, n1, n2, n3, n4, n5, n6, n7, n8, n9;
boolean up, down, left, right, shift, control, alt, enter, backspace, tab, esc, space;

// 2. DICCIONARIO (HASHMAP)
HashMap<String, Boolean> teclado = new HashMap<String, Boolean>();
void inicializarTeclado() {
  String[] letras = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"};
  for (String l : letras) teclado.put(l, false);
  
  for (int num = 0; num <= 9; num++) teclado.put(String.valueOf(num), false);
  
  teclado.put("up", false);
  teclado.put("down", false);
  teclado.put("left", false);
  teclado.put("right", false);
  teclado.put("shift", false);
  teclado.put("control", false);
  teclado.put("alt", false);
  teclado.put("enter", false);
  teclado.put("backspace", false);
  teclado.put("tab", false);
  teclado.put("esc", false);
  teclado.put("space", false);
}

// 3. EVENTO KEY PRESSED
void keyPressed() {
  // ---- TECLAS NO ESPECIALES (Letras) ----
  if (key == 'a' || key == 'A') { a = true; teclado.put("a", true); }
  if (key == 'b' || key == 'B') { b = true; teclado.put("b", true); }
  if (key == 'c' || key == 'C') { c = true; teclado.put("c", true); }
  if (key == 'd' || key == 'D') { d = true; teclado.put("d", true); }
  if (key == 'e' || key == 'E') { e = true; teclado.put("e", true); }
  if (key == 'f' || key == 'F') { f = true; teclado.put("f", true); }
  if (key == 'g' || key == 'G') { g = true; teclado.put("g", true); }
  if (key == 'h' || key == 'H') { h = true; teclado.put("h", true); }
  if (key == 'i' || key == 'I') { i = true; teclado.put("i", true); }
  if (key == 'j' || key == 'J') { j = true; teclado.put("j", true); }
  if (key == 'k' || key == 'K') { k = true; teclado.put("k", true); }
  if (key == 'l' || key == 'L') { l = true; teclado.put("l", true); }
  if (key == 'm' || key == 'M') { m = true; teclado.put("m", true); }
  if (key == 'n' || key == 'N') { n = true; teclado.put("n", true); }
  if (key == 'o' || key == 'O') { o = true; teclado.put("o", true); }
  if (key == 'p' || key == 'P') { p = true; teclado.put("p", true); }
  if (key == 'q' || key == 'Q') { q = true; teclado.put("q", true); }
  if (key == 'r' || key == 'R') { r = true; teclado.put("r", true); }
  if (key == 's' || key == 'S') { s = true; teclado.put("s", true); }
  if (key == 't' || key == 'T') { t = true; teclado.put("t", true); }
  if (key == 'u' || key == 'U') { u = true; teclado.put("u", true); }
  if (key == 'v' || key == 'V') { v = true; teclado.put("v", true); }
  if (key == 'w' || key == 'W') { w = true; teclado.put("w", true); }
  if (key == 'x' || key == 'X') { x = true; teclado.put("x", true); }
  if (key == 'y' || key == 'Y') { y = true; teclado.put("y", true); }
  if (key == 'z' || key == 'Z') { z = true; teclado.put("z", true); }

  // ---- TECLAS NO ESPECIALES (Números) ----
  if (key == '0') { n0 = true; teclado.put("0", true); }
  if (key == '1') { n1 = true; teclado.put("1", true); }
  if (key == '2') { n2 = true; teclado.put("2", true); }
  if (key == '3') { n3 = true; teclado.put("3", true); }
  if (key == '4') { n4 = true; teclado.put("4", true); }
  if (key == '5') { n5 = true; teclado.put("5", true); }
  if (key == '6') { n6 = true; teclado.put("6", true); }
  if (key == '7') { n7 = true; teclado.put("7", true); }
  if (key == '8') { n8 = true; teclado.put("8", true); }
  if (key == '9') { n9 = true; teclado.put("9", true); }

  // ---- TECLAS ESPECIALES (keyCode) ----
  if (key == CODED) {
    if (keyCode == UP)      { up = true;      teclado.put("up", true); }
    if (keyCode == DOWN)    { down = true;    teclado.put("down", true); }
    if (keyCode == LEFT)    { left = true;    teclado.put("left", true); }
    if (keyCode == RIGHT)   { right = true;   teclado.put("right", true); }
    if (keyCode == SHIFT)   { shift = true;   teclado.put("shift", true); }
    if (keyCode == CONTROL) { control = true; teclado.put("control", true); }
    if (keyCode == ALT)     { alt = true;     teclado.put("alt", true); }
  } else {
    if (keyCode == ENTER)     { enter = true;     teclado.put("enter", true); }
    if (keyCode == BACKSPACE) { backspace = true; teclado.put("backspace", true); }
    if (keyCode == TAB)       { tab = true;       teclado.put("tab", true); }
    if (keyCode == ESC)       { esc = true;       teclado.put("esc", true); }
    if (keyCode == ' ')       { space = true;     teclado.put("space", true); }
  }
}

// 4. EVENTO KEY RELEASED
void keyReleased() {
  // ---- TECLAS NO ESPECIALES (Letras) ----
  if (key == 'a' || key == 'A') { a = false; teclado.put("a", false); }
  if (key == 'b' || key == 'B') { b = false; teclado.put("b", false); }
  if (key == 'c' || key == 'C') { c = false; teclado.put("c", false); }
  if (key == 'd' || key == 'D') { d = false; teclado.put("d", false); }
  if (key == 'e' || key == 'E') { e = false; teclado.put("e", false); }
  if (key == 'f' || key == 'F') { f = false; teclado.put("f", false); }
  if (key == 'g' || key == 'G') { g = false; teclado.put("g", false); }
  if (key == 'h' || key == 'H') { h = false; teclado.put("h", false); }
  if (key == 'i' || key == 'I') { i = false; teclado.put("i", false); }
  if (key == 'j' || key == 'J') { j = false; teclado.put("j", false); }
  if (key == 'k' || key == 'K') { k = false; teclado.put("k", false); }
  if (key == 'l' || key == 'L') { l = false; teclado.put("l", false); }
  if (key == 'm' || key == 'M') { m = false; teclado.put("m", false); }
  if (key == 'n' || key == 'N') { n = false; teclado.put("n", false); }
  if (key == 'o' || key == 'O') { o = false; teclado.put("o", false); }
  if (key == 'p' || key == 'P') { p = false; teclado.put("p", false); }
  if (key == 'q' || key == 'Q') { q = false; teclado.put("q", false); }
  if (key == 'r' || key == 'R') { r = false; teclado.put("r", false); }
  if (key == 's' || key == 'S') { s = false; teclado.put("s", false); }
  if (key == 't' || key == 'T') { t = false; teclado.put("t", false); }
  if (key == 'u' || key == 'U') { u = false; teclado.put("u", false); }
  if (key == 'v' || key == 'V') { v = false; teclado.put("v", false); }
  if (key == 'w' || key == 'W') { w = false; teclado.put("w", false); }
  if (key == 'x' || key == 'X') { x = false; teclado.put("x", false); }
  if (key == 'y' || key == 'Y') { y = false; teclado.put("y", false); }
  if (key == 'z' || key == 'Z') { z = false; teclado.put("z", false); }

  // ---- TECLAS NO ESPECIALES (Números) ----
  if (key == '0') { n0 = false; teclado.put("0", false); }
  if (key == '1') { n1 = false; teclado.put("1", false); }
  if (key == '2') { n2 = false; teclado.put("2", false); }
  if (key == '3') { n3 = false; teclado.put("3", false); }
  if (key == '4') { n4 = false; teclado.put("4", false); }
  if (key == '5') { n5 = false; teclado.put("5", false); }
  if (key == '6') { n6 = false; teclado.put("6", false); }
  if (key == '7') { n7 = false; teclado.put("7", false); }
  if (key == '8') { n8 = false; teclado.put("8", false); }
  if (key == '9') { n9 = false; teclado.put("9", false); }

  // ---- TECLAS ESPECIALES (keyCode) ----
  if (key == CODED) {
    if (keyCode == UP)      { up = false;      teclado.put("up", false); }
    if (keyCode == DOWN)    { down = false;    teclado.put("down", false); }
    if (keyCode == LEFT)    { left = false;    teclado.put("left", false); }
    if (keyCode == RIGHT)   { right = false;   teclado.put("right", false); }
    if (keyCode == SHIFT)   { shift = false;   teclado.put("shift", false); }
    if (keyCode == CONTROL) { control = false; teclado.put("control", false); }
    if (keyCode == ALT)     { alt = false;     teclado.put("alt", false); }
  } else {
    if (keyCode == ENTER)     { enter = false;     teclado.put("enter", false); }
    if (keyCode == BACKSPACE) { backspace = false; teclado.put("backspace", false); }
    if (keyCode == TAB)       { tab = false;       teclado.put("tab", false); }
    if (keyCode == ESC)       { esc = false;       teclado.put("esc", false); }
    if (keyCode == ' ')       { space = false;     teclado.put("space", false); }
  }
}
