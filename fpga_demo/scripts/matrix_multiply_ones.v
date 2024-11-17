module tb_matrix_multiply();
    reg clk;
    reg start;
    wire done;
    
    wire [15:0] input_addr;
    wire [15:0] weight_addr;
    wire [15:0] output_addr;

    wire [31:0] input_data;
    wire [31:0] weight_data;
    wire [31:0] output_data;
    wire write_enable;
    
    localparam M = 10'd5;    // Number of images
    localparam N = 10'd784;  // Pixels per image
    localparam K = 10'd5;    // Output dimension
    
    reg [31:0] input_memory [0:3919];   // 5x784
    reg [31:0] weight_memory [0:3919];  // 784x5
    reg [31:0] output_memory [0:24];    // 5x5
    
    // Memory read logic with bounds checking
    assign input_data = (input_addr < 3920) ? input_memory[input_addr] : 32'h0;
    assign weight_data = (weight_addr < 3920) ? weight_memory[weight_addr] : 32'h0;
    
    // Output memory write logic with bounds checking
    always @(posedge clk) begin
        if (write_enable && output_addr < 25) begin
            output_memory[output_addr] <= output_data;
            $display("Writing to output_addr %d: %h (temp_sum: %h)", 
                    output_addr, output_data, mult.temp_sum);
        end
    end
    
    matrix_multiply mult (
        .clk(clk),
        .start(start),
        .m(M),      // 5
        .n(K),      // 5
        .k(N),      // 784
        .input_addr(input_addr),
        .input_data(input_data),
        .weight_addr(weight_addr),
        .weight_data(weight_data),
        .output_addr(output_addr),
        .output_data(output_data),
        .write_enable(write_enable),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Test procedure
    integer i;
    initial begin
        // Initialize memories
        start = 0;
        
        // Initialize all memories to known values
        for (i = 0; i < 3920; i = i + 1) begin
            input_memory[i] = 32'h00000001;    // Small values for easier debugging
            weight_memory[i] = 32'h00000001;    // Small values for easier debugging
        end
        
        // Initialize output memory
        for (i = 0; i < 25; i = i + 1) begin
            output_memory[i] = 32'h0;
        end
        
        // Start multiplication
        #100;  // Initial delay
        start = 1;
        #20;   // Hold start signal
        start = 0;
        
        // Wait for completion
        @(posedge done);
        
        // Display results with proper formatting
        $display("\nMatrix multiplication complete!");
        $display("Result matrix (5x5):");
        for (i = 0; i < 5; i = i + 1) begin
            $display("Row %0d: %08h %08h %08h %08h %08h", 
                i,
                output_memory[i*5],
                output_memory[i*5+1],
                output_memory[i*5+2],
                output_memory[i*5+3],
                output_memory[i*5+4]
            );
        end
        
        // Verify results
        $display("\nVerifying results...");
        for (i = 0; i < 25; i = i + 1) begin
            if (output_memory[i] === 32'hxxxxxxxx) begin
                $display("Error: Invalid result at index %0d: %h", i, output_memory[i]);
            end
        end
        
        #100;
        $finish;
    end

    // Debug monitoring
    always @(posedge clk) begin
        if (mult.current_state == mult.COMPUTE) begin
            $display("Time=%0t: i=%0d, j=%0d, p=%0d, temp_sum=%h", 
                    $time, mult.i, mult.j, mult.p, mult.temp_sum);
            $display("input_addr=%0d, weight_addr=%0d, input_data=%h, weight_data=%h",
                    input_addr, weight_addr, input_data, weight_data);
        end
    end
    
    // Monitor state changes
    always @(mult.current_state) begin
        case (mult.current_state)
            mult.IDLE: $display("Time=%0t: State = IDLE", $time);
            mult.COMPUTE: $display("Time=%0t: State = COMPUTE", $time);
            mult.FINISH: $display("Time=%0t: State = FINISH", $time);
            default: $display("Time=%0t: State = UNKNOWN", $time);
        endcase
    end

endmodule