module image_memory (
    input wire clk,
    input wire reset,
    input wire [15:0] write_addr,    // Address for writing
    input wire [15:0] read_addr,     // Address for reading
    input wire signed [31:0] data_in,
    input wire write_enable,
    output reg signed [31:0] data_out
);
    reg signed [31:0] memory [0:783];  // 32-bit values for 784 pixels

    // Read operation (getter)
    always @(*) begin
        data_out = memory[read_addr];
    end

    // Write operation (setter) with synchronous reset
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 784; i = i + 1) begin
                memory[i] <= 32'h00000000;
            end
        end
        else if (write_enable) begin
            memory[write_addr] <= data_in;
            $display("Memory Write: Address = %d, Data = %d, Write Enable = %b", write_addr, data_in, write_enable);
        end
    end

endmodule