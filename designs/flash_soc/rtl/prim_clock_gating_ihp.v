// IHP clock gate for Ibex. Replaces lowRISC's generic latch-plus-AND prim_clock_gating with the
// library's integrated clock gate, which carries a characterized gating check; test_en_i drives SCE.
module prim_clock_gating #(
  parameter [0:0] NoFpgaGate = 1'b0,
  parameter [0:0] FpgaBufGlobal = 1'b1
) (
  input  wire clk_i,
  input  wire en_i,
  input  wire test_en_i,
  output wire clk_o
);
  sg13g2_slgcp_1 u_icg (.CLK(clk_i), .GATE(en_i), .SCE(test_en_i), .GCLK(clk_o));
endmodule
