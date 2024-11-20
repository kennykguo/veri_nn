module vga_demo(
    input CLOCK_50,    
    input [9:0] SW,
    input [3:0] KEY,
    output [6:0] HEX3, HEX2, HEX1, HEX0,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;  // Reduced size to fit screen better
    parameter GRID_OFFSET_X = 16;
    parameter GRID_OFFSET_Y = 12;
    
    // Memory array for pixel storage
    reg [0:0] pixel_memory [0:783]; // 28x28 = 784 pixels
    
    // Cursor position registers
    reg [4:0] current_x = 5'd14;
    reg [4:0] current_y = 5'd14;
    
    // Button press detection
    reg [3:0] key_prev;
    wire [3:0] key_pressed = ~KEY & ~key_prev;
    
    // Movement control
    reg [19:0] move_delay = 20'd0;
    parameter DELAY_MAX = 20'd100000;
    
    // VGA signals
    wire [7:0] x;
    wire [6:0] y;
    reg [2:0] colour;
    
    // Initialize memory and key_prev
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            pixel_memory[i] <= 1'b0;
        end
        key_prev <= 4'b1111;
    end
    
    // Position display on hex
    hex7seg H3 ({3'b000, current_x[4]}, HEX3);
    hex7seg H2 (current_x[3:0], HEX2);
    hex7seg H1 ({3'b000, current_y[4]}, HEX1);
    hex7seg H0 (current_y[3:0], HEX0);
    
    // Movement and drawing logic
    always @(posedge CLOCK_50) begin
        if (!SW[9]) begin
            current_x <= 5'd14;
            current_y <= 5'd14;
            move_delay <= 20'd0;
            for(i = 0; i < 784; i = i + 1) begin
                pixel_memory[i] <= 1'b0;
            end
        end
        else begin
            key_prev <= ~KEY;
            
            if (move_delay == 0) begin
                if (key_pressed[3] && current_x < (GRID_SIZE-1)) begin
                    current_x <= current_x + 1'd1;
                    move_delay <= DELAY_MAX;
                end
                if (key_pressed[2] && current_x > 0) begin
                    current_x <= current_x - 1'd1;
                    move_delay <= DELAY_MAX;
                end
                if (key_pressed[1] && current_y > 0) begin
                    current_y <= current_y - 1'd1;
                    move_delay <= DELAY_MAX;
                end
                if (key_pressed[0] && current_y < (GRID_SIZE-1)) begin
                    current_y <= current_y + 1'd1;
                    move_delay <= DELAY_MAX;
                end
                
                // Drawing logic
                if (SW[1]) begin
                    pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                end
            end
            else begin
                move_delay <= move_delay - 1'd1;
            end
        end
    end
	 
	 
	 
	 
	 
	 
    reg [4:0] grid_x, grid_y;
	 
    // VGA color logic
	always @(*) begin
		 // Default to white background
		 colour = 3'b111;

		 // Check if within grid bounds
		 if (x >= GRID_OFFSET_X && x < (GRID_OFFSET_X + GRID_SIZE * PIXEL_SIZE) &&
			  y >= GRID_OFFSET_Y && y < (GRID_OFFSET_Y + GRID_SIZE * PIXEL_SIZE)) begin

			  // Calculate grid position
			  grid_x = (x - GRID_OFFSET_X) / PIXEL_SIZE;
			  grid_y = (y - GRID_OFFSET_Y) / PIXEL_SIZE;

			  // Check if current position is cursor
			  if (grid_x == current_x && grid_y == current_y) begin
					// Red cursor on white, blue cursor on black
					colour = pixel_memory[grid_y * GRID_SIZE + grid_x] ? 3'b001 : 3'b100;
			  end else begin
					// Normal pixel color (black if set, white if clear)
					colour = pixel_memory[grid_y * GRID_SIZE + grid_x] ? 3'b000 : 3'b111;
			  end
		 end
	end


    
    // VGA controller
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(colour),    // Was 'color'
        .x(x),             // Was 'vga_x'
        .y(y),             // Was 'vga_y'
        .plot(1'b1),
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
