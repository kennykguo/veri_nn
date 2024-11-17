module matrix_memory (
    input wire [15:0] address,
    output reg [31:0] data_out
);
    reg [31:0] memory [0:3920];  // 32-bit values

    initial begin
        $readmemh("matrix.mif", memory);
        if ($test$plusargs("DEBUG")) begin
            $display("Weight matrix memory file successfully loaded.");
        end
    end

    always @(address) begin
        data_out = memory[address];
    end
endmodule