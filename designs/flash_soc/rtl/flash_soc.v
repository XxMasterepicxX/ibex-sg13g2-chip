// flash_soc: Ibex RV32IMC with 4 KB instruction SRAM, 4 KB data SRAM, an 8-bit GPIO output register
// and a serial loader that fills instruction memory while the core is held in reset. One clock domain.
//
// Memory map, data port:
//   0x0000_0000 - 0x0000_0FFF  IMEM, read only from the data port (constants, .data load image)
//   0x0001_0000 - 0x0001_0FFF  DMEM
//   0x0002_0000                GPIO output register, bits 7:0
// The instruction port reaches IMEM only. Ibex boots at boot_addr + 0x80 = 0x80.
//
// Loader: with load_en high the core stays in reset. On each rising edge of sclk, sampled through a
// synchronizer, one bit of sdi shifts in MSB first; every 42 bits, {addr[9:0], data[31:0]} is written to IMEM.
//
// Test: scan_in/scan_out are stitched by insert_dft. With test_mode high the internal resets come straight
// from rst_n, so the tester controls every asynchronous reset, and every clock gate is held open
// (DFT DRC D9 flagged all 1902 gated flops when the gates opened on scan_en only).
module flash_soc (
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
  assign scan_out = 1'b0;   // replaced by the scan chain output

  // Reset: asynchronous assert, synchronous release.
  reg [1:0] rst_sync;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) rst_sync <= 2'b00;
    else        rst_sync <= {rst_sync[0], 1'b1};
  wire sys_rst_n = test_mode ? rst_n : rst_sync[1];

  // Loader inputs come from pads asynchronously, so they are synchronized before use.
  reg [2:0] sclk_s;
  reg [1:0] sdi_s, load_s;
  always @(posedge clk or negedge sys_rst_n)
    if (!sys_rst_n) begin
      sclk_s <= 3'b000; sdi_s <= 2'b00; load_s <= 2'b00;
    end else begin
      sclk_s <= {sclk_s[1:0], sclk};
      sdi_s  <= {sdi_s[0], sdi};
      load_s <= {load_s[0], load_en};
    end
  wire loading   = load_s[1];
  wire sclk_rise = sclk_s[1] & ~sclk_s[2];

  reg [41:0] ld_shift;
  reg [5:0]  ld_count;
  reg        ld_write;
  always @(posedge clk or negedge sys_rst_n)
    if (!sys_rst_n) begin
      ld_shift <= 42'd0; ld_count <= 6'd0; ld_write <= 1'b0;
    end else begin
      ld_write <= 1'b0;
      if (!loading) ld_count <= 6'd0;
      else if (sclk_rise) begin
        ld_shift <= {ld_shift[40:0], sdi_s[1]};
        if (ld_count == 6'd41) begin
          ld_count <= 6'd0;
          ld_write <= 1'b1;
        end else ld_count <= ld_count + 6'd1;
      end
    end

  wire core_rst_n = test_mode ? rst_n : (sys_rst_n & ~loading);

  // Ibex.
  wire        instr_req, instr_gnt;
  reg         instr_rvalid;
  wire [31:0] instr_addr, instr_rdata;
  reg         instr_err;
  wire        data_req, data_we;
  wire        data_gnt;
  reg         data_rvalid, data_err;
  wire [3:0]  data_be;
  wire [31:0] data_addr, data_wdata;
  reg  [31:0] data_rdata;

  ibex_top #(
    .DmBaseAddr      (32'h1a110000),
    .DmAddrMask      (32'h00000fff),
    .DmHaltAddr      (32'h1a110800),
    .DmExceptionAddr (32'h1a110808)
  ) u_core (
    .clk_i                   (clk),
    .rst_ni                  (core_rst_n),
    .test_en_i               (test_mode),
    .scan_rst_ni             (1'b1),
    .ram_cfg_icache_tag_i    (24'd0),
    .ram_cfg_icache_tag_o    (),
    .ram_cfg_icache_data_i   (24'd0),
    .ram_cfg_icache_data_o   (),
    .cheriot_enable_i        (4'b1010),   // IbexMuBiOff
    .hart_id_i               (32'd0),
    .boot_addr_i             (32'h00000000),
    .trvk_heap_base_addr_i   (32'd0),
    .instr_req_o             (instr_req),
    .instr_gnt_i             (instr_gnt),
    .instr_rvalid_i          (instr_rvalid),
    .instr_addr_o            (instr_addr),
    .instr_rdata_i           (instr_rdata),
    .instr_rdata_intg_i      (7'd0),
    .instr_err_i             (instr_err),
    .data_req_o              (data_req),
    .data_gnt_i              (data_gnt),
    .data_rvalid_i           (data_rvalid),
    .data_we_o               (data_we),
    .data_be_o               (data_be),
    .data_addr_o             (data_addr),
    .data_wdata_o            (data_wdata),
    .data_wdata_intg_o       (),
    .data_tag_o              (),
    .data_rdata_i            (data_rdata),
    .data_rdata_intg_i       (7'd0),
    .data_tag_i              (1'b0),
    .data_err_i              (data_err),
    .trvk_revbm_req_o        (),
    .trvk_revbm_gnt_i        (1'b0),
    .trvk_revbm_rvalid_i     (1'b0),
    .trvk_revbm_addr_o       (),
    .trvk_revbm_rdata_i      (32'd0),
    .trvk_revbm_rdata_intg_i (7'd0),
    .trvk_revbm_err_i        (1'b0),
    .irq_software_i          (1'b0),
    .irq_timer_i             (1'b0),
    .irq_external_i          (1'b0),
    .irq_fast_i              (15'd0),
    .irq_nm_i                (1'b0),
    .scramble_key_valid_i    (1'b0),
    .scramble_key_i          (128'd0),
    .scramble_nonce_i        (64'd0),
    .scramble_req_o          (),
    .debug_req_i             (1'b0),
    .crash_dump_o            (),
    .double_fault_seen_o     (),
    .fetch_enable_i          (4'b0101),   // IbexMuBiOn
    .mcounteren_writable_i   (4'b0101),
    .alert_minor_o           (),
    .alert_major_internal_o  (),
    .alert_major_bus_o       (),
    .core_sleep_o            (),
    .lockstep_cmp_en_o       (),
    .data_req_shadow_o       (),
    .data_we_shadow_o        (),
    .data_be_shadow_o        (),
    .data_addr_shadow_o      (),
    .data_wdata_shadow_o     (),
    .data_wdata_intg_shadow_o(),
    .instr_req_shadow_o      (),
    .instr_addr_shadow_o     ()
  );

  // Data port decode.
  wire d_imem = data_addr[31:12] == 20'h00000;
  wire d_dmem = data_addr[31:12] == 20'h00010;
  wire d_gpio = data_addr[31:2]  == 30'h00008000;
  wire i_imem = instr_addr[31:12] == 20'h00000;

  // IMEM is shared by the loader, the data port and the instruction port, in that priority.
  wire imem_data  = data_req & d_imem & ~data_we;
  assign instr_gnt = instr_req & ~imem_data & ~loading;
  assign data_gnt  = data_req;

  wire [9:0]  imem_addr = loading   ? ld_shift[41:32] :
                          imem_data ? data_addr[11:2] : instr_addr[11:2];
  wire        imem_men  = ld_write | imem_data | (instr_gnt & i_imem);
  wire        imem_wen  = ld_write;
  wire [31:0] imem_dout;

  RM_IHPSG13_1P_1024x32_c2_bm_bist u_imem (
    .A_CLK(clk), .A_MEN(imem_men), .A_WEN(imem_wen), .A_REN(~imem_wen),
    .A_ADDR(imem_addr), .A_DIN(ld_shift[31:0]), .A_DLY(1'b1), .A_DOUT(imem_dout),
    .A_BM(32'hffffffff),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0), .A_BIST_REN(1'b0),
    .A_BIST_ADDR(10'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );

  wire        dmem_men = data_req & d_dmem;
  wire [31:0] dmem_dout;
  wire [31:0] dmem_bm = {{8{data_be[3]}}, {8{data_be[2]}}, {8{data_be[1]}}, {8{data_be[0]}}};

  RM_IHPSG13_1P_1024x32_c2_bm_bist u_dmem (
    .A_CLK(clk), .A_MEN(dmem_men), .A_WEN(data_we), .A_REN(~data_we),
    .A_ADDR(data_addr[11:2]), .A_DIN(data_wdata), .A_DLY(1'b1), .A_DOUT(dmem_dout),
    .A_BM(dmem_bm),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0), .A_BIST_REN(1'b0),
    .A_BIST_ADDR(10'd0), .A_BIST_DIN(32'd0), .A_BIST_BM(32'd0)
  );

  reg [7:0] gpio_q;
  always @(posedge clk or negedge core_rst_n)
    if (!core_rst_n) gpio_q <= 8'd0;
    else if (data_req & data_we & d_gpio & data_be[0]) gpio_q <= data_wdata[7:0];
  assign gpio_o = gpio_q;

  // Responses arrive one cycle after the grant, matching the SRAM's one-cycle read.
  localparam SRC_IMEM = 2'd0, SRC_DMEM = 2'd1, SRC_GPIO = 2'd2, SRC_ERR = 2'd3;
  reg [1:0] d_src;
  always @(posedge clk or negedge core_rst_n)
    if (!core_rst_n) begin
      instr_rvalid <= 1'b0; instr_err <= 1'b0;
      data_rvalid  <= 1'b0; d_src <= SRC_ERR;
    end else begin
      instr_rvalid <= instr_gnt;
      instr_err    <= instr_gnt & ~i_imem;
      data_rvalid  <= data_req;
      d_src <= (d_imem & ~data_we) ? SRC_IMEM : d_dmem ? SRC_DMEM : d_gpio ? SRC_GPIO : SRC_ERR;
    end

  assign instr_rdata = imem_dout;
  always @(*) begin
    data_err = data_rvalid & (d_src == SRC_ERR);
    case (d_src)
      SRC_IMEM: data_rdata = imem_dout;
      SRC_DMEM: data_rdata = dmem_dout;
      SRC_GPIO: data_rdata = {24'd0, gpio_q};
      default:  data_rdata = 32'd0;
    endcase
  end

endmodule
