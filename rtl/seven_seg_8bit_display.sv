module seven_seg_8bit_display (
    input  logic signed [7:0] data_in,   // Signed 8-bit input (-99 to 99)
    output logic [6:0] seg_high,         // Tens
    output logic [6:0] seg_low,          // Units
    output logic       dp_high           // Dot (active low): 0 = negative, 1 = positive
);

    logic [6:0] digit_map [0:9];         // 7-segment encoding map
    logic [6:0] tens_seg, units_seg;
    logic signed [7:0] abs_val;
    logic [6:0] tens, units;
    logic is_neg;

    // 7-segment encoding (common cathode, active low)
    always_comb begin
        digit_map[0] = 7'b1000000;
        digit_map[1] = 7'b1111001;
        digit_map[2] = 7'b0100100;
        digit_map[3] = 7'b0110000;
        digit_map[4] = 7'b0011001;
        digit_map[5] = 7'b0010010;
        digit_map[6] = 7'b0000010;
        digit_map[7] = 7'b1111000;
        digit_map[8] = 7'b0000000;
        digit_map[9] = 7'b0010000;
    end

    always_comb begin
        // Clamp range to [-99, 99]
        logic signed [7:0] val;
        if (data_in > 99)
            val = 99;
        else if (data_in < -99)
            val = -99;
        else
            val = data_in;

        // Sign detection
        is_neg  = val < 0;
        abs_val = is_neg ? -val : val;

        // Decimal digit extraction (safe since abs_val <= 99)
        tens  = abs_val / 10;
        units = abs_val % 10;

        // Segment output mapping
        seg_high = digit_map[tens];
        seg_low  = digit_map[units];

        // Dot ON (active-low) for negative
        dp_high = is_neg ? 1'b1 : 1'b0;
    end
endmodule
