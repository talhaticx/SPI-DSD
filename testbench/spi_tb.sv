`timescale 1ns/1ps

module spi_tb;

    // Testbench signals
    logic active_btn;
    logic clk;
    logic miso;
    logic mosi;
    logic cs;
    logic sclk;
    logic rx; // Output from DUT

    logic [6:0] seg;
    logic [5:0] an;
    logic dpx, dpy, dpz;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 50 MHz
    end

    // MISO toggles only when rx == 1
    always_ff @(posedge sclk) begin
        if (rx && !cs)
            miso <= ~miso;
        else
            miso <= 0;
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
        .dpx(dpx),
        .dpy(dpy),
        .dpz(dpz),
        .rx_debug(rx) // Connect rx output
    );

    // Test sequence
    initial begin
        $dumpfile("spi_wave.vcd");
        $dumpvars(0, spi_tb);

        active_btn = 0;
        // miso = 0;

        #400;
        active_btn = 1;
        #5000;

        active_btn = 0;
        #600;

        active_btn = 1;
        #10_000_000;

        active_btn = 0;
        #5000;

        $finish;
    end

endmodule
