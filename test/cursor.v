reg [7:0] mouse_status;
reg [7:0] mouse_x_rel;
reg [7:0] mouse_y_rel;
reg [9:0] cursor_x;  // 10 bits for larger resolution
reg [9:0] cursor_y;  // 10 bits for larger resolution
wire left_click;

always @(posedge CLOCK_50) begin
    if (KEY[0] == 1'b0) begin
        cursor_x <= SCREEN_WIDTH / 2;  // Reset to center
        cursor_y <= SCREEN_HEIGHT / 2;
    end else if (ps2_key_pressed) begin
        case (byte_count)
            2'b00: mouse_status <= ps2_key_data;  // Status byte
            2'b01: mouse_x_rel <= ps2_key_data;  // X movement
            2'b10: mouse_y_rel <= ps2_key_data;  // Y movement
        endcase
        byte_count <= byte_count + 1'b1;

        if (byte_count == 2'b10) begin
            // Update absolute cursor position
            if (mouse_status[3])  // X negative
                cursor_x <= cursor_x - {2'b0, mouse_x_rel};
            else
                cursor_x <= cursor_x + {2'b0, mouse_x_rel};

            if (mouse_status[4])  // Y negative
                cursor_y <= cursor_y + {2'b0, mouse_y_rel}; // Y-axis is inverted
            else
                cursor_y <= cursor_y - {2'b0, mouse_y_rel};

            // Clamp to screen boundaries
            if (cursor_x < 0)
                cursor_x <= 0;
            else if (cursor_x > SCREEN_WIDTH - 1)
                cursor_x <= SCREEN_WIDTH - 1;

            if (cursor_y < 0)
                cursor_y <= 0;
            else if (cursor_y > SCREEN_HEIGHT - 1)
                cursor_y <= SCREEN_HEIGHT - 1;
        end
    end
end

assign left_click = mouse_status[0];  // Left button state



// wire [9:0] vga_x, vga_y;  // VGA coordinates
// wire cursor_on;

// // Check if the VGA pixel matches the cursor position
// assign cursor_on = (vga_x == cursor_x) && (vga_y == cursor_y);

// always @(posedge CLOCK_50) begin
//     if (cursor_on) begin
//         vga_r <= left_click ? 8'hFF : 8'h80;  // Red when clicked, otherwise light red
//         vga_g <= left_click ? 8'h00 : 8'h80;  // Green off when clicked, otherwise light green
//         vga_b <= left_click ? 8'h00 : 8'h80;  // Blue off when clicked, otherwise light blue
//     end else begin
//         vga_r <= background_r;
//         vga_g <= background_g;
//         vga_b <= background_b;
//     end
// end
