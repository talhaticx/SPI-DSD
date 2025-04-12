// sample

module spi_tb;
// Define some signals
reg clk;
reg rst;
reg [3:0] data;

// Initialize signals
initial begin
    clk = 0;
    rst = 0;
    data = 4'b0000;
end

// Clock generation
always begin
    #5 clk = ~clk;  // Toggle clock every 5 time units
end

// Monitor signal changes
initial begin
    // Open VCD file to dump the values
    $dumpfile("dump.vcd"); // File where data will be saved
    $dumpvars(0, clk, rst, data); // Dump these signals

    // Initialize reset
    #10 rst = 1;
    #10 rst = 0;
    #10 data = 4'b1010;
    #10 data = 4'b1100;

    $display("Completed\n");

    #50 $finish; // Finish the simulation after 50 time units
end
endmodule
