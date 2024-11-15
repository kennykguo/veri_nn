module matrix_multiply(
    input wire clk,
    input wire start,
    input wire [9:0] m,    // First matrix rows - 1024
    input wire [9:0] n,    // Second matrix columns - 1024
    input wire [9:0] k,    // First matrix columns/second matrix rows
    output reg [15:0] input_addr,
    input wire signed [31:0] input_data,    // Declare input_data as signed
    output reg [15:0] weight_addr,
    input wire signed [31:0] weight_data,   // Declare weight_data as signed
    output reg [15:0] output_addr,
    output reg signed [31:0] output_data,   // Declare output_data as signed
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
    reg signed [31:0] temp_sum;  // Signed accumulation
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
                
                // If wait_cycle is on, then we need to wait for one clock cycle. This allows for enough time for memory access
                if (wait_cycle) begin
                    wait_cycle <= 0;

                // Check if we have the final store done. If we do by any chance, then we should skip, in case the code doesn't automatically transition states
                end else if (!final_store_done) begin
                    // Accumulate the sum
                    // Check if we are on the first_mult accumulation
                    if (first_mult) begin
                        // First multiplication
                        temp_sum <= input_data * weight_data;  // Signed multiplication, no need for $signed()
                        first_mult <= 0;
                    end else begin
                        // Accumulate the sum
                        temp_sum <= temp_sum + (input_data * weight_data);  // Signed accumulation
                    end

                    // Display the current accumulated sum and the current inputs for debugging purposes
                    $display("Current Input: input_data = %d, weight_data = %d", input_data, weight_data);
                    $display("Accumulated Sum at (i=%d, j=%d, p=%d): temp_sum = %d", i, j, p, temp_sum);

                    // Check if we are on the last entry of a dot product
                    if (p == k-1) begin
                        // Get the last output address, accumulate it, and write it
                        output_addr <= i * n + j;
                        output_data <= temp_sum;  // Store the signed result
                        write_enable <= 1;

                        // Display the value being stored in the output at the end of the calculation
                        $display("Storing result at output_addr = %d: output_data = %d", output_addr, output_data);

                        // Check if we are done with the matrix multiplication
                        if (i == m-1 && j == n-1) begin
                            final_store_done <= 1;
                            last_calc_done <= 1;
                        end else begin
                            // Increment row/column and reset accumulation for next dot product
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
            end
        endcase
    end

endmodule
