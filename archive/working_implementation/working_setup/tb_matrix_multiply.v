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
    
    localparam M = 10'd5;    // First matrix rows
    localparam N = 10'd5;    // Second matrix columns
    localparam K = 10'd784;  // First matrix columns/Second matrix rows
    
    reg [31:0] output_memory [0:24];    // 5x5
    
    // Instantiate memory modules
    image_memory input_mem (
        .address(input_addr),
        .data_out(input_data)
    );
    
    matrix_memory weight_mem (
        .address(weight_addr),
        .data_out(weight_data)
    );
    
    // Output memory write logic
    always @(posedge clk) begin
        if (write_enable) begin
            output_memory[output_addr] <= output_data;
            $display("Writing to output_addr %5d: %h", output_addr, output_data);
        end
    end
    
    matrix_multiply mult (
        .clk(clk),
        .start(start),
        .m(M),
        .n(N),
        .k(K),
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
        // Initialize
        start = 0;
        
        // Initialize output memory
        for (i = 0; i < 25; i = i + 1) begin
            output_memory[i] = 32'h0;
        end
        
        // Start multiplication
        #20;
        start = 1;
        
        // Wait for completion
        @(posedge done);
        
        // Display results
        $display("\nMatrix multiplication complete!");
        $display("Result matrix (5x5):");
        for (i = 0; i < 5; i = i + 1) begin
            $display("%h %h %h %h %h", 
                output_memory[i*5],
                output_memory[i*5+1],
                output_memory[i*5+2],
                output_memory[i*5+3],
                output_memory[i*5+4]
            );
        end
        
        #100;
        $finish;
    end

endmodule