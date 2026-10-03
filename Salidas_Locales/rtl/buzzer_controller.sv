`timescale 1ns / 1ps

//============================================================
// Módulo: buzzer_controller
// Issue #10 - Buzzer
//
// Función:
// Genera patrones sonoros diferentes según el evento
// recibido desde el sistema.
//
// Comandos:
//   000 -> Sin sonido
//   001 -> Disparo con impacto
//   010 -> Disparo con fallo
//   011 -> Barco hundido
//   100 -> Colocación inválida
//   101 -> Victoria
//
// Los parámetros permiten utilizar valores pequeños durante
// simulación y valores reales posteriormente en hardware.
//============================================================

module buzzer_controller #(
    parameter integer CLK_FREQ = 100_000_000
)(
    input  logic       clk,
    input  logic       rst,

    // Pulso que inicia el sonido
    input  logic       start,

    // Selección del efecto sonoro
    input  logic [2:0] sound_sel,

    // Salida hacia el buzzer
    output logic       buzzer,

    // Indica que todavía se está reproduciendo un sonido
    output logic       busy
);

    //========================================================
    // Códigos de sonidos
    //========================================================

    localparam logic [2:0] SOUND_NONE    = 3'b000;
    localparam logic [2:0] SOUND_HIT     = 3'b001;
    localparam logic [2:0] SOUND_MISS    = 3'b010;
    localparam logic [2:0] SOUND_SUNK    = 3'b011;
    localparam logic [2:0] SOUND_INVALID = 3'b100;
    localparam logic [2:0] SOUND_WIN     = 3'b101;


    //========================================================
    // Divisores aproximados para las frecuencias
    //
    // divisor = CLK_FREQ / (2 * frecuencia)
    //========================================================

    localparam integer DIV_LOW  =
        (CLK_FREQ / (2 * 400));

    localparam integer DIV_MID  =
        (CLK_FREQ / (2 * 800));

    localparam integer DIV_HIGH =
        (CLK_FREQ / (2 * 1200));


    //========================================================
    // Duraciones aproximadas
    //========================================================

    localparam integer DUR_SHORT =
        (CLK_FREQ / 20);     // ~50 ms

    localparam integer DUR_MEDIUM =
        (CLK_FREQ / 10);     // ~100 ms


    //========================================================
    // Registros internos
    //========================================================

    logic [2:0] active_sound;

    logic [16:0] tone_counter;      // hasta DIV_LOW = 125_000
    logic [23:0] duration_counter;  // hasta DUR_MEDIUM = 10_000_000

    logic [16:0] tone_divisor;
    logic [23:0] duration_limit;

    logic [16:0] tone_limit_r;      // tone_divisor - 1, registrado
    logic [23:0] dur_limit_r;       // duration_limit - 1, registrado

    logic [2:0] sequence_step;


    //========================================================
    // Selección del tono
    //========================================================

    always_comb begin

        tone_divisor   = DIV_MID;
        duration_limit = DUR_MEDIUM;

        case (active_sound)

            //------------------------------------------------
            // IMPACTO
            // Tono alto y corto
            //------------------------------------------------

            SOUND_HIT: begin
                tone_divisor   = DIV_HIGH;
                duration_limit = DUR_SHORT;
            end


            //------------------------------------------------
            // FALLO
            // Tono bajo y corto
            //------------------------------------------------

            SOUND_MISS: begin
                tone_divisor   = DIV_LOW;
                duration_limit = DUR_SHORT;
            end


            //------------------------------------------------
            // BARCO HUNDIDO
            // Tono medio más largo
            //------------------------------------------------

            SOUND_SUNK: begin
                tone_divisor   = DIV_MID;
                duration_limit = DUR_MEDIUM;
            end


            //------------------------------------------------
            // COLOCACIÓN INVÁLIDA
            // Tono bajo
            //------------------------------------------------

            SOUND_INVALID: begin
                tone_divisor   = DIV_LOW;
                duration_limit = DUR_MEDIUM;
            end


            //------------------------------------------------
            // VICTORIA
            //
            // Secuencia ascendente:
            // bajo -> medio -> alto
            //------------------------------------------------

            SOUND_WIN: begin

                duration_limit = DUR_SHORT;

                case (sequence_step)

                    3'd0:
                        tone_divisor = DIV_LOW;

                    3'd1:
                        tone_divisor = DIV_MID;

                    3'd2:
                        tone_divisor = DIV_HIGH;

                    default:
                        tone_divisor = DIV_HIGH;

                endcase

            end


            default: begin
                tone_divisor   = DIV_MID;
                duration_limit = DUR_SHORT;
            end

        endcase

    end
    
    always_ff @(posedge clk) begin
      tone_limit_r <= tone_divisor   - 1'b1;
      dur_limit_r  <= duration_limit - 1'b1;
    end


    //========================================================
    // Control principal del buzzer
    //========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            buzzer          <= 1'b0;
            busy            <= 1'b0;

            active_sound    <= SOUND_NONE;

            tone_counter    <= 0;
            duration_counter <= 0;

            sequence_step   <= 0;

        end
        else begin

            //------------------------------------------------
            // Iniciar nuevo sonido
            //------------------------------------------------

            if (start && !busy && (sound_sel != SOUND_NONE)) begin

                active_sound     <= sound_sel;

                busy             <= 1'b1;

                buzzer           <= 1'b0;

                tone_counter     <= 0;
                duration_counter <= 0;

                sequence_step    <= 0;

            end


            //------------------------------------------------
            // Reproducción
            //------------------------------------------------

            else if (busy) begin

                //--------------------------------------------
                // Generación de onda cuadrada
                //--------------------------------------------

                if (tone_counter >= tone_limit_r) begin

                    tone_counter <= 0;
                    buzzer       <= ~buzzer;

                end
                else begin

                    tone_counter <= tone_counter + 1;

                end


                //--------------------------------------------
                // Control de duración
                //--------------------------------------------

                if (duration_counter >= dur_limit_r) begin

                    duration_counter <= 0;


                    //----------------------------------------
                    // Secuencia de victoria
                    //----------------------------------------

                    if (active_sound == SOUND_WIN) begin

                        if (sequence_step < 3'd2) begin

                            sequence_step <=
                                sequence_step + 1'b1;

                            tone_counter <= 0;

                        end
                        else begin

                            busy          <= 1'b0;
                            buzzer        <= 1'b0;
                            active_sound  <= SOUND_NONE;
                            sequence_step <= 0;

                        end

                    end


                    //----------------------------------------
                    // Otros sonidos terminan aquí
                    //----------------------------------------

                    else begin

                        busy           <= 1'b0;
                        buzzer         <= 1'b0;
                        active_sound   <= SOUND_NONE;
                        sequence_step  <= 0;

                    end

                end
                else begin

                    duration_counter <=
                        duration_counter + 1;

                end

            end


            //------------------------------------------------
            // Reposo
            //------------------------------------------------

            else begin

                buzzer <= 1'b0;

            end

        end

    end

endmodule
