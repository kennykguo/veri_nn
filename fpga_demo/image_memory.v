module image_memory (
    input clk,
    input wire reset,                // Active-high reset signal for memory initialization
    input wire init,                 // Initialization signal to load pixel data into memory
    input wire [15:0] address,       // Address for memory read
    input wire [783:0] pixel_data,   // Pixel data for initialization
    output reg [31:0] data_out,      // Output data from memory
    output reg done                  // Signal indicating loop completion
);


    reg signed [31:0] memory [0:783];  // 32-bit memory
    reg [9:0] i;                       // Counter for 0 to 783 (10 bits for 784 values)

    always @(posedge clk) begin
        if (reset) begin
            // Reset logic
            i <= 0;
            done <= 0;
            data_out <= 32'h00000000;

        end else if (init) begin
            // Initialization logic
            if (i < 784) begin
                memory[i] <= (pixel_data[i] == 1) ? 32'h00000001 : 32'h00000000;
                i <= i + 1;  // Increment counter
                done <= 0;   // Not done yet
            end else begin
                done <= 1;   // Signal completion
            end

        end else begin
            // Normal read operation
            data_out <= memory[address];
            done <= 0;       // Not relevant for normal read
        end

    end
endmodule
