// Testbench: loads the program image through the serial loader pins, releases the core and waits
// for GPIO bit 7. Pass means GPIO == 0x80. Works on RTL and on the gate-level netlist.
`timescale 1ns/1ps
module tb_flash_soc;
  parameter string HEX = "prog.hex";
  parameter int    WORDS = 1024;
  parameter real   TCLK = 20.0;          // 50 MHz
  parameter int    TIMEOUT_CYCLES = 200000;

  logic clk = 0, rst_n = 0, load_en = 0, sclk = 0, sdi = 0;
  wire  [7:0] gpio;
  logic [31:0] image [0:WORDS-1];
  int n_words;

`ifdef CHIP
  // The chip with its pad ring; functional mode, test pins held inactive.
  flash_chip dut (.clk(clk), .rst_n(rst_n), .load_en(load_en), .sclk(sclk), .sdi(sdi), .gpio_o(gpio),
                  .test_mode(1'b0), .scan_en(1'b0), .scan_in(1'b0), .scan_out());
`elsif DFT_PORTS
  // Functional mode: test pins held inactive.
  flash_soc dut (.clk(clk), .rst_n(rst_n), .load_en(load_en), .sclk(sclk), .sdi(sdi), .gpio_o(gpio),
                 .test_mode(1'b0), .scan_en(1'b0), .scan_in(1'b0), .scan_out());
`else
  flash_soc dut (.clk(clk), .rst_n(rst_n), .load_en(load_en), .sclk(sclk), .sdi(sdi), .gpio_o(gpio));
`endif

  always #(TCLK/2) clk = ~clk;

`ifdef RT
  // Rad-tolerant build: when the program asks (GPIO 0x10), flip DMEM bits behind the ECC, then check in the
  // SRAM itself that the scrubber wrote the single-bit errors back corrected.
  `define DMEM tb_flash_soc.dut.u_dmem.i_SRAM_1P_behavioral_bm_bist.memory
  initial begin
    wait (gpio === 8'h10);
    @(negedge clk);
`ifdef RT_PLANT
    // Control: a 2-bit error in the word the program reads must end in a bus error and a failed test.
    `DMEM[512] = `DMEM[512] ^ 32'h0000_0021;
`else
    `DMEM[512] = `DMEM[512] ^ 32'h0000_0020;
`endif
    `DMEM[513] = `DMEM[513] ^ 32'h0000_0208;
    `DMEM[514] = `DMEM[514] ^ 32'h4000_0000;
    $display("TB: injected 1-bit errors in DMEM words 512 and 514, a 2-bit error in word 513");
    wait (gpio === 8'h20);
    if (`DMEM[512] !== 32'h1234_5678 || `DMEM[514] !== 32'h0F0F_0F0F)
      $display("TB_RESULT FAIL scrubber left DMEM 512=%08h 514=%08h", `DMEM[512], `DMEM[514]);
    else
      $display("TB: scrubber repaired DMEM words 512 and 514");
    if (`DMEM[513] !== (32'hCAFE_F00D ^ 32'h0000_0208)) $display("TB_RESULT FAIL uncorrectable word 513 was rewritten");
  end
`endif

  task automatic send_word(input logic [9:0] addr, input logic [31:0] data);
    logic [41:0] w = {addr, data};
    for (int i = 41; i >= 0; i--) begin
      sdi = w[i];
      repeat (4) @(negedge clk); sclk = 1;
      repeat (4) @(negedge clk); sclk = 0;
    end
  endtask

  initial begin
    for (int i = 0; i < WORDS; i++) image[i] = 32'hx;
    $readmemh(HEX, image);
    n_words = 0;
    for (int i = 0; i < WORDS; i++) if (!$isunknown(image[i])) n_words = i + 1;
    $display("TB: loading %0d words from %s", n_words, HEX);

    repeat (5) @(negedge clk);
    rst_n = 1; load_en = 1;
    repeat (10) @(negedge clk);
    for (int i = 0; i < n_words; i++) send_word(i[9:0], $isunknown(image[i]) ? 32'd0 : image[i]);
    repeat (10) @(negedge clk);
    // +saif records switching activity from core release to done, for PrimePower.
    if ($test$plusargs("saif")) begin
      $set_toggle_region(tb_flash_soc.dut);
      $toggle_start;
    end
    load_en = 0;

    fork
      begin
        wait (gpio[7] === 1'b1);
        repeat (2) @(negedge clk);
        if ($test$plusargs("saif")) begin
          $toggle_stop;
          $toggle_report("activity.saif", 1.0e-9, "tb_flash_soc.dut");
        end
        if (gpio === 8'h80) $display("TB_RESULT PASS gpio=%02h time=%0t", gpio, $time);
        else                $display("TB_RESULT FAIL gpio=%02h time=%0t", gpio, $time);
      end
      begin
        repeat (TIMEOUT_CYCLES) @(negedge clk);
        $display("TB_RESULT FAIL timeout gpio=%02h", gpio);
      end
    join_any
    $finish;
  end
endmodule
