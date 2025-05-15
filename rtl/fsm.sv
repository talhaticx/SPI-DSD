module fsm (
    input  logic clk,        // 5MHz SPI clock
    input  logic reset,      // Active-high reset
    input  logic done,       // Completion signal
    
    output logic [2:0] data_select,  // Data selection
    output logic transfer,           // Transfer enable
    output logic receive,            // Receive enable
    output logic cs,                 // Chip select (active low)
    output logic byte_reset          // Byte counter reset
);

    // State Encoding
    typedef enum logic [2:0] {
        POWER_UP_DELAY,      // 0 - Wait 6ms after power-up
        SOFT_RST,            // 1 - Soft reset sequence
        MEASUREMENT_MODE,    // 2 - Set measurement mode
        IDLE,                // 3 - Wait state
        SEND,                // 4 - Send command/address
        RECEIVE,             // 5 - Receive data
        CS_HIGH              // 6 - CS deasserted
    } state_t;

    state_t current_state, next_state;
    
    // Delay counters
    logic [15:0] powerup_counter;  // 6ms at 5MHz = 30,000 cycles
    logic [2:0] cs_delay_counter;  // CS high delay
    parameter CS_DELAY = 3;        // Short delay between transactions

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= POWER_UP_DELAY;
            powerup_counter <= 0;
        end else begin
            current_state <= next_state;
            
            // Power-up counter
            if (current_state == POWER_UP_DELAY)
                powerup_counter <= powerup_counter + 1;
            else
                powerup_counter <= 0;
                
            // CS delay counter
            if (current_state == CS_HIGH)
                cs_delay_counter <= cs_delay_counter + 1;
            else
                cs_delay_counter <= 0;
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            POWER_UP_DELAY: begin
                if (powerup_counter >= 30_000)
                    next_state = SOFT_RST;
            end
            
            SOFT_RST: begin
                if (done)
                    next_state = CS_HIGH;
            end
            
            MEASUREMENT_MODE: begin
                if (done)
                    next_state = CS_HIGH;
            end
            
            IDLE: begin
                next_state = SEND;
            end
            
            SEND: begin
                if (done)
                    next_state = RECEIVE;
            end
            
            RECEIVE: begin
                if (done)
                    next_state = CS_HIGH;
            end
            
            CS_HIGH: begin
                if (cs_delay_counter >= CS_DELAY) begin
                    case (current_state)
                        POWER_UP_DELAY: next_state = SOFT_RST;
                        SOFT_RST:       next_state = MEASUREMENT_MODE;
                        MEASUREMENT_MODE: next_state = IDLE;
                        IDLE:          next_state = SEND;
                        SEND:          next_state = RECEIVE;
                        RECEIVE:       next_state = SEND;
                        default:       next_state = IDLE;
                    endcase
                end
            end
        endcase
    end

    // Output logic
    always_comb begin
        // Default outputs
        data_select = 3'b000;
        transfer = 0;
        receive = 0;
        cs = 1;         // Active low
        byte_reset = 0;
        
        case (current_state)
            SOFT_RST: begin
                data_select = 3'b011; // Soft reset command
                transfer = 1;
                cs = 0;
            end
            
            MEASUREMENT_MODE: begin
                data_select = 3'b001; // Measurement mode command
                transfer = 1;
                cs = 0;
            end
            
            SEND: begin
                data_select = 3'b010; // Read command
                transfer = 1;
                cs = 0;
            end
            
            RECEIVE: begin
                data_select = 3'b000; // Dummy bytes
                transfer = 1;
                receive = 1;
                cs = 0;
            end
            
            CS_HIGH: begin
                byte_reset = 1;       // Reset byte counter
            end
            
            default: begin
                // Default outputs already set
            end
        endcase
    end

endmodule
