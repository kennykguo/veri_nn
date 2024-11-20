/*
*   Displays a coloured pattern on the VGA output, which is a large green triangle.
*   Then, allows the user to draw coloured pixels at any x, y coordinates. To set
*   a coordinate, first place the desired value of y onto SW[6:0] and then press KEY[1]
*   to store this value into a register. Next, place the desired value of x onto SW[7:0]
*   and then press KEY[2] to store this into a register. Finally, place the desired 
*   3-bit colour onto SW[2:0] and press KEY[3] to draw the selected pixel. The x 
*   coordinate is displayed (in hexadecimal) on HEX3-2, and y coordinate on HEX1-0.
*/
module vga_demo(CLOCK_50, SW, KEY, HEX3, HEX2, HEX1, HEX0,
                VGA_R, VGA_G, VGA_B,
                VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
    
    input CLOCK_50;    
    input [7:0] SW;
    input [3:0] KEY;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;    
    
    wire [2:0] colour;
    wire [7:0] X;
    wire [6:0] Y;
    
    assign colour = SW[2:0];

    regn UY (SW[6:0], KEY[0], ~KEY[1], CLOCK_50, Y);
    regn UX (SW[7:0], KEY[0], ~KEY[2], CLOCK_50, X);
        defparam UY.n = 7;

    hex7seg H3 (X[7:4], HEX3);
    hex7seg H2 (X[3:0], HEX2);
    hex7seg H1 ({1'b0, Y[6:4]}, HEX1);
    hex7seg H0 (Y[3:0], HEX0);

    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour(colour),
        .x(X),
        .y(Y),
        .plot(~KEY[3]),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
endmodule

module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule

module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule
