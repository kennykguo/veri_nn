module vga_demo(
    input CLOCK_50,
    input [3:0] KEY,
    input PS2_CLK,
    input PS2_DAT,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

    // Mouse interface signals
    wire [9:0] mouse_x;
    wire [9:0] mouse_y;
    wire left_button;

    // 28x28 pixel memory
    reg [27:0] pixel_memory [27:0];
    
    // Grid parameters
    localparam GRID_SIZE = 28;
    localparam PIXEL_SCALE = 2;  // Each grid pixel is 2x2 VGA pixels
    localparam GRID_START_X = 52;  // Center the grid ((160 - (28*2))/2)
    localparam GRID_START_Y = 32;  // Center the grid ((120 - (28*2))/2)

    // Grid position calculation
    wire [4:0] grid_x = (VGA_X - GRID_START_X) / PIXEL_SCALE;
    wire [4:0] grid_y = (VGA_Y - GRID_START_Y) / PIXEL_SCALE;
    
    // Mouse grid position
    wire [4:0] mouse_grid_x = (mouse_x - GRID_START_X) / PIXEL_SCALE;
    wire [4:0] mouse_grid_y = (mouse_y - GRID_START_Y) / PIXEL_SCALE;

    // Drawing logic
    always @(posedge CLOCK_50) begin
        if (!KEY[0]) begin
            // Reset the grid
            integer i;
            for (i = 0; i < GRID_SIZE; i = i + 1)
                pixel_memory[i] <= 28'b0;
        end
        else if (left_button && 
                 mouse_grid_x < GRID_SIZE && 
                 mouse_grid_y < GRID_SIZE) begin
            // Set pixel to black when clicked
            pixel_memory[mouse_grid_y][mouse_grid_x] <= 1'b1;
        end
    end

    // VGA color output
    reg [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;

    // Color selection logic
    always @(*) begin
        if (VGA_X >= GRID_START_X && 
            VGA_X < (GRID_START_X + GRID_SIZE * PIXEL_SCALE) &&
            VGA_Y >= GRID_START_Y && 
            VGA_Y < (GRID_START_Y + GRID_SIZE * PIXEL_SCALE)) begin
            
            // If within grid, check pixel memory
            VGA_COLOR = pixel_memory[grid_y][grid_x] ? 3'b000 : 3'b111;
        end
        else begin
            // Outside grid area - white background
            VGA_COLOR = 3'b111;
        end
    end

    // PS/2 mouse instance
    ps2_mouse mouse (
        .clk(CLOCK_50),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .left_button(left_button)
    );

    // VGA adapter instance
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
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