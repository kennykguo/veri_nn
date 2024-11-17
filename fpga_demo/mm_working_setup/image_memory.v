module image_memory (
    input wire [15:0] address,
    output reg signed [31:0] data_out  // Change to signed for signed data
);
    reg signed [31:0] memory [0:3920];  // Use signed values for memory

    initial begin
        // Assuming your .mif file contains signed hex values (two's complement)
        $readmemh("matrix.mif", memory);
        if ($test$plusargs("DEBUG")) begin
            $display("Weight matrix memory file successfully loaded.");
        end
    end

    always @(address) begin
        data_out = memory[address];  // Signed read from memory
    end
endmodule
