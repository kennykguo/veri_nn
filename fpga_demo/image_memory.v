module image_memory (
    input wire [15:0] address,
    input wire [783:0] pixel_data,  // New input
    output reg [31:0] data_out
);
    reg signed [31:0] memory [0:783];  // 32-bit values

    integer i;
    always @(*) begin
        for (i = 0; i < 784; i = i + 1) begin
            memory[i] = pixel_data[i] ? 32'h00000001 : 32'h00000000;
        end
    end

    always @(address) begin
        data_out = memory[address];
    end
endmodule