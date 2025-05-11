// module clk_div (
//     input  logic clk_100mhz,  // Input clock: 100 MHz (period = 10 ns)
//     input  logic reset,       // Active high reset signal
//     output logic clk_5mhz     // Output clock: 5 MHz (period = 200 ns)
// );
//     // logic inner_clk = 0;
//     logic [3:0] counter; // 4 bits = can count up to 15 → enough for counting up to 10

//     // Initialize clk_5mhz to 0 at reset
//     // initial begin
//     //     clk_5mhz = 0;  // Ensure clk_5mhz starts at 0
//     // end

//     // Clock division and output assignment with reset
//     always_ff @(posedge clk_100mhz or posedge reset) begin
//         if (reset) begin
//             counter   <= 0;        // Reset counter
//             // inner_clk <= 0;        // Reset inner clock
//             clk_5mhz <= 0;         // Reset output clock
//         end
//         else if (counter == 9) begin
//             counter   <= 0;        // Reset counter after 10 cycles
//             // inner_clk  <= ~inner_clk;  // Toggle inner clock (flip HIGH/LOW)
//             clk_5mhz <= ~clk_5mhz; // Drive clk_5mhz with the inner clock
//         end
//         else begin
//             counter <= counter + 1; // Increment counter each clk_100mhz tick
//         end
//     end

// endmodule

module clk_div (
    input  logic clk_in,      // 100 MHz input clock
    output logic clk_out      // 5 MHz output clock
);

    logic [4:0] counter = 0;  
    logic clk_reg = 0;        // Internal register with init

    assign clk_out = clk_reg;

    always_ff @(posedge clk_in) begin
        if (counter == 9) begin
            counter <= 0;
            clk_reg <= ~clk_reg;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
