module neural_network_top (
    input  CLOCK_50,
    input  KEY1,      // Start signal (active low)
    output [9:0] LEDR, // LEDs for state indication
    output [6:0] HEX0  // 7-segment display for output
);

    // Internal signals
    wire clk;
    wire start;
    wire done;
    wire [3:0] argmax_output;
    
    // State signals
    reg [3:0] current_state;
    wire [3:0] next_state;
    
    // Assign clock and start
    assign clk = CLOCK_50;
    assign start = ~KEY1; // Keys are active low

    // Seven segment decoder
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;

    // LED state indicators
    assign LEDR[9:0] = (10'b1 << current_state); // One-hot encoding for states

    // Your existing neural network instance
    neural_network_core core (
        .clk(clk),
        .start(start),
        .done(done),
        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output)
    );

    // Seven segment display decoder
    always @(*) begin
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

endmodule