#!/usr/bin/env ruby
# encoding: utf-8
# Proyecto 3: Piedra, Papel, Tijera, Lagarto, Spock
# CI-3661 - Laboratorio de Lenguajes de Programación I
# Universidad Simón Bolívar

require 'shoes'

# JERARQUÍA DE JUGADAS
class Jugada
  VICTORIAS = {
    :Tijera => { :Papel => "corta", :Lagarto => "decapita" },
    :Papel => { :Piedra => "tapa", :Spock => "desautoriza" },
    :Piedra => { :Lagarto => "aplasta", :Tijera => "aplasta" },
    :Lagarto => { :Spock => "envenena", :Papel => "devora" },
    :Spock => { :Tijera => "rompe", :Piedra => "vaporiza" }
  }

  IMAGENES = {
    :Piedra => "assets/hand.png",
    :Papel => "assets/paper.png",
    :Tijera => "assets/scissors.png",
    :Lagarto => "assets/lizard.png",
    :Spock => "assets/spock.png"
  }

  TODAS = [:Piedra, :Papel, :Tijera, :Lagarto, :Spock]

  def to_s
    self.class.name
  end

  def tipo
    self.class.name.to_sym
  end

  def imagen
    IMAGENES[tipo]
  end

  def puntos(contrincante)
    mi_tipo = self.tipo
    otro_tipo = contrincante.tipo
    return [0, 0] if mi_tipo == otro_tipo
    if VICTORIAS[mi_tipo] && VICTORIAS[mi_tipo][otro_tipo]
      return [1, 0]
    end
    [0, 1]
  end

  def self.crear(tipo)
    case tipo
    when :Piedra then Piedra.new
    when :Papel then Papel.new
    when :Tijera then Tijera.new
    when :Lagarto then Lagarto.new
    when :Spock then Spock.new
    else raise ArgumentError, "Tipo de jugada desconocido: #{tipo}"
    end
  end

  def self.vencedores_de(tipo)
    vencedores = []
    VICTORIAS.each do |ganador, perdedores|
      vencedores << ganador if perdedores.key?(tipo)
    end
    vencedores
  end
end

class Piedra < Jugada; end
class Papel < Jugada; end
class Tijera < Jugada; end
class Lagarto < Jugada; end
class Spock < Jugada; end


# JERARQUÍA DE ESTRATEGIAS
class Estrategia
  @@semillaPadre = 42
  @@rng = Random.new(@@semillaPadre)

  def self.reset_rng
    @@rng = Random.new(@@semillaPadre)
  end

  def prox(j = nil)
    raise NotImplementedError, "Las subclases deben implementar prox()"
  end

  def necesita_input?
    false
  end

  protected

  def random
    @@rng
  end
end

class Manual < Estrategia
  attr_accessor :jugada_seleccionada

  def initialize
    @jugada_seleccionada = nil
  end

  def prox(j = nil)
    if @jugada_seleccionada
      jugada = Jugada.crear(@jugada_seleccionada)
      @jugada_seleccionada = nil
      return jugada
    end
    nil
  end

  def necesita_input?
    true
  end
end

class Uniforme < Estrategia
  def initialize(movimientos)
    @movimientos = movimientos.uniq
    if @movimientos.empty?
      raise ArgumentError, "La lista de movimientos no puede estar vacía. Usa al menos uno de: #{Jugada::TODAS.join(', ')}."
  end
   @movimientos.each do |mov|
      unless Jugada::TODAS.include?(mov)
        raise ArgumentError, "Movimiento inválido: '#{mov}'. Los movimientos válidos son: #{Jugada::TODAS.join(', ')}."
      end
    end
  end
  def prox(j = nil)
    tipo = @movimientos[random.rand(@movimientos.length)]
    Jugada.crear(tipo)
  end
end

class Sesgada < Estrategia
  def initialize(pesos)
    @pesos = pesos
    @total = pesos.values.sum.to_f
  end

  def prox(j = nil)
    r = random.rand * @total
    acumulado = 0.0
    @pesos.each do |jugada, peso|
      acumulado += peso
      return Jugada.crear(jugada) if r <= acumulado
    end
    Jugada.crear(@pesos.keys.last)
  end
end

