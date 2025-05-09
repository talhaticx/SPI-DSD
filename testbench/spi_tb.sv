`timescale 1ns/1ps

module spi_tb;

    // Testbench signals
    logic power_btn;
    logic clk;
    logic miso;
    logic mosi;
    logic cs;
    logic sclk;

    // SPI signals
    logic done;
    logic transfer;
    logic receive;
    logic [1:0] data_select;
    logic [1:0] byte_counter;

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz clock (20 ns period)
    end

    // Instantiate the SPI module
    spi_master uut (
        .power_btn(power_btn),
        .clk(clk),
        .miso(miso),
        .mosi(mosi),
        .cs(cs),
        .sclk(sclk)
    );

    // VCD dump (waveform generation)
    initial begin
        $dumpfile("spi_wave.vcd");
        $dumpvars(0, spi_tb);
    end

    // Test sequence to simulate SPI communication
    initial begin
        power_btn = 0;
        
        // Test the SPI transfer process with different commands
        #500;
        power_btn = 1; // Power ON
        #500;
        
        // Wait for the transfer to complete
        #100_000; // Allow time for SPI transfer to complete
        
        // Power off
        #50 power_btn = 0;
        
        #10_000; // Give time to settle before the end
        $finish;
    end

endmodule
