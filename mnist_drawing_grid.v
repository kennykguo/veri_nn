module mnist_drawing_grid (
    input wire CLOCK_50,    
    input wire reset,
    input wire [3:0] KEY,     
    input wire draw,  
    input wire on,             
    output wire [15:0] read_addr,
    output wire signed [31:0] data_out,
    output wire [7:0] VGA_R, VGA_G, VGA_B,
    output wire VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3,
    input wire [4:0] led_control
);

    // Constants
    localparam GRID_SIZE = 28;
    localparam PIXEL_SIZE = 4;
    localparam DELAY_MAX = 20'd10000;

    // State definitions using one-hot encoding for better synthesis
    localparam [2:0] S_INIT = 3'b001;
    localparam [2:0] S_DRAW_GRID = 3'b010;
    localparam [2:0] S_IDLE = 3'b100;

    // Registered outputs and internal signals
    reg [4:0] current_x, next_x;
    reg [4:0] current_y, next_y;
    reg [19:0] move_delay, next_move_delay;
    reg [2:0] state, next_state;
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    reg [1:0] pixel_x_offset, pixel_y_offset;
    
    // Memory interface
    reg signed [31:0] data_in;
    reg write_enable;
    wire [15:0] write_addr;

    // Reset synchronization (3-stage)
    reg [2:0] reset_sync;
    wire reset_n;
    
    // KEY debouncing (3-stage)
    reg [3:0] key_reg1, key_reg2, key_reg3;
    wire [3:0] key_pressed;
    
    // Synchronize reset
    always @(posedge CLOCK_50) begin
        reset_sync <= {reset_sync[1:0], reset};
    end
    assign reset_n = reset_sync[2];

    // Debounce KEY inputs with 3 stages
    always @(posedge CLOCK_50) begin
        if (reset_n) begin
            key_reg1 <= 4'hF;
            key_reg2 <= 4'hF;
            key_reg3 <= 4'hF;
        end else begin
            key_reg1 <= KEY;
            key_reg2 <= key_reg1;
            key_reg3 <= key_reg2;
        end
    end
    
    // KEY press detection (active low to high)
    assign key_pressed = (~key_reg3 & key_reg2);

    // Memory address calculation
    assign write_addr = current_y * GRID_SIZE + current_x;
    // assign read_addr = write_addr; // For simplicity, using same address

    // Memory instance
    image_memory img_mem (
        .clk(CLOCK_50),
        .reset(reset_n),
        .write_addr(write_addr),
        .read_addr(read_addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .data_out(data_out)
    );

    // State machine sequential logic
    always @(posedge CLOCK_50) begin
        if (reset_n) begin
            state <= S_INIT;
            current_x <= 5'd0;
            current_y <= 5'd0;
            move_delay <= 20'd0;
        end else begin
            state <= next_state;
            current_x <= next_x;
            current_y <= next_y;
            move_delay <= next_move_delay;
        end
    end

    // State machine combinational logic
    always @(*) begin
        // Default assignments
        next_state = state;
        next_x = current_x;
        next_y = current_y;
        next_move_delay = move_delay;
        write_enable = 1'b0;
        data_in = 32'd0;

        case (state)
            S_INIT: begin
                next_state = S_IDLE;
                next_x = 5'd0;
                next_y = 5'd0;
                next_move_delay = 20'd0;
            end

            S_IDLE: begin
                if (on) begin
                    if (move_delay == 20'd0) begin
                        if (key_pressed[3] && current_x < (GRID_SIZE-1)) begin
                            next_x = current_x + 1'd1;
                            next_move_delay = DELAY_MAX;
                        end
                        else if (key_pressed[2] && current_x > 0) begin
                            next_x = current_x - 1'd1;
                            next_move_delay = DELAY_MAX;
                        end
                        else if (key_pressed[1] && current_y > 0) begin
                            next_y = current_y - 1'd1;
                            next_move_delay = DELAY_MAX;
                        end
                        else if (key_pressed[0] && current_y < (GRID_SIZE-1)) begin
                            next_y = current_y + 1'd1;
                            next_move_delay = DELAY_MAX;
                        end

                        if (draw) begin
                            write_enable = 1'b1;
                            data_in = 32'sd1;
                        end
                    end else begin
                        next_move_delay = move_delay - 1'd1;
                    end
                end
            end

            default: next_state = S_INIT;
        endcase
    end

    // VGA control logic
    reg [2:0] colour_out;
    wire is_cursor, is_pixel_set;
    wire [7:0] actual_x;
    wire [6:0] actual_y;

    assign is_cursor = (draw_x[7:2] == current_x && draw_y[6:2] == current_y);
    assign is_pixel_set = (data_out != 32'sd0);
    assign actual_x = {draw_x[7:2], pixel_x_offset};
    assign actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA color output logic
    always @(posedge CLOCK_50) begin
        if (reset_n) begin
            colour_out <= 3'b000;
        end else if (on) begin
            if (is_cursor)
                colour_out <= 3'b100;
            else if (is_pixel_set)
                colour_out <= 3'b111;
            else
                colour_out <= 3'b001;
        end
    end

    // VGA display instance
    vga_adapter VGA (
        .resetn(~reset_n),
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

    // Hex display instances
    hex_display hex0(.IN(current_x[3:0]), .OUT(HEX0));
    hex_display hex1(.IN({3'b000, current_x[4]}), .OUT(HEX1));
    hex_display hex2(.IN(current_y[3:0]), .OUT(HEX2));
    hex_display hex3(.IN({3'b000, current_y[4]}), .OUT(HEX3));

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