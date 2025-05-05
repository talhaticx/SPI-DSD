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
    logic cs_internal;

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
    always_ff @(posedge clk) begin
        if (current_state == MEASUREMENT_MODE && done)
            cs_internal <= 1;    // Deassert CS after measurement command done
        else if (current_state == SEND && done)
            cs_internal <= 0;    // Reassert CS before send
        else if (current_state == SOFT_RST)
            cs_internal <= ~cs_internal; // Toggle CS in Soft Reset
        else if (current_state == IDLE)
            cs_internal <= 1;    // Default CS high in idle
    end

    assign cs = cs_internal;

    // Output Logic
    always_comb begin
        // Default values
        data_select = 2'b00;
        transfer = 0;
        receive = 0;
        // data_size = 2'd0;

        case (current_state)

            IDLE: begin
                data_select = 2'b00;
                transfer = 0;
                receive = 0;
                // data_size = 2'd0;
            end

            MEASUREMENT_MODE: begin
                data_select = 2'b01;
                transfer = 1;
                receive = 0;
                // data_size = 2'd3;
            end

            SEND: begin
                data_select = 2'b10;
                transfer = 1;
                receive = 0;
                // data_size = 2'd2;
            end

            RECEIVE: begin
                data_select = 2'b00; // Dummy data (0x00)
                transfer = 1;
                receive = 1;
                // data_size = 2'd3;
            end

            SOFT_RST: begin
                data_select = 2'b11;
                transfer = 1;
                receive = 0;
                // data_size = 2'd3;
            end

        endcase
    end

endmodule