module PS2_Demo (
    CLOCK_50,
    KEY,
    PS2_CLK,
    PS2_DAT,
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,
    HEX6,
    HEX7
);


// Inputs:
// CLOCK_50: 50 MHz clock signal.
// KEY: Buttons or switches used for resets or input triggers.
// Bidirectional:
// PS2_CLK, PS2_DAT: Bidirectional lines for the PS/2 interface.
// Outputs:
// HEX0 to HEX7: Seven-segment display outputs.
// Interfaces with the PS2_Controller module to handle PS/2 communication.
// Processes received PS/2 data (e.g., keypresses or mouse movements).
// Displays processed data on seven-segment displays (HEX0 to HEX7).

// Inputs
input CLOCK_50;
input [3:0] KEY;

// Bidirectionals for PS2
inout PS2_CLK;
inout PS2_DAT;

// Output display
output [6:0] HEX0;
output [6:0] HEX1;
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX4;
output [6:0] HEX5;
output [6:0] HEX6;
output [6:0] HEX7;

// Internal Wires
wire [7:0] ps2_key_data;      // PS2 key data received
wire ps2_key_pressed;         // Indicates if a key was pressed

// Internal Registers
reg [7:0] last_data_received; // Stores the last data received

// FSM to read data from the PS2 device
always @(posedge CLOCK_50) begin
    if (KEY[0] == 1'b0)
        last_data_received <= 8'h00;
    else if (ps2_key_pressed == 1'b1)
        last_data_received <= ps2_key_data;
end

// Disable unused HEX displays
assign HEX2 = 7'h7F;
assign HEX3 = 7'h7F;
assign HEX4 = 7'h7F;
assign HEX5 = 7'h7F;
assign HEX6 = 7'h7F;
assign HEX7 = 7'h7F;

// PS2 Controller instance
PS2_Controller PS2 (
    .CLOCK_50          (CLOCK_50),
    .reset             (~KEY[0]),
    .PS2_CLK           (PS2_CLK),
    .PS2_DAT           (PS2_DAT),
    .received_data     (ps2_key_data),
    .received_data_en  (ps2_key_pressed)
);
// Interfaces with the mouse. Must pass in received_data, and received_data_en signals when data is available
// Listens to PS2_DAT and PS2_CLK
// Three bytes are sent in sequence 
// Byte 1 (Status Byte): 0b00001001 (Left button pressed, no overflow).
// Byte 2 (X Movement): 0b00000101 (+5 movement on X-axis, positive direction).
// Byte 3 (Y Movement): 0b11111011 (-5 movement on Y-axis, negative direction).



// Hexadecimal to 7-segment display converters
Hexadecimal_To_Seven_Segment Segment0 (
    .hex_number (last_data_received[3:0]),
    .seven_seg_display (HEX0)
);

Hexadecimal_To_Seven_Segment Segment1 (
    .hex_number (last_data_received[7:4]),
    .seven_seg_display (HEX1)
);

endmodule


// reg [1:0] byte_count;
// always @(posedge CLOCK_50) begin
//     if (KEY[0] == 1'b0) begin
//         byte_count <= 2'b00;
//     end else if (ps2_key_pressed) begin
//         case (byte_count)
//             2'b00: mouse_status <= ps2_key_data;
//             2'b01: mouse_x <= ps2_key_data;
//             2'b10: mouse_y <= ps2_key_data;
//         endcase
//         byte_count <= byte_count + 1'b1;
//     end
// end