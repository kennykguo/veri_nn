`timescale 1ns / 1ps

module tb_neural_network_top;

    // Clock and Reset
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;
    reg PS2_CLK, PS2_DAT;

    // Outputs
    wire [7:0] VGA_R, VGA_G, VGA_B;
    wire VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [9:0] LEDR;

    // Parameters for PS2 keyboard codes
    parameter LEFT_ARROW = 8'h6B;
    parameter RIGHT_ARROW = 8'h74;
    parameter UP_ARROW = 8'h75;
    parameter DOWN_ARROW = 8'h72;

    // Clock generation
    always #10 CLOCK_50 = ~CLOCK_50;  // 50 MHz clock for simulation

    // Test stimulus
    initial begin
        // Initialize inputs
        CLOCK_50 = 0;
        KEY = 4'b1111;
        SW = 10'b0000000000;
        PS2_CLK = 0;
        PS2_DAT = 0;
        
        $display("Simulation started.");
        
        // Reset sequence
        #0 SW[9] = 1'b0;   // SET reset
        #20000 SW[9] = 1'b1;  // Assert reset
        
        // Drawing sequence
        #50;
        SW[1:0] = 2'b11;    // Enable drawing
        
        // Simulate drawing pattern
        repeat(5) begin
            PS2_CLK = 0;
            PS2_DAT = RIGHT_ARROW;
            #20;
            PS2_CLK = 1;
            #20;
            
            PS2_CLK = 0;
            PS2_DAT = DOWN_ARROW;
            #20;
            PS2_CLK = 1;
            #20;
        end

        // End drawing
        SW[1:0] = 2'b00;
        #200;

        // Start neural network processing
        SW[2] = 1'b1;
        #10;
        SW[2] = 1'b0;
        
        // Wait for done signal
        @(posedge uut.nn.done);  // Assuming 'done' is in the neural network module
        
        $display("Neural network processing completed.");
        $display("Predicted digit: %d", uut.argmax_output);
        
        #100 $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t SW=%b KEY=%b HEX0=%b argmax_output=%b", 
                 $time, SW, KEY, HEX0, uut.argmax_output);
    end

    // Instantiate the top module
    neural_network_top uut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR)
    );

endmodule
