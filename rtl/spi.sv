// piso Module

module piso (
    input  logic        clk,         // SCLK (5 MHz)
    input  logic        rst,         // Reset (pulse when new byte transfer starts)
    input  logic [7:0]  data_in,     // Parallel 8-bit input
    input  logic        load,        // Load signal to latch data_in
    output logic        mosi         // Serial output (MSB first)
);

    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'h00;
            bit_cnt   <= 3'd0;
        end else begin
            if (load) begin
                shift_reg <= data_in;
                bit_cnt   <= 3'd0;
            end else begin
                shift_reg <= {shift_reg[6:0], 1'b0}; // Left shift
                bit_cnt   <= bit_cnt + 1;
            end
        end
    end

    assign mosi = shift_reg[7]; // MSB first
endmodule


// counter Module

module counter (
    input logic clk,        // Clock input
    input logic rst,      // Active low reset
    output logic [1:0] count // 2-bit counter output (counting from 0 to 3)
);

    logic [2:0] cycle_count; // 3-bit counter to count 8 cycles

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 3'b0; // Reset cycle counter
            count <= 2'b0;        // Reset byte counter
        end
        else begin
            if (cycle_count == 7) begin // After 8 cycles (counting from 0 to 7)
                cycle_count <= 3'b0;  // Reset cycle counter
                count <= count + 1;    // Increment byte counter
            end
            else begin
                cycle_count <= cycle_count + 1; // Increment cycle counter
            end

        end
    end

endmodule


// clk_div Module

module clk_div (
    input  logic clk_100mhz, // Input clock: 100 MHz (period = 10 ns)
    output logic clk_5mhz    // Output clock: 5 MHz (period = 200 ns)
);

    // ====== Calculations ======
    // 
    // Input freq:      100 MHz → period = 1 / 100e6 = 10 ns
    // Desired output:    5 MHz → period = 1 / 5e6   = 200 ns
    //
    // To go from 100 MHz to 5 MHz, we need to divide frequency by:
    //      100 MHz / 5 MHz = 20
    //
    // That means the output clock should toggle every 10 input clock cycles.
    // Because one full period requires a HIGH and a LOW phase:
    //      Toggle every 10 cycles → Full cycle = 20 cycles → 200 ns

    logic [3:0] counter; // 4 bits = can count up to 15 → enough for counting up to 10

    always_ff @(posedge clk_100mhz) begin
        if (counter == 9) begin
            counter   <= 0;         // Reset counter after 10 cycles
            clk_5mhz  <= ~clk_5mhz; // Toggle output clock (flip HIGH/LOW)
        end
        else begin
            counter <= counter + 1; // Increment counter each clk_100mhz tick
        end
    end

endmodule


// fsm Module

module fsm (
    input logic clk,           // Clock input
    input logic power,         // Power switch
    input logic done,          // Done signal from SPI transfer

    output logic [1:0] data_select, // SPI command selector
    output logic transfer,     // SPI transfer enable (MOSI)
    output logic receive,      // SPI receive enable (MISO)
    output logic cs           // Chip select (Active LOW)
    // output logic [1:0] data_size // Data size (number of bytes)
);

    // FSM State Encoding
    typedef enum logic [2:0] { 
        IDLE,                // 000
        MEASUREMENT_MODE,    // 001
        SEND,                // 010
        RECEIVE,             // 011
        SOFT_RST             // 100
    } state_t;

    state_t current_state, next_state;

    // Internal CS control signal
    // logic cs_internal;

    // Next State Logic
    always_comb begin
        next_state = current_state; // Default

        case (current_state)

            IDLE: begin
                if (power)
                    next_state = MEASUREMENT_MODE;
                else
                    next_state = IDLE;
            end

            MEASUREMENT_MODE: begin
                if (!power)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = SEND;
            end

            SEND: begin
                if (!power)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = RECEIVE;
            end

            RECEIVE: begin
                if (!power)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = SEND;
            end

            SOFT_RST: begin
                if (done)
                    next_state = IDLE;
            end

        endcase
    end

    // State Register Update
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end

    // CS Signal Handling
    // always_ff @(posedge clk) begin
    //     if (current_state == MEASUREMENT_MODE && done)
    //         cs_internal <= 1;    // Deassert CS after measurement command done
    //     else if (current_state == SEND && done)
    //         cs_internal <= 0;    // Reassert CS before send
    //     else if (current_state == SOFT_RST)
    //         cs_internal <= ~cs_internal; // Toggle CS in Soft Reset
    //     else if (current_state == IDLE)
    //         cs_internal <= 1;    // Default CS high in idle
    // end

    // assign cs = cs_internal;

    // Output Logic
    always_comb begin
        // Default outputs
        data_select = 2'b00;
        transfer    = 0;
        receive     = 0;
        cs          = 1;

        case (current_state)
            MEASUREMENT_MODE: begin
                if (done) begin
                    // Wait state after sending measurement command
                    cs = 1;
                end else begin
                    data_select = 2'b01;
                    transfer    = 1;
                    cs          = 0;
                end
            end

            SEND: begin
                if (done) begin
                    cs = 0;  // keep CS low between SEND and RECEIVE
                end else begin
                    data_select = 2'b10;
                    transfer    = 1;
                    cs          = 0;
                end
            end

            RECEIVE: begin
                if (done) begin
                    cs = 1;  // finish transfer
                end else begin
                    data_select = 2'b00; // Dummy byte
                    transfer    = 1;
                    receive     = 1;
                    cs          = 0;
                end
            end

            SOFT_RST: begin
                if (done) begin
                    cs = 1;
                end else begin
                    data_select = 2'b11;
                    transfer    = 1;
                    cs          = 0;
                end
            end
        endcase
    end

endmodule

// Remove above after coding

module spi(
    input logic power_btn,
    input logic clk,

    // Master in Slave out
    input logic miso,

    // Mater out Slave in, Chip Select
    output logic mosi, cs,

    // Serial Clock
    output sclk
);

    logic done, transfer, receive;
    logic [1:0] data_select;
    // logic [2:0] data_size;

    logic [1:0] byte_counter;

    logic byte_counter_rst;

    logic transfer_prev;

    logic transfer_posedge;

    logic [7:0] current_byte;
    logic piso_rst, piso_load;

    logic [1:0] byte_counter_dly;

    logic [7:0] data_set [0:3][0:2]; // Max 3 bytes per set

    initial begin
        data_set[0] = '{8'h00, 8'h00, 8'h00};
        data_set[1] = '{8'h0A, 8'h2D, 8'h02};
        data_set[2] = '{8'h0B, 8'h08, 8'h00}; // only 2 bytes counted
        data_set[3] = '{8'h0A, 8'h1F, 8'h52};
    end


    logic [1:0] data_size [3:0]; // valid bytes per set

    initial begin
        data_size[0] = 3;
        data_size[1] = 3;
        data_size[2] = 2; // only 2 bytes valid
        data_size[3] = 3;
    end

    logic temp; // ========================temp================================

    // Instantiation of clk_div Module
    clk_div divider(
        .clk_100mhz(clk),
        .clk_5mhz(sclk)
    );

    // Instantiation of fsm Module
    fsm control_unit(
        .clk(sclk),
        .power(power_btn),
        .done(done),

        .transfer(transfer),
        .receive(receive),
        .data_select(data_select),
        // .data_size(data_size),

        .cs(cs)
    );

    // Instantiation of piso Module
    piso tx_piso (
        .clk(sclk),
        .rst(piso_rst),
        .data_in(current_byte),
        .load(piso_load),
        .mosi(mosi)
    );

    // Instantiation of counter Module
    counter counter(
        .clk(sclk),
        .rst(byte_counter_rst),
        .count(byte_counter)
    );

    // byte_counter_rst logic
    assign transfer_posedge = (transfer && !transfer_prev);

    always_ff @(posedge clk) begin
        transfer_prev <= transfer;

        if (transfer_posedge)
            byte_counter_rst <= 1;
        else
            byte_counter_rst <= 0;
    end

    // done variable logic
    always_ff @(posedge sclk) begin
        byte_counter_dly <= byte_counter;
        done <= (byte_counter_dly == data_size[data_select] - 1);
    end

    // sclk output
    always_ff @(posedge clk) begin
        sclk <= sclk;
    end

    always_ff @(posedge sclk) begin
        // Load next byte when byte_counter increments
        if (transfer) begin
            current_byte <= data_set[data_select][byte_counter];
        end
    end

    // Pulse signals
    assign piso_rst  = byte_counter_rst;
    assign piso_load = (byte_counter == 0) && transfer_posedge;

endmodule
