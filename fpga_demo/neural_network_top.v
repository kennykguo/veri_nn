module neural_network_top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    // Internal signals     
    // wire clk_slow; // Slower clock goes into nn FSM    
    wire start; // Starts sequence     
    wire resetn; // Active-low reset
    
    // State signals for debugging
    wire [3:0] argmax_output;  
    wire [3:0] current_state;
    wire [3:0] next_state;
    wire done;
    
    // Control signal assignments
    wire on = SW[0];         // Drawing grid enable
    wire draw = SW[1];      // Turn on to start drawing
    assign start = SW[2];    // Press to start (high)
    assign resetn = ~SW[9];    // ON to stop reset

    // Debug LEDs
    assign LEDR[9] = start;
    assign LEDR[3:0] = current_state;
    wire [3:0] led_control;
    assign LEDR[8:5] = led_control;

    combined_nn_mnist_grid combined_module (
        .clk(CLOCK_50),
        .reset(resetn),
        .start(start),
        .done(done),
        .on(on),
        .draw(draw),
        .KEY(KEY),
        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .HEX0(HEX2),
        .HEX1(HEX3),
        .HEX2(HEX4),
        .HEX3(HEX5),
        .led_control(led_control)
    );

    // Seven segment decoder logic
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;

    always @(posedge CLOCK_50 or posedge resetn) begin
        if (resetn) begin
            seg7_display = 7'b1111111;
        end else begin
            case (argmax_output)
                4'd0: seg7_display = 7'b1000000;
                4'd1: seg7_display = 7'b1111001;
                4'd2: seg7_display = 7'b0100100;
                4'd3: seg7_display = 7'b0110000;
                4'd4: seg7_display = 7'b0011001;
                4'd5: seg7_display = 7'b0010010;
                4'd6: seg7_display = 7'b0000010;
                4'd7: seg7_display = 7'b1111000;
                4'd8: seg7_display = 7'b0000000;
                4'd9: seg7_display = 7'b0010000;
                4'd10: seg7_display = 7'b0111111;
                default: seg7_display = 7'b1111111;
            endcase
        end
    end

    // Turn off unused display
    assign HEX1 = 7'b1111111;

endmodule