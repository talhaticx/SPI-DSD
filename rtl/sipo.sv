module sipo (
    input  logic clk,       // 5MHz SPI clock
    // input  logic rst,       // active high reset
    input  logic shift_en,  // enable shift on every clock
    input  logic miso,      // input serial bit from slave
    output logic [7:0] data_out // output parallel byte
);

    always_ff @(posedge clk or posedge !shift_en) begin
        if (!shift_en)
            data_out <= 8'h00;
        else if (shift_en)
            data_out <= {data_out[6:0], miso}; // shift left, MSB first
    end

endmodule
