module seven_seg_8bit_display (
    input  logic [7:0] data_in,       // Signed 8-bit input
    output logic [6:0] seg_high,      // Tens
    output logic [6:0] seg_low,       // Units
    output logic       dp_high       // Dot for tens (sign)

);

    logic [6:0] digits [0:15];
    initial begin
        digits[0]  = 7'b1000000;
        digits[1]  = 7'b1111001;
        digits[2]  = 7'b0100100;
        digits[3]  = 7'b0110000;
        digits[4]  = 7'b0011001;
        digits[5]  = 7'b0010010;
        digits[6]  = 7'b0000010;
        digits[7]  = 7'b1111000;
        digits[8]  = 7'b0000000;
        digits[9]  = 7'b0010000;
    end

    logic [7:0] abs_val;
    logic       is_neg;
    logic [3:0] tens, units;

    assign is_neg  = data_in[7];
    assign abs_val = is_neg ? (~data_in + 1) : data_in;

    always_comb begin
        tens  = abs_val / 10;
        units = abs_val % 10;

        seg_high = digits[tens];
        seg_low  = digits[units];

        dp_high = is_neg ? 1'b0 : 1'b1; // Dot ON = negative (active low)
    end
endmodule
