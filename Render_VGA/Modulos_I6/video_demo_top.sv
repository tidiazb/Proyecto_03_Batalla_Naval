`timescale 1ns / 1ps

// ============================================================
// Módulo: video_demo_top
//
// Descripción:
// Top físico de prueba para validar el periférico VGA del
// Issue 6 en la FPGA.
//
// Al iniciar, este módulo recorre los 300 tiles de la pantalla
// y escribe automáticamente un patrón de prueba en la Video RAM.
//
// El patrón permite visualizar:
// - Tablero propio.
// - Tablero rival.
// - HUD.
// - Agua.
// - Barcos.
// - Impactos.
// - Fallos.
// - Fondo.
//
// Una vez inicializada la memoria, el periférico VGA continúa
// leyendo la Video RAM y generando la imagen de forma continua.
// ============================================================

module video_demo_top (

    input  logic       clk_100mhz,
    input  logic       rst,

    output logic       hsync,
    output logic       vsync,

    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue
);

    // ============================================================
    // CONSTANTES
    // ============================================================

    localparam logic [31:0] VGA_BASE = 32'h0001_1000;

    localparam logic [1:0] REGION_FONDO  = 2'b00;
    localparam logic [1:0] REGION_PROPIO = 2'b01;
    localparam logic [1:0] REGION_RIVAL  = 2'b10;
    localparam logic [1:0] REGION_HUD    = 2'b11;


    // Códigos de tiles
    localparam logic [2:0] TILE_AGUA     = 3'b000;
    localparam logic [2:0] TILE_BARCO    = 3'b001;
    localparam logic [2:0] TILE_FALLO    = 3'b010;
    localparam logic [2:0] TILE_IMPACTO  = 3'b011;
    localparam logic [2:0] TILE_SELECCION = 3'b100;
    localparam logic [2:0] TILE_FONDO    = 3'b101;


    // ============================================================
    // SEÑALES HACIA VIDEO_PERIPHERAL
    // ============================================================

    logic [31:0] addr;
    logic [31:0] wdata;
    logic        we;

    logic [31:0] video_rdata;


    // ============================================================
    // CONTADORES DE TILE
    // ============================================================

    logic [4:0] tile_x;
    logic [3:0] tile_y;

    logic [8:0] tile_index;


    // ============================================================
    // VIDEO LAYOUT
    // ============================================================

    logic [1:0] region;
    logic [2:0] board_x;
    logic [2:0] board_y;


    video_layout u_video_layout (

        .tile_x_i  (tile_x),
        .tile_y_i  (tile_y),

        .region_o  (region),
        .board_x_o (board_x),
        .board_y_o (board_y)

    );


    // ============================================================
    // GENERACIÓN DEL PATRÓN DE PRUEBA
    // ============================================================

    logic [31:0] tile_data;

    always_comb begin

        // Fondo negro por defecto
        tile_data = {29'd0, TILE_FONDO};


        case (region)

            // ----------------------------------------------------
            // FONDO
            // ----------------------------------------------------

            REGION_FONDO: begin

                tile_data = {29'd0, TILE_FONDO};

            end


            // ----------------------------------------------------
            // TABLERO PROPIO
            // ----------------------------------------------------

            REGION_PROPIO: begin

                // Agua por defecto
                tile_data = {29'd0, TILE_AGUA};


                // Barco vertical
                // X = 1, Y = 1..4

                if ((board_x == 3'd1) &&
                    (board_y >= 3'd1) &&
                    (board_y <= 3'd4))

                    tile_data = {29'd0, TILE_BARCO};


                // Barco horizontal
                // Y = 6, X = 3..6

                if ((board_y == 3'd6) &&
                    (board_x >= 3'd3) &&
                    (board_x <= 3'd6))

                    tile_data = {29'd0, TILE_BARCO};


                // Impacto sobre barco

                if ((board_x == 3'd1) &&
                    (board_y == 3'd3))

                    tile_data = {29'd0, TILE_IMPACTO};


                // Fallo

                if ((board_x == 3'd6) &&
                    (board_y == 3'd2))

                    tile_data = {29'd0, TILE_FALLO};

            end


            // ----------------------------------------------------
            // TABLERO RIVAL
            // ----------------------------------------------------

            REGION_RIVAL: begin

                // El tablero rival inicia como agua
                tile_data = {29'd0, TILE_AGUA};


                // Impactos conocidos

                if ((board_x == 3'd2) &&
                    (board_y == 3'd2))

                    tile_data = {29'd0, TILE_IMPACTO};


                if ((board_x == 3'd5) &&
                    (board_y == 3'd5))

                    tile_data = {29'd0, TILE_IMPACTO};


                // Fallos conocidos

                if ((board_x == 3'd1) &&
                    (board_y == 3'd6))

                    tile_data = {29'd0, TILE_FALLO};


                if ((board_x == 3'd6) &&
                    (board_y == 3'd1))

                    tile_data = {29'd0, TILE_FALLO};

            end


            // ----------------------------------------------------
            // HUD
            // ----------------------------------------------------

            REGION_HUD: begin

                // Amarillo para distinguir claramente
                // la zona reservada para HUD

                tile_data = {29'd0, TILE_SELECCION};

            end


            default: begin

                tile_data = {29'd0, TILE_FONDO};

            end

        endcase

    end


    // ============================================================
    // FSM DE INICIALIZACIÓN
    // ============================================================

    typedef enum logic [1:0] {

        PREPARAR,
        ESCRIBIR,
        TERMINADO

    } estado_t;

    estado_t estado;


    // ============================================================
    // ESCRITURA DE LOS 300 TILES
    // ============================================================

    always_ff @(posedge clk_100mhz) begin

        if (rst) begin

            tile_x     <= 5'd0;
            tile_y     <= 4'd0;
            tile_index <= 9'd0;

            addr       <= VGA_BASE;
            wdata      <= 32'd0;
            we         <= 1'b0;

            estado     <= PREPARAR;

        end

        else begin

            case (estado)

                // ------------------------------------------------
                // Preparar dirección y dato
                // ------------------------------------------------

                PREPARAR: begin

                    we <= 1'b0;

                    addr <= VGA_BASE +
                            ({23'd0, tile_index} << 2);

                    wdata <= tile_data;

                    estado <= ESCRIBIR;

                end


                // ------------------------------------------------
                // Realizar escritura
                // ------------------------------------------------

                ESCRIBIR: begin

                    we <= 1'b1;


                    // Último tile: 19,14
                    if ((tile_x == 5'd19) &&
                        (tile_y == 4'd14)) begin

                        estado <= TERMINADO;

                    end

                    else begin

                        tile_index <= tile_index + 1'b1;


                        // Final de fila
                        if (tile_x == 5'd19) begin

                            tile_x <= 5'd0;
                            tile_y <= tile_y + 1'b1;

                        end

                        else begin

                            tile_x <= tile_x + 1'b1;

                        end


                        estado <= PREPARAR;

                    end

                end


                // ------------------------------------------------
                // Inicialización terminada
                // ------------------------------------------------

                TERMINADO: begin

                    we <= 1'b0;

                end


                default: begin

                    estado <= PREPARAR;

                end

            endcase

        end

    end


    // ============================================================
    // PERIFÉRICO VGA
    // ============================================================

    video_peripheral u_video_peripheral (

        .clk_100mhz    (clk_100mhz),
        .rst           (rst),

        .addr_i        (addr),
        .wdata_i       (wdata),
        .we_i          (we),

        .video_rdata_o (video_rdata),

        .hsync         (hsync),
        .vsync         (vsync),

        .vga_red       (vga_red),
        .vga_green     (vga_green),
        .vga_blue      (vga_blue)

    );

endmodule
