`timescale 1ns/1ps

module spi_tb;

    // Testbench signals
    logic active_btn;
    logic clk;
    logic miso;
    logic mosi;
    logic cs;
    logic sclk;

    logic [6:0] seg;
    logic [3:0] an;
    logic dp0, dp2, dp4;

    // // SPI signals
    // logic done;
    // logic transfer;
    // logic receive;
    // logic [1:0] data_select;
    // logic [1:0] byte_counter;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 50 MHz clock (20 ns period)
    end

    spi_master uut (
        .active_btn(active_btn),
        .clk(clk),
        .miso(miso),
        .mosi(mosi),
        .cs(cs),
        .sclk(sclk),
        .seg(seg),
        .an(an),
        .dp0(dp0),
        .dp2(dp2),
        .dp4(dp4)
    );

    // VCD dump (waveform generation)
    initial begin
        $dumpfile("spi_wave.vcd");
        $dumpvars(0, spi_tb);
    end

    // Test sequence to simulate SPI communication
    initial begin
        active_btn = 0;
        
        #600; // 2 sclk cycles

        active_btn = 1; // Power ON

        #5000;
        
        active_btn = 0;
        
        #600; // 2 sclk cycles

        active_btn = 1; // Power ON

        // Wait for the transfer to complete
        #30_000; // Allow time for SPI transfer to complete
        
        // Power off
        active_btn = 0;
        
        #5000; // Give time to settle before the end
        $finish;
    end

endmodule
