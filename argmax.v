module argmax (
    input wire clk,
    input wire start,
    input wire [15:0] size,          // Size of input array (10 for final layer)
    input wire [15:0] addr,          // Address to read from input memory
    input wire signed [31:0] data,   // Explicitly declare as signed input
    output reg [3:0] max_index,      // Output class (0-9)
    output reg done
);
    reg [15:0] current_addr;
    reg signed [31:0] max_value;     // Explicitly declare as signed
    reg [3:0] current_max_index;
    reg running;

    // State machine
    always @(posedge clk) begin
        if (start) begin
            current_addr <= 0;
            max_value <= 32'h80000000;  // Minimum signed 32-bit value (-2^31)
            current_max_index <= 0;
            running <= 1;
            done <= 0;
        end
        else if (running) begin
            if (current_addr < size) begin
                // Compare signed values - no need for $signed() when inputs are declared as signed
                if (data > max_value) begin
                    max_value <= data;
                    current_max_index <= current_addr[3:0];
                end
                current_addr <= current_addr + 1;
            end
            else begin
                max_index <= current_max_index;
                running <= 0;
                done <= 1;
            end
        end
    end

endmodule