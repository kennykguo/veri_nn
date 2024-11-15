`timescale 1ns/1ps
module signed_arithmetic_tb;

    reg [7:0] a;        // 8-bit input a
    reg [7:0] b;        // 8-bit input b
    wire [8:0] add1;    // Result of signed addition using $signed
    wire [8:0] add2;    // Result of signed addition using signed keyword
    wire [15:0] mul1;   // Result of signed multiplication using $signed
    wire [15:0] mul2;   // Result of signed multiplication using signed keyword

    // Instantiate the module
    signed_arithmetic_fpga uut (
        .a(a),
        .b(b),
        .add1(add1),
        .add2(add2),
        .mul1(mul1),
        .mul2(mul2)
    );

    initial begin
        // Test Case 1: a = -5 (8'b11111011), b = 10 (8'b00001010)
        a = 8'b11111011; // -5 in signed 8-bit
        b = 8'b00001010; // 10 in signed 8-bit
        #10;
        $display("Test 1: a = -5, b = 10");
        $display("Expected add1, add2: 5 (9'd5), mul1, mul2: -50 (16'd65586)");
        $display("add1 = %d, add2 = %d, mul1 = %d, mul2 = %d", add1, add2, mul1, mul2);

        // Test Case 2: a = -128 (8'b10000000), b = -1 (8'b11111111)
        a = 8'b10000000; // -128 in signed 8-bit
        b = 8'b11111111; // -1 in signed 8-bit
        #10;
        $display("Test 2: a = -128, b = -1");
        $display("Expected add1, add2: -129 (9'b110000111), mul1, mul2: 128 (16'd128)");
        $display("add1 = %d, add2 = %d, mul1 = %d, mul2 = %d", add1, add2, mul1, mul2);

        // Test Case 3: a = 20 (8'b00010100), b = 15 (8'b00001111)
        a = 8'b00010100; // 20 in signed 8-bit
        b = 8'b00001111; // 15 in signed 8-bit
        #10;
        $display("Test 3: a = 20, b = 15");
        $display("Expected add1, add2: 35 (9'd35), mul1, mul2: 300 (16'd300)");
        $display("add1 = %d, add2 = %d, mul1 = %d, mul2 = %d", add1, add2, mul1, mul2);

        $finish;
    end

endmodule
