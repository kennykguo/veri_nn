module drawing_tool (
    input wire clk, rst,
    // Mouse inputs
    input wire mouse_clk,
    input wire mouse_data,
    // VGA outputs
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B,
    output reg VGA_HS,
    output reg VGA_VS,
    // Output register for neural network
    output reg [783:0] pixel_data
);

// VGA Parameters
parameter H_VISIBLE = 640;
parameter V_VISIBLE = 480;
parameter GRID_SIZE = 28;
parameter PIXEL_SIZE = 16; // 448x448 drawing area (28*16)

// Mouse tracking
reg [9:0] mouse_x;
reg [9:0] mouse_y;
reg mouse_left_button;

// Drawing grid (784 pixels)
reg [783:0] drawing_grid;

// VGA counters
reg [9:0] h_count;
reg [9:0] v_count;

// Mouse interface
mouse_controller mouse_inst (
    .clk(clk),
    .rst(rst),
    .mouse_clk(mouse_clk),
    .mouse_data(mouse_data),
    .mouse_x(mouse_x),
    .mouse_y(mouse_y),
    .left_button(mouse_left_button)
);

// Convert mouse coordinates to grid position
wire [4:0] grid_x = mouse_x[9:4]; // Divide by 16
wire [4:0] grid_y = mouse_y[9:4];
wire [9:0] grid_index = (grid_y * GRID_SIZE) + grid_x;

// Drawing logic
always @(posedge clk) begin
    if (rst) begin
        drawing_grid <= 784'b0;
        pixel_data <= 784'b0;
    end
    else if (mouse_left_button && 
             grid_x < GRID_SIZE && 
             grid_y < GRID_SIZE) begin
        drawing_grid[grid_index] <= 1'b1;
        pixel_data[grid_index] <= 1'b1;
    end
end

// VGA display logic
always @(posedge clk) begin
    // VGA timing and sync generation here
    
    // Display logic
    if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
        // Calculate which grid cell we're in
        wire [4:0] display_x = h_count[9:4];
        wire [4:0] display_y = v_count[9:4];
        wire [9:0] display_index = (display_y * GRID_SIZE) + display_x;
        
        // Display grid
        if (display_x < GRID_SIZE && display_y < GRID_SIZE) begin
            if (drawing_grid[display_index]) begin
                // Black pixel
                VGA_R <= 4'b0000;
                VGA_G <= 4'b0000;
                VGA_B <= 4'b0000;
            end
            else begin
                // White pixel
                VGA_R <= 4'b1111;
                VGA_G <= 4'b1111;
                VGA_B <= 4'b1111;
            end
        end
        else begin
            // Gray background
            VGA_R <= 4'b1000;
            VGA_G <= 4'b1000;
            VGA_B <= 4'b1000;
        end
    end
end

endmodule