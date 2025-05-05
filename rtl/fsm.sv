module fsm (
    input logic clk,           // Clock input
    input logic power,         // Power switch
    input logic done,          // Done signal from SPI transfer

    output logic [1:0] data_select, // SPI command selector
    output logic transfer,     // SPI transfer enable (MOSI)
    output logic receive,      // SPI receive enable (MISO)
    output logic cs           // Chip select (Active LOW)
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

    // State Register Update
    always_ff @(posedge clk) begin
        current_state <= next_state;
    end

    // Next State Logic
    always_comb begin
        next_state = current_state; // Default

        case (current_state)
            IDLE: begin
                if (power)
                    next_state = MEASUREMENT_MODE;
                // else stay in IDLE
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

            default: next_state = IDLE; // Safe default
        endcase
    end

    // Output Logic
    always_comb begin
        // Default outputs (applies to IDLE and any unexpected state)
        data_select = 2'b00;
        transfer    = 0;
        receive     = 0;
        cs          = 1;      // Chip select inactive by default

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

            // IDLE state uses the default outputs
            // default: uses the default outputs (redundant but explicit)
        endcase
    end

endmodule