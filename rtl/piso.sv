module piso (
    input  logic        clk,         // SCLK (5 MHz)
    input  logic        rst,         // Reset (pulse when new byte transfer starts)
    input  logic [7:0]  data_in,     // Parallel 8-bit input
    input  logic        load,        // Load signal to latch data_in
    input  logic        shift_en,    // Enabler
    output logic        mosi         // Serial output (MSB first)
);

    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'h00;
            bit_cnt   <= 3'd0;
        end else begin
            if (shift_en) begin 
                if (load) begin
                    shift_reg <= data_in;
                    bit_cnt   <= 3'd0;
                end else begin
                    shift_reg <= {shift_reg[6:0], 1'b0}; // Left shift
                    bit_cnt   <= bit_cnt + 1;
                end
            end
        end
    end

    assign mosi = shift_reg[7]; // MSB first
endmodule
