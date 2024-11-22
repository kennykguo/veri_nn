module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input PS2_CLK,        // PS2 clock input
    input PS2_DAT,        // PS2 data input
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    output [9:0] LEDR
);
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    
    // State definitions for both FSMs
    parameter INIT = 3'b000;
    parameter DRAW_GRID = 3'b001;
    parameter MOVE = 3'b010;
    
    // PS2 keyboard arrow key scan codes
    parameter LEFT_ARROW = 8'h6B;
    parameter RIGHT_ARROW = 8'h74;
    parameter UP_ARROW = 8'h75;
    parameter DOWN_ARROW = 8'h72;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783];
    
    // Cursor position registers
    reg [4:0] current_x;
    reg [4:0] current_y;
    
    // PS2 keyboard interface signals
    wire [7:0] ps2_scan_code;
    wire ps2_key_pressed;
    wire ps2_done_tick;
    
    // Movement control
    reg [19:0] move_delay;
    parameter DELAY_MAX = 20'd2000000;
    
    // Drawing control
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    
    // Inner pixel drawing control
    reg [1:0] pixel_x_offset;
    reg [1:0] pixel_y_offset;
    
    // State registers
    reg [2:0] draw_state;
    reg [2:0] move_state;
    
    // Reset synchronizer
    reg reset_sync1, reset_sync2;
    always @(posedge CLOCK_50) begin
        reset_sync1 <= ~SW[9];
        reset_sync2 <= reset_sync1;
    end
    wire reset = reset_sync2;
    
    // Debug signals
    assign LEDR[9] = SW[9];
    assign LEDR[8] = SW[1];
    assign LEDR[4:0] = current_x[4:0];
    
    // 7-segment display outputs
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);

    // PS2 keyboard controller instance
    ps2_keyboard kb_ctrl (
        .clk(CLOCK_50),
        .reset(reset),
        .ps2d(PS2_DAT),
        .ps2c(PS2_CLK),
        .scan_code(ps2_scan_code),
        .done_tick(ps2_done_tick)
    );
    
    // Initialize registers
    initial begin
        plot = 1'b0;
        reset_sync1 = 1'b1;
        reset_sync2 = 1'b1;
    end

    integer i;
    
    // Movement FSM with synchronous reset
    always @(posedge CLOCK_50) begin
        if (reset) begin
            // Synchronous reset logic
            current_x <= 5'd14;
            current_y <= 5'd14;
            move_delay <= 20'd0;
            move_state <= INIT;
            // Reset pixel memory
            for(i = 0; i < 784; i = i + 1) begin
                pixel_memory[i] <= 1'b0;
            end
        end
        else begin
            case(move_state)
                INIT: begin
                    current_x <= 5'd14;
                    current_y <= 5'd14;
                    move_state <= MOVE;
                end
                
                MOVE: begin
                    if (move_delay == 0) begin
                        if (ps2_done_tick) begin
                            case(ps2_scan_code)
                                RIGHT_ARROW: begin
                                    if (current_x < (GRID_SIZE-1)) begin
                                        current_x <= current_x + 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                LEFT_ARROW: begin
                                    if (current_x > 0) begin
                                        current_x <= current_x - 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                UP_ARROW: begin
                                    if (current_y > 0) begin
                                        current_y <= current_y - 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                DOWN_ARROW: begin
                                    if (current_y < (GRID_SIZE-1)) begin
                                        current_y <= current_y + 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                            endcase
                        end
                        
                        if (SW[1]) begin
                            pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                        end
                    end
                    else begin
                        move_delay <= move_delay - 1'd1;
                    end
                end
                
                default: move_state <= INIT;
            endcase
        end
    end

    // Drawing FSM with synchronous reset
    always @(posedge CLOCK_50) begin
        if (reset) begin
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            pixel_x_offset <= 2'b00;
            pixel_y_offset <= 2'b00;
            plot <= 1'b1;
            draw_state <= INIT;
        end
        else begin
            case(draw_state)
                INIT: begin
                    draw_x <= 8'd0;
                    draw_y <= 7'd0;
                    pixel_x_offset <= 2'b00;
                    pixel_y_offset <= 2'b00;
                    plot <= 1'b1;
                    draw_state <= DRAW_GRID;
                end
                
                DRAW_GRID: begin
                    if (draw_y < (GRID_SIZE * PIXEL_SIZE) && draw_x < (GRID_SIZE * PIXEL_SIZE)) begin
                        plot <= 1'b1;

                        if (pixel_x_offset == 2'b11) begin
                            pixel_x_offset <= 2'b00;
                            if (pixel_y_offset == 2'b11) begin
                                pixel_y_offset <= 2'b00;
                                draw_x <= draw_x + 1'd1;
                                
                                if (draw_x >= (GRID_SIZE * PIXEL_SIZE - 1)) begin
                                    draw_x <= 8'd0;
                                    draw_y <= draw_y + 1'd1;
                                end
                            end 
                            else begin
                                pixel_y_offset <= pixel_y_offset + 1'b1;
                            end
                        end 
                        else begin
                            pixel_x_offset <= pixel_x_offset + 1'b1;
                        end
                        
                        if (draw_y >= (GRID_SIZE * PIXEL_SIZE - 1) && 
                            pixel_y_offset == 2'b11 && pixel_x_offset == 2'b11) begin
                            draw_x <= 8'd0;
                            draw_y <= 7'd0;
                        end
                    end 
                    else begin
                        plot <= 1'b0;
                    end
                end
                
                default: draw_state <= INIT;
            endcase
        end
    end

    // Color output logic
    wire [4:0] mem_x = draw_x[7:2];
    wire [4:0] mem_y = draw_y[6:2];
    wire is_cursor = (mem_x == current_x && mem_y == current_y);
    wire is_pixel_set = pixel_memory[mem_y * GRID_SIZE + mem_x];
    
    reg [2:0] colour_out;
    always @(posedge CLOCK_50) begin
        if (reset) begin
            colour_out <= 3'b001;  // Default background color
        end
        else begin
            colour_out <= is_cursor ? 3'b100 :           // Red for cursor
                         is_pixel_set ? 3'b111 : 3'b001; // White for set pixels, dark blue for grid
        end
    end
    
    // VGA position calculation
    wire [7:0] actual_x = {draw_x[7:2], pixel_x_offset};
    wire [6:0] actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(~reset),  // Active-low reset
        .clock(CLOCK_50),
        .colour(colour_out),
        .x(actual_x),
        .y(actual_y),
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
