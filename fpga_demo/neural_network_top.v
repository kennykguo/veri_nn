module neural_network_top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    input PS2_CLK,
    input PS2_DAT,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    // Internal signals     
    wire clk_slow;         
    wire start;            
    wire resetn;           
    wire init;       
    wire on;
    wire draw;
    wire done;            

    // Memory interface signals
    wire [15:0] grid_write_addr;    // From drawing grid
    wire [31:0] grid_data_write;    // From drawing grid
    wire grid_write_enable;         // From drawing grid
    wire [15:0] nn_write_addr;      // From neural network
    wire [31:0] nn_data_write;      // From neural network
    wire nn_write_enable;           // From neural network
    
    wire [15:0] read_addr;          // Multiplexed read address
    wire [31:0] data_out;           // Memory output data
    
    // State signals for debugging
    wire [3:0] current_state;
    wire [3:0] next_state;
    wire [3:0] argmax_output;

    // Clock divider instance
    clock_divider clk_div (
        .clk_in(CLOCK_50),
        .clk_out(clk_slow),
        .DIVISOR(32'd500)
    );

    // Control signal assignments
    assign start = SW[2];    // Press to start (high)
    assign resetn = ~SW[9];  // ON to stop reset
    assign on = SW[0];       // Drawing grid enable
    assign draw = SW[1];

    // Debug LEDs
    assign LEDR[9] = start;
    assign LEDR[3:0] = current_state;

    // Multiplexed memory write signals
    wire [15:0] write_addr = on ? grid_write_addr : nn_write_addr;
    wire [31:0] data_in = on ? grid_data_write : nn_data_write;
    wire write_enable = on ? grid_write_enable : nn_write_enable;

    // Image memory instance
    image_memory img_mem (
        .clk(CLOCK_50),
        .reset(resetn),
        .write_addr(write_addr),
        .write_enable(write_enable),
        .data_in(data_in),
        .read_addr(read_addr),
        .data_out(data_out)
    );

    // Drawing grid instance with memory interface
    mnist_drawing_grid drawing_grid (
        .CLOCK_50(CLOCK_50),
        .reset(resetn),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .draw(draw),
        .on(on),
        .write_addr(grid_write_addr),
        .write_enable(grid_write_enable),
        .data_write(grid_data_write),
        .read_addr(read_addr),
        .data_read(data_out),
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
        .led_control(LEDR[8:4])
    );

    // Neural network instance with memory interface
    neural_network nn (
        .clk(clk_slow),
        .resetn(resetn),
        .start(start),
        .write_addr(nn_write_addr),
        .write_enable(nn_write_enable),
        .data_write(nn_data_write),
        .image_read_addr(read_addr),
        .image_data_out(data_out),
        .done(done),
        .current_state(current_state),
        .next_state(next_state),
        .argmax_output(argmax_output)
    );

    // Seven segment decoder logic
    reg [6:0] seg7_display;
    assign HEX0 = seg7_display;

    always @(*) begin
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

    // Clock divider module

endmodule

module clock_divider (
    input clk_in,
    input [31:0] DIVISOR,
    output reg clk_out
);
    reg [31:0] counter = 32'd0;
    
    always @(posedge clk_in) begin
        counter <= counter + 32'd1;
        if (counter >= (DIVISOR - 1)) begin
            counter <= 32'd0;
            clk_out <= ~clk_out;
        end
    end
endmodule