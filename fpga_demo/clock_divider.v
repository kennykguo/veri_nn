module clock_divider (
    input clk_in,           // Input clock (e.g., 50 MHz)
    output reg clk_out,     // Slower clock output
    input [31:0] DIVISOR    // Divisor value (e.g., 20)
);

    reg [31:0] counter;     // Counter for clock division

    // Initialize the output clock to 0
    initial begin
        counter = 0;
        clk_out = 0;
    end

    always @(posedge clk_in) begin
        if (counter >= DIVISOR - 1) begin
            counter <= 0;           // Reset the counter
            clk_out <= 1;           // Rise up at the divisor point
        end else begin
            counter <= counter + 1; // Increment the counter
            clk_out <= 0;           // Stay low for the remainder of the cycle
        end
    end
endmodule