class Copiar < Estrategia
  def initialize
    @primera_ronda = true
  end

  def prox(j = nil)
    if @primera_ronda || j.nil?
      @primera_ronda = false
      tipo = Jugada::TODAS[random.rand(Jugada::TODAS.length)]
      return Jugada.crear(tipo)
    end
    Jugada.crear(j.tipo)
  end

  def reset
    @primera_ronda = true
  end
end

class Pensar < Estrategia
  def initialize
    @historial = Hash.new(0)
    Jugada::TODAS.each { |t| @historial[t] = 0 }
  end

  def prox(j = nil)
    @historial[j.tipo] += 1 if j
    total = @historial.values.sum

    if total == 0
      tipo = Jugada::TODAS[random.rand(Jugada::TODAS.length)]
      return Jugada.crear(tipo)
    end

    jugada_mas_probable = @historial.max_by { |_, v| v }[0]
    vencedores = Jugada.vencedores_de(jugada_mas_probable)

    if vencedores.empty?
      tipo = Jugada::TODAS[random.rand(Jugada::TODAS.length)]
    else
      tipo = vencedores[random.rand(vencedores.length)]
    end
    Jugada.crear(tipo)
  end

  def reset
    @historial = Hash.new(0)
    Jugada::TODAS.each { |t| @historial[t] = 0 }
  end
end


# CLASE PARTIDA
class Partida
  attr_reader :jugador1, :jugador2, :estrategia1, :estrategia2
  attr_reader :puntos1, :puntos2, :ronda_actual
  attr_reader :ultima_jugada1, :ultima_jugada2

  def initialize(config)
    @jugador1 = config[:Jugador1] || "Jugador 1"
    @jugador2 = config[:Jugador2] || "Jugador 2"
    @estrategia1 = config[:Estrategia1]
    @estrategia2 = config[:Estrategia2]
    @puntos1 = 0
    @puntos2 = 0
    @ronda_actual = 0
    @ultima_jugada1 = nil
    @ultima_jugada2 = nil
  end

  def jugar_ronda
    j1 = @estrategia1.prox(@ultima_jugada2)
    j2 = @estrategia2.prox(@ultima_jugada1)
    return nil if j1.nil? || j2.nil?

    @ultima_jugada1 = j1
    @ultima_jugada2 = j2

    resultado = j1.puntos(j2)
    @puntos1 += resultado[0]
    @puntos2 += resultado[1]
    @ronda_actual += 1

    {
      jugada1: j1,
      jugada2: j2,
      resultado: resultado,
      puntos: [@puntos1, @puntos2]
    }
  end

  def rondas(n)
    resultados = []
    n.times do
      resultado = jugar_ronda
      resultados << resultado if resultado
    end
    resultados
  end

  def alcanzar(n)
    resultados = []
    while @puntos1 < n && @puntos2 < n
      resultado = jugar_ronda
      resultados << resultado if resultado
    end
    resultados
  end

  def ganador
    if @puntos1 > @puntos2
      @jugador1
    elsif @puntos2 > @puntos1
      @jugador2
    else
      nil
    end
  end

  def terminado?(modo, n)
    case modo
    when :rondas
      @ronda_actual >= n
    when :alcanzar
      @puntos1 >= n || @puntos2 >= n
    else
      false
    end
  end

  def reset
    @puntos1 = 0
    @puntos2 = 0
    @ronda_actual = 0
    @ultima_jugada1 = nil
    @ultima_jugada2 = nil
    @estrategia1.reset if @estrategia1.respond_to?(:reset)
    @estrategia2.reset if @estrategia2.respond_to?(:reset)
    Estrategia.reset_rng
  end
end


