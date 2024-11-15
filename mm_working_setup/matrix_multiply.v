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

    // Debug counters
    reg [31:0] computation_count;
    reg [31:0] multiplication_count;

    always @(posedge clk) begin
        current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE: next_state = start ? COMPUTE : IDLE;
            COMPUTE: next_state = (final_store_done && last_calc_done) ? FINISH : COMPUTE;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                if (start) begin
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
                    computation_count <= 0;
                    multiplication_count <= 0;
                    
                    $display("\n=== Starting Matrix Multiplication ===");
                    $display("Matrix Dimensions: (%0d x %0d) @ (%0d x %0d)", m, k, k, n);
                    $display("Expected number of multiplications: %0d", m * n * k);
                end
            end

            COMPUTE: begin
                write_enable <= 0;
                
                if (wait_cycle) begin
                    wait_cycle <= 0;
                    $display("\n[Wait Cycle] Indices (i=%0d, j=%0d, p=%0d)", i, j, p);
                    $display("Current Addresses: input_addr=%0d, weight_addr=%0d", input_addr, weight_addr);
                end else if (!final_store_done) begin
                    computation_count <= computation_count + 1;
                    
                    $display("\n--- Computation Step %0d ---", computation_count);
                    $display("Current Indices: i=%0d, j=%0d, p=%0d", i, j, p);
                    $display("Memory Addresses: input_addr=%0d, weight_addr=%0d", input_addr, weight_addr);
                    $display("Input Values: input_data=%0d, weight_data=%0d", input_data, weight_data);
                    
                    if (first_mult) begin
                        temp_sum <= input_data * weight_data;
                        first_mult <= 0;
                        multiplication_count <= multiplication_count + 1;
                        $display("First multiplication: %0d * %0d = %0d", 
                                input_data, weight_data, input_data * weight_data);
                    end else begin
                        temp_sum <= temp_sum + (input_data * weight_data);
                        multiplication_count <= multiplication_count + 1;
                        $display("Accumulating: previous_sum=%0d + (%0d * %0d) = %0d",
                                temp_sum, input_data, weight_data, 
                                temp_sum + (input_data * weight_data));
                    end

                    if (p == k-1) begin
                        output_addr <= i * n + j;
                        output_data <= temp_sum + (input_data * weight_data);
                        write_enable <= 1;
                        
                        $display("\n=== Dot Product Complete ===");
                        $display("Storing at output_addr=%0d: final_sum=%0d", 
                                i * n + j, temp_sum + (input_data * weight_data));

                        if (i == m-1 && j == n-1) begin
                            final_store_done <= 1;
                            last_calc_done <= 1;
                            $display("\n*** Matrix Multiplication Complete ***");
                            $display("Total computations: %0d", computation_count + 1);
                            $display("Total multiplications: %0d", multiplication_count + 1);
                        end else begin
                            if (j == n-1) begin
                                i <= i + 1;
                                j <= 0;
                                $display("\n>>> Moving to next row <<<");
                            end else begin
                                j <= j + 1;
                                $display("\n>>> Moving to next column <<<");
                            end
                            p <= 0;
                            temp_sum <= 0;
                            wait_cycle <= 1;
                            first_mult <= 1;

                            input_addr <= (j == n-1) ? (i + 1) * k : i * k;
                            weight_addr <= (j == n-1) ? 0 : (j + 1);
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
                $display("\n=== Matrix Multiplication Finished ===");
            end
        endcase
    end

endmodule