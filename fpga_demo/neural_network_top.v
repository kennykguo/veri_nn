module neural_network_top (
    input CLOCK_50,
    input KEY0,      // Start signal (active low)
    input [9:0] SW,
    output [9:0] LEDR, // LEDs for state indication
    output [6:0] HEX0  // 7-segment display for output
);

    // Internal signals
    wire clk;
    wire clk_slow;
    wire start;
    wire resetn;
    wire done;
    wire [3:0] argmax_output;
    


    // State signals - Changed to wire since they're outputs from neural_network
    wire [3:0] current_state;
    wire [3:0] next_state;
    


    // Clock divider instance
    clock_divider clk_div (
        .clk_in(CLOCK_50),
        .clk_out(clk_slow),
        .DIVISOR(32'd2)  // Adjust this value to change clock speed
    );



    // Assign clock, start and reset
    assign clk = clk_slow;  // Use the slower clock
    assign start = ~KEY0;   // Keys are active low
    assign resetn = SW[0];

    // Seven segment decoder
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;


    assign LEDR[9] = start;  // Shows if start is active
    assign LEDR[8] = mm1_done;  // Shows if mm1 is done
    assign LEDR[7:0] = current_state;  // Shows current state in binary

    // Neural network instance
    neural_network nn (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .done(done),
        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output)
    );

    // Seven segment display decoder with reset
    always @(*) begin
        if (!resetn) begin
            seg7_display = 7'b1111111; // Off when reset is active (low)
        end else begin
            case(argmax_output)
                4'd0: seg7_display = 7'b1000000; // 0
                4'd1: seg7_display = 7'b1111001; // 1
                4'd2: seg7_display = 7'b0100100; // 2
                4'd3: seg7_display = 7'b0110000; // 3
                4'd4: seg7_display = 7'b0011001; // 4
                4'd5: seg7_display = 7'b0010010; // 5
                4'd6: seg7_display = 7'b0000010; // 6
                4'd7: seg7_display = 7'b1111000; // 7
                4'd8: seg7_display = 7'b0000000; // 8
                4'd9: seg7_display = 7'b0010000; // 9
                default: seg7_display = 7'b1111111; // Off
            endcase
        end
    end

endmodule