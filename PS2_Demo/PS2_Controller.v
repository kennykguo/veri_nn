module PS2_Controller #(parameter INITIALIZE_MOUSE = 1) (
    CLOCK_50,
    reset,
    the_command,
    send_command,
    PS2_CLK,
    PS2_DAT,
    command_was_sent,
    error_communication_timed_out,
    received_data,
    received_data_en
);

input           CLOCK_50;
input           reset;
input   [7:0]   the_command;
input           send_command;
inout           PS2_CLK;
inout           PS2_DAT;
output          command_was_sent;
output          error_communication_timed_out;
output  [7:0]   received_data;
output          received_data_en;


// NO NEED TO MODIFY THIS FILE
// Inputs:
// CLOCK_50: Clock signal for synchronization.
// reset: Resets the controller.
// the_command: Command to be sent to the PS/2 device.
// send_command: Trigger to send the command.
// Bidirectional:
// PS2_CLK, PS2_DAT: PS/2 protocol clock and data lines.
// Outputs:
// command_was_sent: Indicates that a command was successfully sent to the PS/2 device.
// error_communication_timed_out: Indicates a timeout error in communication.
// received_data: Data received from the PS/2 device.
// received_data_en: Signal that new data has been received.
// Handles bidirectional communication with PS/2 devices.
// Supports sending commands (e.g., initialization commands for a mouse).
// Receives and processes data, indicating when new data is available.



wire [7:0] the_command_w;
wire send_command_w, command_was_sent_w, error_communication_timed_out_w;
reg init_done;
reg [7:0] idle_counter;
reg ps2_clk_reg, ps2_data_reg, last_ps2_clk;
reg [2:0] ns_ps2_transceiver;
reg [2:0] s_ps2_transceiver;

wire ps2_clk_posedge = (ps2_clk_reg == 1'b1 && last_ps2_clk == 1'b0);
wire ps2_clk_negedge = (ps2_clk_reg == 1'b0 && last_ps2_clk == 1'b1);
wire start_receiving_data = (s_ps2_transceiver == PS2_STATE_1_DATA_IN);
wire wait_for_incoming_data = (s_ps2_transceiver == PS2_STATE_3_END_TRANSFER);

localparam PS2_STATE_0_IDLE        = 3'h0,
           PS2_STATE_1_DATA_IN     = 3'h1,
           PS2_STATE_2_COMMAND_OUT = 3'h2,
           PS2_STATE_3_END_TRANSFER = 3'h3,
           PS2_STATE_4_END_DELAYED = 3'h4;

generate
    if (INITIALIZE_MOUSE) begin
        assign the_command_w = init_done ? the_command : 8'hF4;
        assign send_command_w = init_done ? send_command : (!command_was_sent_w && !error_communication_timed_out_w);
        assign command_was_sent = init_done ? command_was_sent_w : 0;
        assign error_communication_timed_out = init_done ? error_communication_timed_out_w : 1;

        always @(posedge CLOCK_50) begin
            if (reset)
                init_done <= 0;
            else if (command_was_sent_w)
                init_done <= 1;
        end
    end else begin
        assign the_command_w = the_command;
        assign send_command_w = send_command;
        assign command_was_sent = command_was_sent_w;
        assign error_communication_timed_out = error_communication_timed_out_w;
    end
endgenerate

always @(posedge CLOCK_50) begin
    if (reset)
        s_ps2_transceiver <= PS2_STATE_0_IDLE;
    else
        s_ps2_transceiver <= ns_ps2_transceiver;
end

always @(*) begin
    ns_ps2_transceiver = PS2_STATE_0_IDLE;

    case (s_ps2_transceiver)
        PS2_STATE_0_IDLE: begin
            if ((idle_counter == 8'hFF) && send_command)
                ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
            else if (!ps2_data_reg && ps2_clk_posedge)
                ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
        end

        PS2_STATE_1_DATA_IN: begin
            if (received_data_en)
                ns_ps2_transceiver = PS2_STATE_0_IDLE;
        end

        PS2_STATE_2_COMMAND_OUT: begin
            if (command_was_sent || error_communication_timed_out)
                ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
        end

        PS2_STATE_3_END_TRANSFER: begin
            if (!send_command)
                ns_ps2_transceiver = PS2_STATE_0_IDLE;
            else if (!ps2_data_reg && ps2_clk_posedge)
                ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
        end

        PS2_STATE_4_END_DELAYED: begin
            if (received_data_en) begin
                if (!send_command)
                    ns_ps2_transceiver = PS2_STATE_0_IDLE;
                else
                    ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
            end
        end

        default: ns_ps2_transceiver = PS2_STATE_0_IDLE;
    endcase
end

always @(posedge CLOCK_50) begin
    if (reset) begin
        last_ps2_clk <= 1'b1;
        ps2_clk_reg <= 1'b1;
        ps2_data_reg <= 1'b1;
    end else begin
        last_ps2_clk <= ps2_clk_reg;
        ps2_clk_reg <= PS2_CLK;
        ps2_data_reg <= PS2_DAT;
    end
end

always @(posedge CLOCK_50) begin
    if (reset)
        idle_counter <= 6'h00;
    else if ((s_ps2_transceiver == PS2_STATE_0_IDLE) && (idle_counter != 8'hFF))
        idle_counter <= idle_counter + 6'h01;
    else if (s_ps2_transceiver != PS2_STATE_0_IDLE)
        idle_counter <= 6'h00;
end

Altera_UP_PS2_Data_In PS2_Data_In (
    .clk                    (CLOCK_50),
    .reset                  (reset),
    .wait_for_incoming_data (wait_for_incoming_data),
    .start_receiving_data   (start_receiving_data),
    .ps2_clk_posedge        (ps2_clk_posedge),
    .ps2_clk_negedge        (ps2_clk_negedge),
    .ps2_data               (ps2_data_reg),
    .received_data          (received_data),
    .received_data_en       (received_data_en)
);

Altera_UP_PS2_Command_Out PS2_Command_Out (
    .clk                    (CLOCK_50),
    .reset                  (reset),
    .the_command            (the_command_w),
    .send_command           (send_command_w),
    .ps2_clk_posedge        (ps2_clk_posedge),
    .ps2_clk_negedge        (ps2_clk_negedge),
    .PS2_CLK                (PS2_CLK),
    .PS2_DAT                (PS2_DAT),
    .command_was_sent       (command_was_sent_w),
    .error_communication_timed_out (error_communication_timed_out_w)
);

endmodule
