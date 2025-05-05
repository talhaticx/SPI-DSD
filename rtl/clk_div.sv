module clk_div (
    input  logic clk_100mhz, // Input clock: 100 MHz (period = 10 ns)
    output logic clk_5mhz    // Output clock: 5 MHz (period = 200 ns)
);

    // ====== Calculations ======
    // 
    // Input freq:      100 MHz → period = 1 / 100e6 = 10 ns
    // Desired output:    5 MHz → period = 1 / 5e6   = 200 ns
    //
    // To go from 100 MHz to 5 MHz, we need to divide frequency by:
    //      100 MHz / 5 MHz = 20
    //
    // That means the output clock should toggle every 10 input clock cycles.
    // Because one full period requires a HIGH and a LOW phase:
    //      Toggle every 10 cycles → Full cycle = 20 cycles → 200 ns

    logic [3:0] counter; // 4 bits = can count up to 15 → enough for counting up to 10

    always_ff @(posedge clk_100mhz) begin
        if (counter == 9) begin
            counter   <= 0;         // Reset counter after 10 cycles
            clk_5mhz  <= ~clk_5mhz; // Toggle output clock (flip HIGH/LOW)
        end
        else begin
            counter <= counter + 1; // Increment counter each clk_100mhz tick
        end
    end

endmodule
