module PS2_VGA_Demo (
    input CLOCK_50,
    input [3:0] KEY,
    inout PS2_CLK,
    inout PS2_DAT,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,
    output [6:0] HEX0,
    output [6:0] HEX1
);

    // Mouse tracking registers
    reg [7:0] mouse_status;
    reg [7:0] mouse_x_movement;
    reg [7:0] mouse_y_movement;
    reg [9:0] current_x = 80;  // Start in middle of 160x120 screen
    reg [9:0] current_y = 60;
    reg left_button;
    
    // 28x28 pixel memory
    reg [27:0] pixel_memory [27:0];
    
    // Grid parameters
    localparam GRID_SIZE = 28;
    localparam PIXEL_SCALE = 2;
    localparam GRID_START_X = 52;
    localparam GRID_START_Y = 32;

    // PS2 interface signals
    wire [7:0] ps2_key_data;
    wire ps2_key_pressed;
    reg [1:0] byte_count;

    // Mouse data processing
    always @(posedge CLOCK_50) begin
        if (KEY[0] == 1'b0) begin
            byte_count <= 2'b00;
            current_x <= 80;
            current_y <= 60;
            left_button <= 1'b0;
        end 
        else if (ps2_key_pressed) begin
            case (byte_count)
                2'b00: begin
                    mouse_status <= ps2_key_data;
                    left_button <= ps2_key_data[0];  // Left button status
                end
                2'b01: begin
                    mouse_x_movement <= ps2_key_data;
                    // Update X position with bounds checking
                    if (ps2_key_data[7] == 1'b1) begin  // Negative movement
                        if (current_x > 0)
                            current_x <= current_x - (~ps2_key_data[7:0] + 1'b1);
                    end
                    else begin  // Positive movement
                        if (current_x < 159)
                            current_x <= current_x + ps2_key_data;
                    end
                end
                2'b10: begin
                    mouse_y_movement <= ps2_key_data;
                    // Update Y position with bounds checking
                    if (ps2_key_data[7] == 1'b1) begin  // Negative movement
                        if (current_y > 0)
                            current_y <= current_y - (~ps2_key_data[7:0] + 1'b1);
                    end
                    else begin  // Positive movement
                        if (current_y < 119)
                            current_y <= current_y + ps2_key_data;
                    end
                end
            endcase
            byte_count <= byte_count + 1'b1;
        end
    end

    // Drawing logic
    wire [4:0] mouse_grid_x = (current_x - GRID_START_X) / PIXEL_SCALE;
    wire [4:0] mouse_grid_y = (current_y - GRID_START_Y) / PIXEL_SCALE;

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

    // VGA display logic
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    reg [2:0] VGA_COLOR;

    wire [4:0] grid_x = (VGA_X - GRID_START_X) / PIXEL_SCALE;
    wire [4:0] grid_y = (VGA_Y - GRID_START_Y) / PIXEL_SCALE;

    // Color selection logic
    always @(*) begin
        if (VGA_X == current_x && VGA_Y == current_y)
            VGA_COLOR = 3'b100;  // Red cursor
        else if (VGA_X >= GRID_START_X && 
                VGA_X < (GRID_START_X + GRID_SIZE * PIXEL_SCALE) &&
                VGA_Y >= GRID_START_Y && 
                VGA_Y < (GRID_START_Y + GRID_SIZE * PIXEL_SCALE))
            VGA_COLOR = pixel_memory[grid_y][grid_x] ? 3'b000 : 3'b111;
        else
            VGA_COLOR = 3'b111;  // White background
    end

    // PS2 Controller instance
    PS2_Controller PS2 (
        .CLOCK_50(CLOCK_50),
        .reset(~KEY[0]),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .received_data(ps2_key_data),
        .received_data_en(ps2_key_pressed)
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

    // Display mouse coordinates on HEX displays (optional)
    Hexadecimal_To_Seven_Segment Segment0 (
        .hex_number(current_x[3:0]),
        .seven_seg_display(HEX0)
    );

    Hexadecimal_To_Seven_Segment Segment1 (
        .hex_number(current_y[3:0]),
        .seven_seg_display(HEX1)
    );

endmodule