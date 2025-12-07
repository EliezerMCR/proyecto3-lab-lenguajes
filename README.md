# Piedra, Papel, Tijera, Lagarto, Spock

## CI-3661 - Laboratorio de Lenguajes de Programación I
### Universidad Simón Bolívar - Septiembre-Diciembre 2025

---

## Integrantes

| Nombre        | Carnet          |
|---------------|-------------|
| Eliezer Cario | 18-10605    |
| Angel Rodriguez    | [Bro pon tu carné y formatea esto de nuevo para que se vea como tabla]  |

---

## Descripción

Implementación del juego extendido "Piedra, Papel, Tijera, Lagarto, Spock" en Ruby, con interfaz gráfica usando la gema Shoes.

### Reglas del Juego

- Tijera corta a Papel
- Papel tapa a Piedra
- Piedra aplasta a Lagarto
- Lagarto envenena a Spock
- Spock rompe a Tijera
- Tijera decapita a Lagarto
- Lagarto devora a Papel
- Papel desautoriza a Spock
- Spock vaporiza a Piedra
- Piedra aplasta a Tijera

---

## Estructura del Proyecto

```
proyecto3-lab-lenguajes/
├── RPTLS.rb          # Archivo principal con todas las clases
├── README.md         # Este archivo
└── assets/           # Imágenes del juego
    ├── hand.png      # Piedra
    ├── paper.png     # Papel
    ├── scissors.png  # Tijera
    ├── lizard.png    # Lagarto
    └── spock.png     # Spock
```

---

## Dependencias

- **Ruby** (versión 2.5 o superior)
- **Bundler** (para manejo de gemas)
- **Shoes 4** (interfaz gráfica)

---

## Instalación

### 1. Instalar Ruby

#### Ubuntu/Debian:
# HAY QUE HACER BIEN ESTO DE INSTALAR

#### Windows:
Descargar e instalar desde [RubyInstaller](https://rubyinstaller.org/)

### 2. Instalar dependencias con Bundler

```bash
bundle install
```

---

## Ejecución

```bash
bundle exec shoes RPTLS.rb
```

**Nota:** Si `shoes` no está disponible como comando, puede ejecutarse con:
```bash
bundle exec ruby RPTLS.rb
```

---

## Uso

### Configuración de la Partida

1. **Nombres de los jugadores**: Ingresa los nombres en los campos de texto.

2. **Estrategias disponibles**:
   - **Manual**: El jugador selecciona su jugada manualmente.
   - **Uniforme**: Selecciona aleatoriamente de una lista de jugadas (distribución uniforme).
   - **Sesgada**: Selecciona según pesos definidos para cada jugada.
   - **Copiar**: Copia la última jugada del oponente.
   - **Pensar**: Analiza el historial del oponente y contrarresta.

3. **Parámetros de estrategias**:
   - **Uniforme**: Lista de jugadas separadas por coma.
     ```
     Piedra,Papel,Tijera
     ```
   - **Sesgada**: Hash con pesos para cada jugada.
     ```
     {Piedra: 2, Papel: 1, Tijera: 3, Lagarto: 1, Spock: 1}
     ```

4. **Modos de juego**:
   - **Rondas**: Se juega un número fijo N de rondas.
   - **Alcanzar**: Se juega hasta que un jugador alcance N puntos.

## Implementación

### Jerarquía de Jugadas

```
Jugada (clase padre)
├── Piedra
├── Papel
├── Tijera
├── Lagarto
└── Spock
```

Cada clase implementa:
- `to_s`: Representación en string.
- `puntos(contrincante)`: Retorna `[1, 0]` si gana, `[0, 1]` si pierde, `[0, 0]` si empata.

### Jerarquía de Estrategias

```
Estrategia (clase padre, @@semillaPadre = 42)
├── Manual
├── Uniforme
├── Sesgada
├── Copiar
└── Pensar
```

Todas implementan el método `prox(jugada_anterior_oponente)` que retorna la siguiente jugada.

### Clase Partida

Gestiona el flujo del juego entre dos jugadores, soportando:
- Modo Rondas (N iteraciones fijas)
- Modo Alcanzar (hasta N puntos)

---