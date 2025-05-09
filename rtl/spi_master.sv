module spi_master(
    input  logic       active_btn, // active control button
    input  logic       clk,       // 100MHz main clock
    input  logic       miso,      // MISO - Master In Slave Out

    output logic       mosi,      // MOSI - Master Out Slave In
    output logic       cs,        // Chip Select (Active Low)
    output logic       sclk,      // Serial Clock (5MHz)

    output logic [6:0] seg,       // 7 - Segment Data
    output logic [5:0] an,        // Anode Selector

    output logic dp0, dp2, dp4    // Decimal Point (for sign) 
);

    logic done;
    logic done_synced;

    logic transfer, receive;
    logic [1:0] data_select;

    logic [1:0] byte_counter;
    logic       byte_counter_rst;

    logic       transfer_prev, transfer_posedge;

    logic [7:0] current_byte;
    logic       piso_rst, piso_load;
    logic       sipo_rst;

    logic [1:0] data_size [3:0];
    logic [7:0] data_set [0:3][0:2]; // 3-byte max per command

    initial begin
        data_set[0] = '{8'h00, 8'h00, 8'h00}; // Dummy
        data_set[1] = '{8'h0A, 8'h2D, 8'h02}; // Set range
        data_set[2] = '{8'h0B, 8'h08, 8'h00}; // Disable FIFO (2-byte)
        data_set[3] = '{8'h0A, 8'h1F, 8'h52}; // Measurement mode

        data_size[0] = 3;
        data_size[1] = 3;
        data_size[2] = 2;
        data_size[3] = 3;
    end

    // ==================================================
    //                  Transfer Logic
    // ==================================================

    // === Clock Divider ===
    clk_div divider(
        .clk_100mhz(clk),
        .reset(! active_btn),
        .clk_5mhz(sclk)
    );

    // === FSM ===
    fsm control_unit(
        .clk(sclk),
        .active(active_btn),
        .done(done_synced),
        .data_select(data_select),
        .transfer(transfer),
        .receive(receive),
        .cs(cs)
    );

    // === Counter ===
    counter byte_counter_module(
        .clk(sclk),
        .rst(byte_counter_rst),
        .count(byte_counter)
    );

    // === PISO Shift Register ===
    piso piso_module(
        .clk(sclk),
        .rst(piso_rst),
        .data_in(current_byte),
        .load(piso_load),
        .shift_en(transfer),
        .mosi(mosi)
    );

    // === Transfer Edge Detection ===
    always_ff @(posedge sclk) begin
        transfer_prev <= transfer;
    end
    assign transfer_posedge = transfer & ~transfer_prev;

    // === Byte Transfer Logic ===
    always_ff @(posedge sclk) begin
        // if (transfer_posedge) begin
            if (byte_counter < data_size[data_select])
                current_byte <= data_set[data_select][byte_counter];
            else
                current_byte <= 8'h00; // Dummy byte if out of range
        // end
    end

    // === PISO Control ===
    assign piso_load = transfer_posedge;
    assign piso_rst  = ~transfer;

    // === Byte Counter Reset ===
    always_ff @(posedge sclk) begin
        if (!transfer)
            byte_counter_rst <= 1;
        else
            byte_counter_rst <= 0;
    end

    // === Done signal ===
    assign done = (byte_counter == data_size[data_select]);

    // Adding a synchronization flip-flop
    always_ff @(posedge clk) begin
        done_synced <= done;
    end

    // ==================================================
    //                  Receive Logic
    // ==================================================

    // === Received Data Registers ===
    logic [7:0] shift_reg;
    logic [7:0] received_byte0;
    logic [7:0] received_byte1;
    logic [7:0] received_byte2;
    logic       byte_received;

    // === SIPO Shift Register ===
    sipo sipo_module(
        .clk(sclk),
        .rst(sipo_rst),
        .miso(miso),
        .shift_en(receive),
        .data_out(shift_reg)
    );

    // === Byte Received Detection ===
    always_ff @(posedge sclk) begin
        byte_received <= receive && done;
    end

    // === Received Data Storage ===
    always_ff @(posedge sclk) begin
        if (byte_received) begin
            case (byte_counter)
                2'd0: received_byte0 <= shift_reg;
                2'd1: received_byte1 <= shift_reg;
                2'd2: received_byte2 <= shift_reg;
                default: ; // Do nothing
            endcase
        end

    end

    // === SIPO Control ===
    assign sipo_rst  = ~receive;

    // ==================================================
    //                  Display Logic
    // ==================================================

    logic display_clk;
    
    logic [6:0] seg_x_high, seg_x_low;
    logic [6:0] seg_y_high, seg_y_low;
    logic [6:0] seg_z_high, seg_z_low;

    // === Display Frequency Divider ===
    freq_div display_clk_module(
        .clk(clk),
        .rst(!active_btn),
        .clk_out(display_clk)
    );

    // === XDATA Decoder ===
    seven_seg_8bit_display display_x(
        .data_in(received_byte0),
        .seg_high(seg_x_high),
        .seg_low(seg_x_low),
        .dp_high(dp0)
    );

    // === YDATA Decoder ===
    seven_seg_8bit_display display_y(
        .data_in(received_byte1),
        .seg_high(seg_y_high),
        .seg_low(seg_y_low),
        .dp_high(dp2)
    );

    // === ZDATA Decoder ===
    seven_seg_8bit_display display_z(
        .data_in(received_byte2),
        .seg_high(seg_z_high),
        .seg_low(seg_z_low),
        .dp_high(dp4)
    );


    seven_seg_mux display_mux(
        .clk(display_clk),  // from your freq_div module
        .seg0(seg_x_high),
        .seg1(seg_x_low),
        .seg2(seg_y_high),
        .seg3(seg_y_low),
        .seg4(seg_z_high),
        .seg5(seg_z_low),
        .seg(seg),
        .an(an)
    );

endmodule
