module clock_divider (
    input clk_in,
    input [31:0] DIVISOR,
    output reg clk_out
);
    reg [31:0] counter = 32'd0;
    
    always @(posedge clk_in) begin
        counter <= counter + 32'd1;
        if (counter >= (DIVISOR - 1)) begin
            counter <= 32'd0;
            clk_out <= ~clk_out;
        end
    end
endmodule