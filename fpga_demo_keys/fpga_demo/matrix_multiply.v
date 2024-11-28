module matrix_multiply(
    input wire clk,
    input wire start,
    input wire [9:0] m,    
    input wire [9:0] n,    
    input wire [9:0] k,    
    output reg [15:0] input_addr,
    input wire signed [31:0] input_data,    
    output reg [15:0] weight_addr,
    input wire signed [31:0] weight_data,   
    output reg [15:0] output_addr,
    output reg signed [31:0] output_data,   
    output reg write_enable,
    output reg done
);

    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [9:0] i, j, p;
    reg signed [31:0] temp_sum;
    reg final_store_done;
    reg wait_cycle;
    reg first_mult;
    reg last_calc_done;

    // Debug: Track address changes
    always @(input_addr) begin
        // $display("\nTime=%0t | Input Address Changed to: %0d", $time, input_addr);
        // $display("Current indices: i=%0d, j=%0d, p=%0d", i, j, p);
        // $display("Address calculation: i*k + p = %0d*%0d + %0d = %0d", i, k, p, i*k + p);
    end

    always @(weight_addr) begin
        // $display("\nTime=%0t | Weight Address Changed to: %0d", $time, weight_addr);
        // $display("Current indices: i=%0d, j=%0d, p=%0d", i, j, p);
        // $display("Address calculation: p*n + j = %0d*%0d + %0d = %0d", p, n, j, p*n + j);
    end

    // State transition
    always @(posedge clk) begin
        current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: next_state = start ? COMPUTE : IDLE;
            COMPUTE: next_state = (final_store_done && last_calc_done) ? FINISH : COMPUTE;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Main FSM with enhanced memory access debugging
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    $display("\nTime=%0t | Matrix Multiplication Starting", $time);
                    $display("Matrix Dimensions: M=%0d, N=%0d, K=%0d", m, n, k);
                    $display("Total input matrix size: %0d", m * k);
                    $display("Total weight matrix size: %0d", k * n);
                    i <= 0;
                    j <= 0;
                    p <= 0;
                    temp_sum <= 32'h0;
                    done <= 0;
                    final_store_done <= 0;
                    last_calc_done <= 0;
                    write_enable <= 0;
                    wait_cycle <= 1;
                    first_mult <= 1;
                    input_addr <= 0;
                    weight_addr <= 0;
                end
            end

            COMPUTE: begin
                write_enable <= 0;
                
                if (wait_cycle) begin
                    // $display("\nTime=%0t | Wait Cycle", $time);
                    // $display("Next computation will use: i=%0d, j=%0d, p=%0d", i, j, p);
                    wait_cycle <= 0;
                end else if (!final_store_done) begin
                    // Debug memory access with detailed address validation
                    // $display("\nTime=%0t | Memory Access Details:", $time);
                    // $display("Input: addr=%0d, data=%0h", input_addr, input_data);
                    // $display("Weight: addr=%0d, data=%0h", weight_addr, weight_data);
                    // $display("Current multiply-accumulate state: temp_sum=%0h", temp_sum);

                    if (first_mult) begin
                        temp_sum <= input_data * weight_data;
                        first_mult <= 0;
                        // $display("First multiplication started: %0h * %0h", input_data, weight_data);
                    end else begin
                        temp_sum <= temp_sum + (input_data * weight_data);
                        // $display("Accumulation: %0h + (%0h * %0h)", temp_sum, input_data, weight_data);
                    end

                    if (p == k-1) begin
                        output_addr <= i * n + j;
                        output_data <= temp_sum + (input_data * weight_data);
                        write_enable <= 1;
                        
                        // $display("\nTime=%0t | Completing element calculation", $time);
                        // $display("Output position [%0d,%0d] at addr=%0d", i, j, i * n + j);
                        // $display("Final value=%0h", temp_sum + (input_data * weight_data));

                        if (i == m-1 && j == n-1) begin
                            final_store_done <= 1;
                            last_calc_done <= 1;
                        end else begin
                            if (j == n-1) begin
                                i <= i + 1;
                                j <= 0;
                            end else begin
                                j <= j + 1;
                            end
                            p <= 0;
                            temp_sum <= 0;
                            wait_cycle <= 1;
                            first_mult <= 1;

                            // Debug next address calculation
                            input_addr <= (j == n-1) ? (i + 1) * k : i * k;
                            weight_addr <= (j == n-1) ? 0 : (j + 1);
                            // $display("\nTime=%0t | Setting up next element", $time);
                            // $display("Next input_addr calculation: %s", 
                              //  (j == n-1) ? $sformatf("(i+1)*k = %0d", (i+1)*k) : 
                               //             $sformatf("i*k = %0d", i*k));
                        end
                    end else begin
                        p <= p + 1;
                        input_addr <= i * k + p + 1;
                        weight_addr <= (p + 1) * n + j;
                    end
                end
            end

            FINISH: begin
                done <= 1;
                write_enable <= 0;
                $display("\nTime=%0t | Matrix Multiplication Finished", $time);
            end
        endcase
    end

endmodule