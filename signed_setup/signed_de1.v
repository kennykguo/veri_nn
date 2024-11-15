module signed_arithmetic_fpga(
    input [7:0] a,       // 8-bit input a (unsigned)
    input [7:0] b,       // 8-bit input b (unsigned)
    output [8:0] add1,   // 9-bit output for signed addition (using $signed)
    output [8:0] add2,   // 9-bit output for signed addition (using signed keyword)
    output [15:0] mul1,  // 16-bit output for signed multiplication (using $signed)
    output [15:0] mul2   // 16-bit output for signed multiplication (using signed keyword)
);

    // Using $signed for manual casting
    assign add1 = $signed(a) + $signed(b);
    assign mul1 = $signed(a) * $signed(b);

    // Using signed keyword next to signals
    wire signed [7:0] signed_a = a; // Cast a as signed
    wire signed [7:0] signed_b = b; // Cast b as signed

    assign add2 = signed_a + signed_b;
    assign mul2 = signed_a * signed_b;

endmodule
