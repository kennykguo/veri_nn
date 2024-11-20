module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input [3:0] KEY,
    output [6:0] HEX3, HEX2, HEX1, HEX0,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    
    // Current cursor position
    wire [4:0] cursor_x;
    wire [4:0] cursor_y;
    wire [15:0] mem_address;
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4; // Each grid pixel is 4x4 VGA pixels
    parameter GRID_OFFSET_X = 16; // Center the grid
    parameter GRID_OFFSET_Y = 12;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783]; // 28x28 = 784 pixels
    
    // Cursor position registers
    reg [4:0] current_x = 5'd14; // Start in middle
    reg [4:0] current_y = 5'd14;
    
    // VGA coordinates
    wire [7:0] vga_x;
    wire [6:0] vga_y;
    wire [2:0] color;
    
    // Movement control
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd500000; // Debounce delay
    
    // Calculate memory address from cursor position
    assign mem_address = current_y * GRID_SIZE + current_x;
    
    // Initialize memory to all zeros (white pixels)
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] = 1'b0;
        end
    end
    
    // Position display on hex
    hex7seg H3 ({3'b000, current_x[4]}, HEX3);
    hex7seg H2 (current_x[3:0], HEX2);
    hex7seg H1 ({3'b000, current_y[4]}, HEX1);
    hex7seg H0 (current_y[3:0], HEX0);
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        if (!KEY[0]) begin // Reset
            current_x <= 5'd14;
            current_y <= 5'd14;
            move_delay <= 20'd0;
            // Reset memory to all white
            for(i = 0; i < 784; i = i + 1) begin
                pixel_memory[i] <= 1'b0;
            end
        end
        else begin
            if (move_delay == DELAY_MAX) begin
                move_delay <= 20'd0;
                
                // Movement controls
                if (!KEY[3] && current_x < (GRID_SIZE-1)) current_x <= current_x + 1; // Right
                if (!KEY[2] && current_x > 0) current_x <= current_x - 1; // Left
                if (!KEY[1] && current_y > 0) current_y <= current_y - 1; // Up
                if (!KEY[0] && current_y < (GRID_SIZE-1)) current_y <= current_y + 1; // Down
                
                // Drawing when SW[1] is on
                if (SW[1]) begin
                    pixel_memory[mem_address] <= 1'b1; // Set pixel to black
                end
            end
            else
                move_delay <= move_delay + 1;
        end
    end
    
    // VGA coordinate calculation
    assign vga_x = GRID_OFFSET_X + (current_x * PIXEL_SIZE);
    assign vga_y = GRID_OFFSET_Y + (current_y * PIXEL_SIZE);
    
    // Color determination based on memory content
    assign color = pixel_memory[mem_address] ? 3'b000 : 3'b111; // Black if 1, white if 0
    
    // VGA controller
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(color),
        .x(vga_x),
        .y(vga_y),
        .plot(1'b1), // Always plotting to show cursor position
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

module hex7seg(
    input [3:0] hex,
    output reg [6:0] display
);
    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @(*) begin
        case(hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
            default: display = 7'b1111111;
        endcase
    end
endmodule