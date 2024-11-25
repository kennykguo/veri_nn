module image_memory (
    input wire clk,
    input wire reset,
    input wire [15:0] write_addr,    // Address for writing
    input wire [15:0] read_addr,     // Address for reading
    input wire signed [31:0] data_in, // Data input in
    input wire write_enable,          // Write enable signal
    output reg signed [31:0] data_out, // Data output out
    output reg [3:0] led_control     // LED control for the four corners
);

    reg signed [31:0] memory [0:783];  // 32-bit values for 784 pixels (28x28 image)
    reg [3:0] corner_leds; // Register to hold the corner LEDs

    // Write operation (setter) with synchronous reset
    integer i;

    always @(posedge clk) begin
        // Reset takes highest priority
        if (reset) begin
            for (i = 0; i < 784; i = i + 1) begin
                memory[i] <= 32'h00000000;  // Reset memory to zero
            end
            led_control <= 4'b0000; // Reset LEDs to off
        end else if (write_enable) begin
            memory[write_addr] <= data_in;  // Perform write operation with non-blocking
        end

        // Initialize the corner LEDs to all OFF
        corner_leds = 4'b0000;
        // Check each corner of the memory and set the corresponding LED if non-zero
        if (memory[0] == 32'h00000001)         corner_leds[0] = 1; // Top-left corner
        if (memory[28] == 32'h00000001)        corner_leds[1] = 1; // Top-right corner
        if (memory[757] == 32'h00000001)       corner_leds[2] = 1; // Bottom-left corner
        if (memory[782] == 32'h00000001)       corner_leds[3] = 1; // Bottom-right corner

        // Assign the corner LEDs to led_control with non-blocking
        led_control <= corner_leds;
    end

    // Read operation (getter) for memory
    always @(*) begin
        data_out = memory[read_addr];  // Output memory value based on read address (use blocking)
    end

endmodule
