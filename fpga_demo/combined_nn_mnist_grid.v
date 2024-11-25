module combined_nn_mnist_grid (
    input wire clk,
    input wire reset,
    input wire start,
    output wire done,
    input on,         
    input draw, 
    input wire PS2_CLK,
    input wire PS2_DAT, 
    input [3:0] KEY, // KEY[0] = down, KEY[1] = up, KEY[2] = left, KEY[3] = right
    output reg [3:0] current_state,
    output reg [3:0] next_state,
    output wire [3:0] argmax_output,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    input [3:0] led_control
);



// ---------------------------------------------------------------------------
    // Existing neural_network declarations and logic
    // Memory addresses for weights and inputs
    wire [15:0] image_addr, weight1_addr, weight2_addr, weight3_addr, weight4_addr;
    // Memory data signals
    wire signed [31:0] image_data, weight1_data, weight2_data, weight3_data, weight4_data;
    // Separate read/write addresses for each memory module
    wire [15:0] mm1_write_addr, mm1_read_addr;
    wire [15:0] relu1_write_addr, relu1_read_addr;
    wire [15:0] mm2_write_addr, mm2_read_addr;
    wire [15:0] relu2_write_addr, relu2_read_addr;
    wire [15:0] mm3_write_addr, mm3_read_addr;
    wire [15:0] relu3_write_addr, relu3_read_addr;
    wire [15:0] mm4_write_addr, mm4_read_addr;
    // Layer data and memory interfaces
    wire signed [31:0] mm1_data, mm2_data, mm3_data, mm4_data;
    wire signed [31:0] relu1_data, relu2_data, relu3_data;
    wire signed [31:0] mm1_data_out, relu1_data_out;
    wire signed [31:0] mm2_data_out, relu2_data_out;
    wire signed [31:0] mm3_data_out, relu3_data_out;
    wire signed [31:0] mm4_data_out;
    // Write enable signals
    wire write_mm1, write_relu1;
    wire write_mm2, write_relu2;
    wire write_mm3, write_relu3;
    wire write_mm4;
    // Control signals
    reg start_mm1, start_mm2, start_mm3, start_mm4;
    reg start_relu1, start_relu2, start_relu3;
    reg start_argmax;
    // Done signals
    wire mm1_done, mm2_done, mm3_done, mm4_done;
    wire relu1_done, relu2_done, relu3_done;
    wire argmax_done;
    matrix1 weight_mem1(
        .address(weight1_addr),
        .data_out(weight1_data)
    );
    matrix2 weight_mem2(
        .address(weight2_addr),
        .data_out(weight2_data)
    );
    matrix3 weight_mem3(
        .address(weight3_addr),
        .data_out(weight3_data)
    );
    matrix4 weight_mem4(
        .address(weight4_addr),
        .data_out(weight4_data)
    );
    // Memory modules for intermediate results
    mm1_memory mm1_mem(
        .clk(clk),
        .write_addr(mm1_write_addr),
        .read_addr(mm1_read_addr),
        .data_in(mm1_data),
        .write_enable(write_mm1),
        .data_out(mm1_data_out)
    );
    relu1_memory relu1_mem(
        .clk(clk),
        .write_addr(relu1_write_addr),
        .read_addr(relu1_read_addr),
        .data_in(relu1_data),
        .write_enable(write_relu1),
        .data_out(relu1_data_out)
    );
    mm2_memory mm2_mem(
        .clk(clk),
        .write_addr(mm2_write_addr),
        .read_addr(mm2_read_addr),
        .data_in(mm2_data),
        .write_enable(write_mm2),
        .data_out(mm2_data_out)
    );
    relu2_memory relu2_mem(
        .clk(clk),
        .write_addr(relu2_write_addr),
        .read_addr(relu2_read_addr),
        .data_in(relu2_data),
        .write_enable(write_relu2),
        .data_out(relu2_data_out)
    );
    mm3_memory mm3_mem(
        .clk(clk),
        .write_addr(mm3_write_addr),
        .read_addr(mm3_read_addr),
        .data_in(mm3_data),
        .write_enable(write_mm3),
        .data_out(mm3_data_out)
    );
    relu3_memory relu3_mem(
        .clk(clk),
        .write_addr(relu3_write_addr),
        .read_addr(relu3_read_addr),
        .data_in(relu3_data),
        .write_enable(write_relu3),
        .data_out(relu3_data_out)
    );
    mm4_memory mm4_mem(
        .clk(clk),
        .write_addr(mm4_write_addr),
        .read_addr(mm4_read_addr),
        .data_in(mm4_data),
        .write_enable(write_mm4),
        .data_out(mm4_data_out)
    );
    // Neural network components
    matrix_multiply mm1(
        .clk(clk),
        .start(start_mm1),
        .m(10'd1),
        .n(10'd64),
        .k(10'd784),
        .input_addr(image_addr),
        .input_data(image_data),
        .weight_addr(weight1_addr),
        .weight_data(weight1_data),
        .output_addr(mm1_write_addr),
        .output_data(mm1_data),
        .write_enable(write_mm1),
        .done(mm1_done)
    );
    relu relu1(
        .clk(clk),
        .start(start_relu1),
        .d(10'd64),
        .input_addr(mm1_read_addr),
        .input_data(mm1_data_out),
        .output_addr(relu1_write_addr),
        .output_data(relu1_data),
        .write_enable(write_relu1),
        .done(relu1_done)
    );
    matrix_multiply mm2(
        .clk(clk),
        .start(start_mm2),
        .m(10'd1),
        .n(10'd64),
        .k(10'd64),
        .input_addr(relu1_read_addr),
        .input_data(relu1_data_out),
        .weight_addr(weight2_addr),
        .weight_data(weight2_data),
        .output_addr(mm2_write_addr),
        .output_data(mm2_data),
        .write_enable(write_mm2),
        .done(mm2_done)
    );
    relu relu2(
        .clk(clk),
        .start(start_relu2),
        .d(10'd64),
        .input_addr(mm2_read_addr),
        .input_data(mm2_data_out),
        .output_addr(relu2_write_addr),
        .output_data(relu2_data),
        .write_enable(write_relu2),
        .done(relu2_done)
    );
    matrix_multiply mm3(
        .clk(clk),
        .start(start_mm3),
        .m(10'd1),
        .n(10'd32),
        .k(10'd64),
        .input_addr(relu2_read_addr),
        .input_data(relu2_data_out),
        .weight_addr(weight3_addr),
        .weight_data(weight3_data),
        .output_addr(mm3_write_addr),
        .output_data(mm3_data),
        .write_enable(write_mm3),
        .done(mm3_done)
    );
    relu relu3(
        .clk(clk),
        .start(start_relu3),
        .d(10'd32),
        .input_addr(mm3_read_addr),
        .input_data(mm3_data_out),
        .output_addr(relu3_write_addr),
        .output_data(relu3_data),
        .write_enable(write_relu3),
        .done(relu3_done)
    );
    matrix_multiply mm4(
        .clk(clk),
        .start(start_mm4),
        .m(10'd1),
        .n(10'd10),
        .k(10'd32),
        .input_addr(relu3_read_addr),
        .input_data(relu3_data_out),
        .weight_addr(weight4_addr),
        .weight_data(weight4_data),
        .output_addr(mm4_write_addr),
        .output_data(mm4_data),
        .write_enable(write_mm4),
        .done(mm4_done)
    );
    argmax argmax_op(
        .clk(clk),
        .resetn(reset),
        .start(start_argmax),
        .size(16'd10),
        .addr(mm4_read_addr),
        .data(mm4_data_out),
        .max_index(argmax_output),
        .done(argmax_done)
    );
    // State definitions
    localparam IDLE = 4'd0;
    localparam LAYER1_MM = 4'd1;
    localparam LAYER1_RELU = 4'd2;
    localparam LAYER2_MM = 4'd3;
    localparam LAYER2_RELU = 4'd4;
    localparam LAYER3_MM = 4'd5;
    localparam LAYER3_RELU = 4'd6;
    localparam LAYER4_MM = 4'd7;
    localparam ARGMAX = 4'd8;
    localparam DONE = 4'd9;

    // State transitions
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // State machine control logic
    always @(posedge clk) begin
        start_mm1 = 0;
        start_relu1 = 0;
        start_mm2 = 0;
        start_relu2 = 0;
        start_mm3 = 0;
        start_relu3 = 0;
        start_mm4 = 0;
        start_argmax = 0;

        case (current_state)
            IDLE: begin
                if (start) next_state = LAYER1_MM;
                else next_state = IDLE;
                start_mm1 = start;
            end
            
            LAYER1_MM: begin
                if (mm1_done) begin
                    next_state = LAYER1_RELU;
                    start_relu1 = 1;
                end else begin
                    next_state = LAYER1_MM;
                end
            end
            
            LAYER1_RELU: begin
                if (relu1_done) begin
                    next_state = LAYER2_MM;
                    start_mm2 = 1;
                end else begin
                    next_state = LAYER1_RELU;
                end
            end
            
            LAYER2_MM: begin
                if (mm2_done) begin
                    next_state = LAYER2_RELU;
                    start_relu2 = 1;
                end else begin
                    next_state = LAYER2_MM;
                end
            end
            
            LAYER2_RELU: begin
                if (relu2_done) begin
                    next_state = LAYER3_MM;
                    start_mm3 = 1;
                end else begin
                    next_state = LAYER2_RELU;
                end
            end
            
            LAYER3_MM: begin
                if (mm3_done) begin
                    next_state = LAYER3_RELU;
                    start_relu3 = 1;
                end else begin
                    next_state = LAYER3_MM;
                end
            end
            
            LAYER3_RELU: begin
                if (relu3_done) begin
                    next_state = LAYER4_MM;
                    start_mm4 = 1;
                end else begin
                    next_state = LAYER3_RELU;
                end
            end
            
            LAYER4_MM: begin
                if (mm4_done) begin
                    next_state = ARGMAX;
                    start_argmax = 1;
                end else begin
                    next_state = LAYER4_MM;
                end
            end
            
            ARGMAX: begin
                if (argmax_done) next_state = DONE;
                else next_state = ARGMAX;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output assignment
    assign done = (current_state == DONE);
// ---------------------------------------------------------------------------   






// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// ---------------------------------------------------------------------------
// Existing mnist_drawing_grid declarations and logic
// ---------------------------------------------------------------------------
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Grid constants (28x28)
    parameter GRID_SIZE = 28;
    parameter PIXEL_SIZE = 4;
    // State definitions for both FSMs
    parameter INIT = 3'b000;
    parameter DRAW_GRID = 3'b001;
    parameter MOVE = 3'b010;
    // PS2 keyboard arrow key scan codes
    parameter LEFT_ARROW = 8'h6B;
    parameter RIGHT_ARROW = 8'h74;
    parameter UP_ARROW = 8'h75;
    parameter DOWN_ARROW = 8'h72;
    // Cursor position registers
    reg [4:0] current_x;
    reg [4:0] current_y;
    // PS2 keyboard interface signals
    wire [7:0] ps2_scan_code;
    wire ps2_key_pressed;
    wire ps2_done_tick;
    // Movement control
    reg [19:0] move_delay;
    parameter DELAY_MAX = 20'd2000000;
    // Drawing control
    reg plot;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    // Inner pixel drawing control
    reg [1:0] pixel_x_offset;
    reg [1:0] pixel_y_offset;
    // State registers
    reg [2:0] draw_state;
    reg [2:0] move_state;
    // Reset synchronization
    reg [2:0] reset_sync;
    wire reset_f;

    // Grid memory signals
    wire [15:0] draw_write_addr;
    assign draw_write_addr = current_y * GRID_SIZE + current_x;
    reg signed [31:0] draw_data_in;
    wire write_enable;
    assign write_enable = draw && on;

    // Local pixel memory for VGA display
    reg [783:0] pixel_memory;

    // Reset synchronizer
    always @(posedge clk) begin
        reset_sync <= {reset_sync[1:0], reset};
    end
    assign reset_f = reset_sync[2];
    
    // 7-segment display outputs
    hex_display hex0(current_x[3:0], HEX0);
    hex_display hex1({3'b000, current_x[4]}, HEX1);
    hex_display hex2(current_y[3:0], HEX2);
    hex_display hex3({3'b000, current_y[4]}, HEX3);

    // PS2 keyboard controller instance
    ps2_keyboard kb_ctrl (
        .clk(clk),
        .reset(reset),
        .ps2d(PS2_DAT),
        .ps2c(PS2_CLK),
        .scan_code(ps2_scan_code),
        .done_tick(ps2_done_tick)
    );
    

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
    integer i;
    // Movement FSM with synchronous reset
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset logic
            current_x <= 5'd14;
            current_y <= 5'd14;
            move_delay <= 20'd0;
            move_state <= INIT;
            plot = 1'b0;
            // Reset pixel memory
            for (i = 0; i < 784; i = i + 1) begin
                pixel_memory[i] <= 1'b0;
            end
        end

        else if (on) begin
            case(move_state)
                INIT: begin
                    current_x <= 5'd14;
                    current_y <= 5'd14;
                    move_state <= MOVE;
                end
                
                MOVE: begin
                    if (move_delay == 0) begin
                        if (ps2_done_tick) begin
                            case(ps2_scan_code)
                                RIGHT_ARROW: begin
                                    if (current_x < (GRID_SIZE-1)) begin
                                        current_x <= current_x + 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                LEFT_ARROW: begin
                                    if (current_x > 0) begin
                                        current_x <= current_x - 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                UP_ARROW: begin
                                    if (current_y > 0) begin
                                        current_y <= current_y - 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                                DOWN_ARROW: begin
                                    if (current_y < (GRID_SIZE-1)) begin
                                        current_y <= current_y + 1'd1;
                                        move_delay <= DELAY_MAX;
                                    end
                                end
                            endcase
                        end
                        
                        if (draw) begin
                            draw_data_in <= 32'sd1;
                            pixel_memory[current_y * GRID_SIZE + current_x] <= 1'b1;
                        end
                        else begin
                            draw_data_in <= 32'sd0;
                        end
                    end
                    else begin
                        move_delay <= move_delay - 1'd1;
                    end
                end
                
                default: move_state <= INIT;
            endcase
        end
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Drawing FSM with synchronous reset
    always @(posedge clk) begin
        if (reset_f) begin
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            pixel_x_offset <= 2'b00;
            pixel_y_offset <= 2'b00;
            plot <= 1'b1;
            draw_state <= INIT;
        end
        else if (on) begin
            case(draw_state)
                INIT: begin
                    draw_x <= 8'd0;
                    draw_y <= 7'd0;
                    pixel_x_offset <= 2'b00;
                    pixel_y_offset <= 2'b00;
                    plot <= 1'b1;
                    draw_state <= DRAW_GRID;
                end
                
                DRAW_GRID: begin
                    if (draw_y < (GRID_SIZE * PIXEL_SIZE) && draw_x < (GRID_SIZE * PIXEL_SIZE)) begin
                        plot <= 1'b1;

                        if (pixel_x_offset == 2'b11) begin
                            pixel_x_offset <= 2'b00;
                            if (pixel_y_offset == 2'b11) begin
                                pixel_y_offset <= 2'b00;
                                draw_x <= draw_x + 1'd1;
                                
                                if (draw_x >= (GRID_SIZE * PIXEL_SIZE - 1)) begin
                                    draw_x <= 8'd0;
                                    draw_y <= draw_y + 1'd1;
                                end
                            end 
                            else begin
                                pixel_y_offset <= pixel_y_offset + 1'b1;
                            end
                        end 
                        else begin
                            pixel_x_offset <= pixel_x_offset + 1'b1;
                        end
                        
                        if (draw_y >= (GRID_SIZE * PIXEL_SIZE - 1) && 
                            pixel_y_offset == 2'b11 && pixel_x_offset == 2'b11) begin
                            draw_x <= 8'd0;
                            draw_y <= 7'd0;
                        end
                    end 
                    else begin
                        plot <= 1'b0;
                    end
                end
                
                default: draw_state <= INIT;
            endcase
        end
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Color output logic
    wire [4:0] mem_x = draw_x[7:2];
    wire [4:0] mem_y = draw_y[6:2];
    wire is_cursor = (mem_x == current_x && mem_y == current_y);
    wire is_pixel_set = pixel_memory[mem_y * GRID_SIZE + mem_x];
    
    reg [2:0] colour_out;
    always @(posedge clk) begin
        if (reset) begin
            colour_out <= 3'b001;  // Default background color
        end
        else if (on) begin
            colour_out <= is_cursor ? 3'b100 :           // Red for cursor
                         is_pixel_set ? 3'b111 : 3'b001; // White for set pixels, dark blue for grid
        end
    end
    
    // VGA position calculation
    wire [7:0] actual_x = {draw_x[7:2], pixel_x_offset};
    wire [6:0] actual_y = {draw_y[6:2], pixel_y_offset};

    // VGA controller instantiation
    vga_adapter VGA (
        .resetn(~reset),  // Active-low reset
        .clock(clk),
        .colour(colour_out),
        .x(actual_x),
        .y(actual_y),
        .plot(plot),
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
// --------------------------------------------------------------------------- 


// ---------------------------------------------------------------------------   
    image_memory img_mem (
        .clk(clk),
        .reset(reset_f),
        .write_addr(draw_write_addr),
        .read_addr(image_addr),
        .data_in(draw_data_in),
        .write_enable(write_enable),
        .data_out(image_data),
        .led_control(led_control)
    );
// ---------------------------------------------------------------------------   

endmodule







// PS2 Keyboard Controller Module
module ps2_keyboard(
    input clk, reset,
    input ps2d, ps2c,     // PS2 data and clock inputs
    output reg [7:0] scan_code,  // received scan code
    output reg done_tick    // signal to indicate new scan code received
);

    // State declarations
    localparam [1:0] 
        idle = 2'b00,
        dps  = 2'b01,   // data phase start
        load = 2'b10;

    // Signal declarations
    reg [1:0] state_reg, state_next;
    reg [7:0] filter_reg;
    wire [7:0] filter_next;
    reg f_ps2c_reg;
    wire f_ps2c_next;
    reg [3:0] n_reg;
    reg [3:0] n_next;
    reg [10:0] s_reg;
    reg [10:0] s_next;
    wire fall_edge;

    // Filter and falling edge tick generation for PS2 clock
    always @(posedge clk) begin
        if (reset) begin
            filter_reg <= 0;
            f_ps2c_reg <= 0;
        end
        else begin
            filter_reg <= filter_next;
            f_ps2c_reg <= f_ps2c_next;
        end
    end

    assign filter_next = {ps2c, filter_reg[7:1]};
    assign f_ps2c_next = (filter_reg == 8'b11111111) ? 1'b1 :
                        (filter_reg == 8'b00000000) ? 1'b0 :
                        f_ps2c_reg;
    assign fall_edge = f_ps2c_reg & ~f_ps2c_next;

    // FSMD state & data registers
    always @(posedge clk) begin
        if (reset) begin
            state_reg <= idle;
            n_reg <= 0;
            s_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            n_reg <= n_next;
            s_reg <= s_next;
        end
    end

    // FSMD next-state logic
    always @* begin
        state_next = state_reg;
        n_next = n_reg;
        s_next = s_reg;
        done_tick = 1'b0;

        case (state_reg)
            idle: begin
                if (fall_edge & ~ps2d) begin // start bit
                    n_next = 4'b1001;  // count 10 bits
                    s_next = {ps2d, s_reg[10:1]}; // shift in start bit
                    state_next = dps;
                end
            end

            dps: begin // data phase shift
                if (fall_edge) begin
                    n_next = n_reg - 1;
                    s_next = {ps2d, s_reg[10:1]}; // shift in data, parity, stop bits
                    if (n_reg == 0)
                        state_next = load;
                end
            end

            load: begin // check parity and stop bits
                if (s_reg[0] == 1'b0 && s_reg[10] == 1'b1) begin // start bit = 0, stop bit = 1
                    scan_code <= s_reg[8:1]; // extract scan code
                    done_tick = 1'b1;
                end
                state_next = idle;
            end

            default: state_next = idle;
        endcase
    end

endmodule






// Hex display module
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
