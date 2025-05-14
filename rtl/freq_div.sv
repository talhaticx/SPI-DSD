module freq_div (
    input logic clk,     // 100 MHz clock input
    input logic rst,     // Active-high rst
    output logic clk_out // 100 Hz output clock
);

    logic [16:0] count = 0; // 16-bit counter (log2(50000) ≈ 15.67)

    // 1/100M = 10 ns
    // 1/100 = 10 ms
    // toggle per cycle = 2

    // (10ms/10ns * 2) = 50,000 cycles

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
            clk_out <= 0;
        end 
        else if (count == 499) begin // 49999
            count <= 0;
            clk_out <= ~clk_out; // Toggle output
        end 
        else begin
            count <= count + 1;
        end
    end

endmodule