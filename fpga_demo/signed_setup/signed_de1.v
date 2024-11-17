module signed_arithmetic_fpga(
    input [7:0] a,       // 8-bit input a (unsigned)
    input [7:0] b,       // 8-bit input b (unsigned)
    output [8:0] add1,   // 9-bit output for signed addition (using $signed)
    output [8:0] add2,   // 9-bit output for signed addition (using signed keyword)
    output [15:0] mul1,  // 16-bit output for signed multiplication (using $signed)
    output [15:0] mul2   // 16-bit output for signed multiplication (using signed keyword)
);

    // Use $signed casting for signed operations
    assign add1 = $signed(a) + $signed(b);
    assign mul1 = $signed(a) * $signed(b);

    // Use signed keyword directly for signals
    wire signed [7:0] signed_a = a;  // Declare a as signed (this will properly interpret the sign)
    wire signed [7:0] signed_b = b;  // Declare b as signed (this will properly interpret the sign)

    assign add2 = signed_a + signed_b; // Addition with signed values
    assign mul2 = signed_a * signed_b; // Multiplication with signed values

endmodule
