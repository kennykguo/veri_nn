module PS2_Demo (
    CLOCK_50,
    KEY,
    PS2_CLK,
    PS2_DAT,
    VGA_CLK,
    VGA_R,
    VGA_G,
    VGA_B,
    VGA_HS,
    VGA_VS,
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,
    HEX6,
    HEX7
);

// Inputs
input CLOCK_50;
input [3:0] KEY;

// Bidirectionals for PS2
inout PS2_CLK;
inout PS2_DAT;

// VGA outputs
output VGA_CLK;
output [7:0] VGA_R, VGA_G, VGA_B;
output VGA_HS, VGA_VS;

// Output display (7-segment displays)
output [6:0] HEX0;
output [6:0] HEX1;
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX4;
output [6:0] HEX5;
output [6:0] HEX6;
output [6:0] HEX7;

// Internal wires
wire [7:0] ps2_key_data;     // PS2 key data received
wire ps2_key_pressed;        // Indicates if a key was pressed
wire [9:0] cursor_x, cursor_y;  // Mouse cursor coordinates
wire left_click;  // Left mouse button pressed

// Internal registers
reg [7:0] last_data_received;  // Stores last data received
reg [1:0] byte_count;  // To count the bytes from mouse
reg [9:0] mouse_x, mouse_y;  // Mouse X and Y relative movements
reg [9:0] screen_width = 640, screen_height = 480;  // VGA screen resolution

// Mouse data processing
always @(posedge CLOCK_50) begin
    if (KEY[0] == 1'b0) begin
        byte_count <= 2'b00;
        mouse_x <= screen_width / 2;  // Reset to center
        mouse_y <= screen_height / 2;  // Reset to center
    end else if (ps2_key_pressed) begin
        case (byte_count)
            2'b00: begin
                // Store status byte
                // Extract left click and movement data
                byte_count <= 2'b01;
            end
            2'b01: begin
                // Store X movement
                mouse_x <= mouse_x + ps2_key_data;
                byte_count <= 2'b10;
            end
            2'b10: begin
                // Store Y movement
                mouse_y <= mouse_y + ps2_key_data;
                byte_count <= 2'b00;
            end
        endcase
    end
end

// Limit mouse coordinates to screen size
always @(posedge CLOCK_50) begin
    if (mouse_x < 0) mouse_x <= 0;
    else if (mouse_x > screen_width - 1) mouse_x <= screen_width - 1;

    if (mouse_y < 0) mouse_y <= 0;
    else if (mouse_y > screen_height - 1) mouse_y <= screen_height - 1;
end

// PS2 Controller instance (for receiving data from the mouse)
PS2_Controller PS2 (
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0]),
    .PS2_CLK(PS2_CLK),
    .PS2_DAT(PS2_DAT),
    .received_data(ps2_key_data),
    .received_data_en(ps2_key_pressed)
);

// VGA and Cursor Logic

// VGA synchronization (simplified)
VGA_Controller vga_inst (
    .clk(CLOCK_50),
    .reset(~KEY[0]),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .cursor_x(cursor_x),
    .cursor_y(cursor_y),
    .left_click(left_click)
);

// Detect left-click from mouse
assign left_click = ps2_key_data[0];  // Left button pressed from the status byte

// Display cursor position on VGA screen
assign cursor_x = mouse_x;  // Horizontal position
assign cursor_y = mouse_y;  // Vertical position

// Disable unused HEX displays
assign HEX2 = 7'h7F;
assign HEX3 = 7'h7F;
assign HEX4 = 7'h7F;
assign HEX5 = 7'h7F;
assign HEX6 = 7'h7F;
assign HEX7 = 7'h7F;

// Hexadecimal to 7-segment display converters for mouse data (Optional)
Hexadecimal_To_Seven_Segment Segment0 (
    .hex_number(last_data_received[3:0]),
    .seven_seg_display(HEX0)
);

Hexadecimal_To_Seven_Segment Segment1 (
    .hex_number(last_data_received[7:4]),
    .seven_seg_display(HEX1)
);

endmodule


// VGA Controller Module for Cursor Rendering
module VGA_Controller (
    input clk,
    input reset,
    output reg [7:0] VGA_R, VGA_G, VGA_B,  // VGA color outputs
    output reg VGA_HS, VGA_VS,  // VGA synchronization signals
    input [9:0] cursor_x, cursor_y,  // Cursor position
    input left_click  // Left mouse button state
);

// VGA 640x480 @60Hz parameters
parameter SCREEN_WIDTH = 640;
parameter SCREEN_HEIGHT = 480;
parameter H_SYNC_CYCLES = 96;  // Horizontal sync width
parameter H_BACK_PORCH = 48;  // Horizontal back porch
parameter H_ACTIVE_VIDEO = 640;  // Horizontal active video width
parameter H_FRONT_PORCH = 16;  // Horizontal front porch

parameter V_SYNC_CYCLES = 2;  // Vertical sync width
parameter V_BACK_PORCH = 33;  // Vertical back porch
parameter V_ACTIVE_VIDEO = 480;  // Vertical active video height
parameter V_FRONT_PORCH = 10;  // Vertical front porch

// Horizontal and Vertical counters
reg [9:0] h_count = 0;  // Horizontal pixel counter
reg [9:0] v_count = 0;  // Vertical pixel counter

// Generate VGA sync signals and display cursor
always @(posedge clk or posedge reset) begin
    if (reset) begin
        h_count <= 0;
        v_count <= 0;
    end else begin
        // Horizontal counter logic
        if (h_count == SCREEN_WIDTH + H_SYNC_CYCLES + H_BACK_PORCH + H_FRONT_PORCH - 1)
            h_count <= 0;
        else
            h_count <= h_count + 1;

        // Vertical counter logic
        if (h_count == SCREEN_WIDTH + H_SYNC_CYCLES + H_BACK_PORCH + H_FRONT_PORCH - 1) begin
            if (v_count == SCREEN_HEIGHT + V_SYNC_CYCLES + V_BACK_PORCH + V_FRONT_PORCH - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end
    end
end

// VGA synchronization signals
assign VGA_HS = (h_count < H_SYNC_CYCLES);
assign VGA_VS = (v_count < V_SYNC_CYCLES);

// Display the cursor (simple 1x1 pixel representation)
always @(posedge clk) begin
    if ((h_count == cursor_x) && (v_count == cursor_y)) begin
        // If cursor is at current pixel, change color
        VGA_R <= left_click ? 8'hFF : 8'h00;  // Red when clicked, else off
        VGA_G <= left_click ? 8'h00 : 8'h00;  // Green off
        VGA_B <= left_click ? 8'h00 : 8'h00;  // Blue off
    end else begin
        // Background color (black in this case)
        VGA_R <= 8'h00;
        VGA_G <= 8'h00;
        VGA_B <= 8'h00;
    end
end

endmodule
