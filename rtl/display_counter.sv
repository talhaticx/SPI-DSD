module display_counter (
    input  logic clk,
    input  logic rst,           // Active-high reset
    output logic [2:0] count
);

    always_ff @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else if (count == 3'd5)
            count <= 3'd0;
        else
            count <= count + 1;
    end

endmodule
