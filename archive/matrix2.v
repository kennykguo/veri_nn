module matrix2 (
    input wire [15:0] address,
    output reg [31:0] data_out
);
    reg signed [31:0] memory [0:4095];  // 32-bit values

    initial begin
        $readmemh("matrix2.mif", memory);
        if ($test$plusargs("DEBUG")) begin
            $display("Weight matrix 2 memory file successfully loaded.");
        end
    end

    always @(address) begin
        data_out = memory[address];
    end
endmodule