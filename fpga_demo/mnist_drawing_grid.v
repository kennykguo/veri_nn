module mnist_drawing_grid(
    input CLOCK_50,    
    input reset,
    input PS2_CLK,        
    input PS2_DAT,      
    input draw,  
    input on,

    // Memory write interface             
    output reg [15:0] write_addr,    
    output reg signed [31:0] data_write,    
    output reg write_enable,

    // Memory read interface
    output reg [15:0] read_addr,     
    input signed [31:0] data_read,

    // Display outputs
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    output reg [4:0] led_control
);

    // Parameters
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    parameter DELAY_MAX = 20'd2000000;

    parameter [2:0] INIT = 3'b000;
    parameter [2:0] DRAW_GRID = 3'b001;
    parameter [2:0] MOVE = 3'b010;

    parameter [7:0] LEFT_ARROW = 8'h6B;
    parameter [7:0] RIGHT_ARROW = 8'h74;
    parameter [7:0] UP_ARROW = 8'h75;
    parameter [7:0] DOWN_ARROW = 8'h72;

    // Internal signals
    reg [5:0] mem_x;
    reg [4:0] mem_y;

    reg [4:0] current_x, current_y;
    reg [19:0] move_delay;

    reg [7:0] draw_x;
    reg [6:0] draw_y;

    reg [1:0] pixel_x_offset, pixel_y_offset;
    reg [2:0] draw_state, move_state;

    reg plot;
    reg reset_sync1, reset_sync2;
    
    wire ps2_done_tick;
    wire [7:0] ps2_scan_code;
    wire is_cursor, is_pixel_set;

    // Reset synchronization
    always @(posedge CLOCK_50) begin
        reset_sync1 <= reset;
        reset_sync2 <= reset_sync1;
    end
    wire reset_f = reset_sync2;

    // 7-segment display outputs
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);

    // PS2 Keyboard Interface
    ps2_keyboard kb_ctrl(
        .clk(CLOCK_50),
        .reset(reset_f),
        .ps2d(PS2_DAT),
        .ps2c(PS2_CLK),
        .scan_code(ps2_scan_code),
        .done_tick(ps2_done_tick)
    );

    // Memory interface
    always @(*) begin
        read_addr = mem_y * GRID_SIZE + mem_x; // For reading pixel data
    end

    always @(*) begin
        write_addr = current_y * GRID_SIZE + current_x; // For updating pixel data
    end

    assign mem_x = draw_x[7:2];
    assign mem_y = draw_y[6:2];
    assign is_cursor = (mem_x == current_x && mem_y == current_y);
    assign is_pixel_set = (data_read != 32'sd0);

    // Movement FSM
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            current_x <= 5'd0;
            current_y <= 5'd0;
            move_delay <= 20'd0;
            move_state <= INIT;
            write_enable <= 1'b0;
            data_write <= 32'd0;
        end else if (on) begin
            case (move_state)
                INIT: begin
                    current_x <= 5'd0;
                    current_y <= 5'd0;
                    move_state <= MOVE;
                end
                MOVE: begin
                    if (move_delay == 0) begin
                        if (ps2_done_tick) begin
                            case (ps2_scan_code)
                                RIGHT_ARROW: if (current_x < (GRID_SIZE - 1)) begin
                                    current_x <= current_x + 1'b1;
                                    move_delay <= DELAY_MAX;
                                end
                                LEFT_ARROW: if (current_x > 0) begin
                                    current_x <= current_x - 1'b1;
                                    move_delay <= DELAY_MAX;
                                end
                                UP_ARROW: if (current_y > 0) begin
                                    current_y <= current_y - 1'b1;
                                    move_delay <= DELAY_MAX;
                                end
                                DOWN_ARROW: if (current_y < (GRID_SIZE - 1)) begin
                                    current_y <= current_y + 1'b1;
                                    move_delay <= DELAY_MAX;
                                end
                            endcase
                        end
                        if (draw) begin
                            write_enable <= 1'b1;
                            data_write <= 32'sd1; // Setting pixel value
                        end
                    end else begin
                        move_delay <= move_delay - 1'b1;
                    end
                end
                default: move_state <= INIT;
            endcase
        end
    end

    // Drawing FSM
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            pixel_x_offset <= 2'b00;
            pixel_y_offset <= 2'b00;
            plot <= 1'b1;
            draw_state <= INIT;
        end else if (on) begin
            case (draw_state)
                INIT: begin
                    draw_x <= 8'd0;
                    draw_y <= 7'd0;
                    draw_state <= DRAW_GRID;
                end
                DRAW_GRID: begin
                    plot <= 1'b1;
                    if (pixel_x_offset == 2'b11) begin
                        pixel_x_offset <= 2'b00;
                        if (pixel_y_offset == 2'b11) begin
                            pixel_y_offset <= 2'b00;
                            draw_x <= draw_x + 1'b1;
                            if (draw_x == GRID_SIZE * PIXEL_SIZE - 1) begin
                                draw_x <= 8'd0;
                                draw_y <= draw_y + 1'b1;
                            end
                        end else pixel_y_offset <= pixel_y_offset + 1'b1;
                    end else pixel_x_offset <= pixel_x_offset + 1'b1;

                    if (draw_y == GRID_SIZE * PIXEL_SIZE - 1 && pixel_y_offset == 2'b11) begin
                        draw_state <= INIT;
                    end
                end
                default: draw_state <= INIT;
            endcase
        end
    end

    // Color Output
    reg [2:0] colour_out;
    always @(posedge CLOCK_50) begin
        if (reset_f) colour_out <= 3'b001;
        else if (on) begin
            colour_out <= is_cursor ? 3'b100 :
                         is_pixel_set ? 3'b010 : 3'b011;
        end
    end

    // VGA Adapter
    vga_adapter VGA(
        .resetn(~reset),
        .clock(CLOCK_50),
        .colour(colour_out),
        .x({draw_x[7:2], pixel_x_offset}),
        .y({draw_y[6:2], pixel_y_offset}),
        .plot(plot),
        .VGA_R(VGA_R), 
        .VGA_G(VGA_G), 
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), 
        .VGA_VS(VGA_VS), 
        .VGA_BLANK_N(VGA_BLANK_N), 
        .VGA_SYNC_N(VGA_SYNC_N), 
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";

endmodule



// PS2 Keyboard Controller Module
module ps2_keyboard(
    input clk, reset,
    input ps2d, ps2c,     // PS2 data and clock inputs
    output reg [7:0] scan_code,  // received scan code
    output reg done_tick    // signal to indicate new scan code received
);

    // State declarations
    localparam [1:0] 
        idle = 2'b00,
        dps  = 2'b01,   // data phase start
        load = 2'b10;

    // Signal declarations
    reg [1:0] state_reg, state_next;
    reg [7:0] filter_reg;
    wire [7:0] filter_next;
    reg f_ps2c_reg;
    wire f_ps2c_next;
    reg [3:0] n_reg;
    reg [3:0] n_next;
    reg [10:0] s_reg;
    reg [10:0] s_next;
    wire fall_edge;

    // Filter and falling edge tick generation for PS2 clock
    always @(posedge clk) begin
        if (reset) begin
            filter_reg <= 0;
            f_ps2c_reg <= 0;
        end
        else begin
            filter_reg <= filter_next;
            f_ps2c_reg <= f_ps2c_next;
        end
    end

    assign filter_next = {ps2c, filter_reg[7:1]};
    assign f_ps2c_next = (filter_reg == 8'b11111111) ? 1'b1 :
                        (filter_reg == 8'b00000000) ? 1'b0 :
                        f_ps2c_reg;
    assign fall_edge = f_ps2c_reg & ~f_ps2c_next;

    // FSMD state & data registers
    always @(posedge clk) begin
        if (reset) begin
            state_reg <= idle;
            n_reg <= 0;
            s_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            n_reg <= n_next;
            s_reg <= s_next;
        end
    end

    // FSMD next-state logic
    always @* begin
        state_next = state_reg;
        n_next = n_reg;
        s_next = s_reg;
        done_tick = 1'b0;

        case (state_reg)
            idle: begin
                if (fall_edge & ~ps2d) begin // start bit
                    n_next = 4'b1001;  // count 10 bits
                    s_next = {ps2d, s_reg[10:1]}; // shift in start bit
                    state_next = dps;
                end
            end

            dps: begin // data phase shift
                if (fall_edge) begin
                    n_next = n_reg - 1;
                    s_next = {ps2d, s_reg[10:1]}; // shift in data, parity, stop bits
                    if (n_reg == 0)
                        state_next = load;
                end
            end

            load: begin // check parity and stop bits
                if (s_reg[0] == 1'b0 && s_reg[10] == 1'b1) begin // start bit = 0, stop bit = 1
                    scan_code <= s_reg[8:1]; // extract scan code
                    done_tick = 1'b1;
                end
                state_next = idle;
            end

            default: state_next = idle;
        endcase
    end

endmodule


// Hex display module
module hex_display(
    input [3:0] IN,
    output reg [6:0] OUT
);
    always @(*)
        case (IN)
            4'h0: OUT = 7'b1000000;
            4'h1: OUT = 7'b1111001;
            4'h2: OUT = 7'b0100100;
            4'h3: OUT = 7'b0110000;
            4'h4: OUT = 7'b0011001;
            4'h5: OUT = 7'b0010010;
            4'h6: OUT = 7'b0000010;
            4'h7: OUT = 7'b1111000;
            4'h8: OUT = 7'b0000000;
            4'h9: OUT = 7'b0010000;
            4'hA: OUT = 7'b0001000;
            4'hB: OUT = 7'b0000011;
            4'hC: OUT = 7'b1000110;
            4'hD: OUT = 7'b0100001;
            4'hE: OUT = 7'b0000110;
            4'hF: OUT = 7'b0001110;
            default: OUT = 7'b1111111;
        endcase
endmodule
