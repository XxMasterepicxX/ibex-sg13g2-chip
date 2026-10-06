// flash_chip: flash_soc inside an IHP sg13g2_io pad ring. Every chip port is the pad pin of one IO cell.
// Supply pads have no signal pins; their core (vdd, vss) and IO (iovdd, iovss) rails abut around the ring
// and are connected by the power grid, not by this netlist.
module flash_chip (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       load_en,
  input  wire       sclk,
  input  wire       sdi,
  input  wire       test_mode,
  input  wire       scan_en,
  input  wire       scan_in,
  output wire       scan_out,
  output wire [7:0] gpio_o
);
  wire clk_c, rst_n_c, load_en_c, sclk_c, sdi_c, test_mode_c, scan_en_c, scan_in_c, scan_out_c;
  wire [7:0] gpio_c;

  sg13g2_IOPadIn u_pclk   (.pad(clk),       .p2c(clk_c));
  sg13g2_IOPadIn u_prst   (.pad(rst_n),     .p2c(rst_n_c));
  sg13g2_IOPadIn u_pload  (.pad(load_en),   .p2c(load_en_c));
  sg13g2_IOPadIn u_psclk  (.pad(sclk),      .p2c(sclk_c));
  sg13g2_IOPadIn u_psdi   (.pad(sdi),       .p2c(sdi_c));
  sg13g2_IOPadIn u_ptest  (.pad(test_mode), .p2c(test_mode_c));
  sg13g2_IOPadIn u_pscen  (.pad(scan_en),   .p2c(scan_en_c));
  sg13g2_IOPadIn u_pscin  (.pad(scan_in),   .p2c(scan_in_c));
  sg13g2_IOPadOut4mA u_pscout (.pad(scan_out), .c2p(scan_out_c));
  sg13g2_IOPadOut4mA u_pgpio0 (.pad(gpio_o[0]), .c2p(gpio_c[0]));
  sg13g2_IOPadOut4mA u_pgpio1 (.pad(gpio_o[1]), .c2p(gpio_c[1]));
  sg13g2_IOPadOut4mA u_pgpio2 (.pad(gpio_o[2]), .c2p(gpio_c[2]));
  sg13g2_IOPadOut4mA u_pgpio3 (.pad(gpio_o[3]), .c2p(gpio_c[3]));
  sg13g2_IOPadOut4mA u_pgpio4 (.pad(gpio_o[4]), .c2p(gpio_c[4]));
  sg13g2_IOPadOut4mA u_pgpio5 (.pad(gpio_o[5]), .c2p(gpio_c[5]));
  sg13g2_IOPadOut4mA u_pgpio6 (.pad(gpio_o[6]), .c2p(gpio_c[6]));
  sg13g2_IOPadOut4mA u_pgpio7 (.pad(gpio_o[7]), .c2p(gpio_c[7]));

  sg13g2_IOPadVdd   u_pvdd0 ();
  sg13g2_IOPadVdd   u_pvdd1 ();
  sg13g2_IOPadVss   u_pvss0 ();
  sg13g2_IOPadVss   u_pvss1 ();
  sg13g2_IOPadIOVdd u_piovdd0 ();
  sg13g2_IOPadIOVdd u_piovdd1 ();
  sg13g2_IOPadIOVss u_piovss0 ();
  sg13g2_IOPadIOVss u_piovss1 ();

  flash_soc u_soc (
    .clk(clk_c), .rst_n(rst_n_c), .load_en(load_en_c), .sclk(sclk_c), .sdi(sdi_c),
    .test_mode(test_mode_c), .scan_en(scan_en_c), .scan_in(scan_in_c), .scan_out(scan_out_c),
    .gpio_o(gpio_c)
  );
endmodule
