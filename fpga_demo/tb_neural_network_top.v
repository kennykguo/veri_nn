`timescale 1ns / 1ps

module tb_neural_network_top;
    // Clock and reset
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;

    // Outputs
    wire [7:0] VGA_R, VGA_G, VGA_B;
    wire VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [9:0] LEDR;

    // Clock generation (CLOCK_50)
    always #10 CLOCK_50 = ~CLOCK_50;  // 50 MHz clock for simulation

    // Modified press_key task with extended timing
    task press_key;
        input [3:0] key_value;
        begin
            KEY = 4'b1111;      // All keys released (active low)
            #50000;             // Wait 50 us before press
            KEY = key_value;    // Press specific key
            #100000;            // Hold key for 100 us
            KEY = 4'b1111;      // Release key
            #100000;            // Wait 100 us between presses
        end
    endtask

    // Modified draw_pattern task with increased delays
    task draw_pattern;
        integer i;
        begin
            // Initial delay after enabling drawing mode
            #200000;
            // Move right and draw
            // $display("Drawing right movement");
            for(i = 0; i < 3; i = i + 1) begin
                $display("Right movement %d", i);
                press_key(4'b0111);  // Press KEY[3] for right
                #200000; // Increased delay between movements
            end
            
            // Move down and draw
            // $display("Drawing down movement");
            for(i = 0; i < 3; i = i + 1) begin
                $display("Down movement %d", i);
                press_key(4'b1110);  // Press KEY[0] for down
                #200000;
            end
            
            // Move left and draw
            // $display("Drawing left movement");
            for(i = 0; i < 3; i = i + 1) begin
                $display("Left movement %d", i);
                press_key(4'b1011);  // Press KEY[2] for left
                #200000;
            end
            
            // Move up and draw
            // $display("Drawing up movement");
            for(i = 0; i < 3; i = i + 1) begin
                $display("Up movement %d", i);
                press_key(4'b1101);  // Press KEY[1] for up
                #200000;
            end

            // Final delay after pattern completion
            #200000;
        end
    endtask

    initial begin
        // Initialize inputs
        CLOCK_50 = 0;
        KEY = 4'b1111;
        SW = 10'b0000000000;
        
        $display("Simulation started.");
        
        // Reset sequence with extended timing
        #0 SW[9] = 1'b0;   // SET reset to 0 (RESET ON)
        #1000;
        #0 SW[9] = 1'b1;   // Assert reset (RESET OFF)
        #20000;
        
        // Enable drawing mode
        $display("Drawing started.");
        SW[1:0] = 2'b11;    // Enable drawing and on signal
        
        // Draw a pattern
        draw_pattern();

        $display("Drawing ended.");
        
        #2000000;
        // End drawing
        SW[1:0] = 2'b00;
        #20000;

        // Start neural network processing
        $display("Starting neural network processing");
        SW[2] = 1'b1;
        #20000;
        SW[2] = 1'b0;

        // Wait for done signal
        @(posedge uut.nn.done);
        $display("Neural network processing completed.");
        $display("Predicted digit: %d", uut.argmax_output);
        #20000 $finish;
    end

    // Enhanced monitoring
    initial begin
        $monitor("Time=%0t SW=%b KEY=%b Current_Pos=(%d,%d)", 
                 $time, SW, KEY, 
                 uut.drawing_grid.current_x,
                 uut.drawing_grid.current_y);
    end

    // Instantiate the top module
    neural_network_top uut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
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
