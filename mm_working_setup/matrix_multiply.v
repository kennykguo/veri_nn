module matrix_multiply(
    input wire clk,
    input wire start,
    input wire [9:0] m,    // First matrix rows - 1024
    input wire [9:0] n,    // Second matrix columns - 1024
    input wire [9:0] k,    // First matrix columns/second matrix rows
    output reg [15:0] input_addr,
    input wire [31:0] input_data,
    output reg [15:0] weight_addr,
    input wire [31:0] weight_data,
    output reg [15:0] output_addr,
    output reg [31:0] output_data,
    output reg write_enable,
    output reg done
);

    // (A, B) @ (B, C) = (A, C)
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [9:0] i, j, p;
    reg [31:0] temp_sum;
    reg final_store_done;
    reg wait_cycle;
    reg first_mult;
    reg last_calc_done;  // New flag to prevent double calculation

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
                    // Reset all indices
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
                    $display("\nStarting matrix multiplication...");
                end
            end

            COMPUTE: begin
                // Reset write_enable
                write_enable <= 0;
                
                // If wait_cycle is on, then we need to wait for one clock_cycle. This allows for enough time for memory access
                if (wait_cycle) begin
                    wait_cycle <= 0;

                // Check if we have the final store done. If we do by any chance, then we should skip, incase the code doesn't automatically transition states
                end else if (!final_store_done) begin
                    // $display("Time=%0t: Computing element [%0d,%0d, %d]", $time, i, j, p);
                    // $display("  Step %0d: %0d * %0d = %0d", p, input_data, weight_data, input_data * weight_data);
            
                    // Accumulate the sum
                    // Check if we are on the first_mult accumulation
                    if (first_mult) begin
                        // $display("  Running sum: 0 + (%0d * %0d) = %0d", input_data, weight_data, input_data * weight_data);
                        // Set the multiplication to the first data point
                        temp_sum <= input_data * weight_data;
                        // Reset the signal
                        first_mult <= 0;
                    end else begin
                        // $display("  Running sum: %0d + (%0d * %0d) = %0d", temp_sum, input_data, weight_data, temp_sum + (input_data * weight_data));
                        // If we are not, then we should accumulate
                        temp_sum <= temp_sum + (input_data * weight_data);
                    end


                    // Check if we are on the last entry of a dot product
                    if (p == k-1) begin

                        // Get the last output address, accumulate it, and write it
                        output_addr <= i * n + j;
                        output_data <= temp_sum + (input_data * weight_data);
                        write_enable <= 1;

                        // $display("Final calculation for element [%0d,%0d]:", i, j);
                        // $display("  Final step: %0d + (%0d * %0d) = %0d",  temp_sum, input_data, weight_data, temp_sum + (input_data * weight_data));
                        // $display("  Storing result [%0d,%0d] = %0d", i, j, temp_sum + (input_data * weight_data));

                        // Check if we are done the matrix multiplication
                        // If we are done, update the signals correctly to transition
                        if (i == m-1 && j == n-1) begin
                            // Might be a redundant signal, but the code works :P
                            final_store_done <= 1;
                            last_calc_done <= 1;
                            // $display("\nMatrix multiplication completed!");

                        // If we are not done the matrix multiplication
                        // Checks how we should increment i and j (dot product finished)
                        end else begin
                        
                            // Check if we should increment the row, and reset the column (next entry) (dot product moves row since we are at the last column, and then reset the column too)
                            if (j == n-1) begin
                                i <= i + 1;
                                j <= 0;
                                // $display("\nMoving to next row...");
                            
                            // If not, then we should increment the column (move the column up)
                            end else begin
                                j <= j + 1;
                            end

                            // Reset the p value, temp sum, wait_cycle signal, first_mult signal for next k dot product
                            p <= 0;
                            temp_sum <= 0;
                            wait_cycle <= 1;
                            first_mult <= 1;

                            // Update the addresses (We only updated i and j, now we need to increment to the correct rows/columns
                            // If j = n - 1, the column has reached the end, and we should increment the row
                            input_addr <= (j == n-1) ? (i + 1) * k : i * k;
                            // If we are at the last column, we should reset to the last column. Otherwise, we should increment the column index by 1
                            weight_addr <= (j == n-1) ? 0 : (j + 1);
                        end
                    
                    // If we are not in the last entry of the current dot product
                    // Increment the addresses by 1, in the row, or the column direction
                    end else begin
                        p <= p + 1;
                        input_addr <= i * k + p + 1;
                        weight_addr <= (p + 1) * n + j;
                    end
                end

            end

            // Complete the matrix multiplication, and output done signal to signal a state transition in main NN FSM
            FINISH: begin
                done <= 1;
                write_enable <= 0;
            end
        endcase
    end
endmodule