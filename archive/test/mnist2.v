module mnist_drawing_grid(
    input CLOCK_50,    
    input reset,
    input [3:0] KEY,      // KEY[0] = down, KEY[1] = up, KEY[2] = left, KEY[3] = right
    input draw,  
    input on,             
    output wire [15:0] read_addr,
    output wire signed [31:0] data_out,
    
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    input [3:0] led_control
);

    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    
    // State definitions
    parameter INIT = 3'b000;
    parameter DRAW_GRID = 3'b001;
    parameter MOVE = 3'b010;
    
    // Wire declarations for coordinate conversion
    wire [5:0] mem_x;
    wire [4:0] mem_y;
    
    // Cursor position registers
    reg [4:0] current_x;
    reg [4:0] current_y;
    
    // Movement control
    reg [19:0] move_delay;
    parameter DELAY_MAX = 20'd1000000; // Reduced delay for better responsiveness
    
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

    // Memory interface signals
    wire [15:0] write_addr;
    reg signed [31:0] data_in;
    reg write_enable;

    // Reset synchronization
    reg [2:0] reset_sync;
    wire reset_f;

    // Synchronize reset with three FF stages for better metastability handling
    always @(posedge CLOCK_50) begin
        reset_sync <= {reset_sync[1:0], reset};
    end
    assign reset_f = reset_sync[2];


    // KEY debouncing registers
    reg [3:0] key_reg1, key_reg2;
    wire [3:0] key_pressed;


    // Debounce KEY inputs
    always @(posedge CLOCK_50) begin
        key_reg1 <= KEY;
        key_reg2 <= key_reg1;
    end
    

    // Detect KEY press (active low to active high conversion)
    assign key_pressed = ~key_reg2 & key_reg1;


    // Memory instantiation
    image_memory img_mem (
        .clk(CLOCK_50),
        .reset(reset_f),
        .write_addr(write_addr),
        .read_addr(read_addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .data_out(data_out)
    );
    

    // 7-segment displays
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);


    // Memory address calculations
    assign write_addr = current_y * GRID_SIZE + current_x;
    assign mem_x = draw_x[7:2];
    assign mem_y = draw_y[6:2];

    always @(posedge CLOCK_50) begin
        
        if (reset_f) begin
            current_x <= 4'd0;
            current_y <= 4'd0;
            move_delay <= 20'd0;
            move_state <= INIT;
            data_in <= 32'd0;
            write_enable <= 1'b0;
        end
        
        else begin
            if (on) begin
                write_enable <= 1'b1;
                if (move_delay == 0) begin
                    // Right movement
                    if (key_pressed[3] && current_x < (GRID_SIZE-1)) begin
                        current_x <= current_x + 4'd1;
                        move_delay <= DELAY_MAX;
                        $display("Moved Right to (%d, %d)", current_x, current_y);
                    end
                    // Left movement
                    else if (key_pressed[2] && current_x > 0) begin
                        current_x <= current_x - 4'd1;
                        move_delay <= DELAY_MAX;
                        $display("Moved Left to (%d, %d)", current_x, current_y);
                    end
                    // Up movement
                    else if (key_pressed[1] && current_y > 0) begin
                        current_y <= current_y - 4'd1;
                        move_delay <= DELAY_MAX;
                        $display("Moved Up to (%d, %d)", current_x, current_y);
                    end
                    // Down movement
                    else if (key_pressed[0] && current_y < (GRID_SIZE-1)) begin
                        current_y <= current_y + 4'd1;
                        move_delay <= DELAY_MAX;
                        $display("Moved Down to (%d, %d)", current_x, current_y);
                    end
                    
                    // Draw action
                    if (draw) begin
                        write_enable <= 1'b1;
                        data_in <= 32'sd1;
                        $display("Drawing at (%d, %d)", current_x, current_y);
                    end
                end
                else begin
                    move_delay <= move_delay - 1'd1;
                end
            end
        end
    end

    // Color output logic - modified for requested colors
    wire is_cursor = (mem_x == current_x && mem_y == current_y);
    wire is_pixel_set = (data_out != 32'sd0);
    
    reg [2:0] colour_out;
    always @(posedge CLOCK_50) begin
        if (reset_f) begin
            colour_out <= 3'b000; // Black
        end
        else if (on) begin
            if (is_cursor)
                colour_out <= 3'b100; // Red cursor
            else if (is_pixel_set)
                colour_out <= 3'b111; // Black for drawn pixels
            else
                colour_out <= 3'b001; // Blue for undrawn pixels
        end
    end
    
    // VGA position calculation
    wire [7:0] actual_x = {draw_x[7:2], pixel_x_offset};
    wire [6:0] actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(~reset_f),
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