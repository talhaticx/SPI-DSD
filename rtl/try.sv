module try(input logic clk, input logic rst, output logic out);
  always_ff @(posedge clk or posedge rst)
    if (rst)
      out <= 0;
    else
      out <= ~out;
endmodule
