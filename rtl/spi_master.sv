module spi_master(
    input  logic       active_btn, // active control button
    input  logic       clk,       // 100MHz main clock
    input  logic       miso,      // MISO - Master In Slave Out

    output logic       mosi,      // MOSI - Master Out Slave In
    output logic       cs,        // Chip Select (Active Low)
    output logic       sclk,      // Serial Clock (5MHz)

    output logic [6:0] seg,       // 7 - Segment Data
    output logic [5:0] an,        // Anode Selector

    output logic dpx, dpy, dpz,    // Decimal Point (for sign) 

    output logic rx_debug
);

    logic done;
    logic done_synced;

    logic transfer, receive;
    logic [2:0] data_select;

    logic [1:0] byte_counter, byte_counter_synced;
    logic [2:0] bit_counter, bit_counter_synced;
    logic       byte_counter_rst;

    // logic       transfer_prev, transfer_posedge;

    logic [7:0] current_byte;
    logic       piso_rst, piso_load;
    logic       sipo_rst;

    logic tx, tx_synced;
    logic rx, cs_synced;

    logic [1:0] data_size [4:0];
    logic [7:0] data_set [0:3][0:2]; // 3-byte max per command

    logic [2:0] display_count;
    logic [2:0] temp_count = 0;

    always_comb begin
        data_set[0] = '{8'h00, 8'h00, 8'h00}; // Dummy
        data_set[1] = '{8'h0A, 8'h2D, 8'h02}; // Measurement mode
        data_set[2] = '{8'h0B, 8'h08, 8'h00}; // Read Cmd
        data_set[3] = '{8'h0A, 8'h1F, 8'h52}; // Soft reset

        data_size[0] = 3;
        data_size[1] = 3;
        data_size[2] = 2;
        data_size[3] = 3;

        data_size[4] = 0;
    end

    // ==================================================
    //                  Transfer Logic
    // ==================================================

    // === Clock Divider ===
    clk_div divider(
        .clk_in(clk),
        .clk_out(sclk)
    );

    // === FSM ===
    fsm control_unit(
        .clk(sclk),
        .reset(!active_btn),
        .done(done_synced),
        .data_select(data_select),
        .transfer(transfer),
        .receive(receive),
        .cs(cs_synced),
        .byte_reset(byte_counter_rst)
    );

    // === Counter ===
    counter byte_counter_module(
        .clk(sclk),
        .rst(!active_btn || byte_counter_rst || done_synced),
        // .rst_byte(done_synced),
        .byte_counter(byte_counter),
        .bit_counter(bit_counter)
    );

    assign tx = !(!active_btn || byte_counter_rst) && transfer;

    // === PISO Shift Register ===
    piso piso_module(
        .clk(sclk),
        .rst(piso_rst),
        .data_in(current_byte),
        .load(piso_load),
        .shift_en(tx_synced),
        .mosi(mosi)
        // .bit_cnt(bit_counter)
    );

    logic [1:0] safe_sel;

    assign safe_sel = (data_select == 3'b100) ? 2'b00 : data_select[1:0];


    assign current_byte = (byte_counter < data_size[data_select]) ?
                        data_set[safe_sel][byte_counter] :
                        8'h00;

    // === PISO Control ===
    assign piso_load = (bit_counter == 0) ? 1'b1 : 1'b0;
    assign piso_rst  = ~tx;

    // === Done signal ===
    assign done = (byte_counter >= data_size[data_select] - 1) && (bit_counter == 3'd7);

    assign rx_debug = rx;

    // Adding a synchronization flip-flop
    always_ff @(posedge sclk) begin
        done_synced <= done;
        tx_synced <= tx;
        rx <= receive;
        cs <= cs_synced;
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
        // .rst(sipo_rst),
        .miso(miso),
        .shift_en(rx),
        .data_out(shift_reg)
    );

    // === Byte Received Detection ===
    assign byte_received = rx && (bit_counter == 7);


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

    // counter byte_counter_synced_module(
    //     .clk(sclk),
    //     .rst(!tx_synced),
    //     // .rst_byte(done_synced),
    //     .byte_counter(byte_counter_synced),
    //     .bit_counter(bit_counter_synced)
    // );

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
        .dp_high(dpx)
    );

    // === YDATA Decoder ===
    seven_seg_8bit_display display_y(
        .data_in(received_byte1),
        .seg_high(seg_y_high),
        .seg_low(seg_y_low),
        .dp_high(dpy)
    );

    // === ZDATA Decoder ===
    seven_seg_8bit_display display_z(
        .data_in(received_byte2),
        .seg_high(seg_z_high),
        .seg_low(seg_z_low),
        .dp_high(dpz)
    );

    always_ff @(posedge display_clk) begin
        if (temp_count == 3'd5) begin
            temp_count <= 3'd0;
            display_count <= temp_count;
        end
        else begin
            temp_count <= temp_count + 1;
            display_count <= temp_count;
        end
    end

    seven_seg_mux display_mux(
        .sel(display_count),  // from your freq_div module
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