# INTERFAZ GRÁFICA CON SHOES
Shoes.app(title: "Piedra, Papel, Tijera, Lagarto, Spock", width: 900, height: 700) do
  background white

  @partida = nil
  @modo = :rondas
  @n_valor = 5

  def crear_estrategia(tipo, params = nil)
    case tipo
    when "Manual"
      Manual.new
    when "Uniforme"
      if params && !params.empty?
        movs = params.split(",").map { |s| s.strip.to_sym }
        movs = movs.select { |m| Jugada::TODAS.include?(m) }
        movs = Jugada::TODAS if movs.empty?
      else
        movs = Jugada::TODAS
      end
      Uniforme.new(movs)
    when "Sesgada"
      if params && !params.empty?
        begin
          pesos = eval(params)
          pesos = pesos.transform_keys(&:to_sym) if pesos.is_a?(Hash)
        rescue
          pesos = { Piedra: 1, Papel: 1, Tijera: 1, Lagarto: 1, Spock: 1 }
        end
      else
        pesos = { Piedra: 1, Papel: 1, Tijera: 1, Lagarto: 1, Spock: 1 }
      end
      Sesgada.new(pesos)
    when "Copiar"
      Copiar.new
    when "Pensar"
      Pensar.new
    else
      Uniforme.new(Jugada::TODAS)
    end
  end

  def mostrar_configuracion
    @main_stack.clear if @main_stack
    @modo = :rondas  # Reiniciar el modo por defecto
    
    @main_stack = stack(margin: 20) do
       # Título principal
      background rgb(240, 248, 255)  # Fondo azul claro
      title "Piedra, Papel, Tijera, Lagarto, Spock", align: "center", stroke: rgb(70, 130, 180)  # Azul steel
      para "Configura tu partida", align: "center", size: 14, margin_bottom: 20, stroke: rgb(100, 100, 100)

      # Configuración de los jugadores
      flow(margin_top: 20) do
        stack(width: 400, margin: 10) do
          subtitle "Jugador 1"
          para "Nombre:"
          @nombre1 = edit_line("Jugador 1", width: 300)
          para "Estrategia:"
          @estrategia1_select = list_box(items: ["Manual", "Uniforme", "Sesgada", "Copiar", "Pensar"],
                                          width: 300, choose: "Manual")
          para "Parámetros (opcional):"
          @params1 = edit_line("", width: 300)
          para "Uniforme: Piedra,Papel,Tijera,Lagarto,Spock", size: 9, stroke: gray
          para "Sesgada: {Piedra: 2, Papel: 1, Tijera: 1}", size: 9, stroke: gray
        end

        stack(width: 400, margin: 10) do
          subtitle "Jugador 2"
          para "Nombre:"
          @nombre2 = edit_line("Jugador 2", width: 300)
          para "Estrategia:"
          @estrategia2_select = list_box(items: ["Manual", "Uniforme", "Sesgada", "Copiar", "Pensar"],
                                          width: 300, choose: "Uniforme")
          para "Parámetros (opcional):"
          @params2 = edit_line("", width: 300)
          para "Uniforme: Piedra,Papel,Tijera,Lagarto,Spock", size: 9, stroke: gray
          para "Sesgada: {Piedra: 2, Papel: 1, Tijera: 1}", size: 9, stroke: gray
        end
      end

      # Recrear los radio buttons para el modo de juego
      stack(margin: 20) do
        subtitle "Modo de Juego"
        flow do
          @modo_rondas = check { @modo = :rondas; @modo_alcanzar.checked = false }
          para "Rondas (número fijo de iteraciones)", margin_left: 5, align: "automatic"
        end
        flow do
          @modo_alcanzar = check { @modo = :alcanzar; @modo_rondas.checked = false }
          para "Alcanzar (hasta N puntos)", margin_left: 5, align: "automatic"
        end
        @modo_rondas.checked = true  # Seleccionar "Rondas" por defecto
      end

        # Restablecer el valor de N
        flow(margin_top: 10) do
          para "Valor de N: "
          @n_input = edit_line("5", width: 100)
        end
      

      # Botón para iniciar partida
      flow(margin_top: 30) do
        button("Iniciar Partida", width: 200, height: 50) do
          iniciar_partida
        end
      end
    end
  end

  def iniciar_partida
    e1 = crear_estrategia(@estrategia1_select.text, @params1.text)
    e2 = crear_estrategia(@estrategia2_select.text, @params2.text)

    @n_valor = @n_input.text.to_i
    @n_valor = 5 if @n_valor <= 0

    @partida = Partida.new({
      Jugador1: @nombre1.text,
      Jugador2: @nombre2.text,
      Estrategia1: e1,
      Estrategia2: e2
    })

    Estrategia.reset_rng
    mostrar_juego
  end

  def mostrar_juego
    @main_stack.clear if @main_stack

    @main_stack = stack(margin: 20) do
      title "Piedra, Papel, Tijera, Lagarto, Spock", align: "center"

      @marcador = para "#{@partida.jugador1}: 0 - #{@partida.jugador2}: 0",
                       align: "center", size: 18, weight: "bold", padding_bottom: 10

      @info_modo = para "Modo: #{@modo == :rondas ? 'Rondas' : 'Alcanzar'} - N: #{@n_valor} | Ronda: 0",
                        align: "center", size: 12

      flow(margin_top: 20) do
        @panel1 = stack(width: 400, margin: 10) do
          @label1 = subtitle @partida.jugador1, align: "center"
          @img1_container = flow(width: 350, height: 350) do
            background lightgray
            para "?", align: "center", size: 100, margin_top: 120
          end
          @jugada1_label = para "", align: "center", size: 14, weight: "bold"
        end

        stack(width: 80) do
          para "VS", align: "center", size: 24, weight: "bold", margin_top: 150
        end

        @panel2 = stack(width: 400, margin: 10) do
          @label2 = subtitle @partida.jugador2, align: "center"
          @img2_container = flow(width: 350, height: 350) do
            background lightgray
            para "?", align: "center", size: 100, margin_top: 120
          end
          @jugada2_label = para "", align: "center", size: 14, weight: "bold"
        end
      end

      @resultado_label = para "", align: "center", size: 16, weight: "bold", margin_top: 10

      @controles = flow(margin_top: 20) do
        if @partida.estrategia1.necesita_input? || @partida.estrategia2.necesita_input?
          para "Selecciona tu jugada: ", size: 12
          Jugada::TODAS.each do |tipo|
            button(tipo.to_s, width: 100, height: 40) do
              seleccionar_jugada(tipo)
            end
          end
        else
          button("Jugar Ronda", width: 200, height: 50) do
            jugar_ronda_gui
          end
        end

        button("Nueva Partida", width: 150, height: 50, margin_left: 20) do
          mostrar_configuracion
        end
      end
    end
  end

  def seleccionar_jugada(tipo)
    if @partida.estrategia1.necesita_input?
      @partida.estrategia1.jugada_seleccionada = tipo
    end
    if @partida.estrategia2.necesita_input?
      @partida.estrategia2.jugada_seleccionada = tipo
    end
    jugar_ronda_gui
  end

  def jugar_ronda_gui
    return if @partida.terminado?(@modo, @n_valor)

    resultado = @partida.jugar_ronda
    return unless resultado

    @img1_container.clear do
      image resultado[:jugada1].imagen, width: 350, height: 350
    end

    @img2_container.clear do
      image resultado[:jugada2].imagen, width: 350, height: 350
    end

    @jugada1_label.text = resultado[:jugada1].to_s
    @jugada2_label.text = resultado[:jugada2].to_s

    @marcador.text = "#{@partida.jugador1}: #{@partida.puntos1} - #{@partida.jugador2}: #{@partida.puntos2}"
    @info_modo.text = "Modo: #{@modo == :rondas ? 'Rondas' : 'Alcanzar'} - N: #{@n_valor} | Ronda: #{@partida.ronda_actual}"

    case resultado[:resultado]
    when [1, 0]
      @resultado_label.text = "#{@partida.jugador1} gana esta ronda!"
      @resultado_label.style(stroke: green)
    when [0, 1]
      @resultado_label.text = "#{@partida.jugador2} gana esta ronda!"
      @resultado_label.style(stroke: red)
    else
      @resultado_label.text = "Empate!"
      @resultado_label.style(stroke: orange)
    end

    if @partida.terminado?(@modo, @n_valor)
      mostrar_ganador
    end
  end

  def mostrar_ganador
    ganador = @partida.ganador

    @controles.clear do
      if ganador
        para "GANADOR: #{ganador}!", size: 24, weight: "bold", stroke: green
      else
        para "EMPATE!", size: 24, weight: "bold", stroke: orange
      end

      button("Nueva Partida", width: 200, height: 50, margin_top: 20) do
        mostrar_configuracion
      end
    end
  end

  mostrar_configuracion
end
