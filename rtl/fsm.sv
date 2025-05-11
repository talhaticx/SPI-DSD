module fsm (
    input  logic clk,
    input  logic reset,
    input  logic done,

    output logic [2:0] data_select,
    output logic transfer,
    output logic receive,
    output logic cs,
    output logic byte_reset
);

    // State Encoding
    typedef enum logic [2:0] {
        IDLE,               // 000 (0) - ds 0
        MEASUREMENT_MODE,   // 001 (1) - ds 1
        SEND,               // 010 (2) - ds 2
        RECEIVE,            // 011 (3) - ds 0
        SOFT_RST,           // 100 (4) - ds 3
        CS_HIGH             // 101 (5) - ds 4
    } state_t;

    state_t prev_state, current_state, next_state;

    // Delay Counter for CS_HIGH state
    logic [2:0] cs_counter;
    parameter CS_DELAY = 2;

    // State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= SOFT_RST;
            // prev_state <= IDLE;
        end
        else
            current_state <= next_state;
    end

    // prev_state tracking
    always_ff @(posedge clk) begin
        if (!reset && current_state != CS_HIGH)
            prev_state <= current_state;
    end


    // Delay Counter for CS_HIGH
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            cs_counter <= 0;
        else if (current_state == CS_HIGH && cs_counter < CS_DELAY)
            cs_counter <= cs_counter + 1;
        else if (current_state != CS_HIGH)
            cs_counter <= 0;
    end

    // Next State Logic
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                next_state = CS_HIGH;
            end

            MEASUREMENT_MODE: begin
                if (reset)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = CS_HIGH;
            end

            SEND: begin
                if (reset)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = RECEIVE;
            end

            RECEIVE: begin
                if (reset)
                    next_state = SOFT_RST;
                else if (done)
                    next_state = CS_HIGH;
            end

            SOFT_RST: begin
                if (done)
                    next_state = CS_HIGH;
            end

            CS_HIGH: begin
                if (cs_counter == CS_DELAY) begin
                    case (prev_state)
                        IDLE:              next_state = MEASUREMENT_MODE;
                        MEASUREMENT_MODE:  next_state = SEND;
                        SEND:              next_state = RECEIVE;
                        RECEIVE:           next_state = SEND;
                        SOFT_RST:          next_state = IDLE;
                        default:           next_state = IDLE;
                    endcase
                end
            end
        endcase
    end

    // Output Logic
    always_comb begin
        // Default
        data_select = 3'b000;
        transfer    = 0;
        receive     = 0;
        cs          = 1;
        byte_reset  = 0;

        case (current_state)
            MEASUREMENT_MODE: begin
                if (!(done || reset)) begin
                    data_select = 3'b001;
                    transfer    = 1;
                    cs          = 0;
                end
            end

            SEND: begin
                if (done) 
                    receive = 1;
                cs = 0;
                data_select = 3'b010;
                transfer    = 1;
            end

            RECEIVE: begin
                if (!(done || reset)) begin
                    cs = 0;
                    data_select = 3'b000; // dummy byte
                    transfer    = 1;
                    receive     = 1;
                end
            end

            SOFT_RST: begin
                if (!done) begin
                    cs = 0;
                    data_select = 3'b011;
                    transfer    = 1;
                end
            end

            CS_HIGH: begin
                cs = 1;
                byte_reset = 1;
            end
        endcase
    end

endmodule
