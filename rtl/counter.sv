module counter (
    input logic clk,        // Clock input
    input logic rst,      // Active low reset
    output logic [2:0] count // 3-bit counter output (counting from 0 to 5)
);

    logic [2:0] cycle_count; // 3-bit counter to count 8 cycles

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 3'b0; // Reset cycle counter
            count <= 3'b0;        // Reset byte counter
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
