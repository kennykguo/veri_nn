module vga_demo(
    input CLOCK_50,    // 50 MHz clock input
    input [9:0] SW,    // Switch inputs
    input [3:0] KEY,   // Key (button) inputs
    output [7:0] VGA_R, VGA_G, VGA_B, // VGA color output (Red, Green, Blue)
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, // VGA sync and control signals
    output [6:0] HEX0, HEX1, HEX2, HEX3, // 7-segment display outputs for coordinates
    output [9:0] LEDR // LED outputs for debugging and showing data
);
    
    // Grid configuration parameters
    parameter GRID_SIZE = 28;      
    parameter CELL_SIZE = 4;      
    parameter GRID_START_X = 10;  
    parameter GRID_START_Y = 10;  
    
    // Memory array to store grid cell states
    reg [0:0] grid_cells [0:783];  // 784 cells (28x28 grid)
    
    // Cursor position tracking
    reg [4:0] cursor_pos_x; // CURRENT POSITION IN THE GRID
    reg [4:0] cursor_pos_y; // CURRENT POSITION IN THE GRID
    
    // Button input handling
    reg [3:0] prev_button_state;  
    wire [3:0] button_pressed = ~KEY & ~prev_button_state;

    // Movement timing control
    reg [19:0] move_cooldown; 
    parameter MOVE_DELAY_MAX = 20'd100000; 
    
    // VGA coordinate tracking
    wire [7:0] vga_scan_x; // Goes into VGA module
    wire [6:0] vga_scan_y; // Goes into VGA module
    wire [2:0] pixel_color;

    // Drawing control
    reg draw_enable;
    reg [7:0] draw_pos_x;  // CURRENT P
    reg [6:0] draw_pos_y;  
    
    // Cell subdivision tracking
    reg [1:0] subcell_pos_x; 
    reg [1:0] subcell_pos_y; 
    
    // Drawing state machines
    reg [2:0] cell_draw_state;  
    reg [1:0] temp_subcell_x;  
    reg [1:0] temp_subcell_y;  
    
    // Grid drawing state control
    reg [2:0] grid_draw_state;   
    reg [4:0] grid_pos_x, grid_pos_y;  
    
    // Debug output connections
    assign LEDR[9] = SW[9];  
    assign LEDR[8] = SW[1];  
    assign LEDR[4:0] = cursor_pos_x[4:0];  
    
    // Coordinate displays
    hex_display hex0(cursor_pos_x[3:0], HEX0);
    hex_display hex1({3'b000, cursor_pos_x[4]}, HEX1);
    hex_display hex2(cursor_pos_y[3:0], HEX2);
    hex_display hex3({3'b000, cursor_pos_y[4]}, HEX3);
    
    // Initialization block
    integer i;
    initial begin
        for(i = 0; i < 784; i = i + 1) begin
            grid_cells[i] <= 1'b0;
        end
        cursor_pos_x <= 5'd14;
        cursor_pos_y <= 5'd14;
        
        prev_button_state <= 4'b1111;
        move_cooldown <= 20'd0;
        grid_draw_state <= 3'b000;
        draw_pos_x <= GRID_START_X;
        draw_pos_y <= GRID_START_Y;
        subcell_pos_x <= 2'b00;
        subcell_pos_y <= 2'b00;
        cell_draw_state <= 3'b000;
        draw_enable <= 1'b0;
    end
    
    // State machine parameters
    parameter STATE_INIT = 3'b000;
    parameter STATE_DRAW = 3'b001;
    parameter STATE_OPERATE = 3'b010;

    // Cell drawing states
    parameter CELL_DRAW_IDLE = 3'b000;
    parameter CELL_DRAW_ACTIVE = 3'b001;
    parameter CELL_DRAW_UPDATE = 3'b010;

    // Main drawing state machine
    always @(posedge CLOCK_50) begin
        case(grid_draw_state)
            STATE_INIT: begin
                draw_pos_x <= GRID_START_X;
                draw_pos_y <= GRID_START_Y;
                grid_pos_x <= 5'b00000;
                grid_pos_y <= 5'b00000;
                subcell_pos_x <= 2'b00;
                subcell_pos_y <= 2'b00;
                grid_draw_state <= STATE_DRAW;
                draw_enable <= 1'b1;
            end
            
            STATE_DRAW: begin
                if (subcell_pos_x == 2'b11) begin
                    subcell_pos_x <= 2'b00;
                    if (subcell_pos_y == 2'b11) begin
                        subcell_pos_y <= 2'b00;
                        draw_pos_x <= draw_pos_x + CELL_SIZE;
                        if (draw_pos_x >= (GRID_START_X + GRID_SIZE * CELL_SIZE - CELL_SIZE)) begin
                            draw_pos_x <= GRID_START_X;
                            draw_pos_y <= draw_pos_y + CELL_SIZE;
                        end
                    end else begin
                        subcell_pos_y <= subcell_pos_y + 1'b1;
                    end
                end else begin
                    subcell_pos_x <= subcell_pos_x + 1'b1;
                end
                
                if (draw_pos_y >= (GRID_START_Y + GRID_SIZE * CELL_SIZE - CELL_SIZE) && 
                    subcell_pos_y == 2'b11 && subcell_pos_x == 2'b11) begin
                    grid_draw_state <= STATE_OPERATE;
                    cell_draw_state <= CELL_DRAW_IDLE;
                    draw_enable <= 1'b0;
                end
            end
            
            STATE_OPERATE: begin
                // Movement and drawing logic
            end
        endcase

        // This FSM ensures that the position to draw is always updated
        case(cell_draw_state)
            CELL_DRAW_IDLE: begin
                temp_subcell_x <= 2'b00;
                temp_subcell_y <= 2'b00;
                draw_enable <= 1'b0;
                if (SW[1]) cell_draw_state <= CELL_DRAW_ACTIVE;
            end
            
            CELL_DRAW_ACTIVE: begin
                draw_enable <= 1'b1;
                draw_pos_x <= GRID_START_X + (cursor_pos_x * CELL_SIZE) + temp_subcell_x;
                draw_pos_y <= GRID_START_Y + (cursor_pos_y * CELL_SIZE) + temp_subcell_y;
                cell_draw_state <= CELL_DRAW_UPDATE;
            end
            
            CELL_DRAW_UPDATE: begin
                draw_enable <= 1'b0;
                if (temp_subcell_x == 2'b11) begin
                    temp_subcell_x <= 2'b00;
                    if (temp_subcell_y == 2'b11) begin
                        cell_draw_state <= CELL_DRAW_IDLE;
                        grid_cells[cursor_pos_y * GRID_SIZE + cursor_pos_x] <= 1'b1;
                    end else begin
                        temp_subcell_y <= temp_subcell_y + 1'b1;
                        cell_draw_state <= CELL_DRAW_ACTIVE;
                    end
                end else begin
                    temp_subcell_x <= temp_subcell_x + 1'b1;
                    cell_draw_state <= CELL_DRAW_ACTIVE;
                end
            end
        endcase
    end

    // Color output logic
    assign pixel_color = (grid_draw_state == STATE_DRAW) ? 3'b111 :
                       (cell_draw_state == CELL_DRAW_ACTIVE || cell_draw_state == CELL_DRAW_UPDATE) ? 3'b000 :
                       ((vga_scan_x >= GRID_START_X && vga_scan_x < (GRID_START_X + GRID_SIZE * CELL_SIZE) &&
                         vga_scan_y >= GRID_START_Y && vga_scan_y < (GRID_START_Y + GRID_SIZE * CELL_SIZE)) ? 
                        ((((vga_scan_x - GRID_START_X) / CELL_SIZE) == cursor_pos_x && 
                          ((vga_scan_y - GRID_START_Y) / CELL_SIZE) == cursor_pos_y) ? 3'b100 :
                         (grid_cells[((vga_scan_y - GRID_START_Y) / CELL_SIZE) * GRID_SIZE + 
                                   ((vga_scan_x - GRID_START_X) / CELL_SIZE)] ? 3'b000 : 3'b111)) :
                        3'b000);
    
    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(1'b1),
        .clock(CLOCK_50),
        .colour(pixel_color),
        .x(grid_draw_state == STATE_DRAW ? draw_pos_x + subcell_pos_x :
           (cell_draw_state == CELL_DRAW_ACTIVE || cell_draw_state == CELL_DRAW_UPDATE) ? draw_pos_x : vga_scan_x),
        .y(grid_draw_state == STATE_DRAW ? draw_pos_y + subcell_pos_y :
           (cell_draw_state == CELL_DRAW_ACTIVE || cell_draw_state == CELL_DRAW_UPDATE) ? draw_pos_y : vga_scan_y),
        .plot(grid_draw_state == STATE_DRAW || cell_draw_state == CELL_DRAW_ACTIVE),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";
    
endmodule

module hex_display(
    input [3:0] IN,
    output reg [6:0] OUT
);
    always @(*)
        case (IN)
            4'h0: OUT = 7'b1000000;
            4'h1: OUT = 7'b1111001;
            4'h2: OUT = 7'b0100100;
            4'h3: OUT = 7'b0110000;
            4'h4: OUT = 7'b0011001;
            4'h5: OUT = 7'b0010010;
            4'h6: OUT = 7'b0000010;
            4'h7: OUT = 7'b1111000;
            4'h8: OUT = 7'b0000000;
            4'h9: OUT = 7'b0010000;
            4'hA: OUT = 7'b0001000;
            4'hB: OUT = 7'b0000011;
            4'hC: OUT = 7'b1000110;
            4'hD: OUT = 7'b0100001;
            4'hE: OUT = 7'b0000110;
            4'hF: OUT = 7'b0001110;
            default: OUT = 7'b1111111;
        endcase
endmodule