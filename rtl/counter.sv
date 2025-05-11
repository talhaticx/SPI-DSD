module counter (
    input logic clk,        // Clock input
    input logic rst, rst_byte,
    output logic [1:0] byte_counter, // 2-bit counter output (counting from 0 to 3)
    output logic [2:0] bit_counter
);


    always_ff @(posedge clk or posedge rst) begin
        if (rst || rst_byte) begin
            bit_counter <= 3'b0; // Reset cycle counter
            byte_counter <= 2'b0;        // Reset byte counter
        end
        else begin
            if (bit_counter == 7) begin // After 8 cycles (counting from 0 to 7)
                bit_counter <= 3'b0;  // Reset cycle counter
                byte_counter <= byte_counter + 1;    // Increment byte counter
            end
            else begin
                bit_counter <= bit_counter + 1; // Increment cycle counter
            end

        end
    end

endmodule
