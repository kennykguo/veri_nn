module matrix_multiply_top (
    input  wire         CLOCK_50,  // DE1-SoC 50MHz clock
    input  wire  [3:0]  KEY,       // Active-LOW push buttons
    input  wire  [9:0]  SW,        // Switches
    output wire  [9:0]  LEDR,      // LEDs
    output wire  [6:0]  HEX0,      // 7-segment displays
    output wire  [6:0]  HEX1,
    output wire  [6:0]  HEX2,
    output wire  [6:0]  HEX3,
    output wire  [6:0]  HEX4,
    output wire  [6:0]  HEX5
);

    // Internal signals
    wire clk;
    wire rst_n;
    wire start;
    wire done;
    
    wire [15:0] input_addr;
    wire [15:0] weight_addr;
    wire [15:0] output_addr;
    wire [31:0] input_data;
    wire [31:0] weight_data;
    wire [31:0] output_data;
    wire write_enable;
    
    // Constants
    localparam M = 10'd5;    // First matrix rows
    localparam N = 10'd5;    // Second matrix columns
    localparam K = 10'd784;  // First matrix columns/Second matrix rows

    // Assign control signals
    assign clk = CLOCK_50;
    assign rst_n = KEY[0];    // Active-low reset
    assign start = ~KEY[1];   // Active-low start button
    
    // Status LED outputs
    assign LEDR[0] = ~rst_n;  // Reset indicator
    assign LEDR[1] = start;   // Start indicator
    assign LEDR[9] = done;    // Done indicator

    // Memory instances
    image_memory input_mem (
        .clock(clk),
        .address(input_addr),
        .data_out(input_data)
    );
    
    matrix_memory weight_mem (
        .clock(clk),
        .address(weight_addr),
        .data_out(weight_data)
    );
    
    // Output memory instance
    output_memory result_mem (
        .clock(clk),
        .address(output_addr),
        .data(output_data),
        .wren(write_enable),
        .q()  // Not used in this implementation
    );
    
    // Matrix multiplier instance
    matrix_multiply mult (
        .clk(clk),
        .rst_n(rst_n),
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

    // 7-segment display control (showing completion status)
    seven_segment hex0 (
        .in(done ? 4'hd : 4'h0),  // 'd' when done, '0' when running
        .out(HEX0)
    );

    // Turn off unused displays
    assign HEX1 = 7'b1111111;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

endmodule

// Modified memory modules for FPGA
module image_memory (
    input  wire        clock,
    input  wire [15:0] address,
    output reg  [31:0] data_out
);
    // Dual-port RAM inference
    reg [31:0] mem [0:3919];  // 5x784 matrix

    initial begin
        $readmemh("image.mif", mem);
    end

    always @(posedge clock) begin
        data_out <= mem[address];
    end
endmodule

module matrix_memory (
    input  wire        clock,
    input  wire [15:0] address,
    output reg  [31:0] data_out
);
    // Dual-port RAM inference
    reg [31:0] mem [0:3919];  // 784x5 matrix

    initial begin
        $readmemh("matrix.mif", mem);
    end

    always @(posedge clock) begin
        data_out <= mem[address];
    end
endmodule

module output_memory (
    input  wire        clock,
    input  wire [15:0] address,
    input  wire [31:0] data,
    input  wire        wren,
    output reg  [31:0] q
);
    reg [31:0] mem [0:24];  // 5x5 result matrix

    always @(posedge clock) begin
        if (wren)
            mem[address] <= data;
        q <= mem[address];
    end
endmodule

// Seven-segment display decoder
module seven_segment (
    input  wire [3:0] in,
    output reg  [6:0] out
);
    always @(*) begin
        case (in)
            4'h0: out = 7'b1000000;  // 0
            4'h1: out = 7'b1111001;  // 1
            4'h2: out = 7'b0100100;  // 2
            4'h3: out = 7'b0110000;  // 3
            4'h4: out = 7'b0011001;  // 4
            4'h5: out = 7'b0010010;  // 5
            4'h6: out = 7'b0000010;  // 6
            4'h7: out = 7'b1111000;  // 7
            4'h8: out = 7'b0000000;  // 8
            4'h9: out = 7'b0010000;  // 9
            4'ha: out = 7'b0001000;  // A
            4'hb: out = 7'b0000011;  // b
            4'hc: out = 7'b1000110;  // C
            4'hd: out = 7'b0100001;  // d
            4'he: out = 7'b0000110;  // E
            4'hf: out = 7'b0001110;  // F
            default: out = 7'b1111111;
        endcase
    end
endmodule