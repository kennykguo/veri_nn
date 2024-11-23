module image_memory (
    input clk,
    input wire reset,                // Active-high reset signal for memory initialization
    input wire init,                 // Initialization signal to load pixel data into memory
    input wire [15:0] address,       // Address for memory read
    input wire [783:0] pixel_data,   // Pixel data for initialization
    output reg [31:0] data_out       // Output data from memory
);
    reg signed [31:0] memory [0:783];  // 32-bit memory
    integer i;

    // Single always block to handle memory operations
    always @(posedge clk) begin

        if (reset) begin
            // Zero out all memory entries on reset
            for (i = 0; i < 784; i = i + 1) begin
                memory[i] <= 32'h00000000;
            end
            data_out <= 32'h00000000;
        end

        else if (init) begin
            // Initialize memory with pixel data
            for (i = 0; i < 784; i = i + 1) begin
                if (pixel_data[i] == 1) begin
                    memory[i] = 32'h00000001;  // If pixel is 1, set memory[i] to 00000001
                end else begin
                    memory[i] = 32'h00000000;  // If pixel is 0, set memory[i] to 00000000
                end
            end
        end


        else begin
            // Normal read operation
            data_out = memory[address];
        end
    end
endmodule