// lowRISC Ibex, https://github.com/lowRISC/ibex at commit e9f55342edbd27e9e17a0e41b1c95a81abb5eac8, Apache-2.0.
// Converted to Verilog with sv2v 0.0.13. Changed: the generic prim_clock_gating module is removed, so the
// IHP clock gate in prim_clock_gating_ihp.v takes its place.
module ibex_alu (
	operator_i,
	operand_a_i,
	operand_b_i,
	instr_first_cycle_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_sel_i,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	adder_result_o,
	adder_result_ext_o,
	result_o,
	comparison_result_o,
	is_equal_result_o
);
	reg _sv2v_0;
	parameter integer RV32B = 32'sd0;
	input wire [6:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire instr_first_cycle_i;
	input wire [32:0] multdiv_operand_a_i;
	input wire [32:0] multdiv_operand_b_i;
	input wire multdiv_sel_i;
	input wire [63:0] imd_val_q_i;
	output reg [63:0] imd_val_d_o;
	output reg [1:0] imd_val_we_o;
	output wire [31:0] adder_result_o;
	output wire [33:0] adder_result_ext_o;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire is_equal_result_o;
	wire [31:0] operand_a_rev;
	wire [32:0] operand_b_neg;
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 32; _gv_k_1 = _gv_k_1 + 1) begin : gen_rev_operand_a
			localparam k = _gv_k_1;
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	reg adder_op_a_shift1;
	reg adder_op_a_shift2;
	reg adder_op_a_shift3;
	reg adder_op_b_negate;
	reg [32:0] adder_in_a;
	reg [32:0] adder_in_b;
	wire [31:0] adder_result;
	always @(*) begin
		if (_sv2v_0)
			;
		adder_op_a_shift1 = 1'b0;
		adder_op_a_shift2 = 1'b0;
		adder_op_a_shift3 = 1'b0;
		adder_op_b_negate = 1'b0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd1, 7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44, 7'd31, 7'd32, 7'd33, 7'd34: adder_op_b_negate = 1'b1;
			7'd22:
				if (RV32B != 32'sd0)
					adder_op_a_shift1 = 1'b1;
			7'd23:
				if (RV32B != 32'sd0)
					adder_op_a_shift2 = 1'b1;
			7'd24:
				if (RV32B != 32'sd0)
					adder_op_a_shift3 = 1'b1;
			default:
				;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_a = multdiv_operand_a_i;
			adder_op_a_shift1: adder_in_a = {operand_a_i[30:0], 2'b01};
			adder_op_a_shift2: adder_in_a = {operand_a_i[29:0], 3'b001};
			adder_op_a_shift3: adder_in_a = {operand_a_i[28:0], 4'b0001};
			default: adder_in_a = {operand_a_i, 1'b1};
		endcase
	end
	assign operand_b_neg = {operand_b_i, 1'b0} ^ {33 {1'b1}};
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_b = multdiv_operand_b_i;
			adder_op_b_negate: adder_in_b = operand_b_neg;
			default: adder_in_b = {operand_b_i, 1'b0};
		endcase
	end
	assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
	assign adder_result = adder_result_ext_o[32:1];
	assign adder_result_o = adder_result;
	wire is_equal;
	reg is_greater_equal;
	reg cmp_signed;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd27, 7'd25, 7'd43, 7'd31, 7'd33: cmp_signed = 1'b1;
			default: cmp_signed = 1'b0;
		endcase
	end
	assign is_equal = adder_result == 32'b00000000000000000000000000000000;
	assign is_equal_result_o = is_equal;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((operand_a_i[31] ^ operand_b_i[31]) == 1'b0)
			is_greater_equal = adder_result[31] == 1'b0;
		else
			is_greater_equal = operand_a_i[31] ^ cmp_signed;
	end
	reg cmp_result;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd29: cmp_result = is_equal;
			7'd30: cmp_result = ~is_equal;
			7'd27, 7'd28, 7'd33, 7'd34: cmp_result = is_greater_equal;
			7'd25, 7'd26, 7'd31, 7'd32, 7'd43, 7'd44: cmp_result = ~is_greater_equal;
			default: cmp_result = is_equal;
		endcase
	end
	assign comparison_result_o = cmp_result;
	reg shift_left;
	wire shift_ones;
	wire shift_arith;
	wire shift_funnel;
	wire shift_sbmode;
	reg [5:0] shift_amt;
	wire [5:0] shift_amt_compl;
	reg [31:0] shift_operand;
	reg signed [32:0] shift_result_ext_signed;
	reg [32:0] shift_result_ext;
	reg unused_shift_result_ext;
	reg [31:0] shift_result;
	reg [31:0] shift_result_rev;
	wire bfp_op;
	wire [4:0] bfp_len;
	wire [4:0] bfp_off;
	wire [31:0] bfp_mask;
	wire [31:0] bfp_mask_rev;
	wire [31:0] bfp_result;
	assign bfp_op = (RV32B != 32'sd0 ? operator_i == 7'd55 : 1'b0);
	assign bfp_len = {~(|operand_b_i[27:24]), operand_b_i[27:24]};
	assign bfp_off = operand_b_i[20:16];
	assign bfp_mask = (RV32B != 32'sd0 ? ~(32'hffffffff << bfp_len) : {32 {1'sb0}});
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : gen_rev_bfp_mask
			localparam i = _gv_i_1;
			assign bfp_mask_rev[i] = bfp_mask[31 - i];
		end
	endgenerate
	assign bfp_result = (RV32B != 32'sd0 ? (~shift_result & operand_a_i) | ((operand_b_i & bfp_mask) << bfp_off) : {32 {1'sb0}});
	wire [1:1] sv2v_tmp_BA5F8;
	assign sv2v_tmp_BA5F8 = operand_b_i[5] & shift_funnel;
	always @(*) shift_amt[5] = sv2v_tmp_BA5F8;
	assign shift_amt_compl = 32 - operand_b_i[4:0];
	always @(*) begin
		if (_sv2v_0)
			;
		if (bfp_op)
			shift_amt[4:0] = bfp_off;
		else
			shift_amt[4:0] = (instr_first_cycle_i ? (operand_b_i[5] && shift_funnel ? shift_amt_compl[4:0] : operand_b_i[4:0]) : (operand_b_i[5] && shift_funnel ? operand_b_i[4:0] : shift_amt_compl[4:0]));
	end
	assign shift_sbmode = (RV32B != 32'sd0 ? ((operator_i == 7'd49) | (operator_i == 7'd50)) | (operator_i == 7'd51) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd10: shift_left = 1'b1;
			7'd12: shift_left = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b1 : 1'b0);
			7'd55: shift_left = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd14: shift_left = (RV32B != 32'sd0 ? instr_first_cycle_i : 0);
			7'd13: shift_left = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 0);
			7'd47: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? ~instr_first_cycle_i : instr_first_cycle_i) : 1'b0);
			7'd48: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? instr_first_cycle_i : ~instr_first_cycle_i) : 1'b0);
			default: shift_left = 1'b0;
		endcase
		if (shift_sbmode)
			shift_left = 1'b1;
	end
	assign shift_arith = operator_i == 7'd8;
	assign shift_ones = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? (operator_i == 7'd12) | (operator_i == 7'd11) : 1'b0);
	assign shift_funnel = (RV32B != 32'sd0 ? (operator_i == 7'd47) | (operator_i == 7'd48) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		if (RV32B == 32'sd0)
			shift_operand = (shift_left ? operand_a_rev : operand_a_i);
		else
			(* full_case, parallel_case *)
			case (1'b1)
				bfp_op: shift_operand = bfp_mask_rev;
				shift_sbmode: shift_operand = 32'h80000000;
				default: shift_operand = (shift_left ? operand_a_rev : operand_a_i);
			endcase
		shift_result_ext_signed = $signed({shift_ones | (shift_arith & shift_operand[31]), shift_operand}) >>> shift_amt[4:0];
		shift_result_ext = $unsigned(shift_result_ext_signed);
		shift_result = shift_result_ext[31:0];
		unused_shift_result_ext = shift_result_ext[32];
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				shift_result_rev[i] = shift_result[31 - i];
		end
		shift_result = (shift_left ? shift_result_rev : shift_result);
	end
	wire bwlogic_or;
	wire bwlogic_and;
	wire [31:0] bwlogic_operand_b;
	wire [31:0] bwlogic_or_result;
	wire [31:0] bwlogic_and_result;
	wire [31:0] bwlogic_xor_result;
	reg [31:0] bwlogic_result;
	reg bwlogic_op_b_negate;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd5, 7'd6, 7'd7: bwlogic_op_b_negate = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd46: bwlogic_op_b_negate = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 1'b0);
			default: bwlogic_op_b_negate = 1'b0;
		endcase
	end
	assign bwlogic_operand_b = (bwlogic_op_b_negate ? operand_b_neg[32:1] : operand_b_i);
	assign bwlogic_or_result = operand_a_i | bwlogic_operand_b;
	assign bwlogic_and_result = operand_a_i & bwlogic_operand_b;
	assign bwlogic_xor_result = operand_a_i ^ bwlogic_operand_b;
	assign bwlogic_or = (operator_i == 7'd3) | (operator_i == 7'd6);
	assign bwlogic_and = (operator_i == 7'd4) | (operator_i == 7'd7);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			bwlogic_or: bwlogic_result = bwlogic_or_result;
			bwlogic_and: bwlogic_result = bwlogic_and_result;
			default: bwlogic_result = bwlogic_xor_result;
		endcase
	end
	wire [5:0] bitcnt_result;
	wire [31:0] minmax_result;
	reg [31:0] pack_result;
	wire [31:0] sext_result;
	reg [31:0] singlebit_result;
	reg [31:0] rev_result;
	reg [31:0] shuffle_result;
	wire [31:0] xperm_result;
	reg [31:0] butterfly_result;
	reg [31:0] invbutterfly_result;
	reg [31:0] clmul_result;
	reg [31:0] multicycle_result;
	generate
		if (RV32B != 32'sd0) begin : g_alu_rvb
			wire zbe_op;
			wire bitcnt_ctz;
			wire bitcnt_clz;
			wire bitcnt_cz;
			reg [31:0] bitcnt_bits;
			wire [31:0] bitcnt_mask_op;
			reg [31:0] bitcnt_bit_mask;
			reg [191:0] bitcnt_partial;
			wire [31:0] bitcnt_partial_lsb_d;
			wire [31:0] bitcnt_partial_msb_d;
			assign bitcnt_ctz = operator_i == 7'd41;
			assign bitcnt_clz = operator_i == 7'd40;
			assign bitcnt_cz = bitcnt_ctz | bitcnt_clz;
			assign bitcnt_result = bitcnt_partial[0+:6];
			assign bitcnt_mask_op = (bitcnt_clz ? operand_a_rev : operand_a_i);
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_bit_mask = bitcnt_mask_op;
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 1);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 2);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 4);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 8);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 16);
				bitcnt_bit_mask = ~bitcnt_bit_mask;
			end
			assign zbe_op = (operator_i == 7'd53) | (operator_i == 7'd54);
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					zbe_op: bitcnt_bits = operand_b_i;
					bitcnt_cz: bitcnt_bits = bitcnt_bit_mask & ~bitcnt_mask_op;
					default: bitcnt_bits = operand_a_i;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_partial = {32 {6'b000000}};
				begin : sv2v_autoblock_2
					reg [31:0] i;
					for (i = 1; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = {5'h00, bitcnt_bits[i]} + {5'h00, bitcnt_bits[i - 1]};
				end
				begin : sv2v_autoblock_3
					reg [31:0] i;
					for (i = 3; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_4
					reg [31:0] i;
					for (i = 7; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_5
					reg [31:0] i;
					for (i = 15; i < 32; i = i + 16)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(39 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[0+:6] = bitcnt_partial[96+:6] + bitcnt_partial[0+:6];
				bitcnt_partial[48+:6] = bitcnt_partial[96+:6] + bitcnt_partial[48+:6];
				begin : sv2v_autoblock_6
					reg [31:0] i;
					for (i = 11; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_7
					reg [31:0] i;
					for (i = 5; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[186+:6] = {5'h00, bitcnt_bits[0]};
				begin : sv2v_autoblock_8
					reg [31:0] i;
					for (i = 2; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(32 - i) * 6+:6] + {5'h00, bitcnt_bits[i]};
				end
			end
			assign minmax_result = (cmp_result ? operand_a_i : operand_b_i);
			wire packu;
			wire packh;
			assign packu = operator_i == 7'd36;
			assign packh = operator_i == 7'd37;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					packu: pack_result = {operand_b_i[31:16], operand_a_i[31:16]};
					packh: pack_result = {16'h0000, operand_b_i[7:0], operand_a_i[7:0]};
					default: pack_result = {operand_b_i[15:0], operand_a_i[15:0]};
				endcase
			end
			assign sext_result = (operator_i == 7'd38 ? {{24 {operand_a_i[7]}}, operand_a_i[7:0]} : {{16 {operand_a_i[15]}}, operand_a_i[15:0]});
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd49: singlebit_result = operand_a_i | shift_result;
					7'd50: singlebit_result = operand_a_i & ~shift_result;
					7'd51: singlebit_result = operand_a_i ^ shift_result;
					default: singlebit_result = {31'h00000000, shift_result[0]};
				endcase
			end
			wire [4:0] zbp_shift_amt;
			wire gorc_op;
			assign gorc_op = operator_i == 7'd16;
			assign zbp_shift_amt[2:0] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[2:0] : {3 {shift_amt[0]}});
			assign zbp_shift_amt[4:3] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[4:3] : {2 {shift_amt[3]}});
			always @(*) begin
				if (_sv2v_0)
					;
				rev_result = operand_a_i;
				if (zbp_shift_amt[0])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h55555555) << 1)) | ((rev_result & 32'haaaaaaaa) >> 1);
				if (zbp_shift_amt[1])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h33333333) << 2)) | ((rev_result & 32'hcccccccc) >> 2);
				if (zbp_shift_amt[2])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0f0f0f0f) << 4)) | ((rev_result & 32'hf0f0f0f0) >> 4);
				if (zbp_shift_amt[3])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h00ff00ff) << 8)) | ((rev_result & 32'hff00ff00) >> 8);
				if (zbp_shift_amt[4])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0000ffff) << 16)) | ((rev_result & 32'hffff0000) >> 16);
			end
			wire crc_hmode;
			wire crc_bmode;
			wire [31:0] clmul_result_rev;
			if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin : gen_alu_rvb_otearlgrey_full
				localparam [127:0] SHUFFLE_MASK_L = 128'h00ff00000f000f003030303044444444;
				localparam [127:0] SHUFFLE_MASK_R = 128'h0000ff0000f000f00c0c0c0c22222222;
				localparam [127:0] FLIP_MASK_L = 128'h22001100004400004411000011000000;
				localparam [127:0] FLIP_MASK_R = 128'h00880044000022000000882200000088;
				wire [31:0] SHUFFLE_MASK_NOT [0:3];
				genvar _gv_i_2;
				for (_gv_i_2 = 0; _gv_i_2 < 4; _gv_i_2 = _gv_i_2 + 1) begin : gen_shuffle_mask_not
					localparam i = _gv_i_2;
					assign SHUFFLE_MASK_NOT[i] = ~(SHUFFLE_MASK_L[(3 - i) * 32+:32] | SHUFFLE_MASK_R[(3 - i) * 32+:32]);
				end
				wire shuffle_flip;
				assign shuffle_flip = operator_i == 7'd18;
				reg [3:0] shuffle_mode;
				always @(*) begin
					if (_sv2v_0)
						;
					shuffle_result = operand_a_i;
					if (shuffle_flip) begin
						shuffle_mode[3] = shift_amt[0];
						shuffle_mode[2] = shift_amt[1];
						shuffle_mode[1] = shift_amt[2];
						shuffle_mode[0] = shift_amt[3];
					end
					else
						shuffle_mode = shift_amt[3:0];
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
					if (shuffle_mode[3])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[0]) | (((shuffle_result << 8) & SHUFFLE_MASK_L[96+:32]) | ((shuffle_result >> 8) & SHUFFLE_MASK_R[96+:32]));
					if (shuffle_mode[2])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[1]) | (((shuffle_result << 4) & SHUFFLE_MASK_L[64+:32]) | ((shuffle_result >> 4) & SHUFFLE_MASK_R[64+:32]));
					if (shuffle_mode[1])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[2]) | (((shuffle_result << 2) & SHUFFLE_MASK_L[32+:32]) | ((shuffle_result >> 2) & SHUFFLE_MASK_R[32+:32]));
					if (shuffle_mode[0])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[3]) | (((shuffle_result << 1) & SHUFFLE_MASK_L[0+:32]) | ((shuffle_result >> 1) & SHUFFLE_MASK_R[0+:32]));
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
				end
				wire [23:0] sel_n;
				wire [7:0] vld_n;
				wire [7:0] sel_b;
				wire [3:0] vld_b;
				wire [1:0] sel_h;
				wire [1:0] vld_h;
				genvar _gv_i_3;
				for (_gv_i_3 = 0; _gv_i_3 < 8; _gv_i_3 = _gv_i_3 + 1) begin : gen_sel_vld_n
					localparam i = _gv_i_3;
					assign sel_n[i * 3+:3] = operand_b_i[i * 4+:3];
					assign vld_n[i] = ~|operand_b_i[(i * 4) + 3+:1];
				end
				genvar _gv_i_4;
				for (_gv_i_4 = 0; _gv_i_4 < 4; _gv_i_4 = _gv_i_4 + 1) begin : gen_sel_vld_b
					localparam i = _gv_i_4;
					assign sel_b[i * 2+:2] = operand_b_i[i * 8+:2];
					assign vld_b[i] = ~|operand_b_i[(i * 8) + 2+:6];
				end
				genvar _gv_i_5;
				for (_gv_i_5 = 0; _gv_i_5 < 2; _gv_i_5 = _gv_i_5 + 1) begin : gen_sel_vld_h
					localparam i = _gv_i_5;
					assign sel_h[i+:1] = operand_b_i[i * 16+:1];
					assign vld_h[i] = ~|operand_b_i[(i * 16) + 1+:15];
				end
				reg [23:0] sel;
				reg [7:0] vld;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (operator_i)
						7'd19: begin
							sel = sel_n;
							vld = vld_n;
						end
						7'd20: begin : sv2v_autoblock_9
							reg signed [31:0] b;
							for (b = 0; b < 4; b = b + 1)
								begin
									sel[((b * 2) + 0) * 3+:3] = {sel_b[b * 2+:2], 1'b0};
									sel[((b * 2) + 1) * 3+:3] = {sel_b[b * 2+:2], 1'b1};
									vld[b * 2+:2] = {2 {vld_b[b]}};
								end
						end
						7'd21: begin : sv2v_autoblock_10
							reg signed [31:0] h;
							for (h = 0; h < 2; h = h + 1)
								begin
									sel[((h * 4) + 0) * 3+:3] = {sel_h[h+:1], 2'b00};
									sel[((h * 4) + 1) * 3+:3] = {sel_h[h+:1], 2'b01};
									sel[((h * 4) + 2) * 3+:3] = {sel_h[h+:1], 2'b10};
									sel[((h * 4) + 3) * 3+:3] = {sel_h[h+:1], 2'b11};
									vld[h * 4+:4] = {4 {vld_h[h]}};
								end
						end
						default: begin
							sel = sel_n;
							vld = 1'sb0;
						end
					endcase
				end
				wire [31:0] val_n;
				wire [31:0] xperm_n;
				assign val_n = operand_a_i;
				genvar _gv_i_6;
				for (_gv_i_6 = 0; _gv_i_6 < 8; _gv_i_6 = _gv_i_6 + 1) begin : gen_xperm_n
					localparam i = _gv_i_6;
					assign xperm_n[i * 4+:4] = (vld[i] ? val_n[sel[i * 3+:3] * 4+:4] : {4 {1'sb0}});
				end
				assign xperm_result = xperm_n;
				wire clmul_rmode;
				wire clmul_hmode;
				reg [31:0] clmul_op_a;
				reg [31:0] clmul_op_b;
				wire [31:0] operand_b_rev;
				wire [31:0] clmul_and_stage [0:31];
				wire [31:0] clmul_xor_stage1 [0:15];
				wire [31:0] clmul_xor_stage2 [0:7];
				wire [31:0] clmul_xor_stage3 [0:3];
				wire [31:0] clmul_xor_stage4 [0:1];
				wire [31:0] clmul_result_raw;
				genvar _gv_i_7;
				for (_gv_i_7 = 0; _gv_i_7 < 32; _gv_i_7 = _gv_i_7 + 1) begin : gen_rev_operand_b
					localparam i = _gv_i_7;
					assign operand_b_rev[i] = operand_b_i[31 - i];
				end
				assign clmul_rmode = operator_i == 7'd57;
				assign clmul_hmode = operator_i == 7'd58;
				localparam [31:0] CRC32_POLYNOMIAL = 32'h04c11db7;
				localparam [31:0] CRC32_MU_REV = 32'hf7011641;
				localparam [31:0] CRC32C_POLYNOMIAL = 32'h1edc6f41;
				localparam [31:0] CRC32C_MU_REV = 32'hdea713f1;
				wire crc_op;
				wire crc_cpoly;
				reg [31:0] crc_operand;
				wire [31:0] crc_poly;
				wire [31:0] crc_mu_rev;
				assign crc_op = (((((operator_i == 7'd64) | (operator_i == 7'd63)) | (operator_i == 7'd62)) | (operator_i == 7'd61)) | (operator_i == 7'd60)) | (operator_i == 7'd59);
				assign crc_cpoly = ((operator_i == 7'd64) | (operator_i == 7'd62)) | (operator_i == 7'd60);
				assign crc_hmode = (operator_i == 7'd61) | (operator_i == 7'd62);
				assign crc_bmode = (operator_i == 7'd59) | (operator_i == 7'd60);
				assign crc_poly = (crc_cpoly ? CRC32C_POLYNOMIAL : CRC32_POLYNOMIAL);
				assign crc_mu_rev = (crc_cpoly ? CRC32C_MU_REV : CRC32_MU_REV);
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						crc_bmode: crc_operand = {operand_a_i[7:0], 24'h000000};
						crc_hmode: crc_operand = {operand_a_i[15:0], 16'h0000};
						default: crc_operand = operand_a_i;
					endcase
				end
				always @(*) begin
					if (_sv2v_0)
						;
					if (crc_op) begin
						clmul_op_a = (instr_first_cycle_i ? crc_operand : imd_val_q_i[32+:32]);
						clmul_op_b = (instr_first_cycle_i ? crc_mu_rev : crc_poly);
					end
					else begin
						clmul_op_a = (clmul_rmode | clmul_hmode ? operand_a_rev : operand_a_i);
						clmul_op_b = (clmul_rmode | clmul_hmode ? operand_b_rev : operand_b_i);
					end
				end
				genvar _gv_i_8;
				for (_gv_i_8 = 0; _gv_i_8 < 32; _gv_i_8 = _gv_i_8 + 1) begin : gen_clmul_and_op
					localparam i = _gv_i_8;
					assign clmul_and_stage[i] = (clmul_op_b[i] ? clmul_op_a << i : {32 {1'sb0}});
				end
				genvar _gv_i_9;
				for (_gv_i_9 = 0; _gv_i_9 < 16; _gv_i_9 = _gv_i_9 + 1) begin : gen_clmul_xor_op_l1
					localparam i = _gv_i_9;
					assign clmul_xor_stage1[i] = clmul_and_stage[2 * i] ^ clmul_and_stage[(2 * i) + 1];
				end
				genvar _gv_i_10;
				for (_gv_i_10 = 0; _gv_i_10 < 8; _gv_i_10 = _gv_i_10 + 1) begin : gen_clmul_xor_op_l2
					localparam i = _gv_i_10;
					assign clmul_xor_stage2[i] = clmul_xor_stage1[2 * i] ^ clmul_xor_stage1[(2 * i) + 1];
				end
				genvar _gv_i_11;
				for (_gv_i_11 = 0; _gv_i_11 < 4; _gv_i_11 = _gv_i_11 + 1) begin : gen_clmul_xor_op_l3
					localparam i = _gv_i_11;
					assign clmul_xor_stage3[i] = clmul_xor_stage2[2 * i] ^ clmul_xor_stage2[(2 * i) + 1];
				end
				genvar _gv_i_12;
				for (_gv_i_12 = 0; _gv_i_12 < 2; _gv_i_12 = _gv_i_12 + 1) begin : gen_clmul_xor_op_l4
					localparam i = _gv_i_12;
					assign clmul_xor_stage4[i] = clmul_xor_stage3[2 * i] ^ clmul_xor_stage3[(2 * i) + 1];
				end
				assign clmul_result_raw = clmul_xor_stage4[0] ^ clmul_xor_stage4[1];
				genvar _gv_i_13;
				for (_gv_i_13 = 0; _gv_i_13 < 32; _gv_i_13 = _gv_i_13 + 1) begin : gen_rev_clmul_result
					localparam i = _gv_i_13;
					assign clmul_result_rev[i] = clmul_result_raw[31 - i];
				end
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						clmul_rmode: clmul_result = clmul_result_rev;
						clmul_hmode: clmul_result = {1'b0, clmul_result_rev[31:1]};
						default: clmul_result = clmul_result_raw;
					endcase
				end
			end
			else begin : gen_alu_rvb_not_otearlgrey_full
				wire [32:1] sv2v_tmp_4A308;
				assign sv2v_tmp_4A308 = 1'sb0;
				always @(*) shuffle_result = sv2v_tmp_4A308;
				assign xperm_result = 1'sb0;
				wire [32:1] sv2v_tmp_31DA6;
				assign sv2v_tmp_31DA6 = 1'sb0;
				always @(*) clmul_result = sv2v_tmp_31DA6;
				assign clmul_result_rev = 1'sb0;
				assign crc_bmode = 1'sb0;
				assign crc_hmode = 1'sb0;
			end
			if (RV32B == 32'sd3) begin : gen_alu_rvb_full
				reg [191:0] bitcnt_partial_q;
				genvar _gv_i_14;
				for (_gv_i_14 = 0; _gv_i_14 < 32; _gv_i_14 = _gv_i_14 + 1) begin : gen_bitcnt_reg_in_lsb
					localparam i = _gv_i_14;
					assign bitcnt_partial_lsb_d[i] = bitcnt_partial[(31 - i) * 6];
				end
				genvar _gv_i_15;
				for (_gv_i_15 = 0; _gv_i_15 < 16; _gv_i_15 = _gv_i_15 + 1) begin : gen_bitcnt_reg_in_b1
					localparam i = _gv_i_15;
					assign bitcnt_partial_msb_d[i] = bitcnt_partial[((31 - ((2 * i) + 1)) * 6) + 1];
				end
				genvar _gv_i_16;
				for (_gv_i_16 = 0; _gv_i_16 < 8; _gv_i_16 = _gv_i_16 + 1) begin : gen_bitcnt_reg_in_b2
					localparam i = _gv_i_16;
					assign bitcnt_partial_msb_d[16 + i] = bitcnt_partial[((31 - ((4 * i) + 3)) * 6) + 2];
				end
				genvar _gv_i_17;
				for (_gv_i_17 = 0; _gv_i_17 < 4; _gv_i_17 = _gv_i_17 + 1) begin : gen_bitcnt_reg_in_b3
					localparam i = _gv_i_17;
					assign bitcnt_partial_msb_d[24 + i] = bitcnt_partial[((31 - ((8 * i) + 7)) * 6) + 3];
				end
				genvar _gv_i_18;
				for (_gv_i_18 = 0; _gv_i_18 < 2; _gv_i_18 = _gv_i_18 + 1) begin : gen_bitcnt_reg_in_b4
					localparam i = _gv_i_18;
					assign bitcnt_partial_msb_d[28 + i] = bitcnt_partial[((31 - ((16 * i) + 15)) * 6) + 4];
				end
				assign bitcnt_partial_msb_d[30] = bitcnt_partial[5];
				assign bitcnt_partial_msb_d[31] = 1'b0;
				always @(*) begin
					if (_sv2v_0)
						;
					bitcnt_partial_q = {32 {6'b000000}};
					begin : sv2v_autoblock_11
						reg [31:0] i;
						for (i = 0; i < 32; i = i + 1)
							begin : gen_bitcnt_reg_out_lsb
								bitcnt_partial_q[(31 - i) * 6] = imd_val_q_i[32 + i];
							end
					end
					begin : sv2v_autoblock_12
						reg [31:0] i;
						for (i = 0; i < 16; i = i + 1)
							begin : gen_bitcnt_reg_out_b1
								bitcnt_partial_q[((31 - ((2 * i) + 1)) * 6) + 1] = imd_val_q_i[0 + i];
							end
					end
					begin : sv2v_autoblock_13
						reg [31:0] i;
						for (i = 0; i < 8; i = i + 1)
							begin : gen_bitcnt_reg_out_b2
								bitcnt_partial_q[((31 - ((4 * i) + 3)) * 6) + 2] = imd_val_q_i[16 + i];
							end
					end
					begin : sv2v_autoblock_14
						reg [31:0] i;
						for (i = 0; i < 4; i = i + 1)
							begin : gen_bitcnt_reg_out_b3
								bitcnt_partial_q[((31 - ((8 * i) + 7)) * 6) + 3] = imd_val_q_i[24 + i];
							end
					end
					begin : sv2v_autoblock_15
						reg [31:0] i;
						for (i = 0; i < 2; i = i + 1)
							begin : gen_bitcnt_reg_out_b4
								bitcnt_partial_q[((31 - ((16 * i) + 15)) * 6) + 4] = imd_val_q_i[28 + i];
							end
					end
					bitcnt_partial_q[5] = imd_val_q_i[30];
				end
				wire [31:0] butterfly_mask_l [0:4];
				wire [31:0] butterfly_mask_r [0:4];
				wire [31:0] butterfly_mask_not [0:4];
				wire [31:0] lrotc_stage [0:4];
				genvar _gv_stg_1;
				for (_gv_stg_1 = 0; _gv_stg_1 < 5; _gv_stg_1 = _gv_stg_1 + 1) begin : gen_butterfly_ctrl_stage
					localparam stg = _gv_stg_1;
					genvar _gv_seg_1;
					for (_gv_seg_1 = 0; _gv_seg_1 < (2 ** stg); _gv_seg_1 = _gv_seg_1 + 1) begin : gen_butterfly_ctrl
						localparam seg = _gv_seg_1;
						assign lrotc_stage[stg][((2 * (16 >> stg)) * (seg + 1)) - 1:(2 * (16 >> stg)) * seg] = {{16 >> stg {1'b0}}, {16 >> stg {1'b1}}} << bitcnt_partial_q[((32 - ((16 >> stg) * ((2 * seg) + 1))) * 6) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) : ($clog2(16 >> stg) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))) - 1)-:($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = 1'sb0;
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = 1'sb0;
					end
				end
				genvar _gv_stg_2;
				for (_gv_stg_2 = 0; _gv_stg_2 < 5; _gv_stg_2 = _gv_stg_2 + 1) begin : gen_butterfly_not
					localparam stg = _gv_stg_2;
					assign butterfly_mask_not[stg] = ~(butterfly_mask_l[stg] | butterfly_mask_r[stg]);
				end
				always @(*) begin
					if (_sv2v_0)
						;
					butterfly_result = operand_a_i;
					butterfly_result = ((butterfly_result & butterfly_mask_not[0]) | ((butterfly_result & butterfly_mask_l[0]) >> 16)) | ((butterfly_result & butterfly_mask_r[0]) << 16);
					butterfly_result = ((butterfly_result & butterfly_mask_not[1]) | ((butterfly_result & butterfly_mask_l[1]) >> 8)) | ((butterfly_result & butterfly_mask_r[1]) << 8);
					butterfly_result = ((butterfly_result & butterfly_mask_not[2]) | ((butterfly_result & butterfly_mask_l[2]) >> 4)) | ((butterfly_result & butterfly_mask_r[2]) << 4);
					butterfly_result = ((butterfly_result & butterfly_mask_not[3]) | ((butterfly_result & butterfly_mask_l[3]) >> 2)) | ((butterfly_result & butterfly_mask_r[3]) << 2);
					butterfly_result = ((butterfly_result & butterfly_mask_not[4]) | ((butterfly_result & butterfly_mask_l[4]) >> 1)) | ((butterfly_result & butterfly_mask_r[4]) << 1);
					butterfly_result = butterfly_result & operand_b_i;
				end
				always @(*) begin
					if (_sv2v_0)
						;
					invbutterfly_result = operand_a_i & operand_b_i;
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[4]) | ((invbutterfly_result & butterfly_mask_l[4]) >> 1)) | ((invbutterfly_result & butterfly_mask_r[4]) << 1);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[3]) | ((invbutterfly_result & butterfly_mask_l[3]) >> 2)) | ((invbutterfly_result & butterfly_mask_r[3]) << 2);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[2]) | ((invbutterfly_result & butterfly_mask_l[2]) >> 4)) | ((invbutterfly_result & butterfly_mask_r[2]) << 4);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[1]) | ((invbutterfly_result & butterfly_mask_l[1]) >> 8)) | ((invbutterfly_result & butterfly_mask_r[1]) << 8);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[0]) | ((invbutterfly_result & butterfly_mask_l[0]) >> 16)) | ((invbutterfly_result & butterfly_mask_r[0]) << 16);
				end
			end
			else begin : gen_alu_rvb_not_full
				wire [31:0] unused_imd_val_q_1;
				assign unused_imd_val_q_1 = imd_val_q_i[0+:32];
				wire [32:1] sv2v_tmp_98122;
				assign sv2v_tmp_98122 = 1'sb0;
				always @(*) butterfly_result = sv2v_tmp_98122;
				wire [32:1] sv2v_tmp_B39E0;
				assign sv2v_tmp_B39E0 = 1'sb0;
				always @(*) invbutterfly_result = sv2v_tmp_B39E0;
				assign bitcnt_partial_lsb_d = 1'sb0;
				assign bitcnt_partial_msb_d = 1'sb0;
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd45: begin
						multicycle_result = (operand_b_i == 32'h00000000 ? operand_a_i : imd_val_q_i[32+:32]);
						imd_val_d_o = {operand_a_i, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd46: begin
						multicycle_result = imd_val_q_i[32+:32] | bwlogic_and_result;
						imd_val_d_o = {bwlogic_and_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd48, 7'd47, 7'd14, 7'd13: begin
						if (shift_amt[4:0] == 5'h00)
							multicycle_result = (shift_amt[5] ? operand_a_i : imd_val_q_i[32+:32]);
						else
							multicycle_result = imd_val_q_i[32+:32] | shift_result;
						imd_val_d_o = {shift_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60:
						if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
							(* full_case, parallel_case *)
							case (1'b1)
								crc_bmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 8);
								crc_hmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 16);
								default: multicycle_result = clmul_result_rev;
							endcase
							imd_val_d_o = {clmul_result_rev, 32'h00000000};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b01;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					7'd53, 7'd54:
						if (RV32B == 32'sd3) begin
							multicycle_result = (operator_i == 7'd54 ? butterfly_result : invbutterfly_result);
							imd_val_d_o = {bitcnt_partial_lsb_d, bitcnt_partial_msb_d};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b11;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					default: begin
						imd_val_d_o = {operand_a_i, 32'h00000000};
						imd_val_we_o = 2'b00;
						multicycle_result = 1'sb0;
					end
				endcase
			end
		end
		else begin : g_no_alu_rvb
			wire [63:0] unused_imd_val_q;
			assign unused_imd_val_q = imd_val_q_i;
			wire [31:0] unused_butterfly_result;
			assign unused_butterfly_result = butterfly_result;
			wire [31:0] unused_invbutterfly_result;
			assign unused_invbutterfly_result = invbutterfly_result;
			assign bitcnt_result = 1'sb0;
			assign minmax_result = 1'sb0;
			wire [32:1] sv2v_tmp_A0513;
			assign sv2v_tmp_A0513 = 1'sb0;
			always @(*) pack_result = sv2v_tmp_A0513;
			assign sext_result = 1'sb0;
			wire [32:1] sv2v_tmp_75CE4;
			assign sv2v_tmp_75CE4 = 1'sb0;
			always @(*) singlebit_result = sv2v_tmp_75CE4;
			wire [32:1] sv2v_tmp_FA09A;
			assign sv2v_tmp_FA09A = 1'sb0;
			always @(*) rev_result = sv2v_tmp_FA09A;
			wire [32:1] sv2v_tmp_4A308;
			assign sv2v_tmp_4A308 = 1'sb0;
			always @(*) shuffle_result = sv2v_tmp_4A308;
			assign xperm_result = 1'sb0;
			wire [32:1] sv2v_tmp_98122;
			assign sv2v_tmp_98122 = 1'sb0;
			always @(*) butterfly_result = sv2v_tmp_98122;
			wire [32:1] sv2v_tmp_B39E0;
			assign sv2v_tmp_B39E0 = 1'sb0;
			always @(*) invbutterfly_result = sv2v_tmp_B39E0;
			wire [32:1] sv2v_tmp_31DA6;
			assign sv2v_tmp_31DA6 = 1'sb0;
			always @(*) clmul_result = sv2v_tmp_31DA6;
			wire [32:1] sv2v_tmp_BC1B9;
			assign sv2v_tmp_BC1B9 = 1'sb0;
			always @(*) multicycle_result = sv2v_tmp_BC1B9;
			wire [64:1] sv2v_tmp_42A49;
			assign sv2v_tmp_42A49 = {2 {32'b00000000000000000000000000000000}};
			always @(*) imd_val_d_o = sv2v_tmp_42A49;
			wire [2:1] sv2v_tmp_0E15E;
			assign sv2v_tmp_0E15E = {2 {1'b0}};
			always @(*) imd_val_we_o = sv2v_tmp_0E15E;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd2, 7'd5, 7'd3, 7'd6, 7'd4, 7'd7: result_o = bwlogic_result;
			7'd0, 7'd1, 7'd22, 7'd23, 7'd24: result_o = adder_result;
			7'd10, 7'd9, 7'd8, 7'd12, 7'd11: result_o = shift_result;
			7'd17, 7'd18: result_o = shuffle_result;
			7'd19, 7'd20, 7'd21: result_o = xperm_result;
			7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44: result_o = {31'h00000000, cmp_result};
			7'd31, 7'd33, 7'd32, 7'd34: result_o = minmax_result;
			7'd40, 7'd41, 7'd42: result_o = {26'h0000000, bitcnt_result};
			7'd35, 7'd37, 7'd36: result_o = pack_result;
			7'd38, 7'd39: result_o = sext_result;
			7'd46, 7'd45, 7'd47, 7'd48, 7'd14, 7'd13, 7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60, 7'd53, 7'd54: result_o = multicycle_result;
			7'd49, 7'd50, 7'd51, 7'd52: result_o = singlebit_result;
			7'd15, 7'd16: result_o = rev_result;
			7'd55: result_o = bfp_result;
			7'd56, 7'd57, 7'd58: result_o = clmul_result;
			default:
				;
		endcase
	end
	wire unused_shift_amt_compl;
	assign unused_shift_amt_compl = shift_amt_compl[5];
	initial _sv2v_0 = 0;
endmodule
module ibex_branch_predict (
	clk_i,
	rst_ni,
	fetch_rdata_i,
	fetch_pc_i,
	fetch_valid_i,
	predict_branch_taken_o,
	predict_branch_pc_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] fetch_rdata_i;
	input wire [31:0] fetch_pc_i;
	input wire fetch_valid_i;
	output wire predict_branch_taken_o;
	output wire [31:0] predict_branch_pc_o;
	wire [31:0] imm_j_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_cj_type;
	wire [31:0] imm_cb_type;
	reg [31:0] branch_imm;
	wire [31:0] instr;
	wire instr_j;
	wire instr_b;
	wire instr_cj;
	wire instr_cb;
	wire instr_b_taken;
	assign instr = fetch_rdata_i;
	assign imm_j_type = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign imm_b_type = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_cj_type = {{20 {instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
	assign imm_cb_type = {{23 {instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
	assign instr_b = instr[6:0] == 7'h63;
	assign instr_j = instr[6:0] == 7'h6f;
	assign instr_cb = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b110) | (instr[15:13] == 3'b111));
	assign instr_cj = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b101) | (instr[15:13] == 3'b001));
	always @(*) begin
		if (_sv2v_0)
			;
		branch_imm = imm_b_type;
		(* full_case, parallel_case *)
		case (1'b1)
			instr_j: branch_imm = imm_j_type;
			instr_b: branch_imm = imm_b_type;
			instr_cj: branch_imm = imm_cj_type;
			instr_cb: branch_imm = imm_cb_type;
			default:
				;
		endcase
	end
	assign instr_b_taken = (instr_b & imm_b_type[31]) | (instr_cb & imm_cb_type[31]);
	assign predict_branch_taken_o = fetch_valid_i & ((instr_j | instr_cj) | instr_b_taken);
	assign predict_branch_pc_o = fetch_pc_i + branch_imm;
	initial _sv2v_0 = 0;
endmodule
module ibex_cheriot_ex (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	debug_mode_i,
	fwd_we_i,
	fwd_waddr_i,
	fwd_wdata_i,
	fwd_wcap_i,
	rf_raddr_a_i,
	rf_rdata_a_i,
	rf_rcap_a_i,
	rf_raddr_b_i,
	rf_rdata_b_i,
	rf_rcap_b_i,
	rf_waddr_i,
	pcc_cap_i,
	pcc_cap_o,
	pc_id_i,
	branch_req_o,
	branch_req_spec_o,
	branch_target_o,
	cheriot_exec_id_i,
	instr_first_cycle_i,
	instr_valid_i,
	instr_is_cheriot_i,
	instr_is_rv32lsu_i,
	instr_is_compressed_i,
	cheriot_imm12_i,
	cheriot_imm20_i,
	cheriot_imm21_i,
	cheriot_cs2_dec_i,
	cheriot_operator_i,
	cheriot_cap_field_sel_i,
	cheriot_adder_a_sel_i,
	cheriot_adder_b_sel_i,
	cheriot_setaddr_sel_i,
	cheriot_setbounds_sel_i,
	cheriot_rf_we_o,
	result_data_o,
	result_cap_o,
	cheriot_ex_valid_o,
	cheriot_ex_err_o,
	cheriot_ex_err_info_o,
	cheriot_wb_err_o,
	cheriot_wb_err_info_o,
	lsu_req_o,
	lsu_cheriot_err_o,
	lsu_is_cap_o,
	lsu_lc_clrperm_o,
	lsu_we_o,
	lsu_addr_o,
	lsu_type_o,
	lsu_wdata_o,
	lsu_wcap_o,
	lsu_sign_ext_o,
	addr_incr_req_i,
	addr_last_i,
	rv32_lsu_req_i,
	rv32_lsu_we_i,
	rv32_lsu_type_i,
	rv32_lsu_wdata_i,
	rv32_lsu_sign_ext_i,
	rv32_lsu_addr_i,
	rv32_addr_incr_req_o,
	rv32_addr_last_o,
	csr_rdata_i,
	csr_rcap_i,
	csr_mstatus_mie_i,
	csr_access_o,
	csr_addr_o,
	csr_wdata_o,
	csr_wcap_o,
	csr_op_o,
	csr_op_en_o,
	csr_set_mie_o,
	csr_clr_mie_o,
	csr_mshwm_i,
	csr_mshwmb_i,
	csr_mshwm_set_o,
	csr_mshwm_new_o,
	csr_dbg_tclr_fault_i
);
	reg _sv2v_0;
	parameter [0:0] WritebackStage = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire debug_mode_i;
	input wire fwd_we_i;
	input wire [4:0] fwd_waddr_i;
	input wire [31:0] fwd_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] fwd_wcap_i;
	input wire [4:0] rf_raddr_a_i;
	input wire [31:0] rf_rdata_a_i;
	input wire [34:0] rf_rcap_a_i;
	input wire [4:0] rf_raddr_b_i;
	input wire [31:0] rf_rdata_b_i;
	input wire [34:0] rf_rcap_b_i;
	input wire [4:0] rf_waddr_i;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	input wire [111:0] pcc_cap_i;
	output reg [111:0] pcc_cap_o;
	input wire [31:0] pc_id_i;
	output wire branch_req_o;
	output wire branch_req_spec_o;
	output reg [31:0] branch_target_o;
	input wire cheriot_exec_id_i;
	input wire instr_first_cycle_i;
	input wire instr_valid_i;
	input wire instr_is_cheriot_i;
	input wire instr_is_rv32lsu_i;
	input wire instr_is_compressed_i;
	input wire [11:0] cheriot_imm12_i;
	input wire [19:0] cheriot_imm20_i;
	input wire [20:0] cheriot_imm21_i;
	input wire [4:0] cheriot_cs2_dec_i;
	input wire [25:0] cheriot_operator_i;
	input wire [2:0] cheriot_cap_field_sel_i;
	input wire [2:0] cheriot_adder_a_sel_i;
	input wire [1:0] cheriot_adder_b_sel_i;
	input wire [2:0] cheriot_setaddr_sel_i;
	input wire [2:0] cheriot_setbounds_sel_i;
	output wire cheriot_rf_we_o;
	output reg [31:0] result_data_o;
	output reg [34:0] result_cap_o;
	output wire cheriot_ex_valid_o;
	output wire cheriot_ex_err_o;
	output wire [11:0] cheriot_ex_err_info_o;
	output wire cheriot_wb_err_o;
	output wire [15:0] cheriot_wb_err_info_o;
	output wire lsu_req_o;
	output wire lsu_cheriot_err_o;
	output wire lsu_is_cap_o;
	output wire [2:0] lsu_lc_clrperm_o;
	output wire lsu_we_o;
	output wire [31:0] lsu_addr_o;
	output wire [1:0] lsu_type_o;
	output wire [31:0] lsu_wdata_o;
	output wire [34:0] lsu_wcap_o;
	output wire lsu_sign_ext_o;
	input wire addr_incr_req_i;
	input wire [31:0] addr_last_i;
	input wire rv32_lsu_req_i;
	input wire rv32_lsu_we_i;
	input wire [1:0] rv32_lsu_type_i;
	input wire [31:0] rv32_lsu_wdata_i;
	input wire rv32_lsu_sign_ext_i;
	input wire [31:0] rv32_lsu_addr_i;
	output wire rv32_addr_incr_req_o;
	output wire [31:0] rv32_addr_last_o;
	input wire [31:0] csr_rdata_i;
	input wire [34:0] csr_rcap_i;
	input wire csr_mstatus_mie_i;
	output reg csr_access_o;
	output reg [4:0] csr_addr_o;
	output reg [31:0] csr_wdata_o;
	output reg [34:0] csr_wcap_o;
	output reg [4:0] csr_op_o;
	output wire csr_op_en_o;
	output wire csr_set_mie_o;
	output wire csr_clr_mie_o;
	input wire [31:0] csr_mshwm_i;
	input wire [31:0] csr_mshwmb_i;
	output wire csr_mshwm_set_o;
	output wire [31:0] csr_mshwm_new_o;
	input wire csr_dbg_tclr_fault_i;
	wire cheriot_lsu_req;
	wire cheriot_lsu_we;
	wire [31:0] cheriot_lsu_addr;
	wire [31:0] cheriot_lsu_wdata;
	wire [34:0] cheriot_lsu_wcap;
	wire cheriot_lsu_err;
	wire cheriot_lsu_is_cap;
	wire [31:0] rf_rdata_a;
	reg [31:0] rf_rdata_ng_a;
	wire [31:0] rf_rdata_b;
	reg [31:0] rf_rdata_ng_b;
	wire [34:0] rf_rcap_a;
	reg [34:0] rf_rcap_ng_a;
	wire [34:0] rf_rcap_b;
	reg [34:0] rf_rcap_ng_b;
	wire [111:0] rf_fullcap_a;
	wire [111:0] rf_fullcap_b;
	reg [34:0] csc_wcap;
	wire is_load_cap;
	wire is_store_cap;
	wire is_cap;
	reg addr_bound_vio;
	reg perm_vio;
	reg perm_vio_slc;
	wire rv32_lsu_err;
	reg addr_bound_vio_rv32;
	reg perm_vio_rv32;
	localparam [31:0] ibex_cheriot_pkg_W_PVIO = 8;
	reg [7:0] perm_vio_vec;
	reg [7:0] perm_vio_vec_rv32;
	wire [31:0] cs1_addr_plusimm;
	wire [31:0] cs1_imm;
	reg [31:0] addr_result;
	reg cheriot_rf_we_raw;
	reg branch_req_raw;
	reg branch_req_spec_raw;
	reg csr_set_mie_raw;
	reg csr_clr_mie_raw;
	reg cheriot_ex_valid_raw;
	reg cheriot_ex_err_raw;
	reg csr_op_en_raw;
	reg cheriot_wb_err_raw;
	reg cheriot_wb_err_q;
	wire cheriot_wb_err_d;
	wire [2:0] cheriot_lsu_lc_clrperm;
	reg lc_cglg;
	reg lc_csdlm;
	reg lc_ctag;
	wire [31:0] pc_id_nxt;
	reg [111:0] setaddr1_outcap;
	reg [111:0] setbounds_outcap;
	reg [111:0] setbounds_rndn_outcap;
	reg [175:0] setbounds_result;
	reg [31:0] setbounds_maska;
	reg [31:0] setbounds_rlen;
	reg [15:0] cheriot_wb_err_info_q;
	reg [15:0] cheriot_wb_err_info_d;
	reg [4:0] cheriot_err_cause;
	reg [4:0] rv32_err_cause;
	wire [31:0] cpu_lsu_addr;
	wire [31:0] cpu_lsu_wdata;
	wire cpu_lsu_we;
	wire cpu_lsu_cheriot_err;
	wire cpu_lsu_is_cap;
	reg illegal_scr_addr;
	reg scr_legalization;
	reg [111:0] tfcap;
	reg [11:0] pmask;
	reg clr_sealed;
	reg instr_fault;
	reg is_write;
	reg [34:0] trcap;
	reg [2:0] seal_type;
	reg [31:0] tmp32a;
	reg [31:0] tmp32b;
	reg [111:0] tfcap1;
	reg [31:0] taddr1;
	reg [31:0] newlen;
	reg req_exact;
	reg [31:0] tmp_addr;
	reg [111:0] tfcap3;
	reg [31:0] rv32_top_offset;
	reg [32:0] rv32_top_bound;
	reg [31:0] rv32_base_bound;
	reg [31:0] rv32_base_chkaddr;
	reg rv32_top_vio;
	reg rv32_base_vio;
	reg [32:0] rv32_top_chkaddr;
	reg rv32_top_size_ok;
	reg [32:0] chk_top_bound;
	reg [31:0] chk_base_bound;
	reg [31:0] chk_base_chkaddr;
	reg [32:0] chk_top_chkaddr;
	reg chk_top_vio;
	reg chk_base_vio;
	reg chk_top_equal;
	reg chk_cs2_bad_type;
	reg chk_cs1_otype_0;
	reg chk_cs1_otype_1;
	reg chk_cs1_otype_45;
	reg chk_cs1_otype_23;
	always @(*) begin : fwd_data_merger
		if (_sv2v_0)
			;
		if (((rf_raddr_a_i == fwd_waddr_i) && fwd_we_i) && |rf_raddr_a_i) begin
			rf_rdata_ng_a = fwd_wdata_i;
			rf_rcap_ng_a = fwd_wcap_i;
		end
		else begin
			rf_rdata_ng_a = rf_rdata_a_i;
			rf_rcap_ng_a = rf_rcap_a_i;
		end
		if (((rf_raddr_b_i == fwd_waddr_i) && fwd_we_i) && |rf_raddr_b_i) begin
			rf_rdata_ng_b = fwd_wdata_i;
			rf_rcap_ng_b = fwd_wcap_i;
		end
		else begin
			rf_rdata_ng_b = rf_rdata_b_i;
			rf_rcap_ng_b = rf_rcap_b_i;
		end
	end
	function automatic [5:0] sv2v_cast_11B4E;
		input reg [5:0] inp;
		sv2v_cast_11B4E = inp;
	endfunction
	function automatic [2:0] sv2v_cast_A8DF2;
		input reg [2:0] inp;
		sv2v_cast_A8DF2 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_C8DD4;
		input reg [3:0] inp;
		sv2v_cast_C8DD4 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_B2D65;
		input reg [8:0] inp;
		sv2v_cast_B2D65 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_11B4E(1'sb0), sv2v_cast_A8DF2(1'sb0), sv2v_cast_C8DD4(1'sb0), sv2v_cast_B2D65(1'sb0), sv2v_cast_B2D65(1'sb0)};
	assign rf_rcap_a = (instr_is_cheriot_i | instr_is_rv32lsu_i ? rf_rcap_ng_a : ibex_cheriot_pkg_NULL_CAP);
	assign rf_rdata_a = (instr_is_cheriot_i | instr_is_rv32lsu_i ? rf_rdata_ng_a : 32'h00000000);
	assign rf_rcap_b = (instr_is_cheriot_i ? rf_rcap_ng_b : ibex_cheriot_pkg_NULL_CAP);
	assign rf_rdata_b = (instr_is_cheriot_i ? rf_rdata_ng_b : 32'h00000000);
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_expand_bound33;
		input reg [8:0] mant;
		input reg [1:0] cor;
		input reg [4:0] exp5;
		input reg [31:0] addr;
		reg [32:0] cor_val;
		reg [32:0] mask;
		reg [32:0] bound;
		reg [32:0] mant_ext;
		begin
			if (cor[1])
				cor_val = {33 {1'b1}};
			else
				cor_val = {32'h00000000, cor[0]};
			cor_val = (cor_val << exp5) << ibex_cheriot_pkg_CBOUND_W;
			mask = (33'h1ffffffff << exp5) << ibex_cheriot_pkg_CBOUND_W;
			bound = ({1'b0, addr} & mask) + cor_val;
			mant_ext = {24'h000000, mant};
			bound = bound | (mant_ext << exp5);
			ibex_cheriot_pkg_cheriot_expand_bound33 = bound;
		end
	endfunction
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	localparam [11:0] ibex_cheriot_pkg_PERM_EXE_IMSK = 12'h160;
	localparam [11:0] ibex_cheriot_pkg_PERM_MDO_IMSK = 12'h000;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRO_IMSK = 12'h060;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRW_IMSK = 12'h064;
	localparam [11:0] ibex_cheriot_pkg_PERM_MWO_IMSK = 12'h044;
	localparam [11:0] ibex_cheriot_pkg_PERM_SEA_IMSK = 12'h000;
	function automatic [11:0] ibex_cheriot_pkg_cheriot_expand_perms;
		input reg [5:0] cperms;
		reg [11:0] perms;
		begin
			perms = 1'sb0;
			if (cperms[4:3] == 2'b11) begin
				perms = ibex_cheriot_pkg_PERM_MRW_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[4] = cperms[2];
			end
			else if (cperms[4:2] == 3'b101) begin
				perms = ibex_cheriot_pkg_PERM_MRO_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
			end
			else if (cperms[4:0] == 5'b10000)
				perms = ibex_cheriot_pkg_PERM_MWO_IMSK;
			else if (cperms[4:2] == 3'b100) begin
				perms = ibex_cheriot_pkg_PERM_MDO_IMSK;
				perms[2] = cperms[0];
				perms[5] = cperms[1];
			end
			else if (cperms[4:3] == 2'b01) begin
				perms = ibex_cheriot_pkg_PERM_EXE_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[7] = cperms[2];
			end
			else if (cperms[4:3] == 2'b00) begin
				perms = ibex_cheriot_pkg_PERM_SEA_IMSK;
				perms[9] = cperms[0];
				perms[10] = cperms[1];
				perms[11] = cperms[2];
			end
			perms[0] = cperms[5];
			ibex_cheriot_pkg_cheriot_expand_perms = perms;
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_base_correction;
		input reg [1:0] cap_cor;
		reg unused_top_cor_bit;
		begin
			unused_top_cor_bit = cap_cor[1];
			ibex_cheriot_pkg_cheriot_get_base_correction = {2 {cap_cor[0]}};
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_top_correction;
		input reg [1:0] cap_cor;
		ibex_cheriot_pkg_cheriot_get_top_correction = {cap_cor[1] & cap_cor[0], cap_cor[1]};
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_decode_cap;
		input reg [34:0] cap;
		input reg [31:0] addr;
		reg [111:0] d;
		reg [4:0] exp5;
		begin
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			d[34-:2] = cap[34-:2];
			d[32] = cap[32];
			d[31] = cap[31];
			d[30-:6] = cap[30-:6];
			d[24-:3] = cap[24-:3];
			d[21-:4] = cap[21-:4];
			d[17-:9] = cap[17-:9];
			d[8-:ibex_cheriot_pkg_CBOUND_W] = cap[8-:ibex_cheriot_pkg_CBOUND_W];
			d[46-:12] = ibex_cheriot_pkg_cheriot_expand_perms(cap[30-:6]);
			d[111-:33] = ibex_cheriot_pkg_cheriot_expand_bound33(cap[17-:9], ibex_cheriot_pkg_cheriot_get_top_correction(cap[34-:2]), exp5, addr);
			d[78-:32] = sv2v_cast_32(ibex_cheriot_pkg_cheriot_expand_bound33(cap[8-:ibex_cheriot_pkg_CBOUND_W], ibex_cheriot_pkg_cheriot_get_base_correction(cap[34-:2]), exp5, addr));
			ibex_cheriot_pkg_cheriot_decode_cap = d;
		end
	endfunction
	assign rf_fullcap_a = ibex_cheriot_pkg_cheriot_decode_cap(rf_rcap_a, rf_rdata_a);
	assign rf_fullcap_b = ibex_cheriot_pkg_cheriot_decode_cap(rf_rcap_b, rf_rdata_b);
	assign cheriot_rf_we_o = cheriot_rf_we_raw & cheriot_exec_id_i;
	assign branch_req_o = branch_req_raw & cheriot_exec_id_i;
	assign branch_req_spec_o = branch_req_spec_raw & cheriot_exec_id_i;
	assign csr_set_mie_o = csr_set_mie_raw & cheriot_exec_id_i;
	assign csr_clr_mie_o = csr_clr_mie_raw & cheriot_exec_id_i;
	assign csr_op_en_o = csr_op_en_raw & cheriot_exec_id_i;
	assign cheriot_ex_valid_o = cheriot_ex_valid_raw & cheriot_exec_id_i;
	assign cheriot_ex_err_o = (cheriot_ex_err_raw & cheriot_exec_id_i) & ~debug_mode_i;
	generate
		if (WritebackStage) begin : gen_err_wb_stage
			assign cheriot_wb_err_o = cheriot_wb_err_q;
		end
		else begin : gen_err_no_wb_stage
			assign cheriot_wb_err_o = cheriot_wb_err_d;
		end
	endgenerate
	assign cheriot_lsu_lc_clrperm = (debug_mode_i ? {3 {1'sb0}} : {lc_ctag, lc_csdlm, lc_cglg});
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MEPCC = 5'h1f;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTCC = 5'h1c;
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD = 3'd4;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD = 3'd2;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD = 3'd5;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD = 3'd3;
	localparam [31:0] ibex_cheriot_pkg_PERMS_W = 12;
	function automatic [31:0] ibex_cheriot_pkg_cheriot_cap_length;
		input reg [111:0] full_cap;
		reg [32:0] tmp33;
		reg [31:0] result;
		reg [111:0] unused_full_cap;
		begin
			unused_full_cap = full_cap;
			tmp33 = full_cap[111-:33] - {1'b0, full_cap[78-:32]};
			result = (tmp33[32] ? 32'hffffffff : tmp33[31:0]);
			ibex_cheriot_pkg_cheriot_cap_length = result;
		end
	endfunction
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_cap_to_mem;
		input reg [34:0] cap;
		reg [34:0] cap_bits;
		reg [1:0] unused_cap_corr;
		begin
			cap_bits = cap;
			unused_cap_corr = cap_bits[34:33];
			ibex_cheriot_pkg_cheriot_cap_to_mem = cap_bits[32:0];
		end
	endfunction
	function automatic ibex_cheriot_pkg_cheriot_caps_equal;
		input reg [111:0] cap_a;
		input reg [111:0] cap_b;
		input reg [31:0] addr_a;
		input reg [31:0] addr_b;
		reg [111:0] unused_cap_a;
		reg [111:0] unused_cap_b;
		begin
			unused_cap_a = cap_a;
			unused_cap_b = cap_b;
			ibex_cheriot_pkg_cheriot_caps_equal = (((((((cap_a[32] == cap_b[32]) && (cap_a[17-:9] == cap_b[17-:9])) && (cap_a[8-:ibex_cheriot_pkg_CBOUND_W] == cap_b[8-:ibex_cheriot_pkg_CBOUND_W])) && (cap_a[30-:6] == cap_b[30-:6])) && (cap_a[31] == cap_b[31])) && (cap_a[21-:4] == cap_b[21-:4])) && (cap_a[24-:3] == cap_b[24-:3])) && (addr_a == addr_b);
			ibex_cheriot_pkg_cheriot_caps_equal = ibex_cheriot_pkg_cheriot_caps_equal;
		end
	endfunction
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	function automatic ibex_cheriot_pkg_cheriot_perms_covers;
		input reg [11:0] p;
		input reg [11:0] mask;
		ibex_cheriot_pkg_cheriot_perms_covers = &(sv2v_cast_C1AAB(p) | ~sv2v_cast_C1AAB(mask));
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_compress_perms;
		input reg [11:0] perms;
		reg [5:0] cperms;
		begin
			cperms = 1'sb0;
			cperms[5] = perms[0];
			if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_EXE_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[2] = perms[7];
				cperms[4:3] = 2'b01;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MRW_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[2] = perms[4];
				cperms[4:3] = 2'b11;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MRO_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[4:2] = 3'b101;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MWO_IMSK))
				cperms[4:0] = 5'b10000;
			else if (perms[2] | perms[5]) begin
				cperms[0] = perms[2];
				cperms[1] = perms[5];
				cperms[4:2] = 3'b100;
			end
			else begin
				cperms[0] = perms[9];
				cperms[1] = perms[10];
				cperms[2] = perms[11];
				cperms[4:3] = 2'b00;
			end
			ibex_cheriot_pkg_cheriot_compress_perms = cperms;
		end
	endfunction
	function automatic [3:0] ibex_cheriot_pkg_cheriot_decode_otype;
		input reg [2:0] otype3;
		input reg perm_ex;
		reg [3:0] otype4;
		begin
			otype4 = {~perm_ex & (otype3 != 0), otype3};
			ibex_cheriot_pkg_cheriot_decode_otype = otype4;
		end
	endfunction
	function automatic [34:0] sv2v_cast_F2778;
		input reg [34:0] inp;
		sv2v_cast_F2778 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_encode_cap;
		input reg [111:0] d;
		reg [111:0] unused_d;
		begin
			unused_d = d;
			ibex_cheriot_pkg_cheriot_encode_cap = sv2v_cast_F2778(d);
		end
	endfunction
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
	function automatic ibex_cheriot_pkg_cheriot_is_sealed;
		input reg [111:0] in_cap;
		reg result;
		reg [111:0] unused_in_cap;
		begin
			unused_in_cap = in_cap;
			result = in_cap[24-:3] != ibex_cheriot_pkg_OTYPE_UNSEALED;
			ibex_cheriot_pkg_cheriot_is_sealed = result;
		end
	endfunction
	localparam [31:0] ibex_cheriot_pkg_BASE_LO = 0;
	localparam [31:0] ibex_cheriot_pkg_TOP_LO = ibex_cheriot_pkg_BASE_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_CEXP_LO = ibex_cheriot_pkg_TOP_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_LO = ibex_cheriot_pkg_CEXP_LO + ibex_cheriot_pkg_CEXP_W;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_LO = ibex_cheriot_pkg_OTYPE_LO + ibex_cheriot_pkg_OTYPE_W;
	localparam [31:0] ibex_cheriot_pkg_RSVD_LO = ibex_cheriot_pkg_CPERMS_LO + ibex_cheriot_pkg_CPERMS_W;
	function automatic [1:0] ibex_cheriot_pkg_cheriot_compute_corrections;
		input reg [8:0] top;
		input reg [8:0] base;
		input reg [8:0] addr;
		reg top_hi;
		reg addr_hi;
		begin
			top_hi = top < base;
			addr_hi = addr < base;
			ibex_cheriot_pkg_cheriot_compute_corrections = {top_hi ^ addr_hi, addr_hi};
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_mask_loaded_cperms;
		input reg [5:0] cperms_in;
		input reg [2:0] clrperm;
		input reg valid_in;
		input reg sealed;
		reg [5:0] cperms_out;
		reg clr_gl;
		reg clr_lg;
		reg clr_sdlm;
		reg unused_ctag;
		begin
			unused_ctag = clrperm[2];
			clr_gl = clrperm[0] & valid_in;
			clr_lg = (clrperm[0] & valid_in) & ~sealed;
			clr_sdlm = (clrperm[1] & valid_in) & ~sealed;
			cperms_out = cperms_in;
			cperms_out[5] = cperms_in[5] & ~clr_gl;
			if (cperms_in[4:3] == 2'b11) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
				cperms_out[4:2] = (clr_sdlm ? 3'b101 : cperms_in[4:2]);
			end
			else if (cperms_in[4:2] == 3'b101) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			else if (cperms_in[4:0] == 5'b10000)
				cperms_out[4:0] = (clr_sdlm ? 5'h00 : cperms_in[4:0]);
			else if (cperms_in[4:2] == 3'b100) begin
				cperms_out[4] = ~(clr_sdlm & ~cperms_in[1]);
				cperms_out[0] = cperms_in[0] & ~clr_sdlm;
			end
			else if (cperms_in[4:3] == 2'b01) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			ibex_cheriot_pkg_cheriot_mask_loaded_cperms = cperms_out;
		end
	endfunction
	function automatic [8:0] sv2v_cast_1CF2E;
		input reg [8:0] inp;
		sv2v_cast_1CF2E = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_mem_to_cap;
		input reg [32:0] cap_mw;
		input reg [32:0] addr33;
		input reg [2:0] clrperm;
		reg [34:0] cap;
		reg [4:0] exp5;
		reg [5:0] cperms_mem;
		reg [8:0] addrmi9;
		reg sealed;
		reg valid_in;
		begin
			valid_in = cap_mw[32] & addr33[32];
			cap[32] = valid_in & ~clrperm[2];
			cap[8-:ibex_cheriot_pkg_CBOUND_W] = cap_mw[ibex_cheriot_pkg_BASE_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[17-:9] = cap_mw[ibex_cheriot_pkg_TOP_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[21-:4] = cap_mw[ibex_cheriot_pkg_CEXP_LO+:ibex_cheriot_pkg_CEXP_W];
			cap[24-:3] = cap_mw[ibex_cheriot_pkg_OTYPE_LO+:ibex_cheriot_pkg_OTYPE_W];
			sealed = cap[24-:3] != ibex_cheriot_pkg_OTYPE_UNSEALED;
			cperms_mem = cap_mw[ibex_cheriot_pkg_CPERMS_LO+:ibex_cheriot_pkg_CPERMS_W];
			cap[30-:6] = ibex_cheriot_pkg_cheriot_mask_loaded_cperms(cperms_mem, clrperm, cap[32], sealed);
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			addrmi9 = sv2v_cast_1CF2E(addr33[31:0] >> exp5);
			cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(cap[17-:9], cap[8-:ibex_cheriot_pkg_CBOUND_W], addrmi9);
			cap[31] = cap_mw[ibex_cheriot_pkg_RSVD_LO];
			ibex_cheriot_pkg_cheriot_mem_to_cap = cap;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_seal;
		input reg [111:0] in_cap;
		input reg [2:0] new_otype;
		reg [111:0] out_cap;
		begin
			out_cap = in_cap;
			out_cap[24-:3] = new_otype;
			ibex_cheriot_pkg_cheriot_seal = out_cap;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_unseal;
		input reg [111:0] in_cap;
		reg [111:0] out_cap;
		begin
			out_cap = in_cap;
			out_cap[24-:3] = ibex_cheriot_pkg_OTYPE_UNSEALED;
			ibex_cheriot_pkg_cheriot_unseal = out_cap;
		end
	endfunction
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	always @(*) begin : main_ex
		if (_sv2v_0)
			;
		cheriot_rf_we_raw = 1'b0;
		result_data_o = 32'h00000000;
		result_cap_o = ibex_cheriot_pkg_NULL_CAP;
		csc_wcap = ibex_cheriot_pkg_NULL_CAP;
		cheriot_ex_valid_raw = 1'b0;
		cheriot_ex_err_raw = 1'b0;
		cheriot_wb_err_raw = 1'b0;
		csr_access_o = 1'b0;
		csr_addr_o = 5'h00;
		csr_wdata_o = 32'h00000000;
		csr_wcap_o = ibex_cheriot_pkg_NULL_CAP;
		csr_op_o = 5'd0;
		csr_op_en_raw = 1'b0;
		scr_legalization = 1'b0;
		branch_req_raw = 1'b0;
		branch_req_spec_raw = 1'b0;
		csr_set_mie_raw = 1'b0;
		csr_clr_mie_raw = 1'b0;
		branch_target_o = 32'h00000000;
		pcc_cap_o = ibex_cheriot_pkg_NULL_DECODED_CAP;
		tfcap = ibex_cheriot_pkg_NULL_DECODED_CAP;
		lc_cglg = 1'b0;
		lc_csdlm = 1'b0;
		lc_ctag = 1'b0;
		(* full_case, parallel_case *)
		case (1'b1)
			cheriot_operator_i[0]: begin
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
				(* full_case, parallel_case *)
				case (cheriot_cap_field_sel_i)
					3'h0: result_data_o = {20'h00000, rf_fullcap_a[46-:12]};
					3'h1: result_data_o = {28'h0000000, ibex_cheriot_pkg_cheriot_decode_otype(rf_fullcap_a[24-:3], rf_fullcap_a[43])};
					3'h2: result_data_o = rf_fullcap_a[78-:32];
					3'h7: result_data_o = (rf_fullcap_a[111] ? 32'hffffffff : rf_fullcap_a[110:79]);
					3'h3: result_data_o = ibex_cheriot_pkg_cheriot_cap_length(rf_fullcap_a);
					3'h4: result_data_o = {31'h00000000, rf_fullcap_a[32]};
					3'h5: result_data_o = rf_rdata_a;
					3'h6: result_data_o = sv2v_cast_32(ibex_cheriot_pkg_cheriot_cap_to_mem(rf_rcap_a));
					default: result_data_o = 32'h00000000;
				endcase
			end
			cheriot_operator_i[1] | cheriot_operator_i[2]: begin
				result_data_o = rf_rdata_a;
				if (cheriot_operator_i[1])
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(ibex_cheriot_pkg_cheriot_seal(rf_fullcap_a, rf_rdata_b[2:0]));
				else begin
					tfcap = ibex_cheriot_pkg_cheriot_unseal(rf_fullcap_a);
					tfcap[35] = rf_fullcap_a[35] & rf_fullcap_b[35];
					tfcap[30-:6] = ibex_cheriot_pkg_cheriot_compress_perms(tfcap[46-:12]);
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				end
				result_cap_o[32] = (result_cap_o[32] & ~addr_bound_vio) & ~perm_vio;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[3]: begin
				result_data_o = rf_rdata_a;
				tfcap = rf_fullcap_a;
				tfcap[46-:12] = sv2v_cast_12(sv2v_cast_C1AAB(tfcap[46-:12]) & rf_rdata_b[11:0]);
				tfcap[30-:6] = ibex_cheriot_pkg_cheriot_compress_perms(tfcap[46-:12]);
				pmask = sv2v_cast_12(rf_rdata_b[11:0]);
				pmask[0] = 1'b1;
				tfcap[32] = tfcap[32] & (~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) | &sv2v_cast_C1AAB(pmask));
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[16]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = ibex_cheriot_pkg_cheriot_mem_to_cap({1'b0, rf_rdata_b}, {1'b0, rf_rdata_a}, 3'h0);
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			(((cheriot_operator_i[4] | cheriot_operator_i[5]) | cheriot_operator_i[6]) | cheriot_operator_i[21]) | cheriot_operator_i[22]: begin
				result_data_o = addr_result;
				clr_sealed = (cheriot_setaddr_sel_i == 3'h2 ? 1'b0 : ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a));
				tfcap = setaddr1_outcap;
				tfcap[32] = tfcap[32] & ~clr_sealed;
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				instr_fault = (csr_dbg_tclr_fault_i & (rf_fullcap_a[32] | (cheriot_setaddr_sel_i == 3'h2))) & ~result_cap_o[32];
				cheriot_wb_err_raw = instr_fault;
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_ex_valid_raw = 1'b1;
			end
			((((cheriot_operator_i[7] | cheriot_operator_i[9]) | cheriot_operator_i[8]) | cheriot_operator_i[23]) | cheriot_operator_i[24]) | cheriot_operator_i[25]: begin
				tfcap = (cheriot_setbounds_sel_i == 3'h2 ? setbounds_rndn_outcap : setbounds_outcap);
				tfcap[32] = tfcap[32] & ~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
				if (cheriot_setbounds_sel_i == 3'h5) begin
					result_data_o = setbounds_rlen;
					result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				end
				else if (cheriot_setbounds_sel_i == 3'h6) begin
					result_data_o = setbounds_maska;
					result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				end
				else begin
					result_data_o = rf_rdata_a;
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				end
				cheriot_ex_valid_raw = 1'b1;
				instr_fault = ((csr_dbg_tclr_fault_i & rf_fullcap_a[32]) & ~result_cap_o[32]) & ((((cheriot_setbounds_sel_i == 3'h1) || (cheriot_setbounds_sel_i == 3'h3)) || (cheriot_setbounds_sel_i == 3'h4)) || (cheriot_setbounds_sel_i == 3'h2));
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_wb_err_raw = instr_fault;
			end
			cheriot_operator_i[14]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = rf_rcap_a;
				result_cap_o[32] = 1'b0;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[10]: begin
				result_data_o = sv2v_cast_32(((rf_fullcap_a[32] == rf_fullcap_b[32]) && ~addr_bound_vio) && &(rf_fullcap_a[46-:12] | ~rf_fullcap_b[46-:12]));
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[11]: begin
				result_data_o = sv2v_cast_32(ibex_cheriot_pkg_cheriot_caps_equal(rf_fullcap_a, rf_fullcap_b, rf_rdata_a, rf_rdata_b));
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[13]: begin
				result_data_o = rf_rdata_a - rf_rdata_b;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[12]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = rf_rcap_a;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[15]: begin
				lc_cglg = ~rf_fullcap_a[36];
				lc_csdlm = ~rf_fullcap_a[38];
				lc_ctag = ~rf_fullcap_a[41];
				result_data_o = 32'h00000000;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b0;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_ex_err_raw = 1'b0;
			end
			cheriot_operator_i[17]: begin
				result_data_o = 32'h00000000;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b0;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_ex_err_raw = 1'b0;
				csc_wcap = rf_rcap_b;
				csc_wcap[32] = rf_rcap_b[32] & ~perm_vio_slc;
			end
			cheriot_operator_i[18]: begin
				is_write = rf_raddr_a_i != 0;
				instr_fault = perm_vio | illegal_scr_addr;
				csr_access_o = ~instr_fault;
				csr_op_o = 5'd1;
				csr_op_en_raw = ~instr_fault && is_write;
				csr_addr_o = cheriot_cs2_dec_i;
				if (cheriot_cs2_dec_i == ibex_cheriot_pkg_CHERIOT_SCR_MTCC) begin
					scr_legalization = 1'b1;
					csr_wdata_o = {rf_rdata_a[31:2], 2'b00};
					trcap = ibex_cheriot_pkg_cheriot_encode_cap(setaddr1_outcap);
					if (((rf_rdata_a[1:0] != 2'b00) || ~rf_fullcap_a[43]) || (rf_fullcap_a[24-:3] != 0))
						trcap[32] = 1'b0;
					else
						trcap[32] = rf_fullcap_a[32];
					csr_wcap_o = trcap;
				end
				else if (cheriot_cs2_dec_i == ibex_cheriot_pkg_CHERIOT_SCR_MEPCC) begin
					scr_legalization = 1'b1;
					csr_wdata_o = {rf_rdata_a[31:1], 1'b0};
					trcap = ibex_cheriot_pkg_cheriot_encode_cap(setaddr1_outcap);
					if (((rf_rdata_a[0] != 1'b0) || ~rf_fullcap_a[43]) || (rf_fullcap_a[24-:3] != 0))
						trcap[32] = 1'b0;
					else
						trcap[32] = rf_fullcap_a[32];
					csr_wcap_o = trcap;
				end
				else begin
					scr_legalization = 1'b0;
					csr_wdata_o = rf_rdata_a;
					csr_wcap_o = rf_rcap_a;
				end
				result_data_o = csr_rdata_i;
				result_cap_o = csr_rcap_i;
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_wb_err_raw = instr_fault;
			end
			cheriot_operator_i[19] | cheriot_operator_i[20]: begin
				branch_target_o = {addr_result[31:1], 1'b0};
				pcc_cap_o = ibex_cheriot_pkg_cheriot_unseal(rf_fullcap_a);
				result_data_o = pc_id_nxt;
				seal_type = (csr_mstatus_mie_i ? ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD : ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD);
				tfcap = (rf_waddr_i == 5'h01 ? ibex_cheriot_pkg_cheriot_seal(setaddr1_outcap, seal_type) : setaddr1_outcap);
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				instr_fault = perm_vio;
				cheriot_rf_we_raw = ~instr_fault;
				branch_req_raw = ~instr_fault & cheriot_operator_i[19];
				branch_req_spec_raw = ~instr_fault;
				cheriot_wb_err_raw = instr_fault;
				cheriot_ex_err_raw = 1'b0;
				csr_set_mie_raw = (~instr_fault && cheriot_operator_i[19]) && ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD));
				csr_clr_mie_raw = (~instr_fault && cheriot_operator_i[19]) && ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD));
				cheriot_ex_valid_raw = 1'b1;
			end
			default:
				;
		endcase
	end
	assign is_load_cap = cheriot_operator_i[15];
	assign is_store_cap = cheriot_operator_i[17];
	assign is_cap = cheriot_operator_i[15] | cheriot_operator_i[17];
	generate
		if (WritebackStage) begin : gen_lsu_req_wb_stage
			wire unused_instr_first_cycle;
			assign unused_instr_first_cycle = instr_first_cycle_i;
			assign cheriot_lsu_req = is_cap & cheriot_exec_id_i;
		end
		else begin : gen_lsu_req_no_wb_stage
			assign cheriot_lsu_req = (is_cap & cheriot_exec_id_i) & instr_first_cycle_i;
		end
	endgenerate
	assign cheriot_lsu_we = is_store_cap;
	assign cheriot_lsu_addr = cs1_addr_plusimm + {29'h00000000, addr_incr_req_i, 2'b00};
	assign cheriot_lsu_is_cap = is_cap;
	assign cheriot_lsu_wdata = (is_store_cap ? rf_rdata_b : 32'h00000000);
	assign cheriot_lsu_wcap = (is_store_cap ? csc_wcap : ibex_cheriot_pkg_NULL_CAP);
	assign cs1_imm = (is_cap | cheriot_operator_i[19] ? {{20 {cheriot_imm12_i[11]}}, cheriot_imm12_i} : {32 {1'sb0}});
	assign cs1_addr_plusimm = rf_rdata_a + cs1_imm;
	assign pc_id_nxt = pc_id_i + (instr_is_compressed_i ? 32'd2 : 32'd4);
	always @(*) begin : shared_adder
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (cheriot_adder_a_sel_i)
			3'h1: tmp32a = {{20 {cheriot_imm12_i[11]}}, cheriot_imm12_i};
			3'h2: tmp32a = {{11 {cheriot_imm21_i[20]}}, cheriot_imm21_i};
			3'h3: tmp32a = {cheriot_imm20_i[19], cheriot_imm20_i, 11'h000};
			3'h4: tmp32a = rf_rdata_b;
			default: tmp32a = 32'h00000000;
		endcase
		(* full_case, parallel_case *)
		case (cheriot_adder_b_sel_i)
			2'h1: tmp32b = rf_rdata_a;
			2'h2: tmp32b = pc_id_i;
			default: tmp32b = 32'h00000000;
		endcase
		addr_result = tmp32a + tmp32b;
	end
	function automatic [111:0] ibex_cheriot_pkg_cheriot_set_address;
		input reg [111:0] in_cap;
		input reg [31:0] newptr;
		reg [111:0] out_cap;
		reg [4:0] exp5;
		reg [32:0] ptr_minus_base;
		reg [8:0] unused_ptr_minus_base;
		reg [23:0] high_delta;
		reg [23:0] repr_mask;
		reg [8:0] ptr_mantissa;
		begin
			out_cap = in_cap;
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(in_cap[21-:4]);
			repr_mask = {24 {1'b1}} << exp5;
			ptr_minus_base = {1'b0, newptr} - {1'b0, in_cap[78-:32]};
			unused_ptr_minus_base = ptr_minus_base[8:0];
			high_delta = ptr_minus_base[32:ibex_cheriot_pkg_CBOUND_W] & repr_mask;
			if (high_delta != 0)
				out_cap[32] = 1'b0;
			ptr_mantissa = sv2v_cast_1CF2E(newptr >> exp5);
			out_cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(out_cap[17-:9], out_cap[8-:ibex_cheriot_pkg_CBOUND_W], ptr_mantissa);
			ibex_cheriot_pkg_cheriot_set_address = out_cap;
		end
	endfunction
	always @(*) begin : set_address_comb
		if (_sv2v_0)
			;
		if (cheriot_setaddr_sel_i == 3'h1) begin
			tfcap1 = pcc_cap_i;
			taddr1 = pc_id_nxt;
		end
		else if (cheriot_setaddr_sel_i == 3'h2) begin
			tfcap1 = pcc_cap_i;
			taddr1 = addr_result;
		end
		else if (cheriot_setaddr_sel_i == 3'h3) begin
			tfcap1 = rf_fullcap_a;
			taddr1 = addr_result;
		end
		else if ((cheriot_setaddr_sel_i == 3'h4) && scr_legalization) begin
			tfcap1 = rf_fullcap_a;
			taddr1 = csr_wdata_o;
		end
		else begin
			tfcap1 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			taddr1 = 32'h00000000;
		end
		setaddr1_outcap = ibex_cheriot_pkg_cheriot_set_address(tfcap1, taddr1);
	end
	reg [55:0] bound_req;
	function automatic [5:0] ibex_cheriot_pkg_cheriot_thermometer_count;
		input reg [31:0] a32;
		reg [5:0] count;
		reg [15:0] b32;
		begin
			if (a32[31])
				count = 6'd32;
			else begin
				count[5] = 1'b0;
				count[4] = a32[15];
				b32[15:0] = (count[4] ? a32[31:16] : a32[15:0]);
				count[3] = b32[7];
				b32[7:0] = (count[3] ? b32[15:8] : b32[7:0]);
				count[2] = b32[3];
				b32[3:0] = (count[2] ? b32[7:4] : b32[3:0]);
				count[1] = b32[1];
				b32[1:0] = (count[1] ? b32[3:2] : b32[1:0]);
				count[0] = b32[0];
			end
			ibex_cheriot_pkg_cheriot_thermometer_count = count;
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_count_trailing_zeros;
		input reg [31:0] din;
		reg [5:0] count;
		reg [31:0] a32;
		reg signed [31:0] i;
		begin
			a32 = {31'h00000000, din[0]};
			for (i = 1; i < 32; i = i + 1)
				a32[i] = a32[i - 1] | din[i];
			count = ibex_cheriot_pkg_cheriot_thermometer_count(~a32);
			ibex_cheriot_pkg_cheriot_count_trailing_zeros = count;
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_msb_position;
		input reg [31:0] din;
		reg [5:0] count;
		reg [31:0] a32;
		reg signed [31:0] i;
		begin
			a32 = {din[31], 31'h00000000};
			for (i = 30; i >= 0; i = i - 1)
				a32[i] = a32[i + 1] | din[i];
			count = ibex_cheriot_pkg_cheriot_thermometer_count(a32);
			ibex_cheriot_pkg_cheriot_msb_position = count;
		end
	endfunction
	function automatic [5:0] sv2v_cast_6;
		input reg [5:0] inp;
		sv2v_cast_6 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_7548C;
		input reg [4:0] inp;
		sv2v_cast_7548C = inp;
	endfunction
	function automatic [55:0] ibex_cheriot_pkg_cheriot_prep_bounds;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [31:0] length;
		reg [55:0] result;
		reg [5:0] size_result;
		reg [111:0] unused_in_cap;
		begin
			unused_in_cap = in_cap;
			result[55-:33] = {1'b0, addr} + {1'b0, length};
			result[6-:6] = ibex_cheriot_pkg_cheriot_count_trailing_zeros(addr);
			result[12-:6] = ibex_cheriot_pkg_cheriot_msb_position({9'h000, length[31:9]});
			size_result = result[12-:6];
			result[22-:5] = (size_result >= sv2v_cast_6(ibex_cheriot_pkg_MAXCEXP) ? sv2v_cast_7548C(ibex_cheriot_pkg_MAXEXP) : sv2v_cast_7548C(size_result));
			size_result = size_result + 6'd1;
			result[17-:5] = (size_result >= sv2v_cast_6(ibex_cheriot_pkg_MAXCEXP) ? sv2v_cast_7548C(ibex_cheriot_pkg_MAXEXP) : sv2v_cast_7548C(size_result));
			result[0] = ~((result[55-:33] > in_cap[111-:33]) || (addr < in_cap[78-:32]));
			ibex_cheriot_pkg_cheriot_prep_bounds = result;
		end
	endfunction
	function automatic [3:0] ibex_cheriot_pkg_cheriot_compress_exp;
		input reg [4:0] exp5;
		ibex_cheriot_pkg_cheriot_compress_exp = (exp5 == ibex_cheriot_pkg_MAXEXP ? ibex_cheriot_pkg_MAXCEXP : exp5[3:0]);
	endfunction
	function automatic [9:0] sv2v_cast_3DB00;
		input reg [9:0] inp;
		sv2v_cast_3DB00 = inp;
	endfunction
	function automatic [175:0] ibex_cheriot_pkg_cheriot_set_bounds_ex;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [55:0] bound_req;
		input reg req_exact;
		reg [175:0] result;
		reg [111:0] out_cap;
		reg [55:0] unused_bound_req;
		reg [4:0] exp1;
		reg [4:0] exp2;
		reg [4:0] exp_sel;
		reg [32:0] top33req;
		reg [ibex_cheriot_pkg_CBOUND_W:0] base1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] base2;
		reg [ibex_cheriot_pkg_CBOUND_W:0] top1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] top2;
		reg [ibex_cheriot_pkg_CBOUND_W:0] len1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] len2;
		reg [32:0] mask1;
		reg [32:0] mask2;
		reg ovrflw;
		reg topoff1;
		reg topoff2;
		reg topoff;
		reg baseoff1;
		reg baseoff2;
		reg baseoff;
		reg tophi1;
		reg tophi2;
		reg tophi;
		reg in_bound;
		begin
			unused_bound_req = bound_req;
			out_cap = in_cap;
			top33req = bound_req[55-:33];
			exp1 = bound_req[22-:5];
			exp2 = bound_req[17-:5];
			in_bound = bound_req[0];
			mask1 = {33 {1'b1}} << exp1;
			base1 = sv2v_cast_3DB00(addr >> exp1);
			topoff1 = |(top33req & ~mask1);
			baseoff1 = |({1'b0, addr} & ~mask1);
			top1 = sv2v_cast_3DB00(top33req >> exp1) + sv2v_cast_3DB00(topoff1);
			len1 = top1 - base1;
			tophi1 = top1[8:0] >= base1[8:0];
			ovrflw = len1[9];
			mask2 = {33 {1'b1}} << exp2;
			base2 = sv2v_cast_3DB00(addr >> exp2);
			topoff2 = |(top33req & ~mask2);
			baseoff2 = |({1'b0, addr} & ~mask2);
			top2 = sv2v_cast_3DB00(top33req >> exp2) + sv2v_cast_3DB00(topoff2);
			len2 = top2 - base2;
			tophi2 = top2[8:0] >= base2[8:0];
			if (~ovrflw) begin
				exp_sel = exp1;
				out_cap[17-:9] = top1[8:0];
				out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = base1[8:0];
				result[63-:32] = mask1[31:0];
				result[31-:32] = {22'h000000, len1} << exp1;
				topoff = topoff1;
				baseoff = baseoff1;
				tophi = tophi1;
			end
			else begin
				exp_sel = exp2;
				out_cap[17-:9] = top2[8:0];
				out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = base2[8:0];
				result[63-:32] = mask2[31:0];
				result[31-:32] = {22'h000000, len2} << exp2;
				topoff = topoff2;
				baseoff = baseoff2;
				tophi = tophi2;
			end
			out_cap[21-:4] = ibex_cheriot_pkg_cheriot_compress_exp(exp_sel);
			out_cap[34-:2] = (tophi ? 2'b00 : 2'b10);
			if (req_exact & (topoff | baseoff))
				out_cap[32] = 1'b0;
			if (~in_bound)
				out_cap[32] = 1'b0;
			result[175-:112] = out_cap;
			ibex_cheriot_pkg_cheriot_set_bounds_ex = result;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_set_bounds_rounddown;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [55:0] bound_req;
		reg [111:0] out_cap;
		reg [55:0] unused_bound_req;
		reg [ibex_cheriot_pkg_EXP_W:0] explen;
		reg [ibex_cheriot_pkg_EXP_W:0] expb;
		reg [ibex_cheriot_pkg_EXP_W:0] exp_final;
		reg [32:0] top33req;
		reg in_bound;
		reg el_gt_eb;
		reg el_gt_14;
		reg eb_gt_14;
		reg tophi;
		begin
			unused_bound_req = bound_req;
			out_cap = in_cap;
			top33req = bound_req[55-:33];
			explen = bound_req[12-:6];
			expb = bound_req[6-:6];
			in_bound = bound_req[0];
			el_gt_eb = explen > expb;
			el_gt_14 = explen > 14;
			eb_gt_14 = expb > 14;
			exp_final = (el_gt_eb & !eb_gt_14 ? expb : (el_gt_14 ? 6'd14 : explen));
			out_cap[21-:4] = ibex_cheriot_pkg_cheriot_compress_exp(exp_final[4:0]);
			out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = sv2v_cast_1CF2E(addr >> exp_final);
			out_cap[17-:9] = (el_gt_eb | el_gt_14 ? out_cap[8-:ibex_cheriot_pkg_CBOUND_W] - sv2v_cast_1CF2E(1'b1) : sv2v_cast_1CF2E(top33req >> exp_final));
			if (~in_bound)
				out_cap[32] = 1'b0;
			tophi = out_cap[17-:9] >= out_cap[8-:ibex_cheriot_pkg_CBOUND_W];
			out_cap[34-:2] = (tophi ? 2'b00 : 2'b10);
			ibex_cheriot_pkg_cheriot_set_bounds_rounddown = out_cap;
		end
	endfunction
	always @(*) begin : set_bounds_comb
		if (_sv2v_0)
			;
		if ((cheriot_setbounds_sel_i == 3'h5) || (cheriot_setbounds_sel_i == 3'h6)) begin
			newlen = rf_rdata_a;
			req_exact = 1'b0;
			tfcap3 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			tmp_addr = 32'h00000000;
		end
		else if (cheriot_setbounds_sel_i == 3'h4) begin
			newlen = sv2v_cast_32(cheriot_imm12_i);
			req_exact = 1'b0;
			tfcap3 = rf_fullcap_a;
			tmp_addr = rf_rdata_a;
		end
		else if (cheriot_setbounds_sel_i != 3'h0) begin
			newlen = rf_rdata_b;
			req_exact = cheriot_setbounds_sel_i == 3'h3;
			tfcap3 = rf_fullcap_a;
			tmp_addr = rf_rdata_a;
		end
		else begin
			newlen = 32'h00000000;
			req_exact = 1'b0;
			tfcap3 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			tmp_addr = 32'h00000000;
		end
		bound_req = ibex_cheriot_pkg_cheriot_prep_bounds(tfcap3, tmp_addr, newlen);
		setbounds_result = ibex_cheriot_pkg_cheriot_set_bounds_ex(tfcap3, tmp_addr, bound_req, req_exact);
		setbounds_outcap = setbounds_result[175-:112];
		setbounds_maska = setbounds_result[63-:32];
		setbounds_rlen = setbounds_result[31-:32];
		setbounds_rndn_outcap = ibex_cheriot_pkg_cheriot_set_bounds_rounddown(tfcap3, tmp_addr, bound_req);
	end
	wire [31:0] rv32_ls_chkaddr;
	assign rv32_ls_chkaddr = rv32_lsu_addr_i;
	localparam [2:0] ibex_cheriot_pkg_PVIO_LD = 3'h3;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SD = 3'h4;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SEAL = 3'h1;
	localparam [2:0] ibex_cheriot_pkg_PVIO_TAG = 3'h0;
	always @(*) begin : check_rv32
		if (_sv2v_0)
			;
		rv32_base_chkaddr = rv32_ls_chkaddr;
		if (rv32_lsu_type_i == 2'b00) begin
			rv32_top_offset = 32'h00000004;
			rv32_top_size_ok = |rf_fullcap_a[111:81];
		end
		else if (rv32_lsu_type_i == 2'b01) begin
			rv32_top_offset = 32'h00000002;
			rv32_top_size_ok = |rf_fullcap_a[111:80];
		end
		else begin
			rv32_top_offset = 32'h00000001;
			rv32_top_size_ok = |rf_fullcap_a[111:79];
		end
		rv32_top_chkaddr = {1'b0, rv32_base_chkaddr};
		rv32_top_bound = rf_fullcap_a[111-:33] - {1'b0, rv32_top_offset};
		rv32_base_bound = rf_fullcap_a[78-:32];
		rv32_top_vio = (rv32_top_chkaddr > rv32_top_bound) || ~rv32_top_size_ok;
		rv32_base_vio = rv32_base_chkaddr < rv32_base_bound;
		addr_bound_vio_rv32 = (rv32_top_vio | rv32_base_vio) & ~addr_incr_req_i;
		perm_vio_vec_rv32 = 1'sb0;
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_LD] = ~rv32_lsu_we_i && ~rf_fullcap_a[40];
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_SD] = rv32_lsu_we_i && ~rf_fullcap_a[37];
		perm_vio_rv32 = |perm_vio_vec_rv32;
	end
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign rv32_lsu_err = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~debug_mode_i) & (addr_bound_vio_rv32 | perm_vio_rv32);
	wire [31:0] cheriot_ls_chkaddr;
	assign cheriot_ls_chkaddr = cs1_addr_plusimm;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_II_FWD = 3'd1;
	localparam [2:0] ibex_cheriot_pkg_PVIO_ALIGN = 3'h7;
	localparam [2:0] ibex_cheriot_pkg_PVIO_ASR = 3'h6;
	localparam [2:0] ibex_cheriot_pkg_PVIO_EX = 3'h2;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SC = 3'h5;
	always @(*) begin : check_cheriot
		if (_sv2v_0)
			;
		if (cheriot_operator_i[1])
			chk_base_chkaddr = rf_rdata_b;
		else if (cheriot_operator_i[2])
			chk_base_chkaddr = {28'h0000000, ibex_cheriot_pkg_cheriot_decode_otype(rf_fullcap_a[24-:3], rf_fullcap_a[43])};
		else if (cheriot_operator_i[10])
			chk_base_chkaddr = rf_fullcap_b[78-:32];
		else
			chk_base_chkaddr = cheriot_ls_chkaddr;
		if (cheriot_operator_i[10])
			chk_top_chkaddr = rf_fullcap_b[111-:33];
		else if (is_cap)
			chk_top_chkaddr = {1'b0, chk_base_chkaddr[31:3], 3'b000};
		else
			chk_top_chkaddr = {1'b0, chk_base_chkaddr};
		if (cheriot_operator_i[1] | cheriot_operator_i[2]) begin
			chk_top_bound = rf_fullcap_b[111-:33];
			chk_base_bound = rf_fullcap_b[78-:32];
		end
		else if (is_cap) begin
			chk_top_bound = {rf_fullcap_a[111:82], 3'b000};
			chk_base_bound = rf_fullcap_a[78-:32];
		end
		else begin
			chk_top_bound = rf_fullcap_a[111-:33];
			chk_base_bound = rf_fullcap_a[78-:32];
		end
		chk_top_vio = chk_top_chkaddr > chk_top_bound;
		chk_base_vio = chk_base_chkaddr < chk_base_bound;
		chk_top_equal = chk_top_chkaddr == chk_top_bound;
		if (debug_mode_i)
			addr_bound_vio = 1'b0;
		else if (is_cap)
			addr_bound_vio = (chk_top_vio | chk_base_vio) | chk_top_equal;
		else if (cheriot_operator_i[10])
			addr_bound_vio = chk_top_vio | chk_base_vio;
		else if (cheriot_operator_i[1] | cheriot_operator_i[2])
			addr_bound_vio = (chk_top_vio | chk_base_vio) | chk_top_equal;
		else
			addr_bound_vio = 1'b0;
		perm_vio_vec = 1'sb0;
		perm_vio = 0;
		perm_vio_slc = 0;
		chk_cs2_bad_type = 1'b0;
		illegal_scr_addr = 1'b0;
		chk_cs1_otype_0 = rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_UNSEALED;
		chk_cs1_otype_1 = rf_fullcap_a[43] & (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_II_FWD);
		chk_cs1_otype_23 = rf_fullcap_a[43] & ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD));
		chk_cs1_otype_45 = rf_fullcap_a[43] & ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD));
		if (is_load_cap) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
			perm_vio_vec[ibex_cheriot_pkg_PVIO_LD] = ~rf_fullcap_a[40];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] = cheriot_ls_chkaddr[2:0] != 0;
		end
		else if (is_store_cap) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SD] = ~rf_fullcap_a[37];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SC] = ~rf_fullcap_a[41] && rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] = cheriot_ls_chkaddr[2:0] != 0;
			perm_vio_slc = (~rf_fullcap_a[39] && rf_fullcap_b[32]) && ~rf_fullcap_b[35];
		end
		else if (cheriot_operator_i[1]) begin
			chk_cs2_bad_type = (rf_fullcap_a[43] ? (rf_rdata_b[31:3] != 0) || (rf_rdata_b[2:0] == 0) : |rf_rdata_b[31:4] || (rf_rdata_b[3:0] <= 8));
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ((ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) || ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_b)) || ~rf_fullcap_b[45]) || chk_cs2_bad_type;
		end
		else if (cheriot_operator_i[2]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = (~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) || ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_b)) || ~rf_fullcap_b[44];
		end
		else if (cheriot_operator_i[19]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = (ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) && (cheriot_imm12_i != 0)) || ~((((((rf_waddr_i == 0) && (rf_raddr_a_i == 5'h01)) && chk_cs1_otype_45) || (((rf_waddr_i == 0) && (rf_raddr_a_i != 5'h01)) && (chk_cs1_otype_0 || chk_cs1_otype_1))) || ((rf_waddr_i == 5'h01) && (chk_cs1_otype_0 | chk_cs1_otype_23))) || ((rf_waddr_i != 0) && (chk_cs1_otype_0 | chk_cs1_otype_1)));
			perm_vio_vec[ibex_cheriot_pkg_PVIO_EX] = ~rf_fullcap_a[43];
		end
		else if (cheriot_operator_i[18]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ASR] = ~pcc_cap_i[42];
			illegal_scr_addr = ((csr_addr_o < 24) | (csr_addr_o == 27)) | (~debug_mode_i & (csr_addr_o < 28));
		end
		else
			perm_vio_vec = 1'sb0;
		perm_vio = |perm_vio_vec;
	end
	assign cheriot_lsu_err = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~debug_mode_i) & ((addr_bound_vio | perm_vio) | (csr_dbg_tclr_fault_i & perm_vio_slc));
	reg ls_addr_misaligned_only;
	assign cheriot_ex_err_info_o = 12'h000;
	assign cheriot_wb_err_info_o = cheriot_wb_err_info_q;
	assign cheriot_wb_err_d = ((cheriot_wb_err_raw & cheriot_exec_id_i) & cheriot_ex_valid_raw) & ~debug_mode_i;
	wire addr_bound_vio_ext;
	wire [32:0] cheriot_top_chkaddr_ext;
	assign cheriot_top_chkaddr_ext = cheriot_ls_chkaddr + 33'd8;
	assign addr_bound_vio_ext = (is_cap ? addr_bound_vio | (cheriot_top_chkaddr_ext > rf_fullcap_a[111-:33]) : addr_bound_vio);
	function automatic [4:0] ibex_cheriot_pkg_cheriot_violation_cause;
		input reg bound_vio;
		input reg [7:0] perm_vio_vec;
		reg [4:0] vio_cause;
		reg unused_align_vio;
		begin
			unused_align_vio = perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN];
			if (perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG])
				vio_cause = 5'h02;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL])
				vio_cause = 5'h03;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_EX])
				vio_cause = 5'h11;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_LD])
				vio_cause = 5'h12;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SD])
				vio_cause = 5'h13;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SC])
				vio_cause = 5'h15;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_ASR])
				vio_cause = 5'h18;
			else if (bound_vio)
				vio_cause = 5'h01;
			else
				vio_cause = 5'h00;
			ibex_cheriot_pkg_cheriot_violation_cause = vio_cause;
		end
	endfunction
	always @(*) begin : err_cause_comb
		if (_sv2v_0)
			;
		cheriot_err_cause = ibex_cheriot_pkg_cheriot_violation_cause(addr_bound_vio_ext, perm_vio_vec);
		rv32_err_cause = ibex_cheriot_pkg_cheriot_violation_cause(addr_bound_vio_rv32, perm_vio_vec_rv32);
		ls_addr_misaligned_only = (perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] && (perm_vio_vec[6:0] == 0)) && ~addr_bound_vio_ext;
		if (((cheriot_operator_i[18] & cheriot_wb_err_raw) & illegal_scr_addr) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = 16'h1000;
		else if ((cheriot_operator_i[18] & cheriot_wb_err_raw) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {6'h01, cheriot_cs2_dec_i, cheriot_err_cause};
		else if (cheriot_wb_err_raw & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {6'h00, rf_raddr_a_i, cheriot_err_cause};
		else if (((is_load_cap | is_store_cap) & cheriot_lsu_err) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {4'h0, ls_addr_misaligned_only, 1'b0, rf_raddr_a_i, cheriot_err_cause};
		else if (rv32_lsu_req_i & rv32_lsu_err)
			cheriot_wb_err_info_d = {6'h00, rf_raddr_a_i, rv32_err_cause};
		else
			cheriot_wb_err_info_d = cheriot_wb_err_info_q;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			cheriot_wb_err_q <= 1'b0;
			cheriot_wb_err_info_q <= 1'sb0;
		end
		else begin
			cheriot_wb_err_q <= cheriot_wb_err_d;
			cheriot_wb_err_info_q <= cheriot_wb_err_info_d;
		end
	assign lsu_req_o = (instr_is_cheriot_i ? cheriot_lsu_req : rv32_lsu_req_i);
	assign cpu_lsu_cheriot_err = (instr_is_cheriot_i ? cheriot_lsu_err : rv32_lsu_err);
	assign cpu_lsu_addr = (instr_is_cheriot_i ? cheriot_lsu_addr : rv32_lsu_addr_i);
	assign cpu_lsu_we = (instr_is_cheriot_i ? cheriot_lsu_we : rv32_lsu_we_i);
	assign cpu_lsu_wdata = (instr_is_cheriot_i ? cheriot_lsu_wdata : rv32_lsu_wdata_i);
	assign cpu_lsu_is_cap = instr_is_cheriot_i & cheriot_lsu_is_cap;
	assign lsu_cheriot_err_o = cpu_lsu_cheriot_err;
	assign lsu_we_o = cpu_lsu_we;
	assign lsu_addr_o = cpu_lsu_addr;
	assign lsu_wdata_o = cpu_lsu_wdata;
	assign lsu_is_cap_o = cpu_lsu_is_cap;
	assign lsu_lc_clrperm_o = (instr_is_cheriot_i ? cheriot_lsu_lc_clrperm : {3 {1'sb0}});
	assign lsu_type_o = (~instr_is_cheriot_i ? rv32_lsu_type_i : 2'b00);
	assign lsu_wcap_o = (instr_is_cheriot_i ? cheriot_lsu_wcap : ibex_cheriot_pkg_NULL_CAP);
	assign lsu_sign_ext_o = (~instr_is_cheriot_i ? rv32_lsu_sign_ext_i : 1'b0);
	assign rv32_addr_incr_req_o = ((cheriot_enable_i != ibex_pkg_IbexMuBiOn) | instr_is_rv32lsu_i ? addr_incr_req_i : 1'b0);
	assign rv32_addr_last_o = addr_last_i;
	assign csr_mshwm_set_o = (((lsu_req_o & ~lsu_cheriot_err_o) & lsu_we_o) & (lsu_addr_o[31:4] >= csr_mshwmb_i[31:4])) & (lsu_addr_o[31:4] < csr_mshwm_i[31:4]);
	assign csr_mshwm_new_o = {lsu_addr_o[31:4], 4'h0};
	wire unused_dbg_status;
	wire unused_dbg_cs1_vec;
	wire unused_dbg_cs2_vec;
	wire unused_dbg_cd_vec;
	assign unused_dbg_status = |{instr_is_rv32lsu_i, rv32_lsu_req_i, rv32_lsu_we_i, rv32_lsu_err, cheriot_exec_id_i, cheriot_lsu_err, rf_fullcap_a[32], result_cap_o[32], addr_bound_vio, perm_vio, addr_bound_vio_rv32, perm_vio_rv32};
	assign unused_dbg_cs1_vec = |{rf_fullcap_a[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(rf_fullcap_a[21-:4]), rf_fullcap_a[17-:9], rf_fullcap_a[8-:ibex_cheriot_pkg_CBOUND_W], rf_fullcap_a[24-:3], rf_fullcap_a[30-:6], rf_rdata_a};
	assign unused_dbg_cs2_vec = |{rf_fullcap_b[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(rf_fullcap_b[21-:4]), rf_fullcap_b[17-:9], rf_fullcap_b[8-:ibex_cheriot_pkg_CBOUND_W], rf_fullcap_b[24-:3], rf_fullcap_b[30-:6], rf_rdata_b};
	assign unused_dbg_cd_vec = |{result_cap_o[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(result_cap_o[21-:4]), result_cap_o[17-:9], result_cap_o[8-:ibex_cheriot_pkg_CBOUND_W], result_cap_o[24-:3], result_cap_o[30-:6], result_data_o};
	wire unused_cheriot_ex_signals;
	assign unused_cheriot_ex_signals = |{instr_valid_i, csr_mshwm_i[3:0], csr_mshwmb_i[3:0], cheriot_wb_err_q};
	initial _sv2v_0 = 0;
endmodule
module ibex_compressed_decoder (
	clk_i,
	rst_ni,
	valid_i,
	id_in_ready_i,
	instr_i,
	cheriot_enable_i,
	instr_o,
	is_compressed_o,
	gets_expanded_o,
	flush_expanded_i,
	illegal_instr_o
);
	reg _sv2v_0;
	parameter integer RV32ZC = 32'sd3;
	parameter [0:0] ResetAll = 1'b0;
	parameter integer BaseIsa = 32'sd1;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	input wire id_in_ready_i;
	input wire [31:0] instr_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output wire [1:0] gets_expanded_o;
	input wire flush_expanded_i;
	output reg illegal_instr_o;
	generate
		if (!((RV32ZC == 32'sd3) || (RV32ZC == 32'sd2))) begin : gen_unused_valid
			wire unused_valid;
			wire unused_id_in_ready;
			assign unused_valid = valid_i;
			assign unused_id_in_ready = id_in_ready_i;
		end
	endgenerate
	function automatic [6:0] cm_stack_adj_base;
		input reg [3:0] rlist;
		(* full_case, parallel_case *)
		case (rlist)
			4'd4, 4'd5, 4'd6, 4'd7: cm_stack_adj_base = 7'd16;
			4'd8, 4'd9, 4'd10, 4'd11: cm_stack_adj_base = 7'd32;
			4'd12, 4'd13, 4'd14: cm_stack_adj_base = 7'd48;
			4'd15: cm_stack_adj_base = 7'd64;
			default: cm_stack_adj_base = 7'd0;
		endcase
	endfunction
	function automatic [6:0] cm_stack_adj;
		input reg [3:0] rlist;
		input reg [1:0] spimm;
		cm_stack_adj = cm_stack_adj_base(rlist) + (spimm * 16);
	endfunction
	function automatic [4:0] cm_stack_adj_word;
		input reg [3:0] rlist;
		input reg [1:0] spimm;
		reg [6:0] tmp;
		reg [1:0] unused_tmp;
		begin
			tmp = cm_stack_adj(rlist, spimm);
			unused_tmp = tmp[1:0];
			cm_stack_adj_word = tmp[6:2];
		end
	endfunction
	function automatic [4:0] cm_rlist_top_reg;
		input reg [4:0] rlist;
		(* full_case, parallel_case *)
		case (rlist)
			5'd16, 5'd15, 5'd14, 5'd13, 5'd12, 5'd11, 5'd10, 5'd9, 5'd8, 5'd7: cm_rlist_top_reg = 5'd11 + rlist;
			5'd6, 5'd5: cm_rlist_top_reg = 5'd3 + rlist;
			5'd4: cm_rlist_top_reg = 5'd1;
			default: cm_rlist_top_reg = 5'd0;
		endcase
	endfunction
	function automatic [31:0] cm_push_store_reg;
		input reg [4:0] rlist;
		input reg [4:0] sp_offset;
		reg [11:0] neg_offset;
		reg signed [11:0] neg_offset_signed;
		reg [31:0] instr;
		begin
			neg_offset_signed = -$signed({5'b00000, sp_offset, 2'b00});
			neg_offset = $unsigned(neg_offset_signed);
			instr[6:0] = 7'h23;
			instr[11:7] = neg_offset[4:0];
			instr[14:12] = 3'b010;
			instr[19:15] = 5'd2;
			instr[24:20] = cm_rlist_top_reg(rlist);
			instr[31:25] = neg_offset[11:5];
			cm_push_store_reg = instr;
		end
	endfunction
	function automatic [31:0] cm_pop_load_reg;
		input reg [4:0] rlist;
		input reg [4:0] sp_offset;
		reg [31:0] instr;
		begin
			instr[6:0] = 7'h03;
			instr[11:7] = cm_rlist_top_reg(rlist);
			instr[14:12] = 3'b010;
			instr[19:15] = 5'd2;
			instr[31:20] = {5'b00000, sp_offset, 2'b00};
			cm_pop_load_reg = instr;
		end
	endfunction
	function automatic [31:0] cm_sp_addi;
		input reg [3:0] rlist;
		input reg [1:0] spimm;
		input reg decr;
		reg [11:0] imm;
		reg signed [11:0] imm_signed;
		reg [31:0] instr;
		begin
			decr = 1'b0;
			imm[11:7] = 1'sb0;
			imm[6:0] = cm_stack_adj(rlist, spimm);
			imm_signed = (decr ? -$signed(imm) : $signed(imm));
			instr[6:0] = 7'h13;
			instr[11:7] = 5'd2;
			instr[14:12] = 3'b000;
			instr[19:15] = 5'd2;
			instr[31:20] = $unsigned(imm_signed);
			cm_sp_addi = instr;
		end
	endfunction
	function automatic [31:0] cm_mv_reg;
		input reg [4:0] src;
		input reg [4:0] dst;
		reg [31:0] instr;
		begin
			instr[6:0] = 7'h13;
			instr[11:7] = dst;
			instr[14:12] = 3'b000;
			instr[19:15] = src;
			instr[31:20] = 12'd0;
			cm_mv_reg = instr;
		end
	endfunction
	function automatic [31:0] cm_zero_a0;
		input reg _sv2v_unused;
		cm_zero_a0 = cm_mv_reg(5'd0, 5'd10);
	endfunction
	function automatic [31:0] cm_ret_ra;
		input reg _sv2v_unused;
		reg [31:0] instr;
		begin
			instr[6:0] = 7'h67;
			instr[11:7] = 5'd0;
			instr[14:12] = 3'b000;
			instr[19:15] = 5'd1;
			instr[31:20] = 12'd0;
			cm_ret_ra = instr;
		end
	endfunction
	function automatic [31:0] cm_mvsa01;
		input reg a01;
		input reg [2:0] rs;
		reg [4:0] src;
		reg [4:0] dst;
		begin
			src = 5'd10 + {4'd0, a01};
			dst = {rs[2:1] > 2'd0, rs[2:1] == 2'd0, rs[2:0]};
			cm_mvsa01 = cm_mv_reg(src, dst);
		end
	endfunction
	function automatic [31:0] cm_mva01s;
		input reg [2:0] rs;
		input reg a01;
		reg [4:0] src;
		reg [4:0] dst;
		begin
			src = {rs[2:1] > 2'd0, rs[2:1] == 2'd0, rs[2:0]};
			dst = 5'd10 + {4'd0, a01};
			cm_mva01s = cm_mv_reg(src, dst);
		end
	endfunction
	function automatic [4:0] cm_rlist_init;
		input reg [3:0] instr_rlist;
		reg [4:0] rlist;
		begin
			rlist = {1'b0, instr_rlist};
			if (rlist == 5'd15)
				rlist = 5'd16;
			cm_rlist_init = rlist;
		end
	endfunction
	reg [4:0] cm_rlist_d;
	reg [4:0] cm_rlist_q;
	reg [4:0] cm_sp_offset_d;
	reg [4:0] cm_sp_offset_q;
	reg [2:0] cm_state_d;
	reg [2:0] cm_state_q;
	reg [1:0] gets_expanded;
	generate
		if ((RV32ZC == 32'sd3) || (RV32ZC == 32'sd2)) begin : gen_gets_expanded
			assign gets_expanded_o = (valid_i ? gets_expanded : 2'd0);
		end
		else begin : gen_gets_expanded
			assign gets_expanded_o = gets_expanded;
		end
	endgenerate
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	always @(*) begin
		if (_sv2v_0)
			;
		instr_o = instr_i;
		illegal_instr_o = 1'b0;
		gets_expanded = 2'd0;
		cm_rlist_d = cm_rlist_q;
		cm_sp_offset_d = cm_sp_offset_q;
		cm_state_d = cm_state_q;
		(* full_case, parallel_case *)
		case (instr_i[1:0])
			2'b00:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h045, instr_i[4:2], 7'h5b};
						else
							instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h041, instr_i[4:2], 7'h13};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], 7'h03};
					3'b011:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12:10], 5'b00001, instr_i[9:7], 5'b01101, instr_i[4:2], 7'h03};
						else begin
							instr_o = instr_i;
							illegal_instr_o = 1'b1;
						end
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 9'h023};
					3'b100:
						if ((RV32ZC == 32'sd3) || (RV32ZC == 32'sd1))
							(* full_case, parallel_case *)
							case (instr_i[12:10])
								3'b000: instr_o = {10'b0000000000, instr_i[5], instr_i[6], 2'b01, instr_i[9:7], 5'b10001, instr_i[4:2], 7'h03};
								3'b001:
									(* full_case, parallel_case *)
									case (instr_i[6])
										1'b0: instr_o = {10'b0000000000, instr_i[5], 3'b001, instr_i[9:7], 5'b10101, instr_i[4:2], 7'h03};
										1'b1: instr_o = {10'b0000000000, instr_i[5], 3'b001, instr_i[9:7], 5'b00101, instr_i[4:2], 7'h03};
										default: illegal_instr_o = 1'b1;
									endcase
								3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 6'b000000, instr_i[5], instr_i[6], 7'h23};
								3'b011:
									(* full_case, parallel_case *)
									case (instr_i[6])
										1'b0: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 6'b001000, instr_i[5], 8'h23};
										1'b1: illegal_instr_o = 1'b1;
										default: illegal_instr_o = 1'b1;
									endcase
								default: illegal_instr_o = 1'b1;
							endcase
						else
							illegal_instr_o = 1'b1;
					3'b111:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b011, instr_i[11:10], 10'h023};
						else begin
							instr_o = instr_i;
							illegal_instr_o = 1'b1;
						end
					3'b001, 3'b101: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, ({instr_i[12], instr_i[6:2]} == 6'h00 ? 5'h00 : instr_i[11:7]), 7'h13};
						else
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h13};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], 7'h6f};
					3'b010: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h13};
					3'b011: begin
						instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], 7'h37};
						if (((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && (instr_i[11:7] == 5'h02))
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 24'h01115b};
						else if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 24'h010113};
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						(* full_case, parallel_case *)
						case (instr_i[11:10])
							2'b00, 2'b01: begin
								if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 3'b101, (instr_i[6:2] == 5'b00000 ? 5'b00000 : {2'b01, instr_i[9:7]}), 7'h13};
								else
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], 7'h13};
								if (instr_i[12] == 1'b1)
									illegal_instr_o = 1'b1;
							end
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h13};
							2'b11:
								(* full_case, parallel_case *)
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], 7'h33};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b10001, instr_i[9:7], 7'h33};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11001, instr_i[9:7], 7'h33};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h33};
									3'b100, 3'b101: illegal_instr_o = 1'b1;
									3'b110:
										if ((RV32ZC == 32'sd3) || (RV32ZC == 32'sd1))
											instr_o = {9'b000000101, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], 7'h33};
										else
											illegal_instr_o = 1'b1;
									3'b111:
										if ((RV32ZC == 32'sd3) || (RV32ZC == 32'sd1))
											(* full_case, parallel_case *)
											case ({instr_i[4:2]})
												3'b000: instr_o = {14'h03fd, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h13};
												3'b001: instr_o = {14'b01100000010001, instr_i[9:7], 5'b00101, instr_i[9:7], 7'h13};
												3'b010: instr_o = {14'b00001000000001, instr_i[9:7], 5'b10001, instr_i[9:7], 7'h33};
												3'b011: instr_o = {14'b01100000010101, instr_i[9:7], 5'b00101, instr_i[9:7], 7'h13};
												3'b100: illegal_instr_o = 1'b1;
												3'b101: instr_o = {14'h3ffd, instr_i[9:7], 5'b10001, instr_i[9:7], 7'h13};
												default: illegal_instr_o = 1'b1;
											endcase
										else
											illegal_instr_o = 1'b1;
									default: illegal_instr_o = 1'b1;
								endcase
							default: illegal_instr_o = 1'b1;
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 7'b0000001, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], 7'h63};
					default: illegal_instr_o = 1'b1;
				endcase
			2'b10:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, (instr_i[6:2] == 5'b00000 ? 5'b00000 : instr_i[11:7]), 7'h13};
						else
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], 7'h13};
						if (instr_i[12] == 1'b1)
							illegal_instr_o = 1'b1;
					end
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], 7'h03};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b011:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) begin
							instr_o = {3'b000, instr_i[4:2], instr_i[12], instr_i[6:5], 11'h013, instr_i[11:7], 7'h03};
							if (instr_i[11:7] == 5'b00000)
								illegal_instr_o = 1'b1;
						end
						else begin
							instr_o = instr_i;
							illegal_instr_o = 1'b1;
						end
					3'b100:
						if (instr_i[12] == 1'b0) begin
							if (instr_i[6:2] != 5'b00000)
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h33};
							else begin
								instr_o = {12'b000000000000, instr_i[11:7], 15'h0067};
								if (instr_i[11:7] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
						end
						else if (instr_i[6:2] != 5'b00000)
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h33};
						else if (instr_i[11:7] == 5'b00000)
							instr_o = 32'h00100073;
						else
							instr_o = {12'b000000000000, instr_i[11:7], 15'h00e7};
					3'b101:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							illegal_instr_o = 1'b1;
						else if ((RV32ZC == 32'sd3) || (RV32ZC == 32'sd2))
							(* full_case, parallel_case *)
							casez (instr_i[12:8])
								5'b11000: begin
									gets_expanded = 2'd1;
									(* full_case, parallel_case *)
									case (cm_state_q)
										3'd0: begin
											cm_rlist_d = cm_rlist_init(instr_i[7:4]);
											instr_o = cm_push_store_reg(cm_rlist_d, 5'd1);
											if (cm_rlist_d <= 5'd3)
												illegal_instr_o = 1'b1;
											else if (cm_rlist_d == 5'd4) begin
												if (valid_i && id_in_ready_i)
													cm_state_d = 3'd2;
											end
											else begin
												cm_rlist_d = cm_rlist_d - 5'd1;
												cm_sp_offset_d = 5'd2;
												if (valid_i && id_in_ready_i)
													cm_state_d = 3'd1;
											end
										end
										3'd1: begin
											instr_o = cm_push_store_reg(cm_rlist_q, cm_sp_offset_q);
											if (id_in_ready_i) begin
												cm_rlist_d = cm_rlist_q - 5'd1;
												cm_sp_offset_d = cm_sp_offset_q + 5'd1;
												if (cm_rlist_q == 5'd4)
													cm_state_d = 3'd2;
											end
										end
										3'd2: begin
											instr_o = cm_sp_addi(instr_i[7:4], instr_i[3:2], 1'b1);
											if (id_in_ready_i) begin
												gets_expanded = 2'd3;
												cm_state_d = 3'd0;
											end
										end
										default: cm_state_d = 3'd0;
									endcase
								end
								5'b11010, 5'b11100, 5'b11110: begin
									gets_expanded = 2'd1;
									(* full_case, parallel_case *)
									case (cm_state_q)
										3'd0: begin
											cm_rlist_d = cm_rlist_init(instr_i[7:4]);
											cm_sp_offset_d = cm_stack_adj_word(instr_i[7:4], instr_i[3:2]) - 5'd1;
											instr_o = cm_pop_load_reg(cm_rlist_d, cm_sp_offset_d);
											if (cm_rlist_d <= 5'd3)
												illegal_instr_o = 1'b1;
											else if (cm_rlist_d == 5'd4) begin
												if (valid_i && id_in_ready_i)
													cm_state_d = 3'd4;
											end
											else begin
												cm_rlist_d = cm_rlist_d - 5'd1;
												cm_sp_offset_d = cm_sp_offset_d - 5'd1;
												if (valid_i && id_in_ready_i)
													cm_state_d = 3'd3;
											end
										end
										3'd3: begin
											instr_o = cm_pop_load_reg(cm_rlist_q, cm_sp_offset_q);
											if (id_in_ready_i) begin
												cm_rlist_d = cm_rlist_q - 5'd1;
												cm_sp_offset_d = cm_sp_offset_q - 5'd1;
												if (cm_rlist_q == 5'd4)
													cm_state_d = 3'd4;
											end
										end
										3'd4: begin
											instr_o = cm_sp_addi(instr_i[7:4], instr_i[3:2], 1'b0);
											gets_expanded = 2'd2;
											if (id_in_ready_i)
												(* full_case, parallel_case *)
												case (instr_i[12:8])
													5'b11100: cm_state_d = 3'd5;
													5'b11110: cm_state_d = 3'd6;
													default: begin
														gets_expanded = 2'd3;
														cm_state_d = 3'd0;
													end
												endcase
										end
										3'd5: begin
											instr_o = cm_zero_a0(0);
											gets_expanded = 2'd2;
											if (id_in_ready_i)
												cm_state_d = 3'd6;
										end
										3'd6: begin
											instr_o = cm_ret_ra(0);
											if (id_in_ready_i) begin
												gets_expanded = 2'd3;
												cm_state_d = 3'd0;
											end
										end
										default: cm_state_d = 3'd0;
									endcase
								end
								5'b011zz:
									(* full_case, parallel_case *)
									case (instr_i[6:5])
										2'b01: begin
											gets_expanded = 2'd1;
											(* full_case, parallel_case *)
											case (cm_state_q)
												3'd0: begin
													instr_o = cm_mvsa01(1'b0, instr_i[9:7]);
													gets_expanded = 2'd2;
													if (valid_i && id_in_ready_i)
														cm_state_d = 3'd7;
												end
												3'd7: begin
													instr_o = cm_mvsa01(1'b1, instr_i[4:2]);
													if (id_in_ready_i) begin
														gets_expanded = 2'd3;
														cm_state_d = 3'd0;
													end
												end
												default: cm_state_d = 3'd0;
											endcase
										end
										2'b11: begin
											gets_expanded = 2'd1;
											(* full_case, parallel_case *)
											case (cm_state_q)
												3'd0: begin
													instr_o = cm_mva01s(instr_i[9:7], 1'b0);
													gets_expanded = 2'd2;
													if (valid_i && id_in_ready_i)
														cm_state_d = 3'd7;
												end
												3'd7: begin
													instr_o = cm_mva01s(instr_i[4:2], 1'b1);
													if (id_in_ready_i) begin
														gets_expanded = 2'd3;
														cm_state_d = 3'd0;
													end
												end
												default: cm_state_d = 3'd0;
											endcase
										end
										default: illegal_instr_o = 1'b1;
									endcase
								default: illegal_instr_o = 1'b1;
							endcase
						else
							illegal_instr_o = 1'b1;
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 9'h023};
					3'b111:
						if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
							instr_o = {3'b000, instr_i[9:7], instr_i[12], instr_i[6:2], 8'h13, instr_i[11:10], 10'h023};
						else begin
							instr_o = instr_i;
							illegal_instr_o = 1'b1;
						end
					3'b001: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b11:
				;
			default: illegal_instr_o = 1'b1;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cm_state_q <= 3'd0;
		else
			cm_state_q <= (flush_expanded_i ? 3'd0 : cm_state_d);
	generate
		if (ResetAll) begin : g_cm_meta_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					cm_rlist_q <= 1'sb0;
					cm_sp_offset_q <= 1'sb0;
				end
				else begin
					cm_rlist_q <= cm_rlist_d;
					cm_sp_offset_q <= cm_sp_offset_d;
				end
		end
		else begin : g_cm_meta_nr
			always @(posedge clk_i) begin
				cm_rlist_q <= cm_rlist_d;
				cm_sp_offset_q <= cm_sp_offset_d;
			end
		end
		if (BaseIsa != 32'sd1) begin : gen_no_cheriot_cdec
			wire unused_cheriot_enable;
			assign unused_cheriot_enable = ^cheriot_enable_i;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_controller (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	ctrl_busy_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	dret_insn_i,
	wfi_insn_i,
	ebrk_insn_i,
	csr_pipe_flush_i,
	csr_access_i,
	csr_cheriot_always_ok_i,
	instr_valid_i,
	instr_i,
	instr_compressed_i,
	instr_is_compressed_i,
	instr_gets_expanded_i,
	instr_bp_taken_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	instr_fetch_cheriot_acc_vio_i,
	instr_fetch_cheriot_bound_vio_i,
	pc_id_i,
	instr_valid_clear_o,
	id_in_ready_o,
	controller_run_o,
	instr_exec_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	exc_pc_mux_o,
	exc_cause_o,
	lsu_addr_last_i,
	load_err_i,
	store_err_i,
	mem_resp_intg_err_i,
	lsu_err_is_cheriot_i,
	wb_exception_o,
	id_exception_o,
	id_exception_nc_o,
	branch_set_i,
	branch_not_set_i,
	jump_set_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_ext_i,
	nmi_mode_o,
	debug_req_i,
	debug_cause_o,
	debug_csr_save_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mepcc_clrtag_o,
	csr_mtval_o,
	priv_mode_i,
	csr_pcc_perm_sr_i,
	stall_id_i,
	stall_wb_i,
	flush_id_o,
	ready_wb_i,
	perf_jump_o,
	perf_tbranch_o,
	instr_is_cheriot_i,
	cheriot_ex_valid_i,
	cheriot_ex_err_i,
	cheriot_wb_err_i,
	cheriot_ex_err_info_i,
	cheriot_wb_err_info_i,
	cheriot_branch_req_i,
	cheriot_branch_target_i
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output reg ctrl_busy_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire dret_insn_i;
	input wire wfi_insn_i;
	input wire ebrk_insn_i;
	input wire csr_pipe_flush_i;
	input wire csr_access_i;
	input wire csr_cheriot_always_ok_i;
	input wire instr_valid_i;
	input wire [31:0] instr_i;
	input wire [15:0] instr_compressed_i;
	input wire instr_is_compressed_i;
	input wire [1:0] instr_gets_expanded_i;
	input wire instr_bp_taken_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire instr_fetch_cheriot_acc_vio_i;
	input wire instr_fetch_cheriot_bound_vio_i;
	input wire [31:0] pc_id_i;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	output reg controller_run_o;
	input wire instr_exec_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [2:0] pc_mux_o;
	output reg nt_branch_mispredict_o;
	output reg [1:0] exc_pc_mux_o;
	output reg [6:0] exc_cause_o;
	input wire [31:0] lsu_addr_last_i;
	input wire load_err_i;
	input wire store_err_i;
	input wire mem_resp_intg_err_i;
	input wire lsu_err_is_cheriot_i;
	output wire wb_exception_o;
	output wire id_exception_o;
	output wire id_exception_nc_o;
	input wire branch_set_i;
	input wire branch_not_set_i;
	input wire jump_set_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_ext_i;
	output wire nmi_mode_o;
	input wire debug_req_i;
	output wire [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	output wire debug_mode_o;
	output reg debug_mode_entering_o;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg csr_save_wb_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	output reg csr_mepcc_clrtag_o;
	output reg [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire csr_pcc_perm_sr_i;
	input wire stall_id_i;
	input wire stall_wb_i;
	output wire flush_id_o;
	input wire ready_wb_i;
	output reg perf_jump_o;
	output reg perf_tbranch_o;
	input wire instr_is_cheriot_i;
	input wire cheriot_ex_valid_i;
	input wire cheriot_ex_err_i;
	input wire cheriot_wb_err_i;
	input wire [11:0] cheriot_ex_err_info_i;
	input wire [15:0] cheriot_wb_err_info_i;
	input wire cheriot_branch_req_i;
	input wire [31:0] cheriot_branch_target_i;
	reg [3:0] ctrl_fsm_cs;
	reg [3:0] ctrl_fsm_ns;
	reg nmi_mode_q;
	reg nmi_mode_d;
	reg debug_mode_q;
	reg debug_mode_d;
	wire [2:0] debug_cause_d;
	reg [2:0] debug_cause_q;
	reg load_err_q;
	wire load_err_d;
	reg store_err_q;
	wire store_err_d;
	reg lsu_err_is_cheriot_q;
	reg exc_req_q;
	wire exc_req_d;
	wire exc_req_nc;
	wire exc_req_wb;
	reg illegal_insn_q;
	wire illegal_insn_d;
	reg cheriot_ex_err_q;
	wire cheriot_ex_err_d;
	reg cheriot_wb_err_q;
	reg cheriot_asr_err_q;
	wire cheriot_asr_err_d;
	reg instr_fetch_err_prio;
	reg illegal_insn_prio;
	reg ecall_insn_prio;
	reg ebrk_insn_prio;
	reg store_err_prio;
	reg load_err_prio;
	reg cheriot_ex_err_prio;
	reg cheriot_wb_err_prio;
	reg cheriot_asr_err_prio;
	wire stall;
	reg halt_if;
	reg retain_id;
	reg flush_id;
	wire exc_req_lsu;
	wire special_req;
	wire special_req_pc_change;
	wire special_req_flush_only;
	wire do_single_step_d;
	reg do_single_step_q;
	wire enter_debug_mode_prio_d;
	reg enter_debug_mode_prio_q;
	wire enter_debug_mode;
	wire ebreak_into_debug;
	wire irq_enabled;
	wire handle_irq;
	wire id_wb_pending;
	wire irq_nm;
	wire irq_nm_int;
	wire [31:0] irq_nm_int_mtval;
	wire [4:0] irq_nm_int_cause;
	reg [3:0] mfip_id;
	wire unused_irq_timer;
	wire ecall_insn;
	wire mret_insn;
	wire dret_insn;
	wire wfi_insn;
	wire ebrk_insn;
	wire csr_pipe_flush;
	wire instr_fetch_err;
	wire cheriot_ex_err;
	wire mret_cheriot_asr_err;
	wire csr_cheriot_asr_err;
	assign load_err_d = load_err_i;
	assign store_err_d = store_err_i;
	assign ecall_insn = ecall_insn_i & instr_valid_i;
	assign mret_insn = mret_insn_i & instr_valid_i;
	assign dret_insn = dret_insn_i & instr_valid_i;
	assign wfi_insn = wfi_insn_i & instr_valid_i;
	assign ebrk_insn = ebrk_insn_i & instr_valid_i;
	assign csr_pipe_flush = csr_pipe_flush_i & instr_valid_i;
	assign instr_fetch_err = instr_fetch_err_i & instr_valid_i;
	assign cheriot_ex_err = (cheriot_ex_err_i & instr_is_cheriot_i) & instr_valid_i;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (BaseIsa == 32'sd1) begin : g_cheriot_asr_err
			assign mret_cheriot_asr_err = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~csr_pcc_perm_sr_i) & mret_insn;
			assign csr_cheriot_asr_err = (((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~csr_pcc_perm_sr_i) & instr_valid_i) & csr_access_i) & ~illegal_insn_i) & ~csr_cheriot_always_ok_i;
		end
		else begin : g_no_cheriot_asr_err
			assign mret_cheriot_asr_err = 1'b0;
			assign csr_cheriot_asr_err = 1'b0;
			wire unused_cheriot_asr_inputs;
			assign unused_cheriot_asr_inputs = ^{csr_access_i, csr_cheriot_always_ok_i, csr_pcc_perm_sr_i, instr_fetch_cheriot_acc_vio_i, instr_fetch_cheriot_bound_vio_i};
		end
	endgenerate
	assign illegal_insn_d = illegal_insn_i & (ctrl_fsm_cs != 4'd6);
	assign cheriot_ex_err_d = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_ex_err) & (ctrl_fsm_cs != 4'd6);
	assign cheriot_asr_err_d = (~illegal_insn_i & csr_cheriot_asr_err) | mret_cheriot_asr_err;
	assign exc_req_d = (((((ecall_insn | ebrk_insn) | illegal_insn_d) | instr_fetch_err) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_ex_err)) | cheriot_asr_err_d) & (ctrl_fsm_cs != 4'd6);
	assign exc_req_nc = ((((ecall_insn | ebrk_insn) | illegal_insn_d) | instr_fetch_err) | cheriot_asr_err_d) & (ctrl_fsm_cs != 4'd6);
	assign exc_req_lsu = store_err_i | load_err_i;
	assign exc_req_wb = exc_req_lsu | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_i);
	assign id_exception_o = exc_req_d;
	assign id_exception_nc_o = exc_req_nc;
	assign special_req_flush_only = wfi_insn | csr_pipe_flush;
	assign special_req_pc_change = ((mret_insn | dret_insn) | exc_req_d) | exc_req_wb;
	assign special_req = special_req_pc_change | special_req_flush_only;
	assign id_wb_pending = instr_valid_i | ~ready_wb_i;
	generate
		if (WritebackStage) begin : g_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				cheriot_ex_err_prio = 1'b0;
				cheriot_wb_err_prio = 1'b0;
				cheriot_asr_err_prio = 1'b0;
				if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_q)
					cheriot_wb_err_prio = 1'b1;
				else if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_ex_err_q)
					cheriot_ex_err_prio = 1'b1;
				else if (cheriot_asr_err_q)
					cheriot_asr_err_prio = 1'b1;
			end
			assign wb_exception_o = (((load_err_q | store_err_q) | load_err_i) | store_err_i) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_i);
		end
		else begin : g_no_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				cheriot_wb_err_prio = 1'b0;
				cheriot_ex_err_prio = 1'b0;
				cheriot_asr_err_prio = 1'b0;
				if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_ex_err_q)
					cheriot_ex_err_prio = 1'b1;
				else if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_q)
					cheriot_wb_err_prio = 1'b1;
				else if (cheriot_asr_err_q)
					cheriot_asr_err_prio = 1'b1;
			end
			assign wb_exception_o = 1'b0;
		end
		if (MemECC) begin : g_intg_irq_int
			reg mem_resp_intg_err_irq_pending_q;
			wire mem_resp_intg_err_irq_pending_d;
			reg [31:0] mem_resp_intg_err_addr_q;
			reg [31:0] mem_resp_intg_err_addr_d;
			reg mem_resp_intg_err_irq_set;
			reg mem_resp_intg_err_irq_clear;
			wire entering_nmi;
			assign entering_nmi = nmi_mode_d & ~nmi_mode_q;
			always @(*) begin
				if (_sv2v_0)
					;
				mem_resp_intg_err_addr_d = mem_resp_intg_err_addr_q;
				mem_resp_intg_err_irq_set = 1'b0;
				mem_resp_intg_err_irq_clear = 1'b0;
				if (mem_resp_intg_err_irq_pending_q) begin
					if (entering_nmi & !irq_nm_ext_i)
						mem_resp_intg_err_irq_clear = 1'b1;
				end
				else if (mem_resp_intg_err_i) begin
					mem_resp_intg_err_addr_d = lsu_addr_last_i;
					mem_resp_intg_err_irq_set = 1'b1;
				end
			end
			assign mem_resp_intg_err_irq_pending_d = (mem_resp_intg_err_irq_pending_q & ~mem_resp_intg_err_irq_clear) | mem_resp_intg_err_irq_set;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mem_resp_intg_err_irq_pending_q <= 1'b0;
					mem_resp_intg_err_addr_q <= 1'sb0;
				end
				else begin
					mem_resp_intg_err_irq_pending_q <= mem_resp_intg_err_irq_pending_d;
					mem_resp_intg_err_addr_q <= mem_resp_intg_err_addr_d;
				end
			assign irq_nm_int = mem_resp_intg_err_irq_pending_q;
			assign irq_nm_int_cause = 5'b00000;
			assign irq_nm_int_mtval = mem_resp_intg_err_addr_q;
		end
		else begin : g_no_intg_irq_int
			wire unused_mem_resp_intg_err_i;
			assign unused_mem_resp_intg_err_i = mem_resp_intg_err_i;
			assign irq_nm_int = 1'b0;
			assign irq_nm_int_cause = 5'd0;
			assign irq_nm_int_mtval = 1'sb0;
		end
	endgenerate
	assign do_single_step_d = (instr_valid_i ? ~debug_mode_q & debug_single_step_i : do_single_step_q);
	assign enter_debug_mode_prio_d = ((debug_req_i | do_single_step_d) & ~debug_mode_q) & !(|{instr_gets_expanded_i == 2'd1, instr_gets_expanded_i == 2'd2});
	assign enter_debug_mode = enter_debug_mode_prio_d | ((trigger_match_i & ~debug_mode_q) & !(|{instr_gets_expanded_i == 2'd1, instr_gets_expanded_i == 2'd2}));
	assign ebreak_into_debug = (priv_mode_i == 2'b11 ? debug_ebreakm_i : (priv_mode_i == 2'b00 ? debug_ebreaku_i : 1'b0));
	assign irq_nm = irq_nm_ext_i | irq_nm_int;
	assign irq_enabled = csr_mstatus_mie_i | (priv_mode_i == 2'b00);
	assign handle_irq = (((~debug_mode_q & ~debug_single_step_i) & ~nmi_mode_q) & (irq_nm | (irq_pending_i & irq_enabled))) & (instr_gets_expanded_i != 2'd2);
	always @(*) begin : gen_mfip_id
		if (_sv2v_0)
			;
		mfip_id = 4'd0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 14; i >= 0; i = i - 1)
				if (irqs_i[0 + i])
					mfip_id = i[3:0];
		end
	end
	assign unused_irq_timer = irqs_i[16];
	assign debug_cause_d = (trigger_match_i ? 3'h2 : (ebrk_insn_prio & ebreak_into_debug ? 3'h1 : (debug_req_i ? 3'h3 : (do_single_step_d ? 3'h4 : 3'h0))));
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			debug_cause_q <= 3'h0;
		else
			debug_cause_q <= debug_cause_d;
	assign debug_cause_o = debug_cause_q;
	localparam [6:0] ibex_pkg_ExcCauseBreakpoint = 7'h03;
	localparam [6:0] ibex_pkg_ExcCauseCheriFault = 7'h1c;
	localparam [6:0] ibex_pkg_ExcCauseEcallMMode = 7'h0b;
	localparam [6:0] ibex_pkg_ExcCauseEcallUMode = 7'h08;
	localparam [6:0] ibex_pkg_ExcCauseIllegalInsn = 7'h02;
	localparam [6:0] ibex_pkg_ExcCauseInsnAddrMisa = 7'h00;
	localparam [6:0] ibex_pkg_ExcCauseInstrAccessFault = 7'h01;
	localparam [6:0] ibex_pkg_ExcCauseIrqExternalM = 7'h2b;
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	localparam [6:0] ibex_pkg_ExcCauseIrqSoftwareM = 7'h23;
	localparam [6:0] ibex_pkg_ExcCauseIrqTimerM = 7'h27;
	localparam [6:0] ibex_pkg_ExcCauseLoadAccessFault = 7'h05;
	localparam [6:0] ibex_pkg_ExcCauseLoadAddrMisaligned = 7'h04;
	localparam [6:0] ibex_pkg_ExcCauseStoreAccessFault = 7'h07;
	localparam [6:0] ibex_pkg_ExcCauseStoreAddrMisaligned = 7'h06;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		instr_req_o = 1'b1;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_save_wb_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		csr_mepcc_clrtag_o = 1'b0;
		csr_mtval_o = 1'sb0;
		pc_mux_o = 3'd0;
		pc_set_o = 1'b0;
		nt_branch_mispredict_o = 1'b0;
		exc_pc_mux_o = 2'd1;
		exc_cause_o = ibex_pkg_ExcCauseInsnAddrMisa;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		halt_if = 1'b0;
		retain_id = 1'b0;
		flush_id = 1'b0;
		debug_csr_save_o = 1'b0;
		debug_mode_d = debug_mode_q;
		debug_mode_entering_o = 1'b0;
		nmi_mode_d = nmi_mode_q;
		perf_tbranch_o = 1'b0;
		perf_jump_o = 1'b0;
		controller_run_o = 1'b0;
		(* full_case, parallel_case *)
		case (ctrl_fsm_cs)
			4'd0: begin
				instr_req_o = 1'b0;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd1;
			end
			4'd1: begin
				instr_req_o = 1'b1;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd4;
			end
			4'd2: begin
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd3;
			end
			4'd3: begin
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				if ((((irq_nm || irq_pending_i) || debug_req_i) || debug_mode_q) || debug_single_step_i)
					ctrl_fsm_ns = 4'd4;
				else
					ctrl_busy_o = 1'b0;
			end
			4'd4: begin
				if (id_in_ready_o)
					ctrl_fsm_ns = 4'd5;
				if (handle_irq) begin
					ctrl_fsm_ns = 4'd7;
					halt_if = 1'b1;
				end
				if (enter_debug_mode) begin
					ctrl_fsm_ns = 4'd8;
					halt_if = 1'b1;
				end
			end
			4'd5: begin
				controller_run_o = 1'b1;
				pc_mux_o = 3'd1;
				if (special_req) begin
					retain_id = 1'b1;
					if (ready_wb_i | wb_exception_o)
						ctrl_fsm_ns = 4'd6;
				end
				if ((branch_set_i || jump_set_i) || ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_branch_req_i)) begin
					pc_set_o = (BranchPredictor ? ~instr_bp_taken_i : 1'b1);
					perf_tbranch_o = branch_set_i;
					perf_jump_o = jump_set_i;
				end
				if (BranchPredictor) begin
					if (instr_bp_taken_i & branch_not_set_i)
						nt_branch_mispredict_o = 1'b1;
				end
				if ((enter_debug_mode || handle_irq) && (stall || id_wb_pending))
					halt_if = 1'b1;
				if ((!stall && !special_req) && !id_wb_pending) begin
					if (enter_debug_mode) begin
						ctrl_fsm_ns = 4'd8;
						halt_if = 1'b1;
					end
					else if (handle_irq) begin
						ctrl_fsm_ns = 4'd7;
						halt_if = 1'b1;
					end
				end
			end
			4'd7: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd1;
				if (handle_irq) begin
					pc_set_o = 1'b1;
					csr_save_if_o = 1'b1;
					csr_save_cause_o = 1'b1;
					if (irq_nm && !nmi_mode_q) begin
						exc_cause_o = (irq_nm_ext_i ? ibex_pkg_ExcCauseIrqNm : {2'b10, irq_nm_int_cause});
						if (irq_nm_int & !irq_nm_ext_i)
							csr_mtval_o = irq_nm_int_mtval;
						nmi_mode_d = 1'b1;
					end
					else if (irqs_i[14-:15] != 15'b000000000000000)
						exc_cause_o = {2'b01, sv2v_cast_5({1'b1, mfip_id})};
					else if (irqs_i[15])
						exc_cause_o = ibex_pkg_ExcCauseIrqExternalM;
					else if (irqs_i[17])
						exc_cause_o = ibex_pkg_ExcCauseIrqSoftwareM;
					else
						exc_cause_o = ibex_pkg_ExcCauseIrqTimerM;
				end
				ctrl_fsm_ns = 4'd5;
			end
			4'd8: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd2;
				flush_id = 1'b1;
				pc_set_o = 1'b1;
				csr_save_if_o = 1'b1;
				debug_csr_save_o = 1'b1;
				csr_save_cause_o = 1'b1;
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd9: begin
				flush_id = 1'b1;
				pc_mux_o = 3'd2;
				pc_set_o = 1'b1;
				exc_pc_mux_o = 2'd2;
				if (ebreak_into_debug && !debug_mode_q) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
				end
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd6: begin
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd5;
				if (((exc_req_q || store_err_q) || load_err_q) || ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_q)) begin
					pc_set_o = 1'b1;
					pc_mux_o = 3'd2;
					exc_pc_mux_o = (debug_mode_q ? 2'd3 : 2'd0);
					if (WritebackStage) begin : g_writeback_mepc_save
						csr_save_id_o = ~((store_err_q | load_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_q));
						csr_save_wb_o = (store_err_q | load_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_wb_err_q);
					end
					else begin : g_no_writeback_mepc_save
						csr_save_id_o = 1'b0;
					end
					csr_save_cause_o = 1'b1;
					(* full_case, parallel_case *)
					case (1'b1)
						instr_fetch_err_prio:
							if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & instr_fetch_cheriot_acc_vio_i) begin
								exc_cause_o = ibex_pkg_ExcCauseCheriFault;
								csr_mtval_o = 32'h00000402;
							end
							else if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & instr_fetch_cheriot_bound_vio_i) begin
								exc_cause_o = ibex_pkg_ExcCauseCheriFault;
								csr_mtval_o = 32'h00000401;
								csr_mepcc_clrtag_o = 1'b1;
							end
							else begin
								exc_cause_o = ibex_pkg_ExcCauseInstrAccessFault;
								csr_mtval_o = (instr_fetch_err_plus2_i ? pc_id_i + 32'd2 : pc_id_i);
							end
						illegal_insn_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseIllegalInsn;
							csr_mtval_o = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? 32'h00000000 : (instr_is_compressed_i ? {16'b0000000000000000, instr_compressed_i} : instr_i));
						end
						ecall_insn_prio: exc_cause_o = (priv_mode_i == 2'b11 ? ibex_pkg_ExcCauseEcallMMode : ibex_pkg_ExcCauseEcallUMode);
						ebrk_insn_prio:
							if (debug_mode_q | ebreak_into_debug) begin
								pc_set_o = 1'b0;
								csr_save_id_o = 1'b0;
								csr_save_cause_o = 1'b0;
								ctrl_fsm_ns = 4'd9;
								flush_id = 1'b0;
							end
							else begin
								exc_cause_o = ibex_pkg_ExcCauseBreakpoint;
								if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
									csr_mtval_o = pc_id_i;
							end
						store_err_prio:
							if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & lsu_err_is_cheriot_q) begin
								if (cheriot_wb_err_info_i[11]) begin
									exc_cause_o = ibex_pkg_ExcCauseStoreAddrMisaligned;
									csr_mtval_o = lsu_addr_last_i;
								end
								else begin
									exc_cause_o = ibex_pkg_ExcCauseCheriFault;
									csr_mtval_o = {21'h000000, cheriot_wb_err_info_i[10:0]};
								end
							end
							else begin
								exc_cause_o = ibex_pkg_ExcCauseStoreAccessFault;
								csr_mtval_o = lsu_addr_last_i;
							end
						load_err_prio:
							if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & lsu_err_is_cheriot_q) begin
								if (cheriot_wb_err_info_i[11]) begin
									exc_cause_o = ibex_pkg_ExcCauseLoadAddrMisaligned;
									csr_mtval_o = lsu_addr_last_i;
								end
								else begin
									exc_cause_o = ibex_pkg_ExcCauseCheriFault;
									csr_mtval_o = {21'h000000, cheriot_wb_err_info_i[10:0]};
								end
							end
							else begin
								exc_cause_o = ibex_pkg_ExcCauseLoadAccessFault;
								csr_mtval_o = lsu_addr_last_i;
							end
						cheriot_ex_err_prio:
							if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
								exc_cause_o = ibex_pkg_ExcCauseCheriFault;
								csr_mtval_o = {21'h000000, cheriot_ex_err_info_i[10:0]};
							end
						cheriot_wb_err_prio:
							if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
								if (cheriot_wb_err_info_i[12]) begin
									exc_cause_o = ibex_pkg_ExcCauseIllegalInsn;
									csr_mtval_o = {21'h000000, cheriot_wb_err_info_i[10:0]};
								end
								else begin
									exc_cause_o = ibex_pkg_ExcCauseCheriFault;
									csr_mtval_o = {21'h000000, cheriot_wb_err_info_i[10:0]};
								end
							end
						cheriot_asr_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseCheriFault;
							csr_mtval_o = 32'h00000418;
						end
						default:
							;
					endcase
				end
				else if (mret_insn) begin
					pc_mux_o = 3'd3;
					pc_set_o = 1'b1;
					csr_restore_mret_id_o = 1'b1;
					if (nmi_mode_q)
						nmi_mode_d = 1'b0;
				end
				else if (dret_insn) begin
					pc_mux_o = 3'd4;
					pc_set_o = 1'b1;
					debug_mode_d = 1'b0;
					csr_restore_dret_id_o = 1'b1;
				end
				else if (wfi_insn)
					ctrl_fsm_ns = 4'd2;
				if (enter_debug_mode_prio_q && !(ebrk_insn_prio && ebreak_into_debug))
					ctrl_fsm_ns = 4'd8;
			end
			default: begin
				instr_req_o = 1'b0;
				ctrl_fsm_ns = 4'd0;
			end
		endcase
		if (~instr_exec_i)
			halt_if = 1'b1;
	end
	assign flush_id_o = flush_id;
	assign debug_mode_o = debug_mode_q;
	assign nmi_mode_o = nmi_mode_q;
	assign stall = stall_id_i | stall_wb_i;
	assign id_in_ready_o = (~stall & ~halt_if) & ~retain_id;
	assign instr_valid_clear_o = ~(stall | retain_id) | flush_id;
	always @(posedge clk_i or negedge rst_ni) begin : update_regs
		if (!rst_ni) begin
			ctrl_fsm_cs <= 4'd0;
			nmi_mode_q <= 1'b0;
			do_single_step_q <= 1'b0;
			debug_mode_q <= 1'b0;
			enter_debug_mode_prio_q <= 1'b0;
			load_err_q <= 1'b0;
			store_err_q <= 1'b0;
			exc_req_q <= 1'b0;
			illegal_insn_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			nmi_mode_q <= nmi_mode_d;
			do_single_step_q <= do_single_step_d;
			debug_mode_q <= debug_mode_d;
			enter_debug_mode_prio_q <= enter_debug_mode_prio_d;
			load_err_q <= load_err_d;
			store_err_q <= store_err_d;
			exc_req_q <= exc_req_d;
			illegal_insn_q <= illegal_insn_d;
		end
	end
	generate
		if (BaseIsa == 32'sd1) begin : gen_update_regs_cheriot
			always @(posedge clk_i or negedge rst_ni) begin : update_regs_cheriot
				if (!rst_ni) begin
					lsu_err_is_cheriot_q <= 1'b0;
					cheriot_ex_err_q <= 1'b0;
					cheriot_wb_err_q <= 1'b0;
					cheriot_asr_err_q <= 1'b0;
				end
				else begin
					lsu_err_is_cheriot_q <= lsu_err_is_cheriot_i;
					cheriot_ex_err_q <= cheriot_ex_err_d;
					cheriot_wb_err_q <= cheriot_wb_err_i;
					cheriot_asr_err_q <= cheriot_asr_err_d;
				end
			end
		end
		else begin : gen_cheriot_tieoff
			wire unused_cheriot;
			assign unused_cheriot = |{lsu_err_is_cheriot_i, cheriot_ex_err_d, cheriot_wb_err_i, cheriot_asr_err_d};
			wire [1:1] sv2v_tmp_3C51D;
			assign sv2v_tmp_3C51D = 1'b0;
			always @(*) lsu_err_is_cheriot_q = sv2v_tmp_3C51D;
			wire [1:1] sv2v_tmp_60D83;
			assign sv2v_tmp_60D83 = 1'b0;
			always @(*) cheriot_ex_err_q = sv2v_tmp_60D83;
			wire [1:1] sv2v_tmp_7670B;
			assign sv2v_tmp_7670B = 1'b0;
			always @(*) cheriot_wb_err_q = sv2v_tmp_7670B;
			wire [1:1] sv2v_tmp_2DFC1;
			assign sv2v_tmp_2DFC1 = 1'b0;
			always @(*) cheriot_asr_err_q = sv2v_tmp_2DFC1;
		end
	endgenerate
	wire unused_cheriot_ctrl_inputs;
	assign unused_cheriot_ctrl_inputs = ^{cheriot_ex_valid_i, cheriot_ex_err_info_i[11], cheriot_wb_err_info_i[15:13], cheriot_branch_target_i};
	initial _sv2v_0 = 0;
endmodule
module ibex_core (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	cheriot_enable_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_tag_o,
	data_rdata_i,
	data_tag_i,
	data_err_i,
	dummy_instr_id_o,
	dummy_instr_wb_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_wb_o,
	rf_we_wb_o,
	rf_wdata_wb_ecc_o,
	rf_rdata_a_ecc_i,
	rf_rdata_b_ecc_i,
	rf_wcap_ecc_wb_o,
	rf_rcap_a_ecc_i,
	rf_rcap_b_ecc_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	mcounteren_writable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_o
);
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RV32ZC = 32'sd3;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ICacheTweakInfection = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	parameter [31:0] RegFileCapEccWidth = ibex_cheriot_pkg_REGCAP_W;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	output wire data_tag_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_tag_i;
	input wire data_err_i;
	output wire dummy_instr_id_o;
	output wire dummy_instr_wb_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire rf_we_wb_o;
	output wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_o;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_i;
	output wire [RegFileCapEccWidth - 1:0] rf_wcap_ecc_wb_o;
	input wire [RegFileCapEccWidth - 1:0] rf_rcap_a_ecc_i;
	input wire [RegFileCapEccWidth - 1:0] rf_rcap_b_ecc_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	output wire irq_pending_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	input wire [3:0] fetch_enable_i;
	input wire [3:0] mcounteren_writable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire [3:0] core_busy_o;
	localparam [31:0] PMPNumChan = 3;
	localparam [0:0] DataIndTiming = SecureIbex;
	localparam [0:0] PCIncrCheck = SecureIbex;
	localparam [0:0] ShadowCSR = 1'b0;
	wire dummy_instr_id;
	wire instr_valid_id;
	wire instr_new_id;
	wire [31:0] instr_rdata_id;
	wire [31:0] instr_rdata_alu_id;
	wire [15:0] instr_rdata_c_id;
	wire instr_is_compressed_id;
	wire [1:0] instr_gets_expanded_id;
	wire [15:0] instr_expanded_id;
	wire instr_perf_count_id;
	wire instr_bp_taken_id;
	wire instr_fetch_err;
	wire instr_fetch_err_plus2;
	wire instr_fetch_cheriot_acc_vio;
	wire instr_fetch_cheriot_bound_vio;
	wire illegal_c_insn_id;
	wire [31:0] pc_if;
	wire [31:0] pc_id;
	wire [31:0] pc_wb;
	wire [67:0] imd_val_d_ex;
	wire [67:0] imd_val_q_ex;
	wire [1:0] imd_val_we_ex;
	wire data_ind_timing;
	wire dummy_instr_en;
	wire [2:0] dummy_instr_mask;
	wire dummy_instr_seed_en;
	wire [31:0] dummy_instr_seed;
	wire icache_enable;
	wire icache_inval;
	wire icache_ecc_error;
	wire pc_mismatch_alert;
	wire csr_shadow_err;
	wire cheriot_enable_mubi_err;
	wire instr_first_cycle_id;
	wire instr_valid_clear;
	wire pc_set;
	wire nt_branch_mispredict;
	wire [31:0] nt_branch_addr;
	wire [2:0] pc_mux_id;
	wire [1:0] exc_pc_mux_id;
	wire [6:0] exc_cause;
	wire instr_intg_err;
	wire lsu_load_err;
	wire lsu_load_err_raw;
	wire lsu_store_err;
	wire lsu_store_err_raw;
	wire lsu_load_resp_intg_err;
	wire lsu_store_resp_intg_err;
	wire lsu_err_is_cheriot;
	wire expecting_load_resp_id;
	wire expecting_store_resp_id;
	wire lsu_addr_incr_req;
	wire [31:0] lsu_addr_last;
	wire [31:0] lsu_addr;
	wire [31:0] branch_target_ex_rv32;
	wire [31:0] branch_target_ex_cheriot;
	wire [31:0] branch_target_ex;
	wire branch_decision;
	wire ctrl_busy;
	wire if_busy;
	wire lsu_busy;
	wire [4:0] rf_raddr_a;
	wire [31:0] rf_rdata_a;
	wire [4:0] rf_raddr_b;
	wire [31:0] rf_rdata_b;
	wire rf_ren_a;
	wire rf_ren_b;
	wire [4:0] rf_waddr_wb;
	wire [31:0] rf_wdata_wb;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	wire [34:0] rf_wcap_wb;
	wire [34:0] rf_rcap_a;
	wire [34:0] rf_rcap_b;
	function automatic [34:0] sv2v_cast_F2778;
		input reg [34:0] inp;
		sv2v_cast_F2778 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_vec_to_regcap;
		input reg [34:0] vec_in;
		ibex_cheriot_pkg_cheriot_vec_to_regcap = sv2v_cast_F2778(vec_in);
	endfunction
	assign rf_rcap_a = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_a_ecc_i[34:0]);
	assign rf_rcap_b = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_b_ecc_i[34:0]);
	wire [31:0] rf_wdata_fwd_wb;
	wire [34:0] rf_wcap_fwd_wb;
	wire [31:0] rf_wdata_lsu;
	wire [34:0] rf_wcap_lsu;
	wire rf_we_wb;
	wire rf_we_lsu;
	wire rf_ecc_err_comb;
	wire [4:0] rf_waddr_id;
	wire [31:0] rf_wdata_id;
	wire rf_we_id;
	wire rf_rd_a_wb_match;
	wire rf_rd_b_wb_match;
	wire [6:0] alu_operator_ex;
	wire [31:0] alu_operand_a_ex;
	wire [31:0] alu_operand_b_ex;
	wire [31:0] bt_a_operand;
	wire [31:0] bt_b_operand;
	wire [31:0] alu_adder_result_ex;
	wire [31:0] result_ex;
	wire mult_en_ex;
	wire div_en_ex;
	wire mult_sel_ex;
	wire div_sel_ex;
	wire [1:0] multdiv_operator_ex;
	wire [1:0] multdiv_signed_mode_ex;
	wire [31:0] multdiv_operand_a_ex;
	wire [31:0] multdiv_operand_b_ex;
	wire multdiv_ready_id;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_op_en;
	wire [11:0] csr_addr;
	wire [31:0] csr_rdata;
	wire [31:0] csr_wdata;
	wire illegal_csr_insn_id;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_rdata_valid;
	wire [31:0] lsu_wdata;
	wire [34:0] lsu_wcap;
	wire lsu_req_done;
	wire id_in_ready;
	wire ex_valid;
	wire lsu_resp_valid;
	wire lsu_resp_err;
	wire instr_req_int;
	wire instr_req_gated;
	wire instr_exec;
	wire en_wb;
	wire [1:0] instr_type_wb;
	wire ready_wb;
	wire rf_write_wb;
	wire outstanding_load_wb;
	wire outstanding_store_wb;
	wire dummy_instr_wb;
	wire nmi_mode;
	wire [17:0] irqs;
	wire csr_mstatus_mie;
	wire [31:0] csr_mepc;
	wire [31:0] csr_depc;
	wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr;
	wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg;
	wire [2:0] csr_pmp_mseccfg;
	wire pmp_req_err [0:2];
	wire data_req_out;
	wire csr_save_if;
	wire csr_save_id;
	wire csr_save_wb;
	wire csr_restore_mret_id;
	wire csr_restore_dret_id;
	wire csr_save_cause;
	wire csr_mepcc_clrtag;
	wire csr_mtvec_init;
	wire [31:0] csr_mtvec;
	wire [31:0] csr_mtval;
	wire csr_mstatus_tw;
	wire [1:0] priv_mode_id;
	wire [1:0] priv_mode_lsu;
	wire debug_mode;
	wire debug_mode_entering;
	wire [2:0] debug_cause;
	wire debug_csr_save;
	wire debug_single_step;
	wire debug_ebreakm;
	wire debug_ebreaku;
	wire trigger_match;
	wire instr_id_done;
	wire instr_done_wb;
	wire perf_instr_ret_wb;
	wire perf_instr_ret_compressed_wb;
	wire perf_instr_ret_wb_spec;
	wire perf_instr_ret_compressed_wb_spec;
	wire perf_iside_wait;
	wire perf_dside_wait;
	wire perf_mul_wait;
	wire perf_div_wait;
	wire perf_jump;
	wire perf_branch;
	wire perf_tbranch;
	wire perf_load;
	wire perf_store;
	wire illegal_insn_id;
	wire unused_illegal_insn_id;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	wire [111:0] pcc_cap_r;
	wire [111:0] pcc_cap_w;
	wire cheriot_branch_req;
	wire cheriot_branch_req_spec;
	wire instr_is_cheriot_id;
	wire instr_is_rv32lsu_id;
	wire cheriot_exec_id;
	wire [11:0] cheriot_imm12;
	wire [19:0] cheriot_imm20;
	wire [20:0] cheriot_imm21;
	wire [4:0] cheriot_cs2_dec;
	wire [2:0] cheriot_cap_field_sel;
	wire [2:0] cheriot_adder_a_sel;
	wire [1:0] cheriot_adder_b_sel;
	wire [2:0] cheriot_setaddr_sel;
	wire [2:0] cheriot_setbounds_sel;
	wire cheriot_load_id;
	wire cheriot_store_id;
	wire cheriot_rf_we;
	wire [31:0] cheriot_result_data;
	wire [34:0] cheriot_result_cap;
	wire cheriot_ex_valid;
	wire cheriot_ex_err;
	wire [11:0] cheriot_ex_err_info;
	wire cheriot_wb_err;
	wire [15:0] cheriot_wb_err_info;
	wire [25:0] cheriot_operator;
	wire rv32_lsu_req;
	wire rv32_lsu_we;
	wire [1:0] rv32_lsu_type;
	wire [31:0] rv32_lsu_wdata;
	wire rv32_lsu_sign_ext;
	wire rv32_lsu_addr_incr_req;
	wire [31:0] rv32_lsu_addr_last;
	wire cheriot_csr_access;
	wire [4:0] cheriot_csr_addr;
	wire [31:0] cheriot_csr_wdata;
	wire [34:0] cheriot_csr_wcap;
	wire [4:0] cheriot_csr_op;
	wire cheriot_csr_op_en;
	wire [31:0] cheriot_csr_rdata;
	wire [34:0] cheriot_csr_rcap;
	wire cheriot_csr_set_mie;
	wire cheriot_csr_clr_mie;
	wire lsu_is_cap;
	wire lsu_cheriot_err;
	wire [2:0] lsu_lc_clrperm;
	wire csr_dbg_tclr_fault;
	wire cheriot_fatal_err;
	wire [31:0] csr_mshwm;
	wire [31:0] csr_mshwmb;
	wire csr_mshwm_set;
	wire [31:0] csr_mshwm_new;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (SecureIbex) begin : g_core_busy_secure
			localparam [31:0] NumBusySignals = 3;
			localparam [31:0] NumBusyBits = ibex_pkg_IbexMuBiWidth * NumBusySignals;
			wire [NumBusyBits - 1:0] busy_bits_buf;
			prim_buf #(.Width(NumBusyBits)) u_fetch_enable_buf(
				.in_i({ibex_pkg_IbexMuBiWidth {ctrl_busy, if_busy, lsu_busy}}),
				.out_o(busy_bits_buf)
			);
			genvar _gv_i_19;
			for (_gv_i_19 = 0; _gv_i_19 < ibex_pkg_IbexMuBiWidth; _gv_i_19 = _gv_i_19 + 1) begin : g_core_busy_bits
				localparam i = _gv_i_19;
				if (ibex_pkg_IbexMuBiOn[i] == 1'b1) begin : g_pos
					assign core_busy_o[i] = |busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
				else begin : g_neg
					assign core_busy_o[i] = ~|busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
			end
		end
		else begin : g_core_busy_non_secure
			assign core_busy_o = ((ctrl_busy || if_busy) || lsu_busy ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_I = 0;
	localparam [31:0] ibex_pkg_PMP_I2 = 1;
	ibex_if_stage #(
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.DummyInstructions(DummyInstructions),
		.ICache(ICache),
		.RV32ZC(RV32ZC),
		.ICacheECC(ICacheECC),
		.ICacheTweakInfection(ICacheTweakInfection),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.PCIncrCheck(PCIncrCheck),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.BaseIsa(BaseIsa)
	) if_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.boot_addr_i(boot_addr_i),
		.req_i(instr_req_gated),
		.debug_mode_i(debug_mode),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_bus_err_i(instr_err_i),
		.instr_intg_err_o(instr_intg_err),
		.ic_tag_req_o(ic_tag_req_o),
		.ic_tag_write_o(ic_tag_write_o),
		.ic_tag_addr_o(ic_tag_addr_o),
		.ic_tag_wdata_o(ic_tag_wdata_o),
		.ic_tag_rdata_i(ic_tag_rdata_i),
		.ic_data_req_o(ic_data_req_o),
		.ic_data_write_o(ic_data_write_o),
		.ic_data_addr_o(ic_data_addr_o),
		.ic_data_wdata_o(ic_data_wdata_o),
		.ic_data_rdata_i(ic_data_rdata_i),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.ic_scr_key_req_o(ic_scr_key_req_o),
		.instr_valid_id_o(instr_valid_id),
		.instr_new_id_o(instr_new_id),
		.instr_rdata_id_o(instr_rdata_id),
		.instr_rdata_alu_id_o(instr_rdata_alu_id),
		.instr_rdata_c_id_o(instr_rdata_c_id),
		.instr_is_compressed_id_o(instr_is_compressed_id),
		.instr_gets_expanded_id_o(instr_gets_expanded_id),
		.instr_expanded_id_o(instr_expanded_id),
		.instr_bp_taken_o(instr_bp_taken_id),
		.instr_fetch_err_o(instr_fetch_err),
		.instr_fetch_err_plus2_o(instr_fetch_err_plus2),
		.instr_fetch_cheriot_acc_vio_o(instr_fetch_cheriot_acc_vio),
		.instr_fetch_cheriot_bound_vio_o(instr_fetch_cheriot_bound_vio),
		.illegal_c_insn_id_o(illegal_c_insn_id),
		.dummy_instr_id_o(dummy_instr_id),
		.pc_if_o(pc_if),
		.pc_id_o(pc_id),
		.pmp_err_if_i(pmp_req_err[ibex_pkg_PMP_I]),
		.pmp_err_if_plus2_i(pmp_req_err[ibex_pkg_PMP_I2]),
		.instr_valid_clear_i(instr_valid_clear),
		.pc_set_i(pc_set),
		.pc_mux_i(pc_mux_id),
		.nt_branch_mispredict_i(nt_branch_mispredict),
		.exc_pc_mux_i(exc_pc_mux_id),
		.exc_cause(exc_cause),
		.dummy_instr_en_i(dummy_instr_en),
		.dummy_instr_mask_i(dummy_instr_mask),
		.dummy_instr_seed_en_i(dummy_instr_seed_en),
		.dummy_instr_seed_i(dummy_instr_seed),
		.icache_enable_i(icache_enable),
		.icache_inval_i(icache_inval),
		.icache_ecc_error_o(icache_ecc_error),
		.branch_target_ex_i(branch_target_ex),
		.nt_branch_addr_i(nt_branch_addr),
		.csr_mepc_i(csr_mepc),
		.csr_depc_i(csr_depc),
		.csr_mtvec_i(csr_mtvec),
		.csr_mtvec_init_o(csr_mtvec_init),
		.id_in_ready_i(id_in_ready),
		.pc_mismatch_alert_o(pc_mismatch_alert),
		.if_busy_o(if_busy),
		.pcc_cap_i(pcc_cap_r)
	);
	assign perf_iside_wait = id_in_ready & ~instr_valid_id;
	generate
		if (SecureIbex) begin : g_instr_req_gated_secure
			assign instr_req_gated = instr_req_int & (fetch_enable_i == ibex_pkg_IbexMuBiOn);
			assign instr_exec = fetch_enable_i == ibex_pkg_IbexMuBiOn;
		end
		else begin : g_instr_req_gated_non_secure
			wire unused_fetch_enable;
			assign unused_fetch_enable = ^fetch_enable_i[3:1];
			assign instr_req_gated = instr_req_int & fetch_enable_i[0];
			assign instr_exec = fetch_enable_i[0];
		end
	endgenerate
	ibex_id_stage #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.DataIndTiming(DataIndTiming),
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.BaseIsa(BaseIsa)
	) id_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.ctrl_busy_o(ctrl_busy),
		.illegal_insn_o(illegal_insn_id),
		.instr_valid_i(instr_valid_id),
		.instr_rdata_i(instr_rdata_id),
		.instr_rdata_alu_i(instr_rdata_alu_id),
		.instr_rdata_c_i(instr_rdata_c_id),
		.instr_is_compressed_i(instr_is_compressed_id),
		.instr_gets_expanded_i(instr_gets_expanded_id),
		.instr_bp_taken_i(instr_bp_taken_id),
		.branch_decision_i(branch_decision),
		.instr_first_cycle_id_o(instr_first_cycle_id),
		.instr_valid_clear_o(instr_valid_clear),
		.id_in_ready_o(id_in_ready),
		.instr_exec_i(instr_exec),
		.instr_req_o(instr_req_int),
		.pc_set_o(pc_set),
		.pc_mux_o(pc_mux_id),
		.nt_branch_mispredict_o(nt_branch_mispredict),
		.nt_branch_addr_o(nt_branch_addr),
		.exc_pc_mux_o(exc_pc_mux_id),
		.exc_cause_o(exc_cause),
		.icache_inval_o(icache_inval),
		.instr_fetch_err_i(instr_fetch_err),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2),
		.instr_fetch_cheriot_acc_vio_i(instr_fetch_cheriot_acc_vio),
		.instr_fetch_cheriot_bound_vio_i(instr_fetch_cheriot_bound_vio),
		.illegal_c_insn_i(illegal_c_insn_id),
		.pc_id_i(pc_id),
		.ex_valid_i(ex_valid),
		.lsu_resp_valid_i(lsu_resp_valid),
		.alu_operator_ex_o(alu_operator_ex),
		.alu_operand_a_ex_o(alu_operand_a_ex),
		.alu_operand_b_ex_o(alu_operand_b_ex),
		.imd_val_q_ex_o(imd_val_q_ex),
		.imd_val_d_ex_i(imd_val_d_ex),
		.imd_val_we_ex_i(imd_val_we_ex),
		.bt_a_operand_o(bt_a_operand),
		.bt_b_operand_o(bt_b_operand),
		.mult_en_ex_o(mult_en_ex),
		.div_en_ex_o(div_en_ex),
		.mult_sel_ex_o(mult_sel_ex),
		.div_sel_ex_o(div_sel_ex),
		.multdiv_operator_ex_o(multdiv_operator_ex),
		.multdiv_signed_mode_ex_o(multdiv_signed_mode_ex),
		.multdiv_operand_a_ex_o(multdiv_operand_a_ex),
		.multdiv_operand_b_ex_o(multdiv_operand_b_ex),
		.multdiv_ready_id_o(multdiv_ready_id),
		.csr_access_o(csr_access),
		.csr_op_o(csr_op),
		.csr_addr_o(csr_addr),
		.csr_op_en_o(csr_op_en),
		.csr_save_if_o(csr_save_if),
		.csr_save_id_o(csr_save_id),
		.csr_save_wb_o(csr_save_wb),
		.csr_restore_mret_id_o(csr_restore_mret_id),
		.csr_restore_dret_id_o(csr_restore_dret_id),
		.csr_save_cause_o(csr_save_cause),
		.csr_mepcc_clrtag_o(csr_mepcc_clrtag),
		.csr_mtval_o(csr_mtval),
		.priv_mode_i(priv_mode_id),
		.csr_mstatus_tw_i(csr_mstatus_tw),
		.illegal_csr_insn_i(illegal_csr_insn_id),
		.data_ind_timing_i(data_ind_timing),
		.csr_pcc_perm_sr_i(pcc_cap_r[42]),
		.lsu_req_o(rv32_lsu_req),
		.lsu_we_o(rv32_lsu_we),
		.lsu_type_o(rv32_lsu_type),
		.lsu_sign_ext_o(rv32_lsu_sign_ext),
		.lsu_wdata_o(rv32_lsu_wdata),
		.lsu_req_done_i(lsu_req_done),
		.lsu_addr_incr_req_i(rv32_lsu_addr_incr_req),
		.lsu_addr_last_i(rv32_lsu_addr_last),
		.lsu_load_err_i(lsu_load_err),
		.lsu_load_resp_intg_err_i(lsu_load_resp_intg_err),
		.lsu_store_err_i(lsu_store_err),
		.lsu_store_resp_intg_err_i(lsu_store_resp_intg_err),
		.lsu_err_is_cheriot_i(lsu_err_is_cheriot),
		.expecting_load_resp_o(expecting_load_resp_id),
		.expecting_store_resp_o(expecting_store_resp_id),
		.csr_mstatus_mie_i(csr_mstatus_mie),
		.irq_pending_i(irq_pending_o),
		.irqs_i(irqs),
		.irq_nm_i(irq_nm_i),
		.nmi_mode_o(nmi_mode),
		.debug_mode_o(debug_mode),
		.debug_mode_entering_o(debug_mode_entering),
		.debug_cause_o(debug_cause),
		.debug_csr_save_o(debug_csr_save),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step),
		.debug_ebreakm_i(debug_ebreakm),
		.debug_ebreaku_i(debug_ebreaku),
		.trigger_match_i(trigger_match),
		.result_ex_i(result_ex),
		.csr_rdata_i(csr_rdata),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_rdata_a_i(rf_rdata_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_rdata_b_i(rf_rdata_b),
		.rf_ren_a_o(rf_ren_a),
		.rf_ren_b_o(rf_ren_b),
		.rf_waddr_id_o(rf_waddr_id),
		.rf_wdata_id_o(rf_wdata_id),
		.rf_we_id_o(rf_we_id),
		.rf_rd_a_wb_match_o(rf_rd_a_wb_match),
		.rf_rd_b_wb_match_o(rf_rd_b_wb_match),
		.rf_waddr_wb_i(rf_waddr_wb),
		.rf_wdata_fwd_wb_i(rf_wdata_fwd_wb),
		.rf_write_wb_i(rf_write_wb),
		.en_wb_o(en_wb),
		.instr_type_wb_o(instr_type_wb),
		.instr_perf_count_id_o(instr_perf_count_id),
		.ready_wb_i(ready_wb),
		.outstanding_load_wb_i(outstanding_load_wb),
		.outstanding_store_wb_i(outstanding_store_wb),
		.perf_jump_o(perf_jump),
		.perf_branch_o(perf_branch),
		.perf_tbranch_o(perf_tbranch),
		.perf_dside_wait_o(perf_dside_wait),
		.perf_mul_wait_o(perf_mul_wait),
		.perf_div_wait_o(perf_div_wait),
		.instr_id_done_o(instr_id_done),
		.cheriot_exec_id_o(cheriot_exec_id),
		.instr_is_cheriot_id_o(instr_is_cheriot_id),
		.instr_is_rv32lsu_id_o(instr_is_rv32lsu_id),
		.cheriot_imm12_o(cheriot_imm12),
		.cheriot_imm20_o(cheriot_imm20),
		.cheriot_imm21_o(cheriot_imm21),
		.cheriot_operator_o(cheriot_operator),
		.cheriot_cs2_dec_o(cheriot_cs2_dec),
		.cheriot_cap_field_sel_o(cheriot_cap_field_sel),
		.cheriot_adder_a_sel_o(cheriot_adder_a_sel),
		.cheriot_adder_b_sel_o(cheriot_adder_b_sel),
		.cheriot_setaddr_sel_o(cheriot_setaddr_sel),
		.cheriot_setbounds_sel_o(cheriot_setbounds_sel),
		.cheriot_load_o(cheriot_load_id),
		.cheriot_store_o(cheriot_store_id),
		.cheriot_ex_valid_i(cheriot_ex_valid),
		.cheriot_ex_err_i(cheriot_ex_err),
		.cheriot_ex_err_info_i(cheriot_ex_err_info),
		.cheriot_wb_err_i(cheriot_wb_err),
		.cheriot_wb_err_info_i(cheriot_wb_err_info),
		.cheriot_branch_req_i(cheriot_branch_req_spec),
		.cheriot_branch_target_i(branch_target_ex_cheriot)
	);
	assign unused_illegal_insn_id = illegal_insn_id;
	ibex_ex_block #(
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) ex_block_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.alu_operator_i(alu_operator_ex),
		.alu_operand_a_i(alu_operand_a_ex),
		.alu_operand_b_i(alu_operand_b_ex),
		.alu_instr_first_cycle_i(instr_first_cycle_id),
		.bt_a_operand_i(bt_a_operand),
		.bt_b_operand_i(bt_b_operand),
		.multdiv_operator_i(multdiv_operator_ex),
		.mult_en_i(mult_en_ex),
		.div_en_i(div_en_ex),
		.mult_sel_i(mult_sel_ex),
		.div_sel_i(div_sel_ex),
		.multdiv_signed_mode_i(multdiv_signed_mode_ex),
		.multdiv_operand_a_i(multdiv_operand_a_ex),
		.multdiv_operand_b_i(multdiv_operand_b_ex),
		.multdiv_ready_id_i(multdiv_ready_id),
		.data_ind_timing_i(data_ind_timing),
		.imd_val_we_o(imd_val_we_ex),
		.imd_val_d_o(imd_val_d_ex),
		.imd_val_q_i(imd_val_q_ex),
		.alu_adder_result_ex_o(alu_adder_result_ex),
		.result_ex_o(result_ex),
		.branch_target_o(branch_target_ex_rv32),
		.branch_decision_o(branch_decision),
		.ex_valid_o(ex_valid)
	);
	function automatic [5:0] sv2v_cast_7F253;
		input reg [5:0] inp;
		sv2v_cast_7F253 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_752DF;
		input reg [2:0] inp;
		sv2v_cast_752DF = inp;
	endfunction
	function automatic [3:0] sv2v_cast_A52E5;
		input reg [3:0] inp;
		sv2v_cast_A52E5 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_A24F8;
		input reg [8:0] inp;
		sv2v_cast_A24F8 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_7F253(1'sb0), sv2v_cast_752DF(1'sb0), sv2v_cast_A52E5(1'sb0), sv2v_cast_A24F8(1'sb0), sv2v_cast_A24F8(1'sb0)};
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	generate
		if (BaseIsa == 32'sd1) begin : g_cheriot_ex
			ibex_cheriot_ex #(.WritebackStage(WritebackStage)) u_ibex_cheriot_ex(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.cheriot_enable_i(cheriot_enable_i),
				.debug_mode_i(debug_mode),
				.fwd_we_i(rf_write_wb),
				.fwd_waddr_i(rf_waddr_wb),
				.fwd_wdata_i(rf_wdata_fwd_wb),
				.fwd_wcap_i(rf_wcap_fwd_wb),
				.rf_raddr_a_i(rf_raddr_a),
				.rf_rdata_a_i(rf_rdata_a),
				.rf_rcap_a_i(rf_rcap_a),
				.rf_raddr_b_i(rf_raddr_b),
				.rf_rdata_b_i(rf_rdata_b),
				.rf_rcap_b_i(rf_rcap_b),
				.rf_waddr_i(rf_waddr_id),
				.pcc_cap_i(pcc_cap_r),
				.pcc_cap_o(pcc_cap_w),
				.pc_id_i(pc_id),
				.branch_req_o(cheriot_branch_req),
				.branch_req_spec_o(cheriot_branch_req_spec),
				.branch_target_o(branch_target_ex_cheriot),
				.cheriot_exec_id_i(cheriot_exec_id),
				.instr_valid_i(instr_valid_id),
				.instr_first_cycle_i(instr_first_cycle_id),
				.instr_is_cheriot_i(instr_is_cheriot_id),
				.instr_is_rv32lsu_i(instr_is_rv32lsu_id),
				.instr_is_compressed_i(instr_is_compressed_id),
				.cheriot_imm12_i(cheriot_imm12),
				.cheriot_imm20_i(cheriot_imm20),
				.cheriot_imm21_i(cheriot_imm21),
				.cheriot_operator_i(cheriot_operator),
				.cheriot_cs2_dec_i(cheriot_cs2_dec),
				.cheriot_cap_field_sel_i(cheriot_cap_field_sel),
				.cheriot_adder_a_sel_i(cheriot_adder_a_sel),
				.cheriot_adder_b_sel_i(cheriot_adder_b_sel),
				.cheriot_setaddr_sel_i(cheriot_setaddr_sel),
				.cheriot_setbounds_sel_i(cheriot_setbounds_sel),
				.cheriot_rf_we_o(cheriot_rf_we),
				.result_data_o(cheriot_result_data),
				.result_cap_o(cheriot_result_cap),
				.cheriot_ex_valid_o(cheriot_ex_valid),
				.cheriot_ex_err_o(cheriot_ex_err),
				.cheriot_ex_err_info_o(cheriot_ex_err_info),
				.cheriot_wb_err_o(cheriot_wb_err),
				.cheriot_wb_err_info_o(cheriot_wb_err_info),
				.lsu_req_o(lsu_req),
				.lsu_is_cap_o(lsu_is_cap),
				.lsu_lc_clrperm_o(lsu_lc_clrperm),
				.lsu_cheriot_err_o(lsu_cheriot_err),
				.lsu_we_o(lsu_we),
				.lsu_addr_o(lsu_addr),
				.lsu_type_o(lsu_type),
				.lsu_wdata_o(lsu_wdata),
				.lsu_wcap_o(lsu_wcap),
				.lsu_sign_ext_o(lsu_sign_ext),
				.addr_incr_req_i(lsu_addr_incr_req),
				.addr_last_i(lsu_addr_last),
				.rv32_lsu_req_i(rv32_lsu_req),
				.rv32_lsu_we_i(rv32_lsu_we),
				.rv32_lsu_type_i(rv32_lsu_type),
				.rv32_lsu_wdata_i(rv32_lsu_wdata),
				.rv32_lsu_sign_ext_i(rv32_lsu_sign_ext),
				.rv32_lsu_addr_i(alu_adder_result_ex),
				.rv32_addr_incr_req_o(rv32_lsu_addr_incr_req),
				.rv32_addr_last_o(rv32_lsu_addr_last),
				.csr_rdata_i(cheriot_csr_rdata),
				.csr_rcap_i(cheriot_csr_rcap),
				.csr_mstatus_mie_i(csr_mstatus_mie),
				.csr_access_o(cheriot_csr_access),
				.csr_addr_o(cheriot_csr_addr),
				.csr_wdata_o(cheriot_csr_wdata),
				.csr_wcap_o(cheriot_csr_wcap),
				.csr_op_o(cheriot_csr_op),
				.csr_op_en_o(cheriot_csr_op_en),
				.csr_set_mie_o(cheriot_csr_set_mie),
				.csr_clr_mie_o(cheriot_csr_clr_mie),
				.csr_mshwm_i(csr_mshwm),
				.csr_mshwmb_i(csr_mshwmb),
				.csr_mshwm_set_o(csr_mshwm_set),
				.csr_mshwm_new_o(csr_mshwm_new),
				.csr_dbg_tclr_fault_i(csr_dbg_tclr_fault)
			);
			assign branch_target_ex = (instr_valid_id & instr_is_cheriot_id ? branch_target_ex_cheriot : branch_target_ex_rv32);
		end
		else begin : gen_no_cheriot_ex
			assign cheriot_branch_req = 1'b0;
			assign cheriot_branch_req_spec = 1'b0;
			assign branch_target_ex = branch_target_ex_rv32;
			assign pcc_cap_w = ibex_cheriot_pkg_NULL_DECODED_CAP;
			assign cheriot_rf_we = 1'b0;
			assign cheriot_result_data = 32'h00000000;
			assign cheriot_result_cap = ibex_cheriot_pkg_NULL_CAP;
			assign cheriot_ex_valid = 1'b0;
			assign cheriot_ex_err = 1'b0;
			assign cheriot_ex_err_info = 12'h000;
			assign cheriot_wb_err = 1'b0;
			assign cheriot_wb_err_info = 16'h0000;
			assign lsu_req = rv32_lsu_req;
			assign lsu_is_cap = 1'b0;
			assign lsu_lc_clrperm = 1'sb0;
			assign lsu_cheriot_err = 1'b0;
			assign lsu_we = rv32_lsu_we;
			assign lsu_addr = alu_adder_result_ex;
			assign lsu_type = rv32_lsu_type;
			assign lsu_wdata = rv32_lsu_wdata;
			assign lsu_wcap = ibex_cheriot_pkg_NULL_CAP;
			assign lsu_sign_ext = rv32_lsu_sign_ext;
			assign rv32_lsu_addr_incr_req = lsu_addr_incr_req;
			assign rv32_lsu_addr_last = lsu_addr_last;
			assign cheriot_csr_access = 1'b0;
			assign cheriot_csr_addr = 5'h00;
			assign cheriot_csr_wdata = 32'h00000000;
			assign cheriot_csr_wcap = ibex_cheriot_pkg_NULL_CAP;
			assign cheriot_csr_op = 5'd0;
			assign cheriot_csr_op_en = 1'b0;
			assign cheriot_csr_set_mie = 1'b0;
			assign cheriot_csr_clr_mie = 1'b0;
			assign csr_mshwm_set = 1'b0;
			assign csr_mshwm_new = 32'h00000000;
			assign branch_target_ex_cheriot = 32'h00000000;
			wire unused_cheriot_core_sigs;
			assign unused_cheriot_core_sigs = ((((((((((((((((((((^rf_rcap_a_ecc_i | ^rf_rcap_b_ecc_i) | cheriot_exec_id) | instr_is_rv32lsu_id) | ^cheriot_imm12) | ^cheriot_imm20) | ^cheriot_imm21) | ^cheriot_cs2_dec) | ^cheriot_operator) | ^cheriot_csr_rdata) | ^cheriot_csr_rcap) | csr_dbg_tclr_fault) | ^csr_mshwm) | ^csr_mshwmb) | ^rf_wcap_fwd_wb) | ^cheriot_cap_field_sel) | ^cheriot_adder_a_sel) | ^cheriot_adder_b_sel) | ^cheriot_setaddr_sel) | ^cheriot_setbounds_sel) | ^rf_rcap_a) | ^rf_rcap_b;
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_D = 2;
	assign data_req_o = data_req_out & ~pmp_req_err[ibex_pkg_PMP_D];
	assign lsu_resp_err = lsu_load_err | lsu_store_err;
	ibex_load_store_unit #(
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.BaseIsa(BaseIsa)
	) load_store_unit_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.data_req_o(data_req_out),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_bus_err_i(data_err_i),
		.data_pmp_err_i(pmp_req_err[ibex_pkg_PMP_D]),
		.data_addr_o(data_addr_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_wdata_o(data_wdata_o),
		.data_tag_o(data_tag_o),
		.data_rdata_i(data_rdata_i),
		.data_tag_i(data_tag_i),
		.lsu_we_i(lsu_we),
		.lsu_type_i(lsu_type),
		.lsu_wdata_i(lsu_wdata),
		.lsu_wcap_i(lsu_wcap),
		.lsu_sign_ext_i(lsu_sign_ext),
		.lsu_rdata_o(rf_wdata_lsu),
		.lsu_rcap_o(rf_wcap_lsu),
		.lsu_rdata_valid_o(lsu_rdata_valid),
		.lsu_req_i(lsu_req),
		.lsu_is_cap_i(lsu_is_cap),
		.lsu_lc_clrperm_i(lsu_lc_clrperm),
		.lsu_cheriot_err_i(lsu_cheriot_err),
		.adder_result_ex_i(lsu_addr),
		.addr_incr_req_o(lsu_addr_incr_req),
		.addr_last_o(lsu_addr_last),
		.lsu_req_done_o(lsu_req_done),
		.lsu_resp_valid_o(lsu_resp_valid),
		.load_err_o(lsu_load_err_raw),
		.load_resp_intg_err_o(lsu_load_resp_intg_err),
		.store_err_o(lsu_store_err_raw),
		.store_resp_intg_err_o(lsu_store_resp_intg_err),
		.lsu_err_is_cheriot_o(lsu_err_is_cheriot),
		.busy_o(lsu_busy),
		.perf_load_o(perf_load),
		.perf_store_o(perf_store)
	);
	ibex_wb_stage #(
		.ResetAll(ResetAll),
		.WritebackStage(WritebackStage),
		.DummyInstructions(DummyInstructions)
	) wb_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.en_wb_i(en_wb),
		.instr_type_wb_i(instr_type_wb),
		.pc_id_i(pc_id),
		.instr_is_compressed_id_i(instr_is_compressed_id),
		.instr_perf_count_id_i(instr_perf_count_id),
		.instr_is_cheriot_i(instr_is_cheriot_id),
		.cheriot_load_i(cheriot_load_id),
		.cheriot_store_i(cheriot_store_id),
		.ready_wb_o(ready_wb),
		.rf_write_wb_o(rf_write_wb),
		.outstanding_load_wb_o(outstanding_load_wb),
		.outstanding_store_wb_o(outstanding_store_wb),
		.pc_wb_o(pc_wb),
		.perf_instr_ret_wb_o(perf_instr_ret_wb),
		.perf_instr_ret_compressed_wb_o(perf_instr_ret_compressed_wb),
		.perf_instr_ret_wb_spec_o(perf_instr_ret_wb_spec),
		.perf_instr_ret_compressed_wb_spec_o(perf_instr_ret_compressed_wb_spec),
		.rf_waddr_id_i(rf_waddr_id),
		.rf_wdata_id_i(rf_wdata_id),
		.rf_we_id_i(rf_we_id),
		.dummy_instr_id_i(dummy_instr_id),
		.cheriot_rf_we_i(cheriot_rf_we),
		.cheriot_rf_wdata_i(cheriot_result_data),
		.cheriot_rf_wcap_i(cheriot_result_cap),
		.rf_wdata_lsu_i(rf_wdata_lsu),
		.rf_wcap_lsu_i(rf_wcap_lsu),
		.rf_we_lsu_i(rf_we_lsu),
		.rf_wdata_fwd_wb_o(rf_wdata_fwd_wb),
		.rf_wcap_fwd_wb_o(rf_wcap_fwd_wb),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_wdata_wb_o(rf_wdata_wb),
		.rf_wcap_wb_o(rf_wcap_wb),
		.rf_we_wb_o(rf_we_wb),
		.dummy_instr_wb_o(dummy_instr_wb),
		.lsu_resp_valid_i(lsu_resp_valid),
		.lsu_resp_err_i(lsu_resp_err),
		.instr_done_wb_o(instr_done_wb)
	);
	generate
		if (SecureIbex) begin : g_check_mem_response
			assign lsu_load_err = lsu_load_err_raw & (outstanding_load_wb | expecting_load_resp_id);
			assign lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
			assign rf_we_lsu = lsu_rdata_valid & (outstanding_load_wb | expecting_load_resp_id);
		end
		else begin : g_no_check_mem_response
			assign lsu_load_err = lsu_load_err_raw;
			assign lsu_store_err = lsu_store_err_raw;
			assign rf_we_lsu = lsu_rdata_valid;
			wire unused_expecting_load_resp_id;
			wire unused_expecting_store_resp_id;
			assign unused_expecting_load_resp_id = expecting_load_resp_id;
			assign unused_expecting_store_resp_id = expecting_store_resp_id;
		end
	endgenerate
	assign dummy_instr_id_o = dummy_instr_id;
	assign dummy_instr_wb_o = dummy_instr_wb;
	assign rf_raddr_a_o = rf_raddr_a;
	assign rf_waddr_wb_o = rf_waddr_wb;
	assign rf_we_wb_o = rf_we_wb;
	assign rf_raddr_b_o = rf_raddr_b;
	function automatic [34:0] sv2v_cast_4FBCE;
		input reg [34:0] inp;
		sv2v_cast_4FBCE = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_regcap_to_vec;
		input reg [34:0] cap;
		ibex_cheriot_pkg_cheriot_regcap_to_vec = sv2v_cast_4FBCE(cap);
	endfunction
	generate
		if (RegFileECC) begin : gen_regfile_ecc
			wire [1:0] rf_ecc_err_a;
			wire [1:0] rf_ecc_err_b;
			wire rf_ecc_err_a_id;
			wire rf_ecc_err_b_id;
			prim_secded_inv_39_32_enc regfile_ecc_enc(
				.data_i(rf_wdata_wb),
				.data_o(rf_wdata_wb_ecc_o)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_a(
				.data_i(rf_rdata_a_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_a)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_b(
				.data_i(rf_rdata_b_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_b)
			);
			assign rf_rdata_a = rf_rdata_a_ecc_i[31:0];
			assign rf_rdata_b = rf_rdata_b_ecc_i[31:0];
			if (BaseIsa == 32'sd1) begin : gen_cheriot_cap_ecc
				wire [1:0] rf_cap_ecc_err_a;
				wire [1:0] rf_cap_ecc_err_b;
				wire [63:0] wcap_ecc_tmp;
				wire [56:0] unused_wcap_ecc_tmp;
				prim_secded_inv_64_57_enc regfile_cap_ecc_enc(
					.data_i({22'b0000000000000000000000, ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)}),
					.data_o(wcap_ecc_tmp)
				);
				assign rf_wcap_ecc_wb_o = {wcap_ecc_tmp[63:57], ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)};
				assign unused_wcap_ecc_tmp = wcap_ecc_tmp[56:0];
				prim_secded_inv_64_57_dec regfile_cap_ecc_dec_a(
					.data_i({rf_rcap_a_ecc_i[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W], 22'b0000000000000000000000, rf_rcap_a_ecc_i[34:0]}),
					.data_o(),
					.syndrome_o(),
					.err_o(rf_cap_ecc_err_a)
				);
				prim_secded_inv_64_57_dec regfile_cap_ecc_dec_b(
					.data_i({rf_rcap_b_ecc_i[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W], 22'b0000000000000000000000, rf_rcap_b_ecc_i[34:0]}),
					.data_o(),
					.syndrome_o(),
					.err_o(rf_cap_ecc_err_b)
				);
				assign rf_ecc_err_a_id = ((|rf_ecc_err_a | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & |rf_cap_ecc_err_a)) & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
				assign rf_ecc_err_b_id = ((|rf_ecc_err_b | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & |rf_cap_ecc_err_b)) & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
				assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
			end
			else begin : gen_no_cheriot_cap_ecc
				wire unused_rf_cap_ecc_i;
				assign unused_rf_cap_ecc_i = ^rf_rcap_a_ecc_i ^ ^rf_rcap_b_ecc_i;
				assign rf_wcap_ecc_wb_o = {7'b0000000, ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)};
				assign rf_ecc_err_a_id = (|rf_ecc_err_a & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
				assign rf_ecc_err_b_id = (|rf_ecc_err_b & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
				assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
			end
		end
		else begin : gen_no_regfile_ecc
			wire unused_rf_ren_a;
			wire unused_rf_ren_b;
			wire unused_rf_rd_a_wb_match;
			wire unused_rf_rd_b_wb_match;
			assign unused_rf_ren_a = rf_ren_a;
			assign unused_rf_ren_b = rf_ren_b;
			assign unused_rf_rd_a_wb_match = rf_rd_a_wb_match;
			assign unused_rf_rd_b_wb_match = rf_rd_b_wb_match;
			assign rf_wdata_wb_ecc_o = rf_wdata_wb;
			assign rf_wcap_ecc_wb_o = ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb);
			assign rf_rdata_a = rf_rdata_a_ecc_i;
			assign rf_rdata_b = rf_rdata_b_ecc_i;
			assign rf_ecc_err_comb = 1'b0;
		end
	endgenerate
	wire [31:0] crash_dump_mtval;
	assign crash_dump_o[159-:32] = pc_id;
	assign crash_dump_o[127-:32] = pc_if;
	assign crash_dump_o[95-:32] = lsu_addr_last;
	assign crash_dump_o[63-:32] = csr_mepc;
	assign crash_dump_o[31-:32] = crash_dump_mtval;
	assign alert_minor_o = icache_ecc_error;
	generate
		if (BaseIsa == 32'sd1) begin : gen_cheriot_enable_check
			assign cheriot_enable_mubi_err = instr_exec & !((cheriot_enable_i == ibex_pkg_IbexMuBiOn) || (cheriot_enable_i == ibex_pkg_IbexMuBiOff));
		end
		else begin : gen_no_cheriot_enable_check
			assign cheriot_enable_mubi_err = 1'b0;
		end
	endgenerate
	assign alert_major_internal_o = (((rf_ecc_err_comb | pc_mismatch_alert) | csr_shadow_err) | cheriot_fatal_err) | cheriot_enable_mubi_err;
	assign alert_major_bus_o = (lsu_load_resp_intg_err | lsu_store_resp_intg_err) | instr_intg_err;
	assign csr_wdata = alu_operand_a_ex;
	ibex_cs_registers #(
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.DataIndTiming(DataIndTiming),
		.DummyInstructions(DummyInstructions),
		.ShadowCSR(ShadowCSR),
		.ICache(ICache),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.CsrMvendorId(CsrMvendorId),
		.CsrMimpId(CsrMimpId),
		.BaseIsa(BaseIsa)
	) cs_registers_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.hart_id_i(hart_id_i),
		.priv_mode_id_o(priv_mode_id),
		.priv_mode_lsu_o(priv_mode_lsu),
		.csr_mtvec_o(csr_mtvec),
		.csr_mtvec_init_i(csr_mtvec_init),
		.boot_addr_i(boot_addr_i),
		.csr_access_i(csr_access),
		.csr_addr_i(csr_addr),
		.csr_wdata_i(csr_wdata),
		.csr_op_i(csr_op),
		.csr_op_en_i(csr_op_en),
		.csr_rdata_o(csr_rdata),
		.cheriot_csr_access_i(cheriot_csr_access),
		.cheriot_csr_addr_i(cheriot_csr_addr),
		.cheriot_csr_wdata_i(cheriot_csr_wdata),
		.cheriot_csr_wcap_i(cheriot_csr_wcap),
		.cheriot_csr_op_i(cheriot_csr_op),
		.cheriot_csr_op_en_i(cheriot_csr_op_en),
		.cheriot_csr_set_mie_i(cheriot_csr_set_mie),
		.cheriot_csr_clr_mie_i(cheriot_csr_clr_mie),
		.cheriot_csr_rdata_o(cheriot_csr_rdata),
		.cheriot_csr_rcap_o(cheriot_csr_rcap),
		.csr_mshwm_o(csr_mshwm),
		.csr_mshwmb_o(csr_mshwmb),
		.csr_mshwm_set_i(csr_mshwm_set),
		.csr_mshwm_new_i(csr_mshwm_new),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.nmi_mode_i(nmi_mode),
		.irq_pending_o(irq_pending_o),
		.irqs_o(irqs),
		.csr_mstatus_mie_o(csr_mstatus_mie),
		.csr_mstatus_tw_o(csr_mstatus_tw),
		.csr_mepc_o(csr_mepc),
		.csr_mtval_o(crash_dump_mtval),
		.csr_pmp_cfg_o(csr_pmp_cfg),
		.csr_pmp_addr_o(csr_pmp_addr),
		.csr_pmp_mseccfg_o(csr_pmp_mseccfg),
		.csr_depc_o(csr_depc),
		.debug_mode_i(debug_mode),
		.debug_mode_entering_i(debug_mode_entering),
		.debug_cause_i(debug_cause),
		.debug_csr_save_i(debug_csr_save),
		.debug_single_step_o(debug_single_step),
		.debug_ebreakm_o(debug_ebreakm),
		.debug_ebreaku_o(debug_ebreaku),
		.trigger_match_o(trigger_match),
		.pc_if_i(pc_if),
		.pc_id_i(pc_id),
		.pc_wb_i(pc_wb),
		.data_ind_timing_o(data_ind_timing),
		.dummy_instr_en_o(dummy_instr_en),
		.dummy_instr_mask_o(dummy_instr_mask),
		.dummy_instr_seed_en_o(dummy_instr_seed_en),
		.dummy_instr_seed_o(dummy_instr_seed),
		.icache_enable_o(icache_enable),
		.csr_shadow_err_o(csr_shadow_err),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.mcounteren_writable_i(mcounteren_writable_i),
		.csr_save_if_i(csr_save_if),
		.csr_save_id_i(csr_save_id),
		.csr_save_wb_i(csr_save_wb),
		.csr_restore_mret_i(csr_restore_mret_id),
		.csr_restore_dret_i(csr_restore_dret_id),
		.csr_save_cause_i(csr_save_cause),
		.csr_mepcc_clrtag_i(csr_mepcc_clrtag),
		.csr_mcause_i(exc_cause),
		.csr_mtval_i(csr_mtval),
		.illegal_csr_insn_o(illegal_csr_insn_id),
		.double_fault_seen_o(double_fault_seen_o),
		.instr_ret_i(perf_instr_ret_wb),
		.instr_ret_compressed_i(perf_instr_ret_compressed_wb),
		.instr_ret_spec_i(perf_instr_ret_wb_spec),
		.instr_ret_compressed_spec_i(perf_instr_ret_compressed_wb_spec),
		.iside_wait_i(perf_iside_wait),
		.jump_i(perf_jump),
		.branch_i(perf_branch),
		.branch_taken_i(perf_tbranch),
		.mem_load_i(perf_load),
		.mem_store_i(perf_store),
		.dside_wait_i(perf_dside_wait),
		.mul_wait_i(perf_mul_wait),
		.div_wait_i(perf_div_wait),
		.cheriot_branch_req_i(cheriot_branch_req),
		.cheriot_branch_target_i(branch_target_ex_cheriot),
		.pcc_cap_i(pcc_cap_w),
		.pcc_cap_o(pcc_cap_r),
		.csr_dbg_tclr_fault_o(csr_dbg_tclr_fault),
		.cheriot_fatal_err_o(cheriot_fatal_err)
	);
	generate
		if (PMPEnable) begin : g_pmp
			wire [31:0] pc_if_inc;
			wire [101:0] pmp_req_addr;
			wire [5:0] pmp_req_type;
			wire [5:0] pmp_priv_lvl;
			wire [0:2] pmp_req_err_raw;
			assign pc_if_inc = pc_if + 32'd2;
			if (BaseIsa == 32'sd1) begin : g_pmp_addr_gate
				assign pmp_req_addr[68+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, pc_if});
				assign pmp_req_addr[34+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, pc_if_inc});
				assign pmp_req_addr[0+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, data_addr_o[31:0]});
			end
			else begin : g_pmp_addr_no_gate
				assign pmp_req_addr[68+:34] = {2'b00, pc_if};
				assign pmp_req_addr[34+:34] = {2'b00, pc_if_inc};
				assign pmp_req_addr[0+:34] = {2'b00, data_addr_o[31:0]};
			end
			assign pmp_req_type[4+:2] = 2'b00;
			assign pmp_priv_lvl[4+:2] = priv_mode_id;
			assign pmp_req_type[2+:2] = 2'b00;
			assign pmp_priv_lvl[2+:2] = priv_mode_id;
			assign pmp_req_type[0+:2] = (data_we_o ? 2'b01 : 2'b10);
			assign pmp_priv_lvl[0+:2] = priv_mode_lsu;
			ibex_pmp #(
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.PMPGranularity(PMPGranularity),
				.PMPNumChan(PMPNumChan),
				.PMPNumRegions(PMPNumRegions)
			) pmp_i(
				.csr_pmp_cfg_i(csr_pmp_cfg),
				.csr_pmp_addr_i(csr_pmp_addr),
				.csr_pmp_mseccfg_i(csr_pmp_mseccfg),
				.debug_mode_i(debug_mode),
				.priv_mode_i(pmp_priv_lvl),
				.pmp_req_addr_i(pmp_req_addr),
				.pmp_req_type_i(pmp_req_type),
				.pmp_req_err_o(pmp_req_err_raw)
			);
			if (BaseIsa == 32'sd1) begin : g_pmp_cheriot_gate
				assign pmp_req_err[ibex_pkg_PMP_I] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_I]);
				assign pmp_req_err[ibex_pkg_PMP_I2] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_I2]);
				assign pmp_req_err[ibex_pkg_PMP_D] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_D]);
			end
			else begin : g_pmp_no_cheriot_gate
				assign pmp_req_err[ibex_pkg_PMP_I] = pmp_req_err_raw[ibex_pkg_PMP_I];
				assign pmp_req_err[ibex_pkg_PMP_I2] = pmp_req_err_raw[ibex_pkg_PMP_I2];
				assign pmp_req_err[ibex_pkg_PMP_D] = pmp_req_err_raw[ibex_pkg_PMP_D];
			end
		end
		else begin : g_no_pmp
			wire [1:0] unused_priv_lvl_ls;
			wire [(PMPNumRegions * 34) - 1:0] unused_csr_pmp_addr;
			wire [(PMPNumRegions * 6) - 1:0] unused_csr_pmp_cfg;
			wire [2:0] unused_csr_pmp_mseccfg;
			assign unused_priv_lvl_ls = priv_mode_lsu;
			assign unused_csr_pmp_addr = csr_pmp_addr;
			assign unused_csr_pmp_cfg = csr_pmp_cfg;
			assign unused_csr_pmp_mseccfg = csr_pmp_mseccfg;
			assign pmp_req_err[ibex_pkg_PMP_I] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_I2] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_D] = 1'b0;
		end
	endgenerate
	wire unused_instr_new_id;
	wire unused_instr_id_done;
	wire unused_instr_done_wb;
	wire unused_instr_expanded_id;
	wire unused_instr_gets_expanded_id;
	assign unused_instr_id_done = instr_id_done;
	assign unused_instr_new_id = instr_new_id;
	assign unused_instr_done_wb = instr_done_wb;
	assign unused_instr_expanded_id = ^instr_expanded_id;
	assign unused_instr_gets_expanded_id = ^instr_gets_expanded_id;
endmodule
module ibex_counter (
	clk_i,
	rst_ni,
	counter_inc_i,
	counterh_we_i,
	counter_we_i,
	counter_val_i,
	counter_val_o,
	counter_val_upd_o
);
	reg _sv2v_0;
	parameter signed [31:0] CounterWidth = 32;
	parameter [0:0] ProvideValUpd = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire counter_inc_i;
	input wire counterh_we_i;
	input wire counter_we_i;
	input wire [31:0] counter_val_i;
	output wire [63:0] counter_val_o;
	output wire [63:0] counter_val_upd_o;
	wire [63:0] counter;
	wire [CounterWidth - 1:0] counter_upd;
	reg [63:0] counter_load;
	reg we;
	reg [CounterWidth - 1:0] counter_d;
	assign counter_upd = counter[CounterWidth - 1:0] + {{CounterWidth - 1 {1'b0}}, 1'b1};
	always @(*) begin
		if (_sv2v_0)
			;
		we = counter_we_i | counterh_we_i;
		counter_load[63:32] = counter[63:32];
		counter_load[31:0] = counter_val_i;
		if (counterh_we_i) begin
			counter_load[63:32] = counter_val_i;
			counter_load[31:0] = counter[31:0];
		end
		if (we)
			counter_d = counter_load[CounterWidth - 1:0];
		else if (counter_inc_i)
			counter_d = counter_upd[CounterWidth - 1:0];
		else
			counter_d = counter[CounterWidth - 1:0];
	end
	localparam signed [31:0] UseDsp = "no";
	reg [CounterWidth - 1:0] counter_q;
	generate
		if (UseDsp == "yes") begin : g_cnt_dsp
			always @(posedge clk_i)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		else begin : g_cnt_no_dsp
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		if (CounterWidth < 64) begin : g_counter_narrow
			wire [63:CounterWidth] unused_counter_load;
			assign counter[CounterWidth - 1:0] = counter_q;
			assign counter[63:CounterWidth] = 1'sb0;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = 1'sb0;
			end
			assign counter_val_upd_o[63:CounterWidth] = 1'sb0;
			assign unused_counter_load = counter_load[63:CounterWidth];
		end
		else begin : g_counter_full
			assign counter = counter_q;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o = 1'sb0;
			end
		end
	endgenerate
	assign counter_val_o = counter;
	initial _sv2v_0 = 0;
endmodule
module ibex_cs_registers (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	hart_id_i,
	priv_mode_id_o,
	priv_mode_lsu_o,
	csr_mstatus_tw_o,
	csr_mtvec_o,
	csr_mtvec_init_i,
	boot_addr_i,
	csr_access_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_op_en_i,
	csr_rdata_o,
	cheriot_csr_access_i,
	cheriot_csr_addr_i,
	cheriot_csr_wdata_i,
	cheriot_csr_wcap_i,
	cheriot_csr_op_i,
	cheriot_csr_op_en_i,
	cheriot_csr_set_mie_i,
	cheriot_csr_clr_mie_i,
	cheriot_csr_rdata_o,
	cheriot_csr_rcap_o,
	csr_mshwm_o,
	csr_mshwmb_o,
	csr_mshwm_set_i,
	csr_mshwm_new_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	nmi_mode_i,
	irq_pending_o,
	irqs_o,
	csr_mstatus_mie_o,
	csr_mepc_o,
	csr_mtval_o,
	csr_pmp_cfg_o,
	csr_pmp_addr_o,
	csr_pmp_mseccfg_o,
	debug_mode_i,
	debug_mode_entering_i,
	debug_cause_i,
	debug_csr_save_i,
	csr_depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	debug_ebreaku_o,
	trigger_match_o,
	pc_if_i,
	pc_id_i,
	pc_wb_i,
	data_ind_timing_o,
	dummy_instr_en_o,
	dummy_instr_mask_o,
	dummy_instr_seed_en_o,
	dummy_instr_seed_o,
	icache_enable_o,
	csr_shadow_err_o,
	ic_scr_key_valid_i,
	mcounteren_writable_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_save_wb_i,
	csr_restore_mret_i,
	csr_restore_dret_i,
	csr_save_cause_i,
	csr_mepcc_clrtag_i,
	csr_mcause_i,
	csr_mtval_i,
	illegal_csr_insn_o,
	double_fault_seen_o,
	instr_ret_i,
	instr_ret_compressed_i,
	instr_ret_spec_i,
	instr_ret_compressed_spec_i,
	iside_wait_i,
	jump_i,
	branch_i,
	branch_taken_i,
	mem_load_i,
	mem_store_i,
	dside_wait_i,
	mul_wait_i,
	div_wait_i,
	cheriot_branch_req_i,
	cheriot_branch_target_i,
	pcc_cap_i,
	pcc_cap_o,
	csr_dbg_tclr_fault_o,
	cheriot_fatal_err_o
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] DbgTriggerEn = 0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ShadowCSR = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [31:0] MHPMCounterNum = 10;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] PMPEnable = 0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [31:0] hart_id_i;
	output wire [1:0] priv_mode_id_o;
	output wire [1:0] priv_mode_lsu_o;
	output wire csr_mstatus_tw_o;
	output wire [31:0] csr_mtvec_o;
	input wire csr_mtvec_init_i;
	input wire [31:0] boot_addr_i;
	input wire csr_access_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	input wire [1:0] csr_op_i;
	input wire csr_op_en_i;
	output wire [31:0] csr_rdata_o;
	input wire cheriot_csr_access_i;
	input wire [4:0] cheriot_csr_addr_i;
	input wire [31:0] cheriot_csr_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] cheriot_csr_wcap_i;
	input wire [4:0] cheriot_csr_op_i;
	input wire cheriot_csr_op_en_i;
	input wire cheriot_csr_set_mie_i;
	input wire cheriot_csr_clr_mie_i;
	output reg [31:0] cheriot_csr_rdata_o;
	output reg [34:0] cheriot_csr_rcap_o;
	output wire [31:0] csr_mshwm_o;
	output wire [31:0] csr_mshwmb_o;
	input wire csr_mshwm_set_i;
	input wire [31:0] csr_mshwm_new_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire nmi_mode_i;
	output wire irq_pending_o;
	output wire [17:0] irqs_o;
	output wire csr_mstatus_mie_o;
	output wire [31:0] csr_mepc_o;
	output wire [31:0] csr_mtval_o;
	output wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_o;
	output wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_o;
	output wire [2:0] csr_pmp_mseccfg_o;
	input wire debug_mode_i;
	input wire debug_mode_entering_i;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] csr_depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	output wire debug_ebreaku_o;
	output wire trigger_match_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire [31:0] pc_wb_i;
	output wire data_ind_timing_o;
	output wire dummy_instr_en_o;
	output wire [2:0] dummy_instr_mask_o;
	output wire dummy_instr_seed_en_o;
	output wire [31:0] dummy_instr_seed_o;
	output wire icache_enable_o;
	output wire csr_shadow_err_o;
	input wire ic_scr_key_valid_i;
	input wire [3:0] mcounteren_writable_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_save_wb_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_dret_i;
	input wire csr_save_cause_i;
	input wire csr_mepcc_clrtag_i;
	input wire [6:0] csr_mcause_i;
	input wire [31:0] csr_mtval_i;
	output wire illegal_csr_insn_o;
	output reg double_fault_seen_o;
	input wire instr_ret_i;
	input wire instr_ret_compressed_i;
	input wire instr_ret_spec_i;
	input wire instr_ret_compressed_spec_i;
	input wire iside_wait_i;
	input wire jump_i;
	input wire branch_i;
	input wire branch_taken_i;
	input wire mem_load_i;
	input wire mem_store_i;
	input wire dside_wait_i;
	input wire mul_wait_i;
	input wire div_wait_i;
	input wire cheriot_branch_req_i;
	input wire [31:0] cheriot_branch_target_i;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	input wire [111:0] pcc_cap_i;
	output wire [111:0] pcc_cap_o;
	output wire csr_dbg_tclr_fault_o;
	output wire cheriot_fatal_err_o;
	function automatic is_mml_m_exec_cfg;
		input reg [5:0] pmp_cfg;
		reg unused_cfg;
		reg value;
		begin
			unused_cfg = ^{pmp_cfg[4-:2]};
			value = 1'b0;
			if (pmp_cfg[5])
				(* full_case, parallel_case *)
				case ({pmp_cfg[0], pmp_cfg[1], pmp_cfg[2]})
					3'b001, 3'b010, 3'b011, 3'b101: value = 1'b1;
					default: value = 1'b0;
				endcase
			is_mml_m_exec_cfg = value;
		end
	endfunction
	localparam [31:0] RV32BExtra = (RV32B != 32'sd0 ? 1 : 0);
	localparam [31:0] RV32MEnabled = (RV32M == 32'sd0 ? 0 : 1);
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	localparam [31:0] MisaXBit = RV32BExtra | sv2v_cast_32(BaseIsa == 32'sd1);
	localparam [31:0] PMPAddrWidth = (PMPGranularity > 0 ? ibex_pkg_PMP_ADDR_MSB - PMPGranularity : 32);
	localparam [31:0] MHPMCOUNTER_BASE = 3;
	localparam [1:0] ibex_pkg_CSR_MISA_MXL = 2'd1;
	localparam [31:0] MISA_VALUE = ((((((((4 | (sv2v_cast_32(RV32E) << 4)) | 0) | (sv2v_cast_32(!RV32E) << 8)) | (RV32MEnabled << 12)) | 0) | 0) | 1048576) | (MisaXBit << 23)) | (sv2v_cast_32(ibex_pkg_CSR_MISA_MXL) << 30);
	reg [31:0] exception_pc;
	reg [1:0] priv_lvl_q;
	reg [1:0] priv_lvl_d;
	wire [5:0] mstatus_q;
	reg [5:0] mstatus_d;
	wire mstatus_err;
	reg mstatus_en;
	wire [17:0] mie_q;
	wire [17:0] mie_d;
	reg mie_en;
	wire [31:0] mscratch_q;
	reg mscratch_en;
	wire [31:0] mepc_q;
	reg [31:0] mepc_d;
	reg mepc_en;
	wire [6:0] mcause_q;
	reg [6:0] mcause_d;
	reg [34:0] mepc_cap;
	reg mcause_en;
	wire [31:0] mtval_q;
	reg [31:0] mtval_d;
	reg mtval_en;
	wire [31:0] mtvec_q;
	reg [31:0] mtvec_d;
	reg [34:0] mtvec_cap;
	wire mtvec_err;
	reg mtvec_en;
	wire [17:0] mip;
	wire [31:0] dcsr_q;
	reg [31:0] dcsr_d;
	reg dcsr_en;
	wire [31:0] depc_q;
	reg [31:0] depc_d;
	reg depc_en;
	reg [34:0] depc_cap;
	wire [31:0] dscratch0_q;
	wire [31:0] dscratch1_q;
	reg dscratch0_en;
	reg dscratch1_en;
	reg [34:0] dscratch0_cap;
	reg [34:0] dscratch1_cap;
	wire [31:0] mshwm_q;
	wire [31:0] mshwm_d;
	wire [31:0] mshwmb_q;
	reg mshwm_en;
	reg mshwmb_en;
	wire [31:0] cdbg_ctrl_q;
	reg cdbg_ctrl_en;
	reg [111:0] pcc_cap_q;
	reg [111:0] pcc_cap_d;
	wire [2:0] mstack_q;
	reg [2:0] mstack_d;
	reg mstack_en;
	wire [31:0] mstack_epc_q;
	reg [31:0] mstack_epc_d;
	wire [6:0] mstack_cause_q;
	reg [6:0] mstack_cause_d;
	reg [31:0] pmp_addr_rdata [0:15];
	localparam [31:0] ibex_pkg_PMP_CFG_W = 8;
	wire [7:0] pmp_cfg_rdata [0:15];
	wire pmp_csr_err;
	wire [2:0] pmp_mseccfg;
	wire [31:0] mcountinhibit;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcountinhibit_d;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcountinhibit_q;
	reg mcountinhibit_we;
	wire [31:0] mcounteren;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcounteren_d;
	wire [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcounteren_q;
	reg mcounteren_we;
	wire [63:0] mhpmcounter [0:31];
	reg [31:0] mhpmcounter_we;
	reg [31:0] mhpmcounterh_we;
	reg [31:0] mhpmcounter_incr;
	reg [31:0] mhpmevent [0:31];
	wire [4:0] mhpmcounter_idx;
	wire unused_mhpmcounter_we_1;
	wire unused_mhpmcounterh_we_1;
	wire unused_mhpmcounter_incr_1;
	wire [63:0] minstret_next;
	wire [63:0] minstret_raw;
	wire [31:0] tselect_rdata;
	wire [31:0] tmatch_control_rdata;
	wire [31:0] tmatch_value_rdata;
	wire [7:0] cpuctrlsts_part_q;
	reg [7:0] cpuctrlsts_part_d;
	wire [7:0] cpuctrlsts_part_wdata_raw;
	wire [7:0] cpuctrlsts_part_wdata;
	reg cpuctrlsts_part_we;
	wire cpuctrlsts_part_err;
	wire cpuctrlsts_ic_scr_key_valid_q;
	wire cpuctrlsts_ic_scr_key_err;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	wire csr_we_int;
	wire csr_wr;
	reg dbg_csr;
	reg illegal_csr;
	wire illegal_csr_priv;
	wire illegal_csr_dbg;
	wire illegal_csr_write;
	wire [7:0] unused_boot_addr;
	wire [2:0] unused_csr_addr;
	wire mepc_en_combi;
	wire mepc_en_cheriot;
	wire [31:0] mepc_d_combi;
	wire mtvec_en_combi;
	wire mtvec_en_cheriot;
	wire [31:0] mtvec_d_combi;
	wire depc_en_combi;
	wire depc_en_cheriot;
	wire [31:0] depc_d_combi;
	wire dscratch0_en_combi;
	wire dscratch0_en_cheriot;
	wire [31:0] dscratch0_d_combi;
	wire dscratch1_en_combi;
	wire dscratch1_en_cheriot;
	wire [31:0] dscratch1_d_combi;
	assign unused_boot_addr = boot_addr_i[7:0];
	wire [31:0] misa_value_masked;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign misa_value_masked = {MISA_VALUE[31:24], (BaseIsa == 32'sd1 ? (cheriot_enable_i == ibex_pkg_IbexMuBiOn) || (RV32BExtra != 0) : MISA_VALUE[23]), MISA_VALUE[22:9], (BaseIsa == 32'sd1 ? cheriot_enable_i != ibex_pkg_IbexMuBiOn : MISA_VALUE[8]), MISA_VALUE[7:5], (BaseIsa == 32'sd1 ? cheriot_enable_i == ibex_pkg_IbexMuBiOn : MISA_VALUE[4]), MISA_VALUE[3:0]};
	wire [11:0] csr_addr;
	assign csr_addr = csr_addr_i;
	assign unused_csr_addr = csr_addr[7:5];
	assign mhpmcounter_idx = csr_addr[4:0];
	assign illegal_csr_dbg = dbg_csr & ~debug_mode_i;
	assign illegal_csr_priv = csr_addr[9:8] > priv_lvl_q;
	assign illegal_csr_write = (csr_addr[11:10] == 2'b11) && csr_wr;
	assign illegal_csr_insn_o = csr_access_i & (((illegal_csr | illegal_csr_write) | illegal_csr_priv) | illegal_csr_dbg);
	assign mip[17] = irq_software_i;
	assign mip[16] = irq_timer_i;
	assign mip[15] = irq_external_i;
	assign mip[14-:15] = irq_fast_i;
	localparam [31:0] ibex_pkg_CSR_MARCHID_CHERIOT_VALUE = 32'h00000ce1;
	localparam [31:0] ibex_pkg_CSR_MARCHID_VALUE = 32'h00000016;
	localparam [31:0] ibex_pkg_CSR_MCONFIGPTR_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_HIGH = 30;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_LOW = 16;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MML_BIT = 0;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MMWP_BIT = 1;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_RLB_BIT = 2;
	localparam [31:0] ibex_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MIE_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPIE_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH = 12;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW = 11;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPRV_BIT = 17;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_TW_BIT = 21;
	localparam [31:0] ibex_pkg_CSR_MTIX_BIT = 7;
	always @(*) begin
		if (_sv2v_0)
			;
		csr_rdata_int = 1'sb0;
		illegal_csr = 1'b0;
		dbg_csr = 1'b0;
		(* full_case, parallel_case *)
		case (csr_addr_i)
			12'hf11: csr_rdata_int = CsrMvendorId;
			12'hf12: csr_rdata_int = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? ibex_pkg_CSR_MARCHID_CHERIOT_VALUE : ibex_pkg_CSR_MARCHID_VALUE);
			12'hf13: csr_rdata_int = CsrMimpId;
			12'hf14: csr_rdata_int = hart_id_i;
			12'hf15: csr_rdata_int = ibex_pkg_CSR_MCONFIGPTR_VALUE;
			12'h300: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT] = mstatus_q[5];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT] = mstatus_q[4];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW] = mstatus_q[3-:2];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT] = mstatus_q[1];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT] = mstatus_q[0];
			end
			12'h310: csr_rdata_int = 1'sb0;
			12'h30a, 12'h31a: csr_rdata_int = 1'sb0;
			12'h301: csr_rdata_int = misa_value_masked;
			12'h304: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mie_q[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mie_q[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mie_q[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mie_q[14-:15];
			end
			12'h306: csr_rdata_int = mcounteren;
			12'h340: csr_rdata_int = mscratch_q;
			12'h305:
				if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
					illegal_csr = 1'b1;
				else
					csr_rdata_int = mtvec_q;
			12'h341:
				if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
					illegal_csr = 1'b1;
				else
					csr_rdata_int = mepc_q;
			12'h342: csr_rdata_int = {mcause_q[5] | mcause_q[6], (mcause_q[6] ? {26 {1'b1}} : 26'b00000000000000000000000000), mcause_q[4:0]};
			12'h343: csr_rdata_int = mtval_q;
			12'h344: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mip[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mip[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mip[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mip[14-:15];
			end
			12'h747:
				if (PMPEnable && !((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))) begin
					csr_rdata_int = 1'sb0;
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT] = pmp_mseccfg[0];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT] = pmp_mseccfg[1];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT] = pmp_mseccfg[2];
				end
				else
					illegal_csr = 1'b1;
			12'h757:
				if (PMPEnable && !((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn)))
					csr_rdata_int = 1'sb0;
				else
					illegal_csr = 1'b1;
			12'h3a0: csr_rdata_int = {pmp_cfg_rdata[3], pmp_cfg_rdata[2], pmp_cfg_rdata[1], pmp_cfg_rdata[0]};
			12'h3a1: csr_rdata_int = {pmp_cfg_rdata[7], pmp_cfg_rdata[6], pmp_cfg_rdata[5], pmp_cfg_rdata[4]};
			12'h3a2: csr_rdata_int = {pmp_cfg_rdata[11], pmp_cfg_rdata[10], pmp_cfg_rdata[9], pmp_cfg_rdata[8]};
			12'h3a3: csr_rdata_int = {pmp_cfg_rdata[15], pmp_cfg_rdata[14], pmp_cfg_rdata[13], pmp_cfg_rdata[12]};
			12'h3b0: csr_rdata_int = pmp_addr_rdata[0];
			12'h3b1: csr_rdata_int = pmp_addr_rdata[1];
			12'h3b2: csr_rdata_int = pmp_addr_rdata[2];
			12'h3b3: csr_rdata_int = pmp_addr_rdata[3];
			12'h3b4: csr_rdata_int = pmp_addr_rdata[4];
			12'h3b5: csr_rdata_int = pmp_addr_rdata[5];
			12'h3b6: csr_rdata_int = pmp_addr_rdata[6];
			12'h3b7: csr_rdata_int = pmp_addr_rdata[7];
			12'h3b8: csr_rdata_int = pmp_addr_rdata[8];
			12'h3b9: csr_rdata_int = pmp_addr_rdata[9];
			12'h3ba: csr_rdata_int = pmp_addr_rdata[10];
			12'h3bb: csr_rdata_int = pmp_addr_rdata[11];
			12'h3bc: csr_rdata_int = pmp_addr_rdata[12];
			12'h3bd: csr_rdata_int = pmp_addr_rdata[13];
			12'h3be: csr_rdata_int = pmp_addr_rdata[14];
			12'h3bf: csr_rdata_int = pmp_addr_rdata[15];
			12'h7b0: begin
				csr_rdata_int = dcsr_q;
				dbg_csr = 1'b1;
			end
			12'h7b1: begin
				csr_rdata_int = depc_q;
				dbg_csr = 1'b1;
			end
			12'h7b2: begin
				csr_rdata_int = dscratch0_q;
				dbg_csr = 1'b1;
			end
			12'h7b3: begin
				csr_rdata_int = dscratch1_q;
				dbg_csr = 1'b1;
			end
			12'h320: csr_rdata_int = mcountinhibit;
			12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent[mhpmcounter_idx];
			12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
			12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
			12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f: begin
				csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
				illegal_csr = (priv_lvl_q == 2'b00) && !mcounteren[mhpmcounter_idx];
			end
			12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f: begin
				csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
				illegal_csr = (priv_lvl_q == 2'b00) && !mcounteren[mhpmcounter_idx];
			end
			12'h7a0: begin
				csr_rdata_int = tselect_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a1: begin
				csr_rdata_int = tmatch_control_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a2: begin
				csr_rdata_int = tmatch_value_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a3: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h5a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7aa: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7c0: csr_rdata_int = {{23 {1'b0}}, cpuctrlsts_ic_scr_key_valid_q, cpuctrlsts_part_q};
			12'h7c1: csr_rdata_int = 1'sb0;
			12'hbc1:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = mshwm_q;
				else
					illegal_csr = 1'b1;
			12'hbc2:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = mshwmb_q;
				else
					illegal_csr = 1'b1;
			12'hbc4:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = cdbg_ctrl_q;
				else
					illegal_csr = 1'b1;
			default: illegal_csr = 1'b1;
		endcase
		if (!PMPEnable || ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))) begin
			if (|{csr_addr == 12'h3a0, csr_addr == 12'h3a1, csr_addr == 12'h3a2, csr_addr == 12'h3a3, csr_addr == 12'h3b0, csr_addr == 12'h3b1, csr_addr == 12'h3b2, csr_addr == 12'h3b3, csr_addr == 12'h3b4, csr_addr == 12'h3b5, csr_addr == 12'h3b6, csr_addr == 12'h3b7, csr_addr == 12'h3b8, csr_addr == 12'h3b9, csr_addr == 12'h3ba, csr_addr == 12'h3bb, csr_addr == 12'h3bc, csr_addr == 12'h3bd, csr_addr == 12'h3be, csr_addr == 12'h3bf})
				illegal_csr = 1'b1;
		end
	end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		exception_pc = pc_id_i;
		priv_lvl_d = priv_lvl_q;
		mstatus_en = 1'b0;
		mstatus_d = mstatus_q;
		mie_en = 1'b0;
		mscratch_en = 1'b0;
		mepc_en = 1'b0;
		mepc_d = {csr_wdata_int[31:1], 1'b0};
		mcause_en = 1'b0;
		mcause_d = {csr_wdata_int[31:30] == 2'b11, csr_wdata_int[31:30] == 2'b10, csr_wdata_int[4:0]};
		mtval_en = 1'b0;
		mtval_d = csr_wdata_int;
		mtvec_en = csr_mtvec_init_i;
		mtvec_d = (csr_mtvec_init_i ? {boot_addr_i[31:8], 7'b0000000, ~((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn))} : {csr_wdata_int[31:8], 7'b0000000, ~((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn))});
		dcsr_en = 1'b0;
		dcsr_d = dcsr_q;
		depc_d = {csr_wdata_int[31:1], 1'b0};
		depc_en = 1'b0;
		dscratch0_en = 1'b0;
		dscratch1_en = 1'b0;
		mstack_en = 1'b0;
		mstack_d[2] = mstatus_q[4];
		mstack_d[1-:2] = mstatus_q[3-:2];
		mstack_epc_d = mepc_q;
		mstack_cause_d = mcause_q;
		mcountinhibit_we = 1'b0;
		mcounteren_we = 1'b0;
		mhpmcounter_we = 1'sb0;
		mhpmcounterh_we = 1'sb0;
		cpuctrlsts_part_we = 1'b0;
		cpuctrlsts_part_d = cpuctrlsts_part_q;
		mshwm_en = 1'b0;
		mshwmb_en = 1'b0;
		cdbg_ctrl_en = 1'b0;
		double_fault_seen_o = 1'b0;
		if (csr_we_int)
			(* full_case, parallel_case *)
			case (csr_addr_i)
				12'h300: begin
					mstatus_en = 1'b1;
					mstatus_d = {csr_wdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW]), csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT]};
					if ((mstatus_d[3-:2] != 2'b11) && (mstatus_d[3-:2] != 2'b00))
						mstatus_d[3-:2] = 2'b00;
				end
				12'h304: mie_en = 1'b1;
				12'h340: mscratch_en = 1'b1;
				12'h341: mepc_en = ~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn);
				12'h342: mcause_en = 1'b1;
				12'h343: mtval_en = 1'b1;
				12'h305: mtvec_en = ~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn);
				12'h7b0: begin
					dcsr_d = csr_wdata_int;
					dcsr_d[31-:4] = 4'd4;
					if ((dcsr_d[1-:2] != 2'b11) && (dcsr_d[1-:2] != 2'b00))
						dcsr_d[1-:2] = 2'b00;
					dcsr_d[8-:3] = dcsr_q[8-:3];
					dcsr_d[11] = 1'b0;
					dcsr_d[3] = 1'b0;
					dcsr_d[4] = 1'b0;
					dcsr_d[10] = 1'b0;
					dcsr_d[9] = 1'b0;
					dcsr_d[5] = 1'b0;
					dcsr_d[14] = 1'b0;
					dcsr_d[27-:12] = 12'h000;
					dcsr_en = 1'b1;
				end
				12'h7b1: depc_en = 1'b1;
				12'h7b2: dscratch0_en = 1'b1;
				12'h7b3: dscratch1_en = 1'b1;
				12'h306: mcounteren_we = mcounteren_writable_i == ibex_pkg_IbexMuBiOn;
				12'h320: mcountinhibit_we = 1'b1;
				12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: mhpmcounter_we[mhpmcounter_idx] = 1'b1;
				12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: mhpmcounterh_we[mhpmcounter_idx] = 1'b1;
				12'h7c0: begin
					cpuctrlsts_part_d = cpuctrlsts_part_wdata;
					cpuctrlsts_part_we = 1'b1;
				end
				12'hbc1: mshwm_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				12'hbc2: mshwmb_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				12'hbc4: cdbg_ctrl_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				default:
					;
			endcase
		(* full_case, parallel_case *)
		case (1'b1)
			csr_save_cause_i: begin
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_if_i: exception_pc = pc_if_i;
					csr_save_id_i: exception_pc = pc_id_i;
					csr_save_wb_i: exception_pc = pc_wb_i;
					default:
						;
				endcase
				priv_lvl_d = 2'b11;
				if (debug_csr_save_i) begin
					dcsr_d[1-:2] = priv_lvl_q;
					dcsr_d[8-:3] = debug_cause_i;
					dcsr_en = 1'b1;
					depc_d = exception_pc;
					depc_en = 1'b1;
				end
				else if (!debug_mode_i) begin
					mtval_en = 1'b1;
					mtval_d = csr_mtval_i;
					mstatus_en = 1'b1;
					mstatus_d[5] = 1'b0;
					mstatus_d[4] = mstatus_q[5];
					mstatus_d[3-:2] = priv_lvl_q;
					mepc_en = 1'b1;
					mepc_d = exception_pc;
					mcause_en = 1'b1;
					mcause_d = csr_mcause_i;
					mstack_en = 1'b1;
					if (!(mcause_d[5] || mcause_d[6])) begin
						cpuctrlsts_part_we = 1'b1;
						cpuctrlsts_part_d[6] = 1'b1;
						if (cpuctrlsts_part_q[6]) begin
							double_fault_seen_o = 1'b1;
							cpuctrlsts_part_d[7] = 1'b1;
						end
					end
				end
			end
			csr_restore_dret_i: priv_lvl_d = dcsr_q[1-:2];
			csr_restore_mret_i: begin
				priv_lvl_d = mstatus_q[3-:2];
				mstatus_en = 1'b1;
				mstatus_d[5] = mstatus_q[4];
				if (mstatus_q[3-:2] != 2'b11)
					mstatus_d[1] = 1'b0;
				cpuctrlsts_part_we = 1'b1;
				cpuctrlsts_part_d[6] = 1'b0;
				if (nmi_mode_i) begin
					mstatus_d[4] = mstack_q[2];
					mstatus_d[3-:2] = mstack_q[1-:2];
					mepc_en = 1'b1;
					mepc_d = mstack_epc_q;
					mcause_en = 1'b1;
					mcause_d = mstack_cause_q;
				end
				else begin
					mstatus_d[4] = 1'b1;
					mstatus_d[3-:2] = 2'b00;
				end
			end
			default:
				;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			priv_lvl_q <= 2'b11;
		else
			priv_lvl_q <= priv_lvl_d;
	assign priv_mode_id_o = priv_lvl_q;
	assign priv_mode_lsu_o = (mstatus_q[1] ? mstatus_q[3-:2] : priv_lvl_q);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (csr_op_i)
			2'd1: csr_wdata_int = csr_wdata_i;
			2'd2: csr_wdata_int = csr_wdata_i | csr_rdata_o;
			2'd3: csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			2'd0: csr_wdata_int = csr_wdata_i;
			default: csr_wdata_int = csr_wdata_i;
		endcase
	end
	assign csr_wr = |{csr_op_i == 2'd1, csr_op_i == 2'd2, csr_op_i == 2'd3};
	assign csr_we_int = ((csr_wr & csr_op_en_i) & (((~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn)) | debug_mode_i) | pcc_cap_q[42])) & ~illegal_csr_insn_o;
	assign csr_rdata_o = csr_rdata_int;
	assign csr_mepc_o = mepc_q;
	assign csr_depc_o = depc_q;
	assign csr_mtvec_o = mtvec_q;
	assign csr_mtval_o = mtval_q;
	assign csr_mshwm_o = mshwm_q;
	assign csr_mshwmb_o = mshwmb_q;
	assign csr_mstatus_mie_o = mstatus_q[5];
	assign csr_mstatus_tw_o = mstatus_q[0];
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	assign debug_ebreaku_o = dcsr_q[12];
	assign irqs_o = mip & mie_q;
	assign irq_pending_o = |irqs_o;
	localparam [5:0] MSTATUS_RST_VAL = 6'b010000;
	wire mstatus_en_combi;
	reg [5:0] mstatus_d_combi;
	assign mstatus_en_combi = mstatus_en | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & (cheriot_csr_clr_mie_i | cheriot_csr_set_mie_i));
	always @(*) begin
		if (_sv2v_0)
			;
		mstatus_d_combi = mstatus_d;
		mstatus_d_combi[5] = (mstatus_d[5] & ~((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_csr_clr_mie_i)) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_csr_set_mie_i);
	end
	ibex_csr #(
		.Width(6),
		.ShadowCopy(ShadowCSR),
		.ResetValue({MSTATUS_RST_VAL})
	) u_mstatus_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstatus_d_combi}),
		.wr_en_i(mstatus_en_combi),
		.rd_data_o(mstatus_q),
		.rd_error_o(mstatus_err)
	);
	assign mepc_en_combi = mepc_en | mepc_en_cheriot;
	assign mepc_d_combi = ({32 {mepc_en}} & mepc_d) | ({32 {mepc_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mepc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mepc_d_combi),
		.wr_en_i(mepc_en_combi),
		.rd_data_o(mepc_q),
		.rd_error_o()
	);
	assign mie_d[17] = csr_wdata_int[ibex_pkg_CSR_MSIX_BIT];
	assign mie_d[16] = csr_wdata_int[ibex_pkg_CSR_MTIX_BIT];
	assign mie_d[15] = csr_wdata_int[ibex_pkg_CSR_MEIX_BIT];
	assign mie_d[14-:15] = csr_wdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW];
	ibex_csr #(
		.Width(18),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mie_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mie_d}),
		.wr_en_i(mie_en),
		.rd_data_o(mie_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mscratch_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(mscratch_en),
		.rd_data_o(mscratch_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mcause_d}),
		.wr_en_i(mcause_en),
		.rd_data_o(mcause_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mtval_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtval_d),
		.wr_en_i(mtval_en),
		.rd_data_o(mtval_q),
		.rd_error_o()
	);
	assign mtvec_en_combi = mtvec_en | mtvec_en_cheriot;
	assign mtvec_d_combi = ({32 {mtvec_en}} & mtvec_d) | ({32 {mtvec_en_cheriot}} & {cheriot_csr_wdata_i[31:2], 2'b00});
	ibex_csr #(
		.Width(32),
		.ShadowCopy(ShadowCSR),
		.ResetValue(32'd1)
	) u_mtvec_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtvec_d_combi),
		.wr_en_i(mtvec_en_combi),
		.rd_data_o(mtvec_q),
		.rd_error_o(mtvec_err)
	);
	localparam [31:0] DCSR_RESET_VAL = 32'h40000003;
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue({DCSR_RESET_VAL})
	) u_dcsr_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({dcsr_d}),
		.wr_en_i(dcsr_en),
		.rd_data_o(dcsr_q),
		.rd_error_o()
	);
	assign depc_en_combi = depc_en | depc_en_cheriot;
	assign depc_d_combi = ({32 {depc_en}} & depc_d) | ({32 {depc_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_depc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(depc_d_combi),
		.wr_en_i(depc_en_combi),
		.rd_data_o(depc_q),
		.rd_error_o()
	);
	assign dscratch0_en_combi = dscratch0_en | dscratch0_en_cheriot;
	assign dscratch0_d_combi = ({32 {dscratch0_en}} & csr_wdata_int) | ({32 {dscratch0_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch0_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(dscratch0_d_combi),
		.wr_en_i(dscratch0_en_combi),
		.rd_data_o(dscratch0_q),
		.rd_error_o()
	);
	assign dscratch1_en_combi = dscratch1_en | dscratch1_en_cheriot;
	assign dscratch1_d_combi = ({32 {dscratch1_en}} & csr_wdata_int) | ({32 {dscratch1_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch1_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(dscratch1_d_combi),
		.wr_en_i(dscratch1_en_combi),
		.rd_data_o(dscratch1_q),
		.rd_error_o()
	);
	localparam [2:0] MSTACK_RESET_VAL = 3'b100;
	ibex_csr #(
		.Width(3),
		.ShadowCopy(1'b0),
		.ResetValue({MSTACK_RESET_VAL})
	) u_mstack_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstack_d}),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_epc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_epc_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_epc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_cause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_cause_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_cause_q),
		.rd_error_o()
	);
	wire mshwm_en_combi;
	assign mshwm_en_combi = mshwm_en | csr_mshwm_set_i;
	assign mshwm_d = (csr_mshwm_set_i ? csr_mshwm_new_i : {csr_wdata_int[31:4], 4'h0});
	generate
		if (BaseIsa == 32'sd1) begin : g_mshwm
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_mshwm_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(mshwm_d),
				.wr_en_i(mshwm_en_combi),
				.rd_data_o(mshwm_q),
				.rd_error_o()
			);
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_mshwmb_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i({csr_wdata_int[31:4], 4'h0}),
				.wr_en_i(mshwmb_en),
				.rd_data_o(mshwmb_q),
				.rd_error_o()
			);
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_cdbg_ctrl_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i({31'h00000000, csr_wdata_int[0]}),
				.wr_en_i(cdbg_ctrl_en),
				.rd_data_o(cdbg_ctrl_q),
				.rd_error_o()
			);
			assign csr_dbg_tclr_fault_o = cdbg_ctrl_q[0];
		end
		else begin : g_mshwm_tieoff
			assign mshwm_q = 1'sb0;
			assign mshwmb_q = 1'sb0;
			assign cdbg_ctrl_q = 1'sb0;
			assign csr_dbg_tclr_fault_o = 1'b0;
			wire unused_mshwm_sigs;
			assign unused_mshwm_sigs = ^{mshwm_d, mshwmb_en, cdbg_ctrl_en, mshwm_en_combi};
		end
	endgenerate
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_ADDR = 12'h3b0;
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_CFG = 12'h3a0;
	generate
		if (PMPEnable) begin : g_pmp_registers
			wire [2:0] pmp_mseccfg_q;
			wire [2:0] pmp_mseccfg_d;
			wire pmp_mseccfg_we;
			wire pmp_mseccfg_err;
			wire [5:0] pmp_cfg [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_locked;
			wire [PMPNumRegions - 1:0] pmp_cfg_wr_suppress;
			reg [5:0] pmp_cfg_wdata [0:PMPNumRegions - 1];
			wire [PMPAddrWidth - 1:0] pmp_addr [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_we;
			wire [PMPNumRegions - 1:0] pmp_cfg_err;
			wire [PMPNumRegions - 1:0] pmp_addr_we;
			wire [PMPNumRegions - 1:0] pmp_addr_err;
			wire any_pmp_entry_locked;
			genvar _gv_i_20;
			for (_gv_i_20 = 0; _gv_i_20 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_20 = _gv_i_20 + 1) begin : g_exp_rd_data
				localparam i = _gv_i_20;
				if (i < PMPNumRegions) begin : g_implemented_regions
					assign pmp_cfg_rdata[i] = {pmp_cfg[i][5], 2'b00, pmp_cfg[i][4-:2], pmp_cfg[i][2], pmp_cfg[i][1], pmp_cfg[i][0]};
					if (PMPGranularity == 0) begin : g_pmp_g0
						wire [32:1] sv2v_tmp_2683A;
						assign sv2v_tmp_2683A = pmp_addr[i];
						always @(*) pmp_addr_rdata[i] = sv2v_tmp_2683A;
					end
					else if (PMPGranularity == 1) begin : g_pmp_g1
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = pmp_addr[i];
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
					else begin : g_pmp_g2
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = {pmp_addr[i], {PMPGranularity - 1 {1'b1}}};
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
				end
				else begin : g_other_regions
					assign pmp_cfg_rdata[i] = 1'sb0;
					wire [32:1] sv2v_tmp_D50E5;
					assign sv2v_tmp_D50E5 = 1'sb0;
					always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				end
			end
			genvar _gv_i_21;
			for (_gv_i_21 = 0; _gv_i_21 < PMPNumRegions; _gv_i_21 = _gv_i_21 + 1) begin : g_pmp_csrs
				localparam i = _gv_i_21;
				assign pmp_cfg_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & ~pmp_cfg_wr_suppress[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_CFG + (i[11:0] >> 2)));
				wire [1:1] sv2v_tmp_8F287;
				assign sv2v_tmp_8F287 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 7];
				always @(*) pmp_cfg_wdata[i][5] = sv2v_tmp_8F287;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 3+:2])
						2'b00: pmp_cfg_wdata[i][4-:2] = 2'b00;
						2'b01: pmp_cfg_wdata[i][4-:2] = 2'b01;
						2'b10: pmp_cfg_wdata[i][4-:2] = (PMPGranularity == 0 ? 2'b10 : 2'b00);
						2'b11: pmp_cfg_wdata[i][4-:2] = 2'b11;
						default: pmp_cfg_wdata[i][4-:2] = 2'b00;
					endcase
				end
				wire [1:1] sv2v_tmp_45785;
				assign sv2v_tmp_45785 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 2];
				always @(*) pmp_cfg_wdata[i][2] = sv2v_tmp_45785;
				wire [1:1] sv2v_tmp_BB30C;
				assign sv2v_tmp_BB30C = (pmp_mseccfg_q[0] ? csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 1] : &csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W+:2]);
				always @(*) pmp_cfg_wdata[i][1] = sv2v_tmp_BB30C;
				wire [1:1] sv2v_tmp_F1349;
				assign sv2v_tmp_F1349 = csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W];
				always @(*) pmp_cfg_wdata[i][0] = sv2v_tmp_F1349;
				ibex_csr #(
					.Width(6),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstCfg[(15 - i) * 6+:6])
				) u_pmp_cfg_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i({pmp_cfg_wdata[i]}),
					.wr_en_i(pmp_cfg_we[i]),
					.rd_data_o(pmp_cfg[i]),
					.rd_error_o(pmp_cfg_err[i])
				);
				assign pmp_cfg_locked[i] = pmp_cfg[i][5] & ~pmp_mseccfg_q[2];
				assign pmp_cfg_wr_suppress[i] = (pmp_mseccfg_q[0] & ~pmp_mseccfg_q[2]) & is_mml_m_exec_cfg(pmp_cfg_wdata[i]);
				if (i < (PMPNumRegions - 1)) begin : g_lower
					assign pmp_addr_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & (~pmp_cfg_locked[i + 1] | (pmp_cfg[i + 1][4-:2] != 2'b01))) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				else begin : g_upper
					assign pmp_addr_we[i] = (csr_we_int & ~pmp_cfg_locked[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				ibex_csr #(
					.Width(PMPAddrWidth),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstAddr[((15 - i) * 34) + ibex_pkg_PMP_ADDR_MSB-:PMPAddrWidth])
				) u_pmp_addr_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(csr_wdata_int[31-:PMPAddrWidth]),
					.wr_en_i(pmp_addr_we[i]),
					.rd_data_o(pmp_addr[i]),
					.rd_error_o(pmp_addr_err[i])
				);
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = pmp_cfg[i];
				assign csr_pmp_addr_o[0 + (((PMPNumRegions - 1) - i) * 34)+:34] = {pmp_addr_rdata[i], 2'b00};
			end
			assign pmp_mseccfg_we = csr_we_int & (csr_addr == 12'h747);
			assign pmp_mseccfg_d[0] = (pmp_mseccfg_q[0] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT]);
			assign pmp_mseccfg_d[1] = (pmp_mseccfg_q[1] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT]);
			assign any_pmp_entry_locked = |pmp_cfg_locked;
			assign pmp_mseccfg_d[2] = (any_pmp_entry_locked ? 1'b0 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT]);
			ibex_csr #(
				.Width(3),
				.ShadowCopy(ShadowCSR),
				.ResetValue(PMPRstMsecCfg)
			) u_pmp_mseccfg(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(pmp_mseccfg_d),
				.wr_en_i(pmp_mseccfg_we),
				.rd_data_o(pmp_mseccfg_q),
				.rd_error_o(pmp_mseccfg_err)
			);
			assign pmp_csr_err = (|pmp_cfg_err | (|pmp_addr_err)) | pmp_mseccfg_err;
			assign pmp_mseccfg = pmp_mseccfg_q;
		end
		else begin : g_no_pmp_tieoffs
			genvar _gv_i_22;
			for (_gv_i_22 = 0; _gv_i_22 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_22 = _gv_i_22 + 1) begin : g_rdata
				localparam i = _gv_i_22;
				wire [32:1] sv2v_tmp_D50E5;
				assign sv2v_tmp_D50E5 = 1'sb0;
				always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				assign pmp_cfg_rdata[i] = 1'sb0;
			end
			genvar _gv_i_23;
			for (_gv_i_23 = 0; _gv_i_23 < PMPNumRegions; _gv_i_23 = _gv_i_23 + 1) begin : g_outputs
				localparam i = _gv_i_23;
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = 6'b000000;
				assign csr_pmp_addr_o[0 + (((PMPNumRegions - 1) - i) * 34)+:34] = 1'sb0;
			end
			assign pmp_csr_err = 1'b0;
			assign pmp_mseccfg = 1'sb0;
		end
	endgenerate
	assign csr_pmp_mseccfg_o = pmp_mseccfg;
	always @(*) begin : mcountinhibit_update
		if (_sv2v_0)
			;
		if (mcountinhibit_we == 1'b1) begin
			mcountinhibit_d = csr_wdata_int[(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0];
			mcountinhibit_d[1] = 1'b0;
		end
		else
			mcountinhibit_d = mcountinhibit_q;
	end
	always @(*) begin : mcounteren_update
		if (_sv2v_0)
			;
		if (mcounteren_we == 1'b1) begin
			mcounteren_d = csr_wdata_int[(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0];
			mcounteren_d[1] = 1'b0;
		end
		else
			mcounteren_d = mcounteren_q;
	end
	always @(*) begin : gen_mhpmcounter_incr
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmcounter_incr_inactive
					mhpmcounter_incr[i] = 1'b0;
				end
		end
		mhpmcounter_incr[0] = 1'b1;
		mhpmcounter_incr[1] = 1'b0;
		mhpmcounter_incr[2] = instr_ret_i;
		mhpmcounter_incr[3] = dside_wait_i;
		mhpmcounter_incr[4] = iside_wait_i;
		mhpmcounter_incr[5] = mem_load_i;
		mhpmcounter_incr[6] = mem_store_i;
		mhpmcounter_incr[7] = jump_i;
		mhpmcounter_incr[8] = branch_i;
		mhpmcounter_incr[9] = branch_taken_i;
		mhpmcounter_incr[10] = instr_ret_compressed_i;
		mhpmcounter_incr[11] = mul_wait_i;
		mhpmcounter_incr[12] = div_wait_i;
	end
	always @(*) begin : gen_mhpmevent
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmevent_active
					mhpmevent[i] = 1'sb0;
					if (i >= MHPMCOUNTER_BASE)
						mhpmevent[i][i - MHPMCOUNTER_BASE] = 1'b1;
				end
		end
		mhpmevent[1] = 1'sb0;
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = MHPMCOUNTER_BASE + MHPMCounterNum; i < 32; i = i + 1)
				begin : gen_mhpmevent_inactive
					mhpmevent[i] = 1'sb0;
				end
		end
	end
	ibex_counter #(.CounterWidth(64)) mcycle_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[0] & ~mcountinhibit[0]),
		.counterh_we_i(mhpmcounterh_we[0]),
		.counter_we_i(mhpmcounter_we[0]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(mhpmcounter[0]),
		.counter_val_upd_o()
	);
	ibex_counter #(
		.CounterWidth(64),
		.ProvideValUpd(1)
	) minstret_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[2] & ~mcountinhibit[2]),
		.counterh_we_i(mhpmcounterh_we[2]),
		.counter_we_i(mhpmcounter_we[2]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(minstret_raw),
		.counter_val_upd_o(minstret_next)
	);
	assign mhpmcounter[2] = (instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw);
	assign mhpmcounter[1] = 1'sb0;
	assign unused_mhpmcounter_we_1 = mhpmcounter_we[1];
	assign unused_mhpmcounterh_we_1 = mhpmcounterh_we[1];
	assign unused_mhpmcounter_incr_1 = mhpmcounter_incr[1];
	genvar _gv_i_24;
	generate
		for (_gv_i_24 = 0; _gv_i_24 < 29; _gv_i_24 = _gv_i_24 + 1) begin : gen_cntrs
			localparam i = _gv_i_24;
			localparam signed [31:0] Cnt = i + MHPMCOUNTER_BASE;
			if (i < MHPMCounterNum) begin : gen_imp
				wire [63:0] mhpmcounter_raw;
				wire [63:0] mhpmcounter_next;
				ibex_counter #(
					.CounterWidth(MHPMCounterWidth),
					.ProvideValUpd(Cnt == 10)
				) mcounters_variable_i(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.counter_inc_i(mhpmcounter_incr[Cnt] & ~mcountinhibit[Cnt]),
					.counterh_we_i(mhpmcounterh_we[Cnt]),
					.counter_we_i(mhpmcounter_we[Cnt]),
					.counter_val_i(csr_wdata_int),
					.counter_val_o(mhpmcounter_raw),
					.counter_val_upd_o(mhpmcounter_next)
				);
				if (Cnt == 10) begin : gen_compressed_instr_cnt
					assign mhpmcounter[Cnt] = (instr_ret_compressed_spec_i & ~mcountinhibit[Cnt] ? mhpmcounter_next : mhpmcounter_raw);
				end
				else begin : gen_other_cnts
					wire [63:0] unused_mhpmcounter_next;
					assign mhpmcounter[Cnt] = mhpmcounter_raw;
					assign unused_mhpmcounter_next = mhpmcounter_next;
				end
			end
			else begin : gen_unimp
				assign mhpmcounter[Cnt] = 1'sb0;
				if (Cnt == 10) begin : gen_no_compressed_instr_cnt
					wire unused_instr_ret_compressed_spec_i;
					assign unused_instr_ret_compressed_spec_i = instr_ret_compressed_spec_i;
				end
			end
		end
		if (MHPMCounterNum < 29) begin : g_mcountinhibit_reduced
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounterh_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_incr;
			assign mcountinhibit = {{29 - MHPMCounterNum {1'b0}}, mcountinhibit_q};
			assign unused_mhphcounter_we = mhpmcounter_we[31:MHPMCounterNum + MHPMCOUNTER_BASE];
			assign unused_mhphcounterh_we = mhpmcounterh_we[31:MHPMCounterNum + MHPMCOUNTER_BASE];
			assign unused_mhphcounter_incr = mhpmcounter_incr[31:MHPMCounterNum + MHPMCOUNTER_BASE];
		end
		else begin : g_mcountinhibit_full
			assign mcountinhibit = mcountinhibit_q;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mcountinhibit_q <= 1'sb0;
		else
			mcountinhibit_q <= mcountinhibit_d;
	generate
		if (MHPMCounterNum < 29) begin : g_mcounteren_reduced
			assign mcounteren = {{29 - MHPMCounterNum {1'b0}}, mcounteren_q};
		end
		else begin : g_mcounteren_full
			assign mcounteren = mcounteren_q;
		end
	endgenerate
	ibex_csr #(
		.Width(MHPMCounterNum + MHPMCOUNTER_BASE),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcounteren_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mcounteren_d),
		.wr_en_i(mcounteren_we),
		.rd_data_o(mcounteren_q),
		.rd_error_o()
	);
	generate
		if (DbgTriggerEn) begin : gen_trigger_regs
			localparam [31:0] DbgHwNumLen = (DbgHwBreakNum > 1 ? $clog2(DbgHwBreakNum) : 1);
			localparam [31:0] MaxTselect = DbgHwBreakNum - 1;
			wire [DbgHwNumLen - 1:0] tselect_d;
			wire [DbgHwNumLen - 1:0] tselect_q;
			wire tmatch_control_d;
			wire [DbgHwBreakNum - 1:0] tmatch_control_q;
			wire [31:0] tmatch_value_d;
			wire [31:0] tmatch_value_q [0:DbgHwBreakNum - 1];
			wire selected_tmatch_control;
			wire [31:0] selected_tmatch_value;
			wire tselect_we;
			wire [DbgHwBreakNum - 1:0] tmatch_control_we;
			wire [DbgHwBreakNum - 1:0] tmatch_value_we;
			wire [DbgHwBreakNum - 1:0] trigger_match;
			assign tselect_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a0);
			genvar _gv_i_25;
			for (_gv_i_25 = 0; _gv_i_25 < DbgHwBreakNum; _gv_i_25 = _gv_i_25 + 1) begin : g_dbg_tmatch_we
				localparam i = _gv_i_25;
				assign tmatch_control_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a1);
				assign tmatch_value_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a2);
			end
			assign tselect_d = (csr_wdata_int < DbgHwBreakNum ? csr_wdata_int[DbgHwNumLen - 1:0] : MaxTselect[DbgHwNumLen - 1:0]);
			assign tmatch_control_d = csr_wdata_int[2];
			assign tmatch_value_d = csr_wdata_int[31:0];
			ibex_csr #(
				.Width(DbgHwNumLen),
				.ShadowCopy(1'b0),
				.ResetValue(1'sb0)
			) u_tselect_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(tselect_d),
				.wr_en_i(tselect_we),
				.rd_data_o(tselect_q),
				.rd_error_o()
			);
			genvar _gv_i_26;
			for (_gv_i_26 = 0; _gv_i_26 < DbgHwBreakNum; _gv_i_26 = _gv_i_26 + 1) begin : g_dbg_tmatch_reg
				localparam i = _gv_i_26;
				ibex_csr #(
					.Width(1),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_control_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_control_d),
					.wr_en_i(tmatch_control_we[i]),
					.rd_data_o(tmatch_control_q[i]),
					.rd_error_o()
				);
				ibex_csr #(
					.Width(32),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_value_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_value_d),
					.wr_en_i(tmatch_value_we[i]),
					.rd_data_o(tmatch_value_q[i]),
					.rd_error_o()
				);
			end
			localparam [31:0] TSelectRdataPadlen = (DbgHwNumLen >= 32 ? 0 : 32 - DbgHwNumLen);
			assign tselect_rdata = {{TSelectRdataPadlen {1'b0}}, tselect_q};
			if (DbgHwBreakNum > 1) begin : g_dbg_tmatch_multiple_select
				assign selected_tmatch_control = tmatch_control_q[tselect_q];
				assign selected_tmatch_value = tmatch_value_q[tselect_q];
			end
			else begin : g_dbg_tmatch_single_select
				assign selected_tmatch_control = tmatch_control_q[0];
				assign selected_tmatch_value = tmatch_value_q[0];
			end
			assign tmatch_control_rdata = {29'h05000209, selected_tmatch_control, 2'b00};
			assign tmatch_value_rdata = selected_tmatch_value;
			genvar _gv_i_27;
			for (_gv_i_27 = 0; _gv_i_27 < DbgHwBreakNum; _gv_i_27 = _gv_i_27 + 1) begin : g_dbg_trigger_match
				localparam i = _gv_i_27;
				assign trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i]);
			end
			assign trigger_match_o = |trigger_match;
		end
		else begin : gen_no_trigger_regs
			assign tselect_rdata = 'b0;
			assign tmatch_control_rdata = 'b0;
			assign tmatch_value_rdata = 'b0;
			assign trigger_match_o = 'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata_raw = csr_wdata_int[7:0];
	generate
		if (DataIndTiming) begin : gen_dit
			assign cpuctrlsts_part_wdata[1] = cpuctrlsts_part_wdata_raw[1];
		end
		else begin : gen_no_dit
			wire unused_dit;
			assign unused_dit = cpuctrlsts_part_wdata_raw[1];
			assign cpuctrlsts_part_wdata[1] = 1'b0;
		end
	endgenerate
	assign data_ind_timing_o = cpuctrlsts_part_q[1];
	generate
		if (DummyInstructions) begin : gen_dummy
			assign cpuctrlsts_part_wdata[2] = cpuctrlsts_part_wdata_raw[2];
			assign cpuctrlsts_part_wdata[5-:3] = cpuctrlsts_part_wdata_raw[5-:3];
			assign dummy_instr_seed_en_o = csr_we_int && (csr_addr == 12'h7c1);
			assign dummy_instr_seed_o = csr_wdata_int;
		end
		else begin : gen_no_dummy
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			assign unused_dummy_en = cpuctrlsts_part_wdata_raw[2];
			assign unused_dummy_mask = cpuctrlsts_part_wdata_raw[5-:3];
			assign cpuctrlsts_part_wdata[2] = 1'b0;
			assign cpuctrlsts_part_wdata[5-:3] = 3'b000;
			assign dummy_instr_seed_en_o = 1'b0;
			assign dummy_instr_seed_o = 1'sb0;
		end
	endgenerate
	assign dummy_instr_en_o = cpuctrlsts_part_q[2];
	assign dummy_instr_mask_o = cpuctrlsts_part_q[5-:3];
	generate
		if (ICache) begin : gen_icache_enable
			assign cpuctrlsts_part_wdata[0] = cpuctrlsts_part_wdata_raw[0];
			ibex_csr #(
				.Width(1),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'b0)
			) u_cpuctrlsts_ic_scr_key_valid_q_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(ic_scr_key_valid_i),
				.wr_en_i(1'b1),
				.rd_data_o(cpuctrlsts_ic_scr_key_valid_q),
				.rd_error_o(cpuctrlsts_ic_scr_key_err)
			);
		end
		else begin : gen_no_icache
			wire unused_icen;
			assign unused_icen = cpuctrlsts_part_wdata_raw[0];
			assign cpuctrlsts_part_wdata[0] = 1'b0;
			wire unused_ic_scr_key_valid;
			assign unused_ic_scr_key_valid = ic_scr_key_valid_i;
			assign cpuctrlsts_ic_scr_key_valid_q = 1'b0;
			assign cpuctrlsts_ic_scr_key_err = 1'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata[7] = cpuctrlsts_part_wdata_raw[7];
	assign cpuctrlsts_part_wdata[6] = cpuctrlsts_part_wdata_raw[6];
	assign icache_enable_o = cpuctrlsts_part_q[0] & ~(debug_mode_i | debug_mode_entering_i);
	ibex_csr #(
		.Width(8),
		.ShadowCopy(ShadowCSR),
		.ResetValue(1'sb0)
	) u_cpuctrlsts_part_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({cpuctrlsts_part_d}),
		.wr_en_i(cpuctrlsts_part_we),
		.rd_data_o(cpuctrlsts_part_q),
		.rd_error_o(cpuctrlsts_part_err)
	);
	assign csr_shadow_err_o = (((mstatus_err | mtvec_err) | pmp_csr_err) | cpuctrlsts_part_err) | cpuctrlsts_ic_scr_key_err;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DEPCC = 5'h18;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0 = 5'h19;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1 = 5'h1a;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MEPCC = 5'h1f;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC = 5'h1e;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTCC = 5'h1c;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTDC = 5'h1d;
	function automatic [5:0] sv2v_cast_9ED85;
		input reg [5:0] inp;
		sv2v_cast_9ED85 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_0A8E9;
		input reg [2:0] inp;
		sv2v_cast_0A8E9 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_B6B73;
		input reg [3:0] inp;
		sv2v_cast_B6B73 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_EDEAE;
		input reg [8:0] inp;
		sv2v_cast_EDEAE = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_9ED85(1'sb0), sv2v_cast_0A8E9(1'sb0), sv2v_cast_B6B73(1'sb0), sv2v_cast_EDEAE(1'sb0), sv2v_cast_EDEAE(1'sb0)};
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TM = 6'b111111;
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
	function automatic [5:0] sv2v_cast_A63C5;
		input reg [5:0] inp;
		sv2v_cast_A63C5 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_E4109;
		input reg [2:0] inp;
		sv2v_cast_E4109 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_DE3BF;
		input reg [3:0] inp;
		sv2v_cast_DE3BF = inp;
	endfunction
	function automatic [8:0] sv2v_cast_1CF2E;
		input reg [8:0] inp;
		sv2v_cast_1CF2E = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TM = {4'b0010, sv2v_cast_A63C5(ibex_cheriot_pkg_CPERMS_TM), sv2v_cast_E4109(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_DE3BF(ibex_cheriot_pkg_MAXCEXP), sv2v_cast_1CF2E(9'h100), sv2v_cast_EDEAE(1'sb0)};
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TS = 6'b100111;
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TS = {4'b0010, sv2v_cast_A63C5(ibex_cheriot_pkg_CPERMS_TS), sv2v_cast_E4109(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_DE3BF(ibex_cheriot_pkg_MAXCEXP), sv2v_cast_1CF2E(9'h100), sv2v_cast_EDEAE(1'sb0)};
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TX = 6'b101111;
	function automatic [5:0] sv2v_cast_6;
		input reg [5:0] inp;
		sv2v_cast_6 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
	localparam [111:0] ibex_cheriot_pkg_ROOT_DECODED_CAP_TX = {81'h100000000000000001eb2, sv2v_cast_6(ibex_cheriot_pkg_CPERMS_TX), sv2v_cast_3(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_4(ibex_cheriot_pkg_MAXCEXP), 18'h20000};
	function automatic [34:0] sv2v_cast_F2778;
		input reg [34:0] inp;
		sv2v_cast_F2778 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TX = sv2v_cast_F2778(ibex_cheriot_pkg_ROOT_DECODED_CAP_TX);
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_expand_bound33;
		input reg [8:0] mant;
		input reg [1:0] cor;
		input reg [4:0] exp5;
		input reg [31:0] addr;
		reg [32:0] cor_val;
		reg [32:0] mask;
		reg [32:0] bound;
		reg [32:0] mant_ext;
		begin
			if (cor[1])
				cor_val = {33 {1'b1}};
			else
				cor_val = {32'h00000000, cor[0]};
			cor_val = (cor_val << exp5) << ibex_cheriot_pkg_CBOUND_W;
			mask = (33'h1ffffffff << exp5) << ibex_cheriot_pkg_CBOUND_W;
			bound = ({1'b0, addr} & mask) + cor_val;
			mant_ext = {24'h000000, mant};
			bound = bound | (mant_ext << exp5);
			ibex_cheriot_pkg_cheriot_expand_bound33 = bound;
		end
	endfunction
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	localparam [11:0] ibex_cheriot_pkg_PERM_EXE_IMSK = 12'h160;
	localparam [11:0] ibex_cheriot_pkg_PERM_MDO_IMSK = 12'h000;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRO_IMSK = 12'h060;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRW_IMSK = 12'h064;
	localparam [11:0] ibex_cheriot_pkg_PERM_MWO_IMSK = 12'h044;
	localparam [11:0] ibex_cheriot_pkg_PERM_SEA_IMSK = 12'h000;
	function automatic [11:0] ibex_cheriot_pkg_cheriot_expand_perms;
		input reg [5:0] cperms;
		reg [11:0] perms;
		begin
			perms = 1'sb0;
			if (cperms[4:3] == 2'b11) begin
				perms = ibex_cheriot_pkg_PERM_MRW_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[4] = cperms[2];
			end
			else if (cperms[4:2] == 3'b101) begin
				perms = ibex_cheriot_pkg_PERM_MRO_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
			end
			else if (cperms[4:0] == 5'b10000)
				perms = ibex_cheriot_pkg_PERM_MWO_IMSK;
			else if (cperms[4:2] == 3'b100) begin
				perms = ibex_cheriot_pkg_PERM_MDO_IMSK;
				perms[2] = cperms[0];
				perms[5] = cperms[1];
			end
			else if (cperms[4:3] == 2'b01) begin
				perms = ibex_cheriot_pkg_PERM_EXE_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[7] = cperms[2];
			end
			else if (cperms[4:3] == 2'b00) begin
				perms = ibex_cheriot_pkg_PERM_SEA_IMSK;
				perms[9] = cperms[0];
				perms[10] = cperms[1];
				perms[11] = cperms[2];
			end
			perms[0] = cperms[5];
			ibex_cheriot_pkg_cheriot_expand_perms = perms;
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_base_correction;
		input reg [1:0] cap_cor;
		reg unused_top_cor_bit;
		begin
			unused_top_cor_bit = cap_cor[1];
			ibex_cheriot_pkg_cheriot_get_base_correction = {2 {cap_cor[0]}};
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_top_correction;
		input reg [1:0] cap_cor;
		ibex_cheriot_pkg_cheriot_get_top_correction = {cap_cor[1] & cap_cor[0], cap_cor[1]};
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_decode_cap;
		input reg [34:0] cap;
		input reg [31:0] addr;
		reg [111:0] d;
		reg [4:0] exp5;
		begin
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			d[34-:2] = cap[34-:2];
			d[32] = cap[32];
			d[31] = cap[31];
			d[30-:6] = cap[30-:6];
			d[24-:3] = cap[24-:3];
			d[21-:4] = cap[21-:4];
			d[17-:9] = cap[17-:9];
			d[8-:ibex_cheriot_pkg_CBOUND_W] = cap[8-:ibex_cheriot_pkg_CBOUND_W];
			d[46-:12] = ibex_cheriot_pkg_cheriot_expand_perms(cap[30-:6]);
			d[111-:33] = ibex_cheriot_pkg_cheriot_expand_bound33(cap[17-:9], ibex_cheriot_pkg_cheriot_get_top_correction(cap[34-:2]), exp5, addr);
			d[78-:32] = sv2v_cast_32(ibex_cheriot_pkg_cheriot_expand_bound33(cap[8-:ibex_cheriot_pkg_CBOUND_W], ibex_cheriot_pkg_cheriot_get_base_correction(cap[34-:2]), exp5, addr));
			ibex_cheriot_pkg_cheriot_decode_cap = d;
		end
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_encode_cap;
		input reg [111:0] d;
		reg [111:0] unused_d;
		begin
			unused_d = d;
			ibex_cheriot_pkg_cheriot_encode_cap = sv2v_cast_F2778(d);
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_compute_corrections;
		input reg [8:0] top;
		input reg [8:0] base;
		input reg [8:0] addr;
		reg top_hi;
		reg addr_hi;
		begin
			top_hi = top < base;
			addr_hi = addr < base;
			ibex_cheriot_pkg_cheriot_compute_corrections = {top_hi ^ addr_hi, addr_hi};
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_set_address;
		input reg [111:0] in_cap;
		input reg [31:0] newptr;
		reg [111:0] out_cap;
		reg [4:0] exp5;
		reg [32:0] ptr_minus_base;
		reg [8:0] unused_ptr_minus_base;
		reg [23:0] high_delta;
		reg [23:0] repr_mask;
		reg [8:0] ptr_mantissa;
		begin
			out_cap = in_cap;
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(in_cap[21-:4]);
			repr_mask = {24 {1'b1}} << exp5;
			ptr_minus_base = {1'b0, newptr} - {1'b0, in_cap[78-:32]};
			unused_ptr_minus_base = ptr_minus_base[8:0];
			high_delta = ptr_minus_base[32:ibex_cheriot_pkg_CBOUND_W] & repr_mask;
			if (high_delta != 0)
				out_cap[32] = 1'b0;
			ptr_mantissa = sv2v_cast_1CF2E(newptr >> exp5);
			out_cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(out_cap[17-:9], out_cap[8-:ibex_cheriot_pkg_CBOUND_W], ptr_mantissa);
			ibex_cheriot_pkg_cheriot_set_address = out_cap;
		end
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_pcc_to_mepc;
		input reg [111:0] pcc;
		input reg [31:0] address;
		input reg clrtag;
		reg [34:0] cap;
		reg [111:0] new_dcap;
		begin
			new_dcap = ibex_cheriot_pkg_cheriot_set_address(pcc, address);
			cap = ibex_cheriot_pkg_cheriot_encode_cap(new_dcap);
			if (clrtag)
				cap[32] = 1'b0;
			ibex_cheriot_pkg_cheriot_pcc_to_mepc = cap;
		end
	endfunction
	generate
		if (BaseIsa == 32'sd1) begin : gen_scr
			wire [34:0] pcc_exc_cap;
			reg [34:0] mtdc_cap;
			reg [31:0] mtdc_data;
			reg [34:0] mscratchc_cap;
			reg [31:0] mscratchc_data;
			reg [34:0] mstack_epc_cap_q;
			wire mtdc_en_cheriot;
			wire mscratchc_en_cheriot;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (cheriot_csr_addr_i)
					ibex_cheriot_pkg_CHERIOT_SCR_DEPCC: begin
						cheriot_csr_rdata_o = (debug_mode_i ? depc_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? depc_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0: begin
						cheriot_csr_rdata_o = (debug_mode_i ? dscratch0_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? dscratch0_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1: begin
						cheriot_csr_rdata_o = (debug_mode_i ? dscratch1_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? dscratch1_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MTCC: begin
						cheriot_csr_rdata_o = mtvec_q;
						cheriot_csr_rcap_o = mtvec_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MTDC: begin
						cheriot_csr_rdata_o = mtdc_data;
						cheriot_csr_rcap_o = mtdc_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC: begin
						cheriot_csr_rdata_o = mscratchc_data;
						cheriot_csr_rcap_o = mscratchc_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MEPCC: begin
						cheriot_csr_rdata_o = mepc_q;
						cheriot_csr_rcap_o = mepc_cap;
					end
					default: begin
						cheriot_csr_rdata_o = 32'h00000000;
						cheriot_csr_rcap_o = ibex_cheriot_pkg_NULL_CAP;
					end
				endcase
			end
			assign pcc_cap_o = pcc_cap_q;
			assign pcc_exc_cap = ibex_cheriot_pkg_cheriot_pcc_to_mepc(pcc_cap_q, exception_pc, csr_mepcc_clrtag_i);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					pcc_cap_q <= ibex_cheriot_pkg_ROOT_DECODED_CAP_TX;
				else if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					pcc_cap_q <= pcc_cap_d;
			reg [111:0] tf_cap;
			reg [34:0] tr_cap;
			reg [31:0] tr_addr;
			always @(*) begin
				if (_sv2v_0)
					;
				if (csr_save_cause_i) begin
					tr_cap = mtvec_cap;
					tr_addr = mtvec_q;
				end
				else if (csr_restore_mret_i) begin
					tr_cap = mepc_cap;
					tr_addr = mepc_q;
				end
				else if (csr_restore_dret_i & debug_mode_i) begin
					tr_cap = depc_cap;
					tr_addr = depc_q;
				end
				else begin
					tr_cap = ibex_cheriot_pkg_NULL_CAP;
					tr_addr = 32'h00000000;
				end
				tf_cap = ibex_cheriot_pkg_cheriot_decode_cap(tr_cap, tr_addr);
				if ((csr_save_cause_i | csr_restore_mret_i) | (csr_restore_dret_i & debug_mode_i))
					pcc_cap_d = tf_cap;
				else if (cheriot_branch_req_i)
					pcc_cap_d = pcc_cap_i;
				else
					pcc_cap_d = pcc_cap_q;
			end
			assign mtvec_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MTCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mtvec_cap <= ibex_cheriot_pkg_ROOT_CAP_TX;
				else if (mtvec_en_cheriot)
					mtvec_cap <= cheriot_csr_wcap_i;
			assign mepc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MEPCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mstack_epc_cap_q <= ibex_cheriot_pkg_NULL_CAP;
				else if (mstack_en)
					mstack_epc_cap_q <= mepc_cap;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mepc_cap <= ibex_cheriot_pkg_ROOT_CAP_TX;
				else if ((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_save_cause_i) && ~debug_csr_save_i) && ~debug_mode_i)
					mepc_cap <= pcc_exc_cap;
				else if (((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_restore_mret_i) && nmi_mode_i)
					mepc_cap <= mstack_epc_cap_q;
				else if (mepc_en_cheriot)
					mepc_cap <= cheriot_csr_wcap_i;
			assign mtdc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MTDC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mtdc_cap <= ibex_cheriot_pkg_ROOT_CAP_TM;
					mtdc_data <= 32'h00000000;
				end
				else if (mtdc_en_cheriot) begin
					mtdc_cap <= cheriot_csr_wcap_i;
					mtdc_data <= cheriot_csr_wdata_i;
				end
			assign mscratchc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mscratchc_cap <= ibex_cheriot_pkg_ROOT_CAP_TS;
					mscratchc_data <= 32'h00000000;
				end
				else if (mscratchc_en_cheriot) begin
					mscratchc_cap <= cheriot_csr_wcap_i;
					mscratchc_data <= cheriot_csr_wdata_i;
				end
			assign depc_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DEPCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					depc_cap <= ibex_cheriot_pkg_NULL_CAP;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && (csr_save_cause_i & debug_csr_save_i))
					depc_cap <= pcc_exc_cap;
				else if (depc_en_cheriot)
					depc_cap <= cheriot_csr_wcap_i;
			assign dscratch0_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0)) && (cheriot_csr_op_i == 5'd1);
			assign dscratch1_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					dscratch0_cap <= ibex_cheriot_pkg_NULL_CAP;
					dscratch1_cap <= ibex_cheriot_pkg_NULL_CAP;
				end
				else if (dscratch0_en_cheriot)
					dscratch0_cap <= cheriot_csr_wcap_i;
				else if (dscratch1_en_cheriot)
					dscratch1_cap <= cheriot_csr_wcap_i;
			reg cheriot_fatal_err_q;
			assign cheriot_fatal_err_o = cheriot_fatal_err_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					cheriot_fatal_err_q <= 1'b0;
				else if (((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_save_cause_i) && ~mtvec_cap[32])
					cheriot_fatal_err_q <= 1'b1;
		end
		else begin : gen_no_scr
			wire [32:1] sv2v_tmp_4680A;
			assign sv2v_tmp_4680A = 32'h00000000;
			always @(*) cheriot_csr_rdata_o = sv2v_tmp_4680A;
			wire [35:1] sv2v_tmp_0D477;
			assign sv2v_tmp_0D477 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) cheriot_csr_rcap_o = sv2v_tmp_0D477;
			assign pcc_cap_o = ibex_cheriot_pkg_NULL_DECODED_CAP;
			wire [112:1] sv2v_tmp_20C5C;
			assign sv2v_tmp_20C5C = ibex_cheriot_pkg_NULL_DECODED_CAP;
			always @(*) pcc_cap_q = sv2v_tmp_20C5C;
			wire [112:1] sv2v_tmp_68429;
			assign sv2v_tmp_68429 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			always @(*) pcc_cap_d = sv2v_tmp_68429;
			wire [35:1] sv2v_tmp_7F107;
			assign sv2v_tmp_7F107 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) mepc_cap = sv2v_tmp_7F107;
			wire [35:1] sv2v_tmp_71F64;
			assign sv2v_tmp_71F64 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) mtvec_cap = sv2v_tmp_71F64;
			wire [35:1] sv2v_tmp_CA7BE;
			assign sv2v_tmp_CA7BE = ibex_cheriot_pkg_NULL_CAP;
			always @(*) depc_cap = sv2v_tmp_CA7BE;
			wire [35:1] sv2v_tmp_44A49;
			assign sv2v_tmp_44A49 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) dscratch0_cap = sv2v_tmp_44A49;
			wire [35:1] sv2v_tmp_E3208;
			assign sv2v_tmp_E3208 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) dscratch1_cap = sv2v_tmp_E3208;
			assign mtvec_en_cheriot = 1'b0;
			assign mepc_en_cheriot = 1'b0;
			assign depc_en_cheriot = 1'b0;
			assign dscratch0_en_cheriot = 1'b0;
			assign dscratch1_en_cheriot = 1'b0;
			assign cheriot_fatal_err_o = 1'b0;
			wire unused_cheriot_scr_sigs;
			assign unused_cheriot_scr_sigs = ((((((((((((^cheriot_csr_addr_i | ^cheriot_csr_op_i) | cheriot_csr_op_en_i) | ^cheriot_csr_wcap_i) | csr_mepcc_clrtag_i) | cheriot_branch_req_i) | ^pcc_cap_i) | ^mepc_cap) | ^mtvec_cap) | ^depc_cap) | ^dscratch0_cap) | ^dscratch1_cap) | ^pcc_cap_d) | ^pcc_cap_q;
		end
	endgenerate
	wire unused_cheriot_csr_inputs;
	assign unused_cheriot_csr_inputs = ^{cheriot_csr_access_i, cheriot_branch_target_i};
	initial _sv2v_0 = 0;
endmodule
module ibex_csr (
	clk_i,
	rst_ni,
	wr_data_i,
	wr_en_i,
	rd_data_o,
	rd_error_o
);
	parameter [31:0] Width = 32;
	parameter [0:0] ShadowCopy = 1'b0;
	parameter [Width - 1:0] ResetValue = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire [Width - 1:0] wr_data_i;
	input wire wr_en_i;
	output wire [Width - 1:0] rd_data_o;
	output wire rd_error_o;
	reg [Width - 1:0] rdata_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= ResetValue;
		else if (wr_en_i)
			rdata_q <= wr_data_i;
	assign rd_data_o = rdata_q;
	generate
		if (ShadowCopy) begin : gen_shadow
			reg [Width - 1:0] shadow_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					shadow_q <= ~ResetValue;
				else if (wr_en_i)
					shadow_q <= ~wr_data_i;
			assign rd_error_o = rdata_q != ~shadow_q;
		end
		else begin : gen_no_shadow
			assign rd_error_o = 1'b0;
		end
	endgenerate
endmodule
module ibex_decoder (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	dret_insn_o,
	ecall_insn_o,
	wfi_insn_o,
	jump_set_o,
	branch_taken_i,
	icache_inval_o,
	instr_first_cycle_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	illegal_c_insn_i,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	bt_a_mux_sel_o,
	bt_b_mux_sel_o,
	imm_i_type_o,
	imm_s_type_o,
	imm_b_type_o,
	imm_u_type_o,
	imm_j_type_o,
	zimm_rs1_type_o,
	rf_wdata_sel_o,
	rf_we_o,
	rf_we_or_load_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_o,
	rf_ren_a_o,
	rf_ren_b_o,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	alu_multicycle_o,
	mult_en_o,
	div_en_o,
	mult_sel_o,
	div_sel_o,
	multdiv_operator_o,
	multdiv_signed_mode_o,
	csr_access_o,
	csr_op_o,
	csr_addr_o,
	csr_cheriot_always_ok_o,
	data_req_o,
	cheriot_data_req_o,
	data_we_o,
	data_type_o,
	data_sign_extension_o,
	jump_in_dec_o,
	branch_in_dec_o,
	instr_is_cheriot_o,
	instr_is_legal_cheriot_o,
	cheriot_imm12_o,
	cheriot_imm20_o,
	cheriot_imm21_o,
	cheriot_operator_o,
	cheriot_cs2_dec_o,
	cheriot_cap_field_sel_o,
	cheriot_adder_a_sel_o,
	cheriot_adder_b_sel_o,
	cheriot_setaddr_sel_o,
	cheriot_setbounds_sel_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	parameter integer BaseIsa = 32'sd1;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output wire illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg dret_insn_o;
	output reg ecall_insn_o;
	output reg wfi_insn_o;
	output reg jump_set_o;
	input wire branch_taken_i;
	output reg icache_inval_o;
	input wire instr_first_cycle_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire illegal_c_insn_i;
	output reg imm_a_mux_sel_o;
	output reg [2:0] imm_b_mux_sel_o;
	output reg [1:0] bt_a_mux_sel_o;
	output reg [2:0] bt_b_mux_sel_o;
	output wire [31:0] imm_i_type_o;
	output wire [31:0] imm_s_type_o;
	output wire [31:0] imm_b_type_o;
	output wire [31:0] imm_u_type_o;
	output wire [31:0] imm_j_type_o;
	output wire [31:0] zimm_rs1_type_o;
	output reg rf_wdata_sel_o;
	output wire rf_we_o;
	output wire rf_we_or_load_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_o;
	output reg rf_ren_a_o;
	output reg rf_ren_b_o;
	output reg [6:0] alu_operator_o;
	output reg [1:0] alu_op_a_mux_sel_o;
	output reg alu_op_b_mux_sel_o;
	output reg alu_multicycle_o;
	output wire mult_en_o;
	output wire div_en_o;
	output reg mult_sel_o;
	output reg div_sel_o;
	output reg [1:0] multdiv_operator_o;
	output reg [1:0] multdiv_signed_mode_o;
	output reg csr_access_o;
	output reg [1:0] csr_op_o;
	output wire [11:0] csr_addr_o;
	output reg csr_cheriot_always_ok_o;
	output reg data_req_o;
	output reg cheriot_data_req_o;
	output reg data_we_o;
	output reg [1:0] data_type_o;
	output reg data_sign_extension_o;
	output reg jump_in_dec_o;
	output reg branch_in_dec_o;
	output reg instr_is_cheriot_o;
	output wire instr_is_legal_cheriot_o;
	output wire [11:0] cheriot_imm12_o;
	output wire [19:0] cheriot_imm20_o;
	output wire [20:0] cheriot_imm21_o;
	output reg [25:0] cheriot_operator_o;
	output wire [4:0] cheriot_cs2_dec_o;
	output reg [2:0] cheriot_cap_field_sel_o;
	output reg [2:0] cheriot_adder_a_sel_o;
	output reg [1:0] cheriot_adder_b_sel_o;
	output reg [2:0] cheriot_setaddr_sel_o;
	output reg [2:0] cheriot_setbounds_sel_o;
	localparam [0:0] CheriLimit16Regs = BaseIsa == 32'sd1;
	reg illegal_insn;
	wire illegal_reg_16;
	reg csr_illegal;
	reg rf_we;
	wire [31:0] instr;
	wire [31:0] instr_alu;
	wire [9:0] unused_instr_alu;
	wire [4:0] instr_rs1;
	wire [4:0] instr_rs2;
	wire [4:0] instr_rs3;
	wire [4:0] instr_rd;
	reg use_rs3_d;
	reg use_rs3_q;
	reg [1:0] csr_op;
	reg [6:0] opcode;
	reg [6:0] opcode_alu;
	wire instr_is_legal_cheriot;
	assign instr = instr_rdata_i;
	assign instr_alu = instr_rdata_alu_i;
	assign imm_i_type_o = {{20 {instr[31]}}, instr[31:20]};
	assign imm_s_type_o = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_b_type_o = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type_o = {instr[31:12], 12'b000000000000};
	assign imm_j_type_o = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign csr_addr_o = instr[31:20];
	assign zimm_rs1_type_o = {27'b000000000000000000000000000, instr_rs1};
	generate
		if (RV32B != 32'sd0) begin : gen_rs3_flop
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					use_rs3_q <= 1'b0;
				else
					use_rs3_q <= use_rs3_d;
		end
		else begin : gen_no_rs3_flop
			wire unused_clk;
			wire unused_rst_n;
			assign unused_clk = clk_i;
			assign unused_rst_n = rst_ni;
			wire [1:1] sv2v_tmp_12378;
			assign sv2v_tmp_12378 = use_rs3_d;
			always @(*) use_rs3_q = sv2v_tmp_12378;
		end
	endgenerate
	assign instr_rs1 = instr[19:15];
	assign instr_rs2 = instr[24:20];
	assign instr_rs3 = instr[31:27];
	wire [4:0] raddr_a;
	wire [4:0] raddr_b;
	assign raddr_a = (cheriot_operator_o[22] ? 5'h03 : (use_rs3_q & ~instr_first_cycle_i ? instr_rs3 : instr_rs1));
	assign raddr_b = instr_rs2;
	assign instr_rd = instr[11:7];
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (CheriLimit16Regs) begin : gen_16_regs
			assign rf_raddr_a_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {1'b0, raddr_a[3:0]} : raddr_a);
			assign rf_raddr_b_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {1'b0, raddr_b[3:0]} : raddr_b);
			assign rf_waddr_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {1'b0, instr_rd[3:0]} : instr_rd);
		end
		else begin : gen_regs
			assign rf_raddr_a_o = raddr_a;
			assign rf_raddr_b_o = raddr_b;
			assign rf_waddr_o = instr_rd;
		end
	endgenerate
	wire rf_we_or_load;
	assign rf_we_or_load = rf_we | (opcode == 7'h03);
	assign rf_we_or_load_o = rf_we_or_load;
	generate
		if (RV32E || CheriLimit16Regs) begin : gen_16reg_check_active
			assign illegal_reg_16 = (RV32E || (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && ((((raddr_a[4] && rf_ren_a_o) || (raddr_b[4] && rf_ren_b_o)) || ((instr_rs3[4] && use_rs3_d) && rf_ren_a_o)) || (instr_rd[4] && rf_we_or_load));
		end
		else begin : gen_16reg_check_inactive
			assign illegal_reg_16 = 1'b0;
		end
	endgenerate
	always @(*) begin : csr_operand_check
		if (_sv2v_0)
			;
		csr_op_o = csr_op;
		if (((csr_op == 2'd2) || (csr_op == 2'd3)) && (instr_rs1 == {5 {1'sb0}}))
			csr_op_o = 2'd0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		jump_in_dec_o = 1'b0;
		jump_set_o = 1'b0;
		branch_in_dec_o = 1'b0;
		icache_inval_o = 1'b0;
		multdiv_operator_o = 2'd0;
		multdiv_signed_mode_o = 2'b00;
		rf_wdata_sel_o = 1'd0;
		rf_we = 1'b0;
		rf_ren_a_o = 1'b0;
		rf_ren_b_o = 1'b0;
		csr_access_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = 2'd0;
		csr_cheriot_always_ok_o = 1'b0;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 1'b0;
		data_req_o = 1'b0;
		cheriot_data_req_o = 1'b0;
		illegal_insn = 1'b0;
		ebrk_insn_o = 1'b0;
		mret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		wfi_insn_o = 1'b0;
		cheriot_operator_o = 1'sb0;
		instr_is_cheriot_o = 1'b0;
		cheriot_cap_field_sel_o = 3'h0;
		cheriot_adder_a_sel_o = 3'h0;
		cheriot_adder_b_sel_o = 2'h0;
		cheriot_setaddr_sel_o = 3'h0;
		cheriot_setbounds_sel_o = 3'h0;
		opcode = instr[6:0];
		(* full_case, parallel_case *)
		case (opcode)
			7'h6f:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~illegal_c_insn_i) begin
					cheriot_operator_o[20] = 1'b1;
					instr_is_cheriot_o = 1'b1;
					illegal_insn = 1'b0;
					rf_we = 1'b1;
					cheriot_adder_a_sel_o = 3'h2;
					cheriot_adder_b_sel_o = 2'h2;
					cheriot_setaddr_sel_o = 3'h1;
				end
				else begin
					jump_in_dec_o = 1'b1;
					if (instr_first_cycle_i) begin
						rf_we = BranchTargetALU;
						jump_set_o = 1'b1;
					end
					else
						rf_we = 1'b1;
				end
			7'h67:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~illegal_c_insn_i) begin
					if (instr[14:12] == 3'b000)
						cheriot_operator_o[19] = 1'b1;
					instr_is_cheriot_o = 1'b1;
					rf_ren_a_o = 1'b1;
					rf_we = 1'b1;
					cheriot_adder_a_sel_o = 3'h1;
					cheriot_adder_b_sel_o = 2'h1;
					cheriot_setaddr_sel_o = 3'h1;
					if (instr[14:12] != 3'b000)
						illegal_insn = 1'b1;
				end
				else begin
					jump_in_dec_o = 1'b1;
					if (instr_first_cycle_i) begin
						rf_we = BranchTargetALU;
						jump_set_o = 1'b1;
					end
					else
						rf_we = 1'b1;
					if (instr[14:12] != 3'b000)
						illegal_insn = 1'b1;
					rf_ren_a_o = 1'b1;
				end
			7'h63: begin
				branch_in_dec_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: illegal_insn = 1'b0;
					default: illegal_insn = 1'b1;
				endcase
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
			end
			7'h23: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				data_req_o = 1'b1;
				data_we_o = 1'b1;
				if (instr[14])
					illegal_insn = 1'b1;
				else if (instr[13:12] == 2'b11) begin
					if ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) begin
						cheriot_operator_o[17] = ~illegal_c_insn_i;
						instr_is_cheriot_o = ~illegal_c_insn_i;
						cheriot_data_req_o = ~illegal_c_insn_i;
						data_req_o = 1'b0;
						illegal_insn = 1'b0;
					end
					else begin
						cheriot_data_req_o = 1'b0;
						illegal_insn = 1'b1;
					end
				end
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: data_type_o = 2'b00;
					default: data_type_o = 2'b00;
				endcase
			end
			7'h03: begin
				rf_ren_a_o = 1'b1;
				data_req_o = 1'b1;
				data_type_o = 2'b00;
				data_sign_extension_o = ~instr[14];
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: begin
						data_type_o = 2'b00;
						if (instr[14])
							illegal_insn = 1'b1;
					end
					2'b11:
						if ((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && ~instr[14]) && ~illegal_c_insn_i) begin
							cheriot_operator_o[15] = 1'b1;
							instr_is_cheriot_o = 1'b1;
							cheriot_data_req_o = 1'b1;
							data_req_o = 1'b0;
							illegal_insn = 1'b0;
						end
						else begin
							cheriot_data_req_o = 1'b0;
							illegal_insn = 1'b1;
						end
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h37: rf_we = 1'b1;
			7'h17:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~illegal_c_insn_i) begin
					cheriot_operator_o[21] = 1'b1;
					instr_is_cheriot_o = 1'b1;
					illegal_insn = 1'b0;
					rf_we = 1'b1;
					cheriot_adder_a_sel_o = 3'h3;
					cheriot_adder_b_sel_o = 2'h2;
					cheriot_setaddr_sel_o = 3'h2;
				end
				else
					rf_we = 1'b1;
			7'h13: begin
				rf_ren_a_o = 1'b1;
				rf_we = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: illegal_insn = 1'b0;
					3'b001:
						(* full_case, parallel_case *)
						case (instr[31:27])
							5'b00000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
							5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
							5'b01001, 5'b00101, 5'b01101: illegal_insn = (RV32B != 32'sd0 ? instr[26:25] != 2'b00 : 1'b1);
							5'b00001:
								if (instr[26] == 1'b0)
									illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								else
									illegal_insn = 1'b1;
							5'b01100:
								(* full_case, parallel_case *)
								case (instr[26:20])
									7'b0000000, 7'b0000001, 7'b0000010, 7'b0000100, 7'b0000101: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
									7'b0010000, 7'b0010001, 7'b0010010, 7'b0011000, 7'b0011001, 7'b0011010: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
									default: illegal_insn = 1'b1;
								endcase
							default: illegal_insn = 1'b1;
						endcase
					3'b101:
						if (instr[26])
							illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						else
							(* full_case, parallel_case *)
							case (instr[31:27])
								5'b00000, 5'b01000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
								5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								5'b01100, 5'b01001: illegal_insn = (RV32B != 32'sd0 ? instr[26:25] != 2'b00 : 1'b1);
								5'b01101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (RV32B == 32'sd1)
										illegal_insn = (instr[24:20] == 5'b11000 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (instr[24:20] == 5'b00111)
										illegal_insn = (RV32B == 32'sd1 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00001: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								default: illegal_insn = 1'b1;
							endcase
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h33: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				rf_we = 1'b1;
				if ({instr[26], instr[13:12]} == 3'b101)
					illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
				else
					(* full_case, parallel_case *)
					case ({instr[31:25], instr[14:12]})
						10'b0000000000, 10'b0100000000, 10'b0000000010, 10'b0000000011, 10'b0000000100, 10'b0000000110, 10'b0000000111, 10'b0000000001, 10'b0000000101, 10'b0100000101: illegal_insn = 1'b0;
						10'b0010000010, 10'b0010000100, 10'b0010000110, 10'b0100000111, 10'b0100000110, 10'b0100000100, 10'b0110000001, 10'b0110000101, 10'b0000101100, 10'b0000101110, 10'b0000101101, 10'b0000101111, 10'b0000100100, 10'b0100100100, 10'b0000100111, 10'b0100100001, 10'b0010100001, 10'b0110100001, 10'b0100100101, 10'b0100100111: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						10'b0110100101, 10'b0010100101, 10'b0000100001, 10'b0000100101, 10'b0010100010, 10'b0010100100, 10'b0010100110, 10'b0010000001, 10'b0010000101, 10'b0000101001, 10'b0000101010, 10'b0000101011: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
						10'b0100100110, 10'b0000100110: illegal_insn = (RV32B == 32'sd3 ? 1'b0 : 1'b1);
						10'b0000001000: begin
							multdiv_operator_o = 2'd0;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001001: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001010: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b01;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001011: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001100: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001101: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001110: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001111: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						default: illegal_insn = 1'b1;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000: rf_we = 1'b0;
					3'b001: begin
						jump_in_dec_o = 1'b1;
						rf_we = 1'b0;
						if (instr_first_cycle_i) begin
							jump_set_o = 1'b1;
							icache_inval_o = 1'b1;
						end
					end
					default: illegal_insn = 1'b1;
				endcase
			7'h73:
				if (instr[14:12] == 3'b000) begin
					(* full_case, parallel_case *)
					case (instr[31:20])
						12'h000: ecall_insn_o = 1'b1;
						12'h001: ebrk_insn_o = 1'b1;
						12'h302: mret_insn_o = 1'b1;
						12'h7b2: dret_insn_o = 1'b1;
						12'h105: wfi_insn_o = 1'b1;
						default: illegal_insn = 1'b1;
					endcase
					if ((instr_rs1 != 5'b00000) || (instr_rd != 5'b00000))
						illegal_insn = 1'b1;
				end
				else begin
					csr_access_o = 1'b1;
					rf_wdata_sel_o = 1'd1;
					rf_we = 1'b1;
					if (~instr[14])
						rf_ren_a_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr[13:12])
						2'b01: csr_op = 2'd1;
						2'b10: csr_op = 2'd2;
						2'b11: csr_op = 2'd3;
						default: csr_illegal = 1'b1;
					endcase
					csr_cheriot_always_ok_o = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ((instr[31:28] == 4'hc) && ((instr[27] == 1'b0) || (instr[26:25] == 2'b00)));
					illegal_insn = csr_illegal;
				end
			7'h5b:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~illegal_c_insn_i) begin
					instr_is_cheriot_o = 1'b1;
					rf_ren_a_o = 1'b1;
					rf_we = 1'b1;
					if (instr[14:12] == 3'b000) begin
						if (instr[31:25] == 7'h7f)
							(* full_case, parallel_case *)
							case (instr[24:20])
								5'h00: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h0;
								end
								5'h01: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h1;
								end
								5'h02: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h2;
								end
								5'h03: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h3;
								end
								5'h04: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h4;
								end
								5'h08: begin
									cheriot_operator_o[23] = 1'b1;
									cheriot_setbounds_sel_o = 3'h5;
								end
								5'h09: begin
									cheriot_operator_o[24] = 1'b1;
									cheriot_setbounds_sel_o = 3'h6;
								end
								5'h0a: cheriot_operator_o[12] = 1'b1;
								5'h0b: cheriot_operator_o[14] = 1'b1;
								5'h0f: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h5;
								end
								5'h17: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h6;
								end
								5'h18: begin
									cheriot_operator_o[0] = 1'b1;
									cheriot_cap_field_sel_o = 3'h7;
								end
								default: illegal_insn = 1'b1;
							endcase
						else if (instr[31:25] == 7'h01) begin
							cheriot_operator_o[18] = 1'b1;
							cheriot_setaddr_sel_o = 3'h4;
						end
						else begin
							rf_ren_b_o = 1'b1;
							(* full_case, parallel_case *)
							case (instr[31:25])
								7'h08: begin
									cheriot_operator_o[7] = 1'b1;
									cheriot_setbounds_sel_o = 3'h1;
								end
								7'h09: begin
									cheriot_operator_o[8] = 1'b1;
									cheriot_setbounds_sel_o = 3'h3;
								end
								7'h0a: begin
									cheriot_operator_o[25] = 1'b1;
									cheriot_setbounds_sel_o = 3'h2;
								end
								7'h0b: cheriot_operator_o[1] = 1'b1;
								7'h0c: cheriot_operator_o[2] = 1'b1;
								7'h0d: cheriot_operator_o[3] = 1'b1;
								7'h10: begin
									cheriot_operator_o[4] = 1'b1;
									cheriot_adder_a_sel_o = 3'h4;
									cheriot_setaddr_sel_o = 3'h3;
								end
								7'h11: begin
									cheriot_operator_o[5] = 1'b1;
									cheriot_adder_a_sel_o = 3'h4;
									cheriot_adder_b_sel_o = 2'h1;
									cheriot_setaddr_sel_o = 3'h3;
								end
								7'h14: cheriot_operator_o[13] = 1'b1;
								7'h16: cheriot_operator_o[16] = 1'b1;
								7'h20: cheriot_operator_o[10] = 1'b1;
								7'h21: cheriot_operator_o[11] = 1'b1;
								default: illegal_insn = 1'b1;
							endcase
						end
					end
					else if (instr[14:12] == 3'b001) begin
						cheriot_operator_o[6] = 1'b1;
						cheriot_adder_a_sel_o = 3'h1;
						cheriot_adder_b_sel_o = 2'h1;
						cheriot_setaddr_sel_o = 3'h3;
					end
					else if (instr[14:12] == 3'b010) begin
						cheriot_operator_o[9] = 1'b1;
						cheriot_setbounds_sel_o = 3'h4;
					end
					else
						illegal_insn = 1'b1;
				end
				else
					illegal_insn = 1'b1;
			7'h7b:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~illegal_c_insn_i) begin
					cheriot_operator_o[22] = 1'b1;
					instr_is_cheriot_o = 1'b1;
					rf_ren_a_o = 1'b1;
					rf_we = 1'b1;
					illegal_insn = 1'b0;
					cheriot_adder_a_sel_o = 3'h3;
					cheriot_adder_b_sel_o = 2'h1;
					cheriot_setaddr_sel_o = 3'h3;
				end
				else
					illegal_insn = 1'b1;
			default: illegal_insn = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn = 1'b1;
		if (illegal_insn) begin
			rf_we = 1'b0;
			data_req_o = 1'b0;
			data_we_o = 1'b0;
			jump_in_dec_o = 1'b0;
			jump_set_o = 1'b0;
			branch_in_dec_o = 1'b0;
			csr_access_o = 1'b0;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operator_o = 7'd44;
		alu_op_a_mux_sel_o = 2'd3;
		alu_op_b_mux_sel_o = 1'd1;
		imm_a_mux_sel_o = 1'd1;
		imm_b_mux_sel_o = 3'd0;
		bt_a_mux_sel_o = 2'd2;
		bt_b_mux_sel_o = 3'd0;
		opcode_alu = instr_alu[6:0];
		use_rs3_d = 1'b0;
		alu_multicycle_o = 1'b0;
		mult_sel_o = 1'b0;
		div_sel_o = 1'b0;
		(* full_case, parallel_case *)
		case (opcode_alu)
			7'h6f: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = 3'd4;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd4;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h67: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd0;
					bt_b_mux_sel_o = 3'd0;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd0;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h63: begin
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd29;
					3'b001: alu_operator_o = 7'd30;
					3'b100: alu_operator_o = 7'd25;
					3'b101: alu_operator_o = 7'd27;
					3'b110: alu_operator_o = 7'd26;
					3'b111: alu_operator_o = 7'd28;
					default:
						;
				endcase
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
				end
				if (instr_first_cycle_i) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd0;
				end
				else if (!BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
					alu_operator_o = 7'd0;
				end
			end
			7'h23: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				alu_operator_o = 7'd0;
				if (!instr_alu[14]) begin
					imm_b_mux_sel_o = 3'd1;
					alu_op_b_mux_sel_o = 1'd1;
				end
			end
			7'h03: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_operator_o = 7'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
			end
			7'h37: begin
				alu_op_a_mux_sel_o = 2'd3;
				alu_op_b_mux_sel_o = 1'd1;
				imm_a_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h17: begin
				alu_op_a_mux_sel_o = 2'd2;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h13: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd0;
					3'b010: alu_operator_o = 7'd43;
					3'b011: alu_operator_o = 7'd44;
					3'b100: alu_operator_o = 7'd2;
					3'b110: alu_operator_o = 7'd3;
					3'b111: alu_operator_o = 7'd4;
					3'b001:
						if (RV32B != 32'sd0)
							(* full_case, parallel_case *)
							case (instr_alu[31:27])
								5'b00000: alu_operator_o = 7'd10;
								5'b00100:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										alu_operator_o = 7'd12;
								5'b01001: alu_operator_o = 7'd50;
								5'b00101: alu_operator_o = 7'd49;
								5'b01101: alu_operator_o = 7'd51;
								5'b00001:
									if (instr_alu[26] == 0)
										alu_operator_o = 7'd17;
								5'b01100:
									(* full_case, parallel_case *)
									case (instr_alu[26:20])
										7'b0000000: alu_operator_o = 7'd40;
										7'b0000001: alu_operator_o = 7'd41;
										7'b0000010: alu_operator_o = 7'd42;
										7'b0000100: alu_operator_o = 7'd38;
										7'b0000101: alu_operator_o = 7'd39;
										7'b0010000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd59;
												alu_multicycle_o = 1'b1;
											end
										7'b0010001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd61;
												alu_multicycle_o = 1'b1;
											end
										7'b0010010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd63;
												alu_multicycle_o = 1'b1;
											end
										7'b0011000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd60;
												alu_multicycle_o = 1'b1;
											end
										7'b0011001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd62;
												alu_multicycle_o = 1'b1;
											end
										7'b0011010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd64;
												alu_multicycle_o = 1'b1;
											end
										default:
											;
									endcase
								default:
									;
							endcase
						else
							alu_operator_o = 7'd10;
					3'b101:
						if (RV32B != 32'sd0) begin
							if (instr_alu[26] == 1'b1) begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							else
								(* full_case, parallel_case *)
								case (instr_alu[31:27])
									5'b00000: alu_operator_o = 7'd9;
									5'b01000: alu_operator_o = 7'd8;
									5'b00100:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
											alu_operator_o = 7'd11;
									5'b01001: alu_operator_o = 7'd52;
									5'b01100: begin
										alu_operator_o = 7'd13;
										alu_multicycle_o = 1'b1;
									end
									5'b01101: alu_operator_o = 7'd15;
									5'b00101: alu_operator_o = 7'd16;
									5'b00001:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
											if (instr_alu[26] == 1'b0)
												alu_operator_o = 7'd18;
										end
									default:
										;
								endcase
						end
						else if (instr_alu[31:27] == 5'b00000)
							alu_operator_o = 7'd9;
						else if (instr_alu[31:27] == 5'b01000)
							alu_operator_o = 7'd8;
					default:
						;
				endcase
			end
			7'h33: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				if (instr_alu[26]) begin
					if (RV32B != 32'sd0)
						(* full_case, parallel_case *)
						case ({instr_alu[26:25], instr_alu[14:12]})
							5'b11001: begin
								alu_operator_o = 7'd46;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b11101: begin
								alu_operator_o = 7'd45;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10001: begin
								alu_operator_o = 7'd47;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10101: begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							default:
								;
						endcase
				end
				else
					(* full_case, parallel_case *)
					case ({instr_alu[31:25], instr_alu[14:12]})
						10'b0000000000: alu_operator_o = 7'd0;
						10'b0100000000: alu_operator_o = 7'd1;
						10'b0000000010: alu_operator_o = 7'd43;
						10'b0000000011: alu_operator_o = 7'd44;
						10'b0000000100: alu_operator_o = 7'd2;
						10'b0000000110: alu_operator_o = 7'd3;
						10'b0000000111: alu_operator_o = 7'd4;
						10'b0000000001: alu_operator_o = 7'd10;
						10'b0000000101: alu_operator_o = 7'd9;
						10'b0100000101: alu_operator_o = 7'd8;
						10'b0110000001:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd14;
								alu_multicycle_o = 1'b1;
							end
						10'b0110000101:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd13;
								alu_multicycle_o = 1'b1;
							end
						10'b0000101100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd31;
						10'b0000101110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd33;
						10'b0000101101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd32;
						10'b0000101111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd34;
						10'b0000100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd35;
						10'b0100100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd36;
						10'b0000100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd37;
						10'b0100000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd5;
						10'b0100000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd6;
						10'b0100000111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd7;
						10'b0010000010:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd22;
						10'b0010000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd23;
						10'b0010000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd24;
						10'b0100100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd50;
						10'b0010100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd49;
						10'b0110100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd51;
						10'b0100100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd52;
						10'b0100100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd55;
						10'b0110100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd15;
						10'b0010100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd16;
						10'b0000100001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd17;
						10'b0000100101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd18;
						10'b0010100010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd19;
						10'b0010100100:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd20;
						10'b0010100110:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd21;
						10'b0010000001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd12;
						10'b0010000101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd11;
						10'b0000101001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd56;
						10'b0000101010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd57;
						10'b0000101011:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd58;
						10'b0100100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd54;
								alu_multicycle_o = 1'b1;
							end
						10'b0000100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd53;
								alu_multicycle_o = 1'b1;
							end
						10'b0000001000: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001001: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001010: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001011: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001100: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001101: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001110: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001111: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						default:
							;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: begin
						alu_operator_o = 7'd0;
						alu_op_a_mux_sel_o = 2'd0;
						alu_op_b_mux_sel_o = 1'd1;
					end
					3'b001:
						if (BranchTargetALU) begin
							bt_a_mux_sel_o = 2'd2;
							bt_b_mux_sel_o = 3'd5;
						end
						else begin
							alu_op_a_mux_sel_o = 2'd2;
							alu_op_b_mux_sel_o = 1'd1;
							imm_b_mux_sel_o = 3'd5;
							alu_operator_o = 7'd0;
						end
					default:
						;
				endcase
			7'h73:
				if (instr_alu[14:12] == 3'b000) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
				end
				else begin
					imm_a_mux_sel_o = 1'd0;
					if (instr_alu[14])
						alu_op_a_mux_sel_o = 2'd3;
					else
						alu_op_a_mux_sel_o = 2'd0;
				end
			default:
				;
		endcase
	end
	assign mult_en_o = (illegal_insn_o ? 1'b0 : mult_sel_o);
	assign div_en_o = (illegal_insn_o ? 1'b0 : div_sel_o);
	assign illegal_insn_o = illegal_insn | illegal_reg_16;
	assign rf_we_o = rf_we & ~illegal_reg_16;
	assign unused_instr_alu = {instr_alu[19:15], instr_alu[11:7]};
	assign instr_is_legal_cheriot = |cheriot_operator_o;
	assign instr_is_legal_cheriot_o = instr_is_legal_cheriot & ~illegal_reg_16;
	assign cheriot_cs2_dec_o = (cheriot_operator_o[18] ? instr[24:20] : 5'h00);
	assign cheriot_imm12_o = (((cheriot_operator_o[19] | cheriot_operator_o[9]) | cheriot_operator_o[6]) | cheriot_operator_o[15] ? {instr[31:25], instr[24:20]} : (cheriot_operator_o[17] ? {instr[31:25], instr[11:7]} : 12'h000));
	assign cheriot_imm20_o = (cheriot_operator_o[21] | cheriot_operator_o[22] ? instr[31:12] : 20'h00000);
	assign cheriot_imm21_o = (cheriot_operator_o[20] ? {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} : 21'h000000);
	generate
		if (BaseIsa != 32'sd1) begin : gen_no_cheriot_decoder
			wire unused_cheriot_enable;
			assign unused_cheriot_enable = ^cheriot_enable_i;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_dummy_instr (
	clk_i,
	rst_ni,
	dummy_instr_en_i,
	dummy_instr_mask_i,
	dummy_instr_seed_en_i,
	dummy_instr_seed_i,
	fetch_valid_i,
	id_in_ready_i,
	insert_dummy_instr_o,
	dummy_instr_data_o
);
	reg _sv2v_0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	input wire clk_i;
	input wire rst_ni;
	input wire dummy_instr_en_i;
	input wire [2:0] dummy_instr_mask_i;
	input wire dummy_instr_seed_en_i;
	input wire [31:0] dummy_instr_seed_i;
	input wire fetch_valid_i;
	input wire id_in_ready_i;
	output wire insert_dummy_instr_o;
	output wire [31:0] dummy_instr_data_o;
	localparam [31:0] TIMEOUT_CNT_W = 5;
	localparam [31:0] OP_W = 5;
	localparam [31:0] LFSR_OUT_W = 17;
	wire [16:0] lfsr_data;
	wire [4:0] dummy_cnt_incr;
	wire [4:0] dummy_cnt_threshold;
	wire [4:0] dummy_cnt_d;
	reg [4:0] dummy_cnt_q;
	wire dummy_cnt_en;
	wire lfsr_en;
	wire [16:0] lfsr_state;
	wire insert_dummy_instr;
	reg [6:0] dummy_set;
	reg [2:0] dummy_opcode;
	wire [31:0] dummy_instr;
	reg [31:0] dummy_instr_seed_q;
	wire [31:0] dummy_instr_seed_d;
	assign lfsr_en = insert_dummy_instr & id_in_ready_i;
	assign dummy_instr_seed_d = dummy_instr_seed_q ^ dummy_instr_seed_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dummy_instr_seed_q <= 1'sb0;
		else if (dummy_instr_seed_en_i)
			dummy_instr_seed_q <= dummy_instr_seed_d;
	localparam [31:0] sv2v_uu_lfsr_i_EntropyDw = 8;
	localparam [7:0] sv2v_uu_lfsr_i_ext_entropy_i_0 = 1'sb0;
	prim_lfsr #(
		.LfsrDw(ibex_pkg_LfsrWidth),
		.StateOutDw(LFSR_OUT_W),
		.DefaultSeed(RndCnstLfsrSeed),
		.StatePermEn(1'b1),
		.StatePerm(RndCnstLfsrPerm)
	) lfsr_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.seed_en_i(dummy_instr_seed_en_i),
		.seed_i(dummy_instr_seed_d),
		.lfsr_en_i(lfsr_en),
		.entropy_i(sv2v_uu_lfsr_i_ext_entropy_i_0),
		.state_o(lfsr_state)
	);
	function automatic [16:0] sv2v_cast_92F3A;
		input reg [16:0] inp;
		sv2v_cast_92F3A = inp;
	endfunction
	assign lfsr_data = sv2v_cast_92F3A(lfsr_state);
	assign dummy_cnt_threshold = lfsr_data[4-:TIMEOUT_CNT_W] & {dummy_instr_mask_i, {2 {1'b1}}};
	assign dummy_cnt_incr = dummy_cnt_q + {{4 {1'b0}}, 1'b1};
	assign dummy_cnt_d = (insert_dummy_instr ? {5 {1'sb0}} : dummy_cnt_incr);
	assign dummy_cnt_en = (dummy_instr_en_i & id_in_ready_i) & (fetch_valid_i | insert_dummy_instr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dummy_cnt_q <= 1'sb0;
		else if (dummy_cnt_en)
			dummy_cnt_q <= dummy_cnt_d;
	assign insert_dummy_instr = dummy_instr_en_i & (dummy_cnt_q == dummy_cnt_threshold);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (lfsr_data[16-:2])
			2'b00: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b000;
			end
			2'b01: begin
				dummy_set = 7'b0000001;
				dummy_opcode = 3'b000;
			end
			2'b10: begin
				dummy_set = 7'b0000001;
				dummy_opcode = 3'b100;
			end
			2'b11: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b111;
			end
			default: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b000;
			end
		endcase
	end
	assign dummy_instr = {dummy_set, lfsr_data[14-:5], lfsr_data[9-:5], dummy_opcode, 12'h033};
	assign insert_dummy_instr_o = insert_dummy_instr;
	assign dummy_instr_data_o = dummy_instr;
	initial _sv2v_0 = 0;
endmodule
module ibex_ex_block (
	clk_i,
	rst_ni,
	alu_operator_i,
	alu_operand_a_i,
	alu_operand_b_i,
	alu_instr_first_cycle_i,
	bt_a_operand_i,
	bt_b_operand_i,
	multdiv_operator_i,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	multdiv_signed_mode_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_ready_id_i,
	data_ind_timing_i,
	imd_val_we_o,
	imd_val_d_o,
	imd_val_q_i,
	alu_adder_result_ex_o,
	result_ex_o,
	branch_target_o,
	branch_decision_o,
	ex_valid_o
);
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire [6:0] alu_operator_i;
	input wire [31:0] alu_operand_a_i;
	input wire [31:0] alu_operand_b_i;
	input wire alu_instr_first_cycle_i;
	input wire [31:0] bt_a_operand_i;
	input wire [31:0] bt_b_operand_i;
	input wire [1:0] multdiv_operator_i;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] multdiv_signed_mode_i;
	input wire [31:0] multdiv_operand_a_i;
	input wire [31:0] multdiv_operand_b_i;
	input wire multdiv_ready_id_i;
	input wire data_ind_timing_i;
	output wire [1:0] imd_val_we_o;
	output wire [67:0] imd_val_d_o;
	input wire [67:0] imd_val_q_i;
	output wire [31:0] alu_adder_result_ex_o;
	output wire [31:0] result_ex_o;
	output wire [31:0] branch_target_o;
	output wire branch_decision_o;
	output wire ex_valid_o;
	wire [31:0] alu_result;
	wire [31:0] multdiv_result;
	wire [32:0] multdiv_alu_operand_b;
	wire [32:0] multdiv_alu_operand_a;
	wire [33:0] alu_adder_result_ext;
	wire alu_cmp_result;
	wire alu_is_equal_result;
	wire multdiv_valid;
	wire multdiv_sel;
	wire [63:0] alu_imd_val_q;
	wire [63:0] alu_imd_val_d;
	wire [1:0] alu_imd_val_we;
	wire [67:0] multdiv_imd_val_d;
	wire [1:0] multdiv_imd_val_we;
	generate
		if (RV32M != 32'sd0) begin : gen_multdiv_m
			assign multdiv_sel = mult_sel_i | div_sel_i;
		end
		else begin : gen_multdiv_no_m
			assign multdiv_sel = 1'b0;
		end
	endgenerate
	assign imd_val_d_o[34+:34] = (multdiv_sel ? multdiv_imd_val_d[34+:34] : {2'b00, alu_imd_val_d[32+:32]});
	assign imd_val_d_o[0+:34] = (multdiv_sel ? multdiv_imd_val_d[0+:34] : {2'b00, alu_imd_val_d[0+:32]});
	assign imd_val_we_o = (multdiv_sel ? multdiv_imd_val_we : alu_imd_val_we);
	assign alu_imd_val_q = {imd_val_q_i[65-:32], imd_val_q_i[31-:32]};
	assign result_ex_o = (multdiv_sel ? multdiv_result : alu_result);
	assign branch_decision_o = alu_cmp_result;
	generate
		if (BranchTargetALU) begin : g_branch_target_alu
			wire [32:0] bt_alu_result;
			wire unused_bt_carry;
			assign bt_alu_result = bt_a_operand_i + bt_b_operand_i;
			assign unused_bt_carry = bt_alu_result[32];
			assign branch_target_o = bt_alu_result[31:0];
		end
		else begin : g_no_branch_target_alu
			wire [31:0] unused_bt_a_operand;
			wire [31:0] unused_bt_b_operand;
			assign unused_bt_a_operand = bt_a_operand_i;
			assign unused_bt_b_operand = bt_b_operand_i;
			assign branch_target_o = alu_adder_result_ex_o;
		end
	endgenerate
	ibex_alu #(.RV32B(RV32B)) alu_i(
		.operator_i(alu_operator_i),
		.operand_a_i(alu_operand_a_i),
		.operand_b_i(alu_operand_b_i),
		.instr_first_cycle_i(alu_instr_first_cycle_i),
		.imd_val_q_i(alu_imd_val_q),
		.imd_val_we_o(alu_imd_val_we),
		.imd_val_d_o(alu_imd_val_d),
		.multdiv_operand_a_i(multdiv_alu_operand_a),
		.multdiv_operand_b_i(multdiv_alu_operand_b),
		.multdiv_sel_i(multdiv_sel),
		.adder_result_o(alu_adder_result_ex_o),
		.adder_result_ext_o(alu_adder_result_ext),
		.result_o(alu_result),
		.comparison_result_o(alu_cmp_result),
		.is_equal_result_o(alu_is_equal_result)
	);
	generate
		if (RV32M == 32'sd1) begin : gen_multdiv_slow
			ibex_multdiv_slow multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.valid_o(multdiv_valid),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.multdiv_result_o(multdiv_result)
			);
		end
		else if ((RV32M == 32'sd2) || (RV32M == 32'sd3)) begin : gen_multdiv_fast
			ibex_multdiv_fast #(.RV32M(RV32M)) multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.valid_o(multdiv_valid),
				.multdiv_result_o(multdiv_result)
			);
		end
	endgenerate
	assign ex_valid_o = (multdiv_sel ? multdiv_valid : ~(|alu_imd_val_we));
endmodule
module ibex_fetch_fifo (
	clk_i,
	rst_ni,
	clear_i,
	busy_o,
	in_valid_i,
	in_addr_i,
	in_rdata_i,
	in_err_i,
	cheriot_force_uc_i,
	out_valid_o,
	out_ready_i,
	out_addr_o,
	out_rdata_o,
	out_err_o,
	out_err_plus2_o
);
	reg _sv2v_0;
	parameter [31:0] NUM_REQS = 2;
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	output wire [NUM_REQS - 1:0] busy_o;
	input wire in_valid_i;
	input wire [31:0] in_addr_i;
	input wire [31:0] in_rdata_i;
	input wire in_err_i;
	input wire cheriot_force_uc_i;
	output reg out_valid_o;
	input wire out_ready_i;
	output wire [31:0] out_addr_o;
	output reg [31:0] out_rdata_o;
	output reg out_err_o;
	output reg out_err_plus2_o;
	localparam [31:0] DEPTH = NUM_REQS + 1;
	wire [(DEPTH * 32) - 1:0] rdata_d;
	reg [(DEPTH * 32) - 1:0] rdata_q;
	wire [DEPTH - 1:0] err_d;
	reg [DEPTH - 1:0] err_q;
	wire [DEPTH - 1:0] valid_d;
	reg [DEPTH - 1:0] valid_q;
	wire [DEPTH - 1:0] lowest_free_entry;
	wire [DEPTH - 1:0] valid_pushed;
	wire [DEPTH - 1:0] valid_popped;
	wire [DEPTH - 1:0] entry_en;
	wire pop_fifo;
	wire [31:0] rdata;
	wire [31:0] rdata_unaligned;
	wire err;
	wire err_unaligned;
	wire err_plus2;
	wire valid;
	wire valid_unaligned;
	wire aligned_is_compressed;
	wire unaligned_is_compressed;
	wire addr_incr_two;
	wire [31:1] instr_addr_next;
	wire [31:1] instr_addr_d;
	reg [31:1] instr_addr_q;
	wire instr_addr_en;
	wire unused_addr_in;
	assign rdata = (valid_q[0] ? rdata_q[0+:32] : in_rdata_i);
	assign err = (valid_q[0] ? err_q[0] : in_err_i);
	assign valid = valid_q[0] | in_valid_i;
	assign rdata_unaligned = (valid_q[1] ? {rdata_q[47-:16], rdata[31:16]} : {in_rdata_i[15:0], rdata[31:16]});
	assign err_unaligned = (valid_q[1] ? (err_q[1] & ~unaligned_is_compressed) | err_q[0] : (valid_q[0] & err_q[0]) | (in_err_i & (~valid_q[0] | ~unaligned_is_compressed)));
	assign err_plus2 = (valid_q[1] ? err_q[1] & ~err_q[0] : (in_err_i & valid_q[0]) & ~err_q[0]);
	assign valid_unaligned = (valid_q[1] ? 1'b1 : valid_q[0] & in_valid_i);
	assign unaligned_is_compressed = cheriot_force_uc_i | ((rdata[17:16] != 2'b11) & ~err);
	assign aligned_is_compressed = (rdata[1:0] != 2'b11) & ~err;
	always @(*) begin
		if (_sv2v_0)
			;
		if (out_addr_o[1]) begin
			out_rdata_o = rdata_unaligned;
			out_err_o = err_unaligned;
			out_err_plus2_o = err_plus2;
			if (unaligned_is_compressed)
				out_valid_o = valid;
			else
				out_valid_o = valid_unaligned;
		end
		else begin
			out_rdata_o = rdata;
			out_err_o = err;
			out_err_plus2_o = 1'b0;
			out_valid_o = valid;
		end
	end
	assign instr_addr_en = clear_i | (out_ready_i & out_valid_o);
	assign addr_incr_two = (instr_addr_q[1] ? unaligned_is_compressed : aligned_is_compressed);
	assign instr_addr_next = instr_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};
	assign instr_addr_d = (clear_i ? in_addr_i[31:1] : instr_addr_next);
	generate
		if (ResetAll) begin : g_instr_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_addr_q <= 1'sb0;
				else if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
		else begin : g_instr_addr_nr
			always @(posedge clk_i)
				if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
	endgenerate
	assign out_addr_o = {instr_addr_q, 1'b0};
	assign unused_addr_in = in_addr_i[0];
	assign busy_o = valid_q[DEPTH - 1:DEPTH - NUM_REQS];
	assign pop_fifo = (out_ready_i & out_valid_o) & (~aligned_is_compressed | out_addr_o[1]);
	genvar _gv_i_28;
	generate
		for (_gv_i_28 = 0; _gv_i_28 < (DEPTH - 1); _gv_i_28 = _gv_i_28 + 1) begin : g_fifo_next
			localparam i = _gv_i_28;
			if (i == 0) begin : g_ent0
				assign lowest_free_entry[i] = ~valid_q[i];
			end
			else begin : g_ent_others
				assign lowest_free_entry[i] = ~valid_q[i] & valid_q[i - 1];
			end
			assign valid_pushed[i] = (in_valid_i & lowest_free_entry[i]) | valid_q[i];
			assign valid_popped[i] = (pop_fifo ? valid_pushed[i + 1] : valid_pushed[i]);
			assign valid_d[i] = valid_popped[i] & ~clear_i;
			assign entry_en[i] = (valid_pushed[i + 1] & pop_fifo) | ((in_valid_i & lowest_free_entry[i]) & ~pop_fifo);
			assign rdata_d[i * 32+:32] = (valid_q[i + 1] ? rdata_q[(i + 1) * 32+:32] : in_rdata_i);
			assign err_d[i] = (valid_q[i + 1] ? err_q[i + 1] : in_err_i);
		end
	endgenerate
	assign lowest_free_entry[DEPTH - 1] = ~valid_q[DEPTH - 1] & valid_q[DEPTH - 2];
	assign valid_pushed[DEPTH - 1] = valid_q[DEPTH - 1] | (in_valid_i & lowest_free_entry[DEPTH - 1]);
	assign valid_popped[DEPTH - 1] = (pop_fifo ? 1'b0 : valid_pushed[DEPTH - 1]);
	assign valid_d[DEPTH - 1] = valid_popped[DEPTH - 1] & ~clear_i;
	assign entry_en[DEPTH - 1] = in_valid_i & lowest_free_entry[DEPTH - 1];
	assign rdata_d[(DEPTH - 1) * 32+:32] = in_rdata_i;
	assign err_d[DEPTH - 1] = in_err_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			valid_q <= 1'sb0;
		else
			valid_q <= valid_d;
	genvar _gv_i_29;
	generate
		for (_gv_i_29 = 0; _gv_i_29 < DEPTH; _gv_i_29 = _gv_i_29 + 1) begin : g_fifo_regs
			localparam i = _gv_i_29;
			if (ResetAll) begin : g_rdata_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rdata_q[i * 32+:32] <= 1'sb0;
						err_q[i] <= 1'sb0;
					end
					else if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
			else begin : g_rdata_nr
				always @(posedge clk_i)
					if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_icache (
	clk_i,
	rst_ni,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	err_o,
	err_plus2_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	instr_rvalid_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	icache_enable_i,
	icache_inval_i,
	busy_o,
	ecc_error_o
);
	reg _sv2v_0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ResetAll = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchCache = 1'b0;
	parameter [0:0] TweakInfection = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output wire err_o;
	output wire err_plus2_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_rvalid_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output reg ic_scr_key_req_o;
	input wire icache_enable_i;
	input wire icache_inval_i;
	output wire busy_o;
	output wire ecc_error_o;
	localparam [31:0] NUM_FB = 4;
	localparam [31:0] FB_THRESHOLD = 2;
	wire [31:0] lookup_addr_aligned;
	wire [31:0] prefetch_addr_d;
	reg [31:0] prefetch_addr_q;
	wire prefetch_addr_en;
	wire lookup_throttle;
	wire lookup_req_ic0;
	wire [31:0] lookup_addr_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] lookup_index_ic0;
	wire fill_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] fill_index_ic0;
	wire [ibex_pkg_IC_TAG_SIZE - 1:0] fill_tag_ic0;
	wire [63:0] fill_wdata_ic0;
	wire lookup_grant_ic0;
	wire lookup_actual_ic0;
	wire fill_grant_ic0;
	wire tag_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] tag_index_ic0;
	wire [1:0] tag_banks_ic0;
	wire tag_write_ic0;
	wire [TagSizeECC - 1:0] tag_wdata_ic0;
	wire data_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] data_index_ic0;
	wire [1:0] data_banks_ic0;
	wire data_write_ic0;
	wire [LineSizeECC - 1:0] data_wdata_ic0;
	reg [LineSizeECC - 1:0] data_tweak_lw_ic0;
	reg [LineSizeECC - 1:0] data_tweak_lw_ic1;
	reg [TagSizeECC - 1:0] tag_tweak_lw_ic0;
	reg [TagSizeECC - 1:0] tag_tweak_lw_ic1;
	wire [TagSizeECC - 1:0] tag_rdata_ic1 [0:1];
	reg [LineSizeECC - 1:0] hit_data_ecc_ic1;
	wire [63:0] hit_data_ic1;
	reg lookup_valid_ic1;
	localparam [31:0] ibex_pkg_IC_INDEX_HI = (ibex_pkg_IC_INDEX_W + ibex_pkg_IC_LINE_W) - 1;
	reg [31:ibex_pkg_IC_INDEX_HI + 1] lookup_addr_ic1;
	wire [1:0] tag_match_ic1;
	wire tag_hit_ic1;
	wire [1:0] tag_invalid_ic1;
	wire [1:0] lowest_invalid_way_ic1;
	wire [1:0] round_robin_way_ic1;
	reg [1:0] round_robin_way_q;
	wire [1:0] sel_way_ic1;
	wire ecc_err_ic1;
	wire ecc_write_req;
	wire [1:0] ecc_write_ways;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ecc_write_index;
	reg [1:0] fb_fill_level;
	wire fill_cache_new;
	wire fill_new_alloc;
	wire fill_spec_req;
	wire fill_spec_done;
	wire fill_spec_hold;
	wire [(NUM_FB * NUM_FB) - 1:0] fill_older_d;
	reg [(NUM_FB * NUM_FB) - 1:0] fill_older_q;
	wire [3:0] fill_alloc_sel;
	wire [3:0] fill_alloc;
	wire [3:0] fill_busy_d;
	reg [3:0] fill_busy_q;
	wire [3:0] fill_done;
	reg [3:0] fill_in_ic1;
	wire [3:0] fill_stale_d;
	reg [3:0] fill_stale_q;
	wire [3:0] fill_cache_d;
	reg [3:0] fill_cache_q;
	wire [3:0] fill_hit_ic1;
	wire [3:0] fill_hit_d;
	reg [3:0] fill_hit_q;
	localparam [31:0] ibex_pkg_BUS_BYTES = 4;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS = ibex_pkg_IC_LINE_BYTES / ibex_pkg_BUS_BYTES;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS_W = $clog2(ibex_pkg_IC_LINE_BEATS);
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_cnt_q;
	wire [3:0] fill_ext_hold_d;
	reg [3:0] fill_ext_hold_q;
	wire [3:0] fill_ext_done_d;
	reg [3:0] fill_ext_done_q;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_cnt_q;
	wire [3:0] fill_rvd_done;
	wire [3:0] fill_ram_done_d;
	reg [3:0] fill_ram_done_q;
	wire [3:0] fill_out_grant;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_out_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_out_cnt_q;
	wire [3:0] fill_out_done;
	wire [3:0] fill_ext_req;
	wire [3:0] fill_rvd_exp;
	wire [3:0] fill_ram_req;
	wire [3:0] fill_out_req;
	wire [3:0] fill_data_sel;
	wire [3:0] fill_data_reg;
	wire [3:0] fill_data_hit;
	wire [3:0] fill_data_rvd;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS_W) - 1:0] fill_ext_off;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS_W) - 1:0] fill_rvd_off;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_beat;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_beat;
	wire [3:0] fill_ext_arb;
	wire [3:0] fill_ram_arb;
	wire [3:0] fill_out_arb;
	wire [3:0] fill_rvd_arb;
	wire [3:0] fill_entry_en;
	wire [3:0] fill_addr_en;
	wire [3:0] fill_way_en;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_data_en;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_err_d;
	reg [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_err_q;
	reg [31:0] fill_addr_q [0:3];
	reg [1:0] fill_way_q [0:3];
	wire [63:0] fill_data_d [0:3];
	reg [63:0] fill_data_q [0:3];
	localparam [31:0] ibex_pkg_BUS_W = 2;
	reg [31:ibex_pkg_BUS_W] fill_ext_req_addr;
	reg [31:0] fill_ram_req_addr;
	reg [1:0] fill_ram_req_way;
	reg [63:0] fill_ram_req_data;
	reg [63:0] fill_out_data;
	reg [ibex_pkg_IC_LINE_BEATS - 1:0] fill_out_err;
	wire instr_req;
	wire [31:ibex_pkg_BUS_W] instr_addr;
	wire skid_complete_instr;
	wire skid_ready;
	wire output_compressed;
	wire skid_valid_d;
	reg skid_valid_q;
	wire skid_en;
	wire [15:0] skid_data_d;
	reg [15:0] skid_data_q;
	reg skid_err_q;
	wire output_valid;
	wire addr_incr_two;
	wire output_addr_en;
	wire [31:1] output_addr_incr;
	wire [31:1] output_addr_d;
	reg [31:1] output_addr_q;
	reg [15:0] output_data_lo;
	reg [15:0] output_data_hi;
	wire data_valid;
	wire output_ready;
	wire [63:0] line_data;
	wire [ibex_pkg_IC_LINE_BEATS - 1:0] line_err;
	reg [31:0] line_data_muxed;
	reg line_err_muxed;
	wire [31:0] output_data;
	wire output_err;
	reg [1:0] inval_state_q;
	reg [1:0] inval_state_d;
	reg inval_write_req;
	reg inval_block_cache;
	reg [ibex_pkg_IC_INDEX_W - 1:0] inval_index_d;
	reg [ibex_pkg_IC_INDEX_W - 1:0] inval_index_q;
	reg inval_index_en;
	wire inval_active;
	assign lookup_addr_aligned = {lookup_addr_ic0[31:ibex_pkg_IC_LINE_W], {ibex_pkg_IC_LINE_W {1'b0}}};
	assign prefetch_addr_d = (lookup_grant_ic0 ? lookup_addr_aligned + {{(ibex_pkg_ADDR_W - ibex_pkg_IC_LINE_W) - 1 {1'b0}}, 1'b1, {ibex_pkg_IC_LINE_W {1'b0}}} : addr_i);
	assign prefetch_addr_en = branch_i | lookup_grant_ic0;
	generate
		if (ResetAll) begin : g_prefetch_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					prefetch_addr_q <= 1'sb0;
				else if (prefetch_addr_en)
					prefetch_addr_q <= prefetch_addr_d;
		end
		else begin : g_prefetch_addr_nr
			always @(posedge clk_i)
				if (prefetch_addr_en)
					prefetch_addr_q <= prefetch_addr_d;
		end
	endgenerate
	assign lookup_throttle = fb_fill_level > FB_THRESHOLD[1:0];
	assign lookup_req_ic0 = ((req_i & ~&fill_busy_q) & (branch_i | ~lookup_throttle)) & ~ecc_write_req;
	assign lookup_addr_ic0 = (branch_i ? addr_i : prefetch_addr_q);
	assign lookup_index_ic0 = lookup_addr_ic0[ibex_pkg_IC_INDEX_HI:ibex_pkg_IC_LINE_W];
	assign fill_req_ic0 = |fill_ram_req;
	assign fill_index_ic0 = fill_ram_req_addr[ibex_pkg_IC_INDEX_HI:ibex_pkg_IC_LINE_W];
	assign fill_tag_ic0 = {~inval_write_req & ~ecc_write_req, fill_ram_req_addr[31:ibex_pkg_IC_INDEX_HI + 1]};
	assign fill_wdata_ic0 = fill_ram_req_data;
	assign lookup_grant_ic0 = lookup_req_ic0;
	assign fill_grant_ic0 = ((fill_req_ic0 & ~lookup_req_ic0) & ~inval_write_req) & ~ecc_write_req;
	assign lookup_actual_ic0 = (lookup_grant_ic0 & icache_enable_i) & ~inval_block_cache;
	assign tag_req_ic0 = ((lookup_req_ic0 | fill_req_ic0) | inval_write_req) | ecc_write_req;
	assign tag_index_ic0 = (inval_write_req ? inval_index_q : (ecc_write_req ? ecc_write_index : (fill_grant_ic0 ? fill_index_ic0 : lookup_index_ic0)));
	assign tag_banks_ic0 = (ecc_write_req ? ecc_write_ways : (fill_grant_ic0 ? fill_ram_req_way : {ibex_pkg_IC_NUM_WAYS {1'b1}}));
	assign tag_write_ic0 = (fill_grant_ic0 | inval_write_req) | ecc_write_req;
	assign data_req_ic0 = lookup_req_ic0 | fill_req_ic0;
	assign data_index_ic0 = tag_index_ic0;
	assign data_banks_ic0 = tag_banks_ic0;
	assign data_write_ic0 = tag_write_ic0;
	generate
		if (ICacheECC) begin : gen_ecc_wdata
			wire [21:0] tag_ecc_input_padded;
			wire [27:0] tag_ecc_output_padded;
			wire [22 - ibex_pkg_IC_TAG_SIZE:0] unused_tag_ecc_output;
			assign tag_ecc_input_padded = {{22 - ibex_pkg_IC_TAG_SIZE {1'b0}}, fill_tag_ic0};
			assign unused_tag_ecc_output = tag_ecc_output_padded[21:ibex_pkg_IC_TAG_SIZE - 1];
			prim_secded_inv_28_22_enc tag_ecc_enc(
				.data_i(tag_ecc_input_padded),
				.data_o(tag_ecc_output_padded)
			);
			assign tag_wdata_ic0 = {tag_ecc_output_padded[27:22], tag_ecc_output_padded[ibex_pkg_IC_TAG_SIZE - 1:0]};
			genvar _gv_bank_1;
			for (_gv_bank_1 = 0; _gv_bank_1 < ibex_pkg_IC_LINE_BEATS; _gv_bank_1 = _gv_bank_1 + 1) begin : gen_ecc_banks
				localparam bank = _gv_bank_1;
				prim_secded_inv_39_32_enc data_ecc_enc(
					.data_i(fill_wdata_ic0[bank * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE]),
					.data_o(data_wdata_ic0[bank * BusSizeECC+:BusSizeECC])
				);
			end
		end
		else begin : gen_noecc_wdata
			assign tag_wdata_ic0 = fill_tag_ic0;
			assign data_wdata_ic0 = fill_wdata_ic0;
		end
	endgenerate
	localparam [31:0] ibex_pkg_IC_DATA_ECC_SIZE = 7;
	localparam [31:0] ibex_pkg_IC_TAG_ECC_SIZE = 6;
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	generate
		if (TweakInfection) begin : gen_tweak_infection
			wire [31:0] data_address_ic0;
			wire [(ibex_pkg_ADDR_W - ibex_pkg_IC_LINE_W) - 1:0] data_tweak_ic0;
			assign data_address_ic0 = (inval_write_req ? {32 {1'sb0}} : (ecc_write_req ? {32 {1'sb0}} : (fill_grant_ic0 ? fill_ram_req_addr : lookup_addr_ic0)));
			assign data_tweak_ic0 = data_address_ic0[31:ibex_pkg_IC_LINE_W];
			wire unused_data_address_ic0;
			assign unused_data_address_ic0 = ^data_address_ic0[2:0];
			if (ICacheECC) begin : gen_ecc_tweak
				always @(*) begin
					if (_sv2v_0)
						;
					data_tweak_lw_ic0 = 1'sb0;
					begin : sv2v_autoblock_1
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							data_tweak_lw_ic0 = data_tweak_lw_ic0 | (sv2v_cast_033B0({data_tweak_ic0, {ibex_pkg_IC_LINE_W {1'b0}}}) << (i * (ibex_pkg_ADDR_W + ibex_pkg_IC_DATA_ECC_SIZE)));
					end
				end
			end
			else begin : gen_no_ecc_tweak
				always @(*) begin
					if (_sv2v_0)
						;
					data_tweak_lw_ic0 = 1'sb0;
					begin : sv2v_autoblock_2
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							data_tweak_lw_ic0 = data_tweak_lw_ic0 | (sv2v_cast_033B0({data_tweak_ic0, {ibex_pkg_IC_LINE_W {1'b0}}}) << (i * ibex_pkg_ADDR_W));
					end
				end
			end
			reg [(ibex_pkg_ADDR_W - ibex_pkg_IC_LINE_W) - 1:0] data_tweak_ic1;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					data_tweak_ic1 <= 1'sb0;
				else if (data_req_ic0)
					data_tweak_ic1 <= data_tweak_ic0;
			if (ICacheECC) begin : gen_ecc_tweak_ic1
				always @(*) begin
					if (_sv2v_0)
						;
					data_tweak_lw_ic1 = 1'sb0;
					begin : sv2v_autoblock_3
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							data_tweak_lw_ic1 = data_tweak_lw_ic1 | (sv2v_cast_033B0({data_tweak_ic1, {ibex_pkg_IC_LINE_W {1'b0}}}) << (i * (ibex_pkg_ADDR_W + ibex_pkg_IC_DATA_ECC_SIZE)));
					end
				end
			end
			else begin : gen_no_ecc_tweak_ic1
				always @(*) begin
					if (_sv2v_0)
						;
					data_tweak_lw_ic1 = 1'sb0;
					begin : sv2v_autoblock_4
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							data_tweak_lw_ic1 = data_tweak_lw_ic1 | (sv2v_cast_033B0({data_tweak_ic1, {ibex_pkg_IC_LINE_W {1'b0}}}) << (i * ibex_pkg_ADDR_W));
					end
				end
			end
			if (ICacheECC) begin : gen_ecc_tag_tweak
				always @(*) begin
					if (_sv2v_0)
						;
					tag_tweak_lw_ic0 = 1'sb0;
					begin : sv2v_autoblock_5
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							tag_tweak_lw_ic0 = tag_tweak_lw_ic0 | (sv2v_cast_0CBAD({tag_index_ic0}) << (i * (ibex_pkg_IC_INDEX_W + ibex_pkg_IC_TAG_ECC_SIZE)));
					end
				end
			end
			else begin : gen_no_ecc_tag_tweak
				always @(*) begin
					if (_sv2v_0)
						;
					tag_tweak_lw_ic0 = 1'sb0;
					begin : sv2v_autoblock_6
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							tag_tweak_lw_ic0 = tag_tweak_lw_ic0 | (sv2v_cast_0CBAD({tag_index_ic0}) << (i * ibex_pkg_IC_INDEX_W));
					end
				end
			end
			reg [ibex_pkg_IC_INDEX_W - 1:0] tag_index_ic1;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					tag_index_ic1 <= 1'sb0;
				else if (tag_req_ic0)
					tag_index_ic1 <= tag_index_ic0;
			if (ICacheECC) begin : gen_ecc_tag_tweak_ic1
				always @(*) begin
					if (_sv2v_0)
						;
					tag_tweak_lw_ic1 = 1'sb0;
					begin : sv2v_autoblock_7
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							tag_tweak_lw_ic1 = tag_tweak_lw_ic1 | (sv2v_cast_0CBAD({tag_index_ic1}) << (i * (ibex_pkg_IC_INDEX_W + ibex_pkg_IC_TAG_ECC_SIZE)));
					end
				end
			end
			else begin : gen_no_ecc_tag_tweak_ic1
				always @(*) begin
					if (_sv2v_0)
						;
					tag_tweak_lw_ic1 = 1'sb0;
					begin : sv2v_autoblock_8
						reg signed [31:0] i;
						for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
							tag_tweak_lw_ic1 = tag_tweak_lw_ic1 | (sv2v_cast_0CBAD({tag_index_ic1}) << (i * ibex_pkg_IC_INDEX_W));
					end
				end
			end
		end
		else begin : gen_no_tweak_infection
			wire [LineSizeECC:1] sv2v_tmp_96204;
			assign sv2v_tmp_96204 = 1'sb0;
			always @(*) data_tweak_lw_ic0 = sv2v_tmp_96204;
			wire [LineSizeECC:1] sv2v_tmp_B4405;
			assign sv2v_tmp_B4405 = 1'sb0;
			always @(*) data_tweak_lw_ic1 = sv2v_tmp_B4405;
			wire [TagSizeECC:1] sv2v_tmp_6DFE7;
			assign sv2v_tmp_6DFE7 = 1'sb0;
			always @(*) tag_tweak_lw_ic0 = sv2v_tmp_6DFE7;
			wire [TagSizeECC:1] sv2v_tmp_39166;
			assign sv2v_tmp_39166 = 1'sb0;
			always @(*) tag_tweak_lw_ic1 = sv2v_tmp_39166;
		end
	endgenerate
	assign ic_tag_req_o = {ibex_pkg_IC_NUM_WAYS {tag_req_ic0}} & tag_banks_ic0;
	assign ic_tag_write_o = tag_write_ic0;
	assign ic_tag_addr_o = tag_index_ic0;
	assign ic_tag_wdata_o = tag_wdata_ic0 ^ tag_tweak_lw_ic0;
	genvar _gv_way_1;
	generate
		for (_gv_way_1 = 0; _gv_way_1 < ibex_pkg_IC_NUM_WAYS; _gv_way_1 = _gv_way_1 + 1) begin : gen_tag_untweak
			localparam way = _gv_way_1;
			assign tag_rdata_ic1[way] = ic_tag_rdata_i[(1 - way) * TagSizeECC+:TagSizeECC] ^ tag_tweak_lw_ic1;
		end
	endgenerate
	assign ic_data_req_o = {ibex_pkg_IC_NUM_WAYS {data_req_ic0}} & data_banks_ic0;
	assign ic_data_write_o = data_write_ic0;
	assign ic_data_addr_o = data_index_ic0;
	assign ic_data_wdata_o = data_wdata_ic0 ^ data_tweak_lw_ic0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			lookup_valid_ic1 <= 1'b0;
		else
			lookup_valid_ic1 <= lookup_actual_ic0;
	generate
		if (ResetAll) begin : g_lookup_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					lookup_addr_ic1 <= 1'sb0;
					fill_in_ic1 <= 1'sb0;
				end
				else if (lookup_grant_ic0) begin
					lookup_addr_ic1 <= lookup_addr_ic0[31:ibex_pkg_IC_INDEX_HI + 1];
					fill_in_ic1 <= fill_alloc_sel;
				end
		end
		else begin : g_lookup_addr_nr
			always @(posedge clk_i)
				if (lookup_grant_ic0) begin
					lookup_addr_ic1 <= lookup_addr_ic0[31:ibex_pkg_IC_INDEX_HI + 1];
					fill_in_ic1 <= fill_alloc_sel;
				end
		end
	endgenerate
	genvar _gv_way_2;
	generate
		for (_gv_way_2 = 0; _gv_way_2 < ibex_pkg_IC_NUM_WAYS; _gv_way_2 = _gv_way_2 + 1) begin : gen_tag_match
			localparam way = _gv_way_2;
			assign tag_match_ic1[way] = tag_rdata_ic1[way][ibex_pkg_IC_TAG_SIZE - 1:0] == {1'b1, lookup_addr_ic1[31:ibex_pkg_IC_INDEX_HI + 1]};
			assign tag_invalid_ic1[way] = ~tag_rdata_ic1[way][ibex_pkg_IC_TAG_SIZE - 1];
		end
	endgenerate
	assign tag_hit_ic1 = |tag_match_ic1;
	always @(*) begin
		if (_sv2v_0)
			;
		hit_data_ecc_ic1 = 'b0;
		begin : sv2v_autoblock_9
			reg signed [31:0] way;
			for (way = 0; way < ibex_pkg_IC_NUM_WAYS; way = way + 1)
				if (tag_match_ic1[way])
					hit_data_ecc_ic1 = hit_data_ecc_ic1 | (ic_data_rdata_i[(1 - way) * LineSizeECC+:LineSizeECC] ^ data_tweak_lw_ic1);
		end
	end
	assign lowest_invalid_way_ic1[0] = tag_invalid_ic1[0];
	assign round_robin_way_ic1[0] = round_robin_way_q[1];
	genvar _gv_way_3;
	generate
		for (_gv_way_3 = 1; _gv_way_3 < ibex_pkg_IC_NUM_WAYS; _gv_way_3 = _gv_way_3 + 1) begin : gen_lowest_way
			localparam way = _gv_way_3;
			assign lowest_invalid_way_ic1[way] = tag_invalid_ic1[way] & ~|tag_invalid_ic1[way - 1:0];
			assign round_robin_way_ic1[way] = round_robin_way_q[way - 1];
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			round_robin_way_q <= 2'b01;
		else if (lookup_valid_ic1)
			round_robin_way_q <= round_robin_way_ic1;
	assign sel_way_ic1 = (|tag_invalid_ic1 ? lowest_invalid_way_ic1 : round_robin_way_q);
	generate
		if (ICacheECC) begin : gen_data_ecc_checking
			wire [1:0] tag_err_ic1;
			wire [(ibex_pkg_IC_LINE_BEATS * 2) - 1:0] data_err_ic1;
			wire ecc_correction_write_d;
			reg ecc_correction_write_q;
			wire [1:0] ecc_correction_ways_d;
			reg [1:0] ecc_correction_ways_q;
			reg [ibex_pkg_IC_INDEX_W - 1:0] lookup_index_ic1;
			reg [ibex_pkg_IC_INDEX_W - 1:0] ecc_correction_index_q;
			genvar _gv_way_4;
			for (_gv_way_4 = 0; _gv_way_4 < ibex_pkg_IC_NUM_WAYS; _gv_way_4 = _gv_way_4 + 1) begin : gen_tag_ecc
				localparam way = _gv_way_4;
				wire [1:0] tag_err_bank_ic1;
				wire [27:0] tag_rdata_padded_ic1;
				assign tag_rdata_padded_ic1 = {tag_rdata_ic1[way][TagSizeECC - 1-:6], {22 - ibex_pkg_IC_TAG_SIZE {1'b0}}, tag_rdata_ic1[way][ibex_pkg_IC_TAG_SIZE - 1:0]};
				prim_secded_inv_28_22_dec data_ecc_dec(
					.data_i(tag_rdata_padded_ic1),
					.data_o(),
					.syndrome_o(),
					.err_o(tag_err_bank_ic1)
				);
				assign tag_err_ic1[way] = |tag_err_bank_ic1;
			end
			genvar _gv_bank_2;
			for (_gv_bank_2 = 0; _gv_bank_2 < ibex_pkg_IC_LINE_BEATS; _gv_bank_2 = _gv_bank_2 + 1) begin : gen_ecc_banks
				localparam bank = _gv_bank_2;
				prim_secded_inv_39_32_dec data_ecc_dec(
					.data_i(hit_data_ecc_ic1[bank * BusSizeECC+:BusSizeECC]),
					.data_o(),
					.syndrome_o(),
					.err_o(data_err_ic1[bank * 2+:2])
				);
				assign hit_data_ic1[bank * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] = hit_data_ecc_ic1[bank * BusSizeECC+:ibex_pkg_BUS_SIZE];
			end
			assign ecc_err_ic1 = lookup_valid_ic1 & ((|data_err_ic1 & tag_hit_ic1) | (|tag_err_ic1));
			assign ecc_correction_ways_d = {ibex_pkg_IC_NUM_WAYS {|tag_err_ic1}} | (tag_match_ic1 & {ibex_pkg_IC_NUM_WAYS {|data_err_ic1}});
			assign ecc_correction_write_d = ecc_err_ic1;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					ecc_correction_write_q <= 1'b0;
				else
					ecc_correction_write_q <= ecc_correction_write_d;
			if (ResetAll) begin : g_lookup_ind_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						lookup_index_ic1 <= 1'sb0;
					else if (lookup_grant_ic0)
						lookup_index_ic1 <= lookup_addr_ic0[ibex_pkg_IC_INDEX_HI-:ibex_pkg_IC_INDEX_W];
			end
			else begin : g_lookup_ind_nr
				always @(posedge clk_i)
					if (lookup_grant_ic0)
						lookup_index_ic1 <= lookup_addr_ic0[ibex_pkg_IC_INDEX_HI-:ibex_pkg_IC_INDEX_W];
			end
			if (ResetAll) begin : g_ecc_correction_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						ecc_correction_ways_q <= 1'sb0;
						ecc_correction_index_q <= 1'sb0;
					end
					else if (ecc_err_ic1) begin
						ecc_correction_ways_q <= ecc_correction_ways_d;
						ecc_correction_index_q <= lookup_index_ic1;
					end
			end
			else begin : g_ecc_correction_nr
				always @(posedge clk_i)
					if (ecc_err_ic1) begin
						ecc_correction_ways_q <= ecc_correction_ways_d;
						ecc_correction_index_q <= lookup_index_ic1;
					end
			end
			assign ecc_write_req = ecc_correction_write_q;
			assign ecc_write_ways = ecc_correction_ways_q;
			assign ecc_write_index = ecc_correction_index_q;
			assign ecc_error_o = ecc_err_ic1;
		end
		else begin : gen_no_data_ecc
			assign ecc_err_ic1 = 1'b0;
			assign ecc_write_req = 1'b0;
			assign ecc_write_ways = 1'sb0;
			assign ecc_write_index = 1'sb0;
			assign hit_data_ic1 = hit_data_ecc_ic1;
			assign ecc_error_o = 1'b0;
		end
		if (BranchCache) begin : gen_caching_logic
			localparam [31:0] CACHE_AHEAD = 2;
			localparam [31:0] CACHE_CNT_W = 2;
			wire cache_cnt_dec;
			wire [1:0] cache_cnt_d;
			reg [1:0] cache_cnt_q;
			assign cache_cnt_dec = lookup_grant_ic0 & |cache_cnt_q;
			assign cache_cnt_d = (branch_i ? CACHE_AHEAD[1:0] : cache_cnt_q - {1'b0, cache_cnt_dec});
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					cache_cnt_q <= 1'sb0;
				else
					cache_cnt_q <= cache_cnt_d;
			assign fill_cache_new = ((branch_i | (|cache_cnt_q)) & icache_enable_i) & ~inval_block_cache;
		end
		else begin : gen_cache_all
			assign fill_cache_new = icache_enable_i & ~inval_block_cache;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		fb_fill_level = 1'sb0;
		begin : sv2v_autoblock_10
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_busy_q[i] & ~fill_stale_q[i])
					fb_fill_level = fb_fill_level + 2'b01;
		end
	end
	assign fill_new_alloc = lookup_grant_ic0;
	assign fill_spec_req = (~icache_enable_i | branch_i) & ~|fill_ext_req;
	assign fill_spec_done = fill_spec_req & instr_gnt_i;
	assign fill_spec_hold = fill_spec_req & ~instr_gnt_i;
	genvar _gv_fb_1;
	generate
		for (_gv_fb_1 = 0; _gv_fb_1 < NUM_FB; _gv_fb_1 = _gv_fb_1 + 1) begin : gen_fbs
			localparam fb = _gv_fb_1;
			if (fb == 0) begin : gen_fb_zero
				assign fill_alloc_sel[fb] = ~fill_busy_q[fb];
			end
			else begin : gen_fb_rest
				assign fill_alloc_sel[fb] = ~fill_busy_q[fb] & (&fill_busy_q[fb - 1:0]);
			end
			assign fill_alloc[fb] = fill_alloc_sel[fb] & fill_new_alloc;
			assign fill_busy_d[fb] = fill_alloc[fb] | (fill_busy_q[fb] & ~fill_done[fb]);
			assign fill_older_d[fb * NUM_FB+:NUM_FB] = (fill_alloc[fb] ? fill_busy_q : fill_older_q[fb * NUM_FB+:NUM_FB]) & ~fill_done;
			assign fill_done[fb] = ((((fill_ram_done_q[fb] | fill_hit_q[fb]) | ~fill_cache_q[fb]) | (|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS])) & ((fill_out_done[fb] | fill_stale_q[fb]) | branch_i)) & fill_rvd_done[fb];
			assign fill_stale_d[fb] = fill_busy_q[fb] & (branch_i | fill_stale_q[fb]);
			assign fill_cache_d[fb] = (fill_alloc[fb] & fill_cache_new) | (((fill_cache_q[fb] & fill_busy_q[fb]) & icache_enable_i) & ~icache_inval_i);
			assign fill_hit_ic1[fb] = ((lookup_valid_ic1 & fill_in_ic1[fb]) & tag_hit_ic1) & ~ecc_err_ic1;
			assign fill_hit_d[fb] = fill_hit_ic1[fb] | (fill_hit_q[fb] & fill_busy_q[fb]);
			assign fill_ext_req[fb] = fill_busy_q[fb] & ~fill_ext_done_d[fb];
			assign fill_ext_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_spec_done} : fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_ext_arb[fb] & instr_gnt_i});
			assign fill_ext_hold_d[fb] = (fill_alloc[fb] & fill_spec_hold) | (fill_ext_arb[fb] & ~instr_gnt_i);
			assign fill_ext_done_d[fb] = ((((fill_ext_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)] | fill_hit_ic1[fb]) | fill_hit_q[fb]) | (~fill_cache_q[fb] & ((branch_i | fill_stale_q[fb]) | fill_ext_beat[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)]))) & ~fill_ext_hold_q[fb]) & fill_busy_q[fb];
			assign fill_rvd_exp[fb] = fill_busy_q[fb] & ~fill_rvd_done[fb];
			assign fill_rvd_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W) * 1 {1'sb0}} : fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_rvd_arb[fb]});
			assign fill_rvd_done[fb] = (fill_ext_done_q[fb] & ~fill_ext_hold_q[fb]) & (fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] == fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)]);
			assign fill_out_req[fb] = ((fill_busy_q[fb] & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & (((fill_hit_ic1[fb] | fill_hit_q[fb]) | (fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] > fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)])) | fill_rvd_arb[fb]);
			assign fill_out_grant[fb] = fill_out_arb[fb] & output_ready;
			assign fill_out_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {1'b0, lookup_addr_ic0[2:ibex_pkg_BUS_W]} : fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_out_grant[fb]});
			assign fill_out_done[fb] = fill_out_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_ram_req[fb] = ((((fill_busy_q[fb] & fill_rvd_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)]) & ~fill_hit_q[fb]) & fill_cache_q[fb]) & ~|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS]) & ~fill_ram_done_q[fb];
			assign fill_ram_done_d[fb] = fill_ram_arb[fb] | (fill_ram_done_q[fb] & fill_busy_q[fb]);
			assign fill_ext_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = {1'b0, fill_addr_q[fb][2:ibex_pkg_BUS_W]} + fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1))) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)-:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_ext_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] = fill_ext_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1))) + ibex_pkg_IC_LINE_BEATS_W) - 1)-:ibex_pkg_IC_LINE_BEATS_W];
			assign fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = {1'b0, fill_addr_q[fb][2:ibex_pkg_BUS_W]} + fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1))) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)-:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] = fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1))) + ibex_pkg_IC_LINE_BEATS_W) - 1)-:ibex_pkg_IC_LINE_BEATS_W];
			assign fill_ext_arb[fb] = fill_ext_req[fb] & ~|(fill_ext_req & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_ram_arb[fb] = (fill_ram_req[fb] & fill_grant_ic0) & ~|(fill_ram_req & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_data_sel[fb] = ~|(((fill_busy_q & ~fill_out_done) & ~fill_stale_q) & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_out_arb[fb] = fill_out_req[fb] & fill_data_sel[fb];
			assign fill_rvd_arb[fb] = (instr_rvalid_i & fill_rvd_exp[fb]) & ~|(fill_rvd_exp & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_data_reg[fb] = (((fill_busy_q[fb] & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & fill_data_sel[fb]) & (((fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] > fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)]) | fill_hit_q[fb]) | (|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS]));
			assign fill_data_hit[fb] = (fill_busy_q[fb] & fill_hit_ic1[fb]) & fill_data_sel[fb];
			assign fill_data_rvd[fb] = ((((((fill_busy_q[fb] & fill_rvd_arb[fb]) & ~fill_hit_q[fb]) & ~fill_hit_ic1[fb]) & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & (fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] == fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)])) & fill_data_sel[fb];
			assign fill_entry_en[fb] = fill_alloc[fb] | fill_busy_q[fb];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					fill_busy_q[fb] <= 1'b0;
					fill_older_q[fb * NUM_FB+:NUM_FB] <= 1'sb0;
					fill_stale_q[fb] <= 1'b0;
					fill_cache_q[fb] <= 1'b0;
					fill_hit_q[fb] <= 1'b0;
					fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
					fill_ext_hold_q[fb] <= 1'b0;
					fill_ext_done_q[fb] <= 1'b0;
					fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
					fill_ram_done_q[fb] <= 1'b0;
					fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
				end
				else if (fill_entry_en[fb]) begin
					fill_busy_q[fb] <= fill_busy_d[fb];
					fill_older_q[fb * NUM_FB+:NUM_FB] <= fill_older_d[fb * NUM_FB+:NUM_FB];
					fill_stale_q[fb] <= fill_stale_d[fb];
					fill_cache_q[fb] <= fill_cache_d[fb];
					fill_hit_q[fb] <= fill_hit_d[fb];
					fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_ext_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
					fill_ext_hold_q[fb] <= fill_ext_hold_d[fb];
					fill_ext_done_q[fb] <= fill_ext_done_d[fb];
					fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_rvd_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
					fill_ram_done_q[fb] <= fill_ram_done_d[fb];
					fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_out_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
				end
			assign fill_addr_en[fb] = fill_alloc[fb];
			assign fill_way_en[fb] = lookup_valid_ic1 & fill_in_ic1[fb];
			if (ResetAll) begin : g_fill_addr_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						fill_addr_q[fb] <= 1'sb0;
					else if (fill_addr_en[fb])
						fill_addr_q[fb] <= lookup_addr_ic0;
			end
			else begin : g_fill_addr_nr
				always @(posedge clk_i)
					if (fill_addr_en[fb])
						fill_addr_q[fb] <= lookup_addr_ic0;
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					fill_way_q[fb] <= 1'sb0;
				else if (fill_way_en[fb])
					fill_way_q[fb] <= sel_way_ic1;
			assign fill_data_d[fb] = (fill_hit_ic1[fb] ? hit_data_ic1 : {ibex_pkg_IC_LINE_BEATS {instr_rdata_i}});
			genvar _gv_b_1;
			for (_gv_b_1 = 0; _gv_b_1 < ibex_pkg_IC_LINE_BEATS; _gv_b_1 = _gv_b_1 + 1) begin : gen_data_buf
				localparam b = _gv_b_1;
				assign fill_err_d[(fb * ibex_pkg_IC_LINE_BEATS) + b] = ((fill_rvd_arb[fb] & instr_err_i) & (fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] == b[ibex_pkg_IC_LINE_BEATS_W - 1:0])) | (fill_busy_q[fb] & fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b]);
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b] <= 1'sb0;
					else if (fill_entry_en[fb])
						fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b] <= fill_err_d[(fb * ibex_pkg_IC_LINE_BEATS) + b];
				assign fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b] = fill_hit_ic1[fb] | ((fill_rvd_arb[fb] & ~fill_hit_q[fb]) & (fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] == b[ibex_pkg_IC_LINE_BEATS_W - 1:0]));
				if (ResetAll) begin : g_fill_data_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= 1'sb0;
						else if (fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b])
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= fill_data_d[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE];
				end
				else begin : g_fill_data_nr
					always @(posedge clk_i)
						if (fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b])
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= fill_data_d[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE];
				end
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		fill_ext_req_addr = 1'sb0;
		begin : sv2v_autoblock_11
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_ext_arb[i])
					fill_ext_req_addr = fill_ext_req_addr | {fill_addr_q[i][31:ibex_pkg_IC_LINE_W], fill_ext_off[i * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W]};
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		fill_ram_req_addr = 1'sb0;
		fill_ram_req_way = 1'sb0;
		fill_ram_req_data = 1'sb0;
		begin : sv2v_autoblock_12
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_ram_arb[i]) begin
					fill_ram_req_addr = fill_ram_req_addr | fill_addr_q[i];
					fill_ram_req_way = fill_ram_req_way | fill_way_q[i];
					fill_ram_req_data = fill_ram_req_data | fill_data_q[i];
				end
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		fill_out_data = 1'sb0;
		fill_out_err = 1'sb0;
		begin : sv2v_autoblock_13
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_data_reg[i]) begin
					fill_out_data = fill_out_data | fill_data_q[i];
					fill_out_err = fill_out_err | (fill_err_q[i * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS] & ~{ibex_pkg_IC_LINE_BEATS {fill_hit_q[i]}});
				end
		end
	end
	assign instr_req = ((~icache_enable_i | branch_i) & lookup_grant_ic0) | (|fill_ext_req);
	assign instr_addr = (|fill_ext_req ? fill_ext_req_addr : lookup_addr_ic0[31:ibex_pkg_BUS_W]);
	assign instr_req_o = instr_req;
	assign instr_addr_o = {instr_addr[31:ibex_pkg_BUS_W], {ibex_pkg_BUS_W {1'b0}}};
	assign line_data = (|fill_data_hit ? hit_data_ic1 : fill_out_data);
	assign line_err = (|fill_data_hit ? {ibex_pkg_IC_LINE_BEATS {1'b0}} : fill_out_err);
	always @(*) begin
		if (_sv2v_0)
			;
		line_data_muxed = 1'sb0;
		line_err_muxed = 1'b0;
		begin : sv2v_autoblock_14
			reg [31:0] i;
			for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
				if ((output_addr_q[2:ibex_pkg_BUS_W] + {{ibex_pkg_IC_LINE_BEATS_W - 1 {1'b0}}, skid_valid_q}) == i[ibex_pkg_IC_LINE_BEATS_W - 1:0]) begin
					line_data_muxed = line_data_muxed | line_data[i * 32+:32];
					line_err_muxed = line_err_muxed | line_err[i];
				end
		end
	end
	assign output_data = (|fill_data_rvd ? instr_rdata_i : line_data_muxed);
	assign output_err = (|fill_data_rvd ? instr_err_i : line_err_muxed);
	assign data_valid = |fill_out_arb;
	assign skid_data_d = output_data[31:16];
	assign skid_en = data_valid & (ready_i | skid_ready);
	generate
		if (ResetAll) begin : g_skid_data_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					skid_data_q <= 1'sb0;
					skid_err_q <= 1'sb0;
				end
				else if (skid_en) begin
					skid_data_q <= skid_data_d;
					skid_err_q <= output_err;
				end
		end
		else begin : g_skid_data_nr
			always @(posedge clk_i)
				if (skid_en) begin
					skid_data_q <= skid_data_d;
					skid_err_q <= output_err;
				end
		end
	endgenerate
	assign skid_complete_instr = skid_valid_q & ((skid_data_q[1:0] != 2'b11) | skid_err_q);
	assign skid_ready = (output_addr_q[1] & ~skid_valid_q) & (~output_compressed | output_err);
	assign output_ready = (ready_i | skid_ready) & ~skid_complete_instr;
	assign output_compressed = rdata_o[1:0] != 2'b11;
	assign skid_valid_d = (branch_i ? 1'b0 : (skid_valid_q ? ~(ready_i & ((skid_data_q[1:0] != 2'b11) | skid_err_q)) : data_valid & ((output_addr_q[1] & (~output_compressed | output_err)) | (((~output_addr_q[1] & output_compressed) & ~output_err) & ready_i))));
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			skid_valid_q <= 1'b0;
		else
			skid_valid_q <= skid_valid_d;
	assign output_valid = skid_complete_instr | (data_valid & (((~output_addr_q[1] | skid_valid_q) | output_err) | (output_data[17:16] != 2'b11)));
	assign output_addr_en = branch_i | (ready_i & valid_o);
	assign addr_incr_two = output_compressed & ~err_o;
	assign output_addr_incr = output_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};
	assign output_addr_d = (branch_i ? addr_i[31:1] : output_addr_incr);
	generate
		if (ResetAll) begin : g_output_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					output_addr_q <= 1'sb0;
				else if (output_addr_en)
					output_addr_q <= output_addr_d;
		end
		else begin : g_output_addr_nr
			always @(posedge clk_i)
				if (output_addr_en)
					output_addr_q <= output_addr_d;
		end
	endgenerate
	localparam [31:0] ibex_pkg_IC_OUTPUT_BEATS = 2;
	always @(*) begin
		if (_sv2v_0)
			;
		output_data_lo = 1'sb0;
		begin : sv2v_autoblock_15
			reg [31:0] i;
			for (i = 0; i < ibex_pkg_IC_OUTPUT_BEATS; i = i + 1)
				if (output_addr_q[1:1] == i[0:0])
					output_data_lo = output_data_lo | output_data[i * 16+:16];
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		output_data_hi = 1'sb0;
		begin : sv2v_autoblock_16
			reg [31:0] i;
			for (i = 0; i < 1; i = i + 1)
				if (output_addr_q[1:1] == i[0:0])
					output_data_hi = output_data_hi | output_data[(i + 1) * 16+:16];
		end
		if (&output_addr_q[1:1])
			output_data_hi = output_data_hi | output_data[15:0];
	end
	assign valid_o = output_valid;
	assign rdata_o = {output_data_hi, (skid_valid_q ? skid_data_q : output_data_lo)};
	assign addr_o = {output_addr_q, 1'b0};
	assign err_o = (skid_valid_q & skid_err_q) | (~skid_complete_instr & output_err);
	assign err_plus2_o = skid_valid_q & ~skid_err_q;
	always @(*) begin
		if (_sv2v_0)
			;
		inval_state_d = inval_state_q;
		inval_index_d = inval_index_q;
		inval_index_en = 1'b0;
		inval_write_req = 1'b0;
		ic_scr_key_req_o = 1'b0;
		inval_block_cache = 1'b1;
		(* full_case, parallel_case *)
		case (inval_state_q)
			2'd0: begin
				inval_state_d = 2'd1;
				if (~ic_scr_key_valid_i)
					ic_scr_key_req_o = 1'b1;
			end
			2'd1:
				if (ic_scr_key_valid_i) begin
					inval_state_d = 2'd2;
					inval_index_d = 1'sb0;
					inval_index_en = 1'b1;
				end
			2'd2: begin
				inval_write_req = 1'b1;
				inval_index_d = inval_index_q + {{ibex_pkg_IC_INDEX_W - 1 {1'b0}}, 1'b1};
				inval_index_en = 1'b1;
				if (icache_inval_i) begin
					ic_scr_key_req_o = 1'b1;
					inval_state_d = 2'd1;
				end
				else if (&inval_index_q)
					inval_state_d = 2'd3;
			end
			2'd3:
				if (icache_inval_i) begin
					ic_scr_key_req_o = 1'b1;
					inval_state_d = 2'd1;
				end
				else
					inval_block_cache = 1'b0;
			default:
				;
		endcase
	end
	assign inval_active = inval_state_q != 2'd3;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inval_state_q <= 2'd0;
		else
			inval_state_q <= inval_state_d;
	generate
		if (ResetAll) begin : g_inval_index_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inval_index_q <= 1'sb0;
				else if (inval_index_en)
					inval_index_q <= inval_index_d;
		end
		else begin : g_inval_index_nr
			always @(posedge clk_i)
				if (inval_index_en)
					inval_index_q <= inval_index_d;
		end
	endgenerate
	assign busy_o = inval_active | (|(fill_busy_q & ~fill_rvd_done));
	initial _sv2v_0 = 0;
endmodule
module ibex_id_stage (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	ctrl_busy_o,
	illegal_insn_o,
	instr_valid_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	instr_rdata_c_i,
	instr_is_compressed_i,
	instr_gets_expanded_i,
	instr_bp_taken_i,
	instr_req_o,
	instr_first_cycle_id_o,
	instr_valid_clear_o,
	id_in_ready_o,
	instr_exec_i,
	icache_inval_o,
	branch_decision_i,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	nt_branch_addr_o,
	exc_pc_mux_o,
	exc_cause_o,
	illegal_c_insn_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	instr_fetch_cheriot_acc_vio_i,
	instr_fetch_cheriot_bound_vio_i,
	pc_id_i,
	ex_valid_i,
	lsu_resp_valid_i,
	alu_operator_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	imd_val_we_ex_i,
	imd_val_d_ex_i,
	imd_val_q_ex_o,
	bt_a_operand_o,
	bt_b_operand_o,
	mult_en_ex_o,
	div_en_ex_o,
	mult_sel_ex_o,
	div_sel_ex_o,
	multdiv_operator_ex_o,
	multdiv_signed_mode_ex_o,
	multdiv_operand_a_ex_o,
	multdiv_operand_b_ex_o,
	multdiv_ready_id_o,
	csr_access_o,
	csr_op_o,
	csr_addr_o,
	csr_op_en_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mepcc_clrtag_o,
	csr_mtval_o,
	priv_mode_i,
	csr_mstatus_tw_i,
	illegal_csr_insn_i,
	data_ind_timing_i,
	csr_pcc_perm_sr_i,
	lsu_req_o,
	lsu_we_o,
	lsu_type_o,
	lsu_sign_ext_o,
	lsu_wdata_o,
	lsu_req_done_i,
	lsu_addr_incr_req_i,
	lsu_addr_last_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_i,
	nmi_mode_o,
	lsu_load_err_i,
	lsu_load_resp_intg_err_i,
	lsu_store_err_i,
	lsu_store_resp_intg_err_i,
	lsu_err_is_cheriot_i,
	expecting_load_resp_o,
	expecting_store_resp_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	result_ex_i,
	csr_rdata_i,
	rf_raddr_a_o,
	rf_rdata_a_i,
	rf_raddr_b_o,
	rf_rdata_b_i,
	rf_ren_a_o,
	rf_ren_b_o,
	rf_waddr_id_o,
	rf_wdata_id_o,
	rf_we_id_o,
	rf_rd_a_wb_match_o,
	rf_rd_b_wb_match_o,
	rf_waddr_wb_i,
	rf_wdata_fwd_wb_i,
	rf_write_wb_i,
	en_wb_o,
	instr_type_wb_o,
	instr_perf_count_id_o,
	ready_wb_i,
	outstanding_load_wb_i,
	outstanding_store_wb_i,
	perf_jump_o,
	perf_branch_o,
	perf_tbranch_o,
	perf_dside_wait_o,
	perf_mul_wait_o,
	perf_div_wait_o,
	instr_id_done_o,
	cheriot_exec_id_o,
	instr_is_cheriot_id_o,
	instr_is_rv32lsu_id_o,
	cheriot_imm12_o,
	cheriot_imm20_o,
	cheriot_imm21_o,
	cheriot_operator_o,
	cheriot_cs2_dec_o,
	cheriot_cap_field_sel_o,
	cheriot_adder_a_sel_o,
	cheriot_adder_b_sel_o,
	cheriot_setaddr_sel_o,
	cheriot_setbounds_sel_o,
	cheriot_load_o,
	cheriot_store_o,
	cheriot_ex_valid_i,
	cheriot_ex_err_i,
	cheriot_ex_err_info_i,
	cheriot_wb_err_i,
	cheriot_wb_err_info_i,
	cheriot_branch_req_i,
	cheriot_branch_target_i
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] BranchTargetALU = 0;
	parameter [0:0] WritebackStage = 0;
	parameter [0:0] BranchPredictor = 0;
	parameter [0:0] MemECC = 1'b0;
	parameter integer BaseIsa = 32'sd1;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output wire ctrl_busy_o;
	output wire illegal_insn_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire [15:0] instr_rdata_c_i;
	input wire instr_is_compressed_i;
	input wire [1:0] instr_gets_expanded_i;
	input wire instr_bp_taken_i;
	output wire instr_req_o;
	output wire instr_first_cycle_id_o;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	input wire instr_exec_i;
	output wire icache_inval_o;
	input wire branch_decision_i;
	output wire pc_set_o;
	output wire [2:0] pc_mux_o;
	output wire nt_branch_mispredict_o;
	output wire [31:0] nt_branch_addr_o;
	output wire [1:0] exc_pc_mux_o;
	output wire [6:0] exc_cause_o;
	input wire illegal_c_insn_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire instr_fetch_cheriot_acc_vio_i;
	input wire instr_fetch_cheriot_bound_vio_i;
	input wire [31:0] pc_id_i;
	input wire ex_valid_i;
	input wire lsu_resp_valid_i;
	output wire [6:0] alu_operator_ex_o;
	output wire [31:0] alu_operand_a_ex_o;
	output wire [31:0] alu_operand_b_ex_o;
	input wire [1:0] imd_val_we_ex_i;
	input wire [67:0] imd_val_d_ex_i;
	output wire [67:0] imd_val_q_ex_o;
	output reg [31:0] bt_a_operand_o;
	output reg [31:0] bt_b_operand_o;
	output wire mult_en_ex_o;
	output wire div_en_ex_o;
	output wire mult_sel_ex_o;
	output wire div_sel_ex_o;
	output wire [1:0] multdiv_operator_ex_o;
	output wire [1:0] multdiv_signed_mode_ex_o;
	output wire [31:0] multdiv_operand_a_ex_o;
	output wire [31:0] multdiv_operand_b_ex_o;
	output wire multdiv_ready_id_o;
	output wire csr_access_o;
	output wire [1:0] csr_op_o;
	output wire [11:0] csr_addr_o;
	output wire csr_op_en_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_save_wb_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire csr_mepcc_clrtag_o;
	output wire [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire csr_mstatus_tw_i;
	input wire illegal_csr_insn_i;
	input wire data_ind_timing_i;
	input wire csr_pcc_perm_sr_i;
	output wire lsu_req_o;
	output wire lsu_we_o;
	output wire [1:0] lsu_type_o;
	output wire lsu_sign_ext_o;
	output wire [31:0] lsu_wdata_o;
	input wire lsu_req_done_i;
	input wire lsu_addr_incr_req_i;
	input wire [31:0] lsu_addr_last_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_i;
	output wire nmi_mode_o;
	input wire lsu_load_err_i;
	input wire lsu_load_resp_intg_err_i;
	input wire lsu_store_err_i;
	input wire lsu_store_resp_intg_err_i;
	input wire lsu_err_is_cheriot_i;
	output wire expecting_load_resp_o;
	output wire expecting_store_resp_o;
	output wire debug_mode_o;
	output wire debug_mode_entering_o;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	input wire [31:0] result_ex_i;
	input wire [31:0] csr_rdata_i;
	output wire [4:0] rf_raddr_a_o;
	input wire [31:0] rf_rdata_a_i;
	output wire [4:0] rf_raddr_b_o;
	input wire [31:0] rf_rdata_b_i;
	output wire rf_ren_a_o;
	output wire rf_ren_b_o;
	output wire [4:0] rf_waddr_id_o;
	output reg [31:0] rf_wdata_id_o;
	output wire rf_we_id_o;
	output wire rf_rd_a_wb_match_o;
	output wire rf_rd_b_wb_match_o;
	input wire [4:0] rf_waddr_wb_i;
	input wire [31:0] rf_wdata_fwd_wb_i;
	input wire rf_write_wb_i;
	output wire en_wb_o;
	output wire [1:0] instr_type_wb_o;
	output wire instr_perf_count_id_o;
	input wire ready_wb_i;
	input wire outstanding_load_wb_i;
	input wire outstanding_store_wb_i;
	output wire perf_jump_o;
	output reg perf_branch_o;
	output wire perf_tbranch_o;
	output wire perf_dside_wait_o;
	output wire perf_mul_wait_o;
	output wire perf_div_wait_o;
	output wire instr_id_done_o;
	output wire cheriot_exec_id_o;
	output wire instr_is_cheriot_id_o;
	output wire instr_is_rv32lsu_id_o;
	output wire [11:0] cheriot_imm12_o;
	output wire [19:0] cheriot_imm20_o;
	output wire [20:0] cheriot_imm21_o;
	output wire [25:0] cheriot_operator_o;
	output wire [4:0] cheriot_cs2_dec_o;
	output wire [2:0] cheriot_cap_field_sel_o;
	output wire [2:0] cheriot_adder_a_sel_o;
	output wire [1:0] cheriot_adder_b_sel_o;
	output wire [2:0] cheriot_setaddr_sel_o;
	output wire [2:0] cheriot_setbounds_sel_o;
	output wire cheriot_load_o;
	output wire cheriot_store_o;
	input wire cheriot_ex_valid_i;
	input wire cheriot_ex_err_i;
	input wire [11:0] cheriot_ex_err_info_i;
	input wire cheriot_wb_err_i;
	input wire [15:0] cheriot_wb_err_info_i;
	input wire cheriot_branch_req_i;
	input wire [31:0] cheriot_branch_target_i;
	wire illegal_insn_dec;
	wire illegal_dret_insn;
	wire illegal_umode_insn;
	wire ebrk_insn;
	wire mret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire wfi_insn_dec;
	wire wb_exception;
	wire unused_id_exception;
	wire id_exception_nc;
	wire branch_in_dec;
	wire branch_set;
	wire branch_set_raw;
	reg branch_set_raw_d;
	reg branch_jump_set_done_q;
	wire branch_jump_set_done_d;
	reg branch_not_set;
	wire branch_taken;
	wire jump_in_dec;
	wire jump_set_dec;
	wire jump_set;
	reg jump_set_raw;
	wire instr_first_cycle;
	wire instr_executing_spec;
	wire instr_executing;
	wire instr_done;
	wire controller_run;
	wire stall_ld_hz;
	wire stall_mem;
	reg stall_multdiv;
	reg stall_branch;
	reg stall_jump;
	wire stall_id;
	wire stall_wb;
	wire flush_id;
	wire multicycle_done;
	wire mem_resp_intg_err;
	wire [31:0] imm_i_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_j_type;
	wire [31:0] zimm_rs1_type;
	wire [31:0] imm_a;
	reg [31:0] imm_b;
	wire rf_wdata_sel;
	wire rf_we_dec;
	reg rf_we_raw;
	wire rf_ren_a;
	wire rf_ren_b;
	wire rf_ren_a_dec;
	wire rf_ren_b_dec;
	wire rf_we_or_load;
	assign rf_ren_a = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_a_dec;
	assign rf_ren_b = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_b_dec;
	assign rf_ren_a_o = rf_ren_a;
	assign rf_ren_b_o = rf_ren_b;
	wire [31:0] rf_rdata_a_fwd;
	wire [31:0] rf_rdata_b_fwd;
	wire cheriot_lsu_req_dec;
	wire ex_valid_all;
	wire [6:0] alu_operator;
	wire [1:0] alu_op_a_mux_sel;
	wire [1:0] alu_op_a_mux_sel_dec;
	wire alu_op_b_mux_sel;
	wire alu_op_b_mux_sel_dec;
	wire alu_multicycle_dec;
	reg stall_alu;
	reg [67:0] imd_val_q;
	wire [1:0] bt_a_mux_sel;
	wire [2:0] bt_b_mux_sel;
	wire imm_a_mux_sel;
	wire [2:0] imm_b_mux_sel;
	wire [2:0] imm_b_mux_sel_dec;
	wire mult_en_id;
	wire mult_en_dec;
	wire div_en_id;
	wire div_en_dec;
	wire multdiv_en_dec;
	wire [1:0] multdiv_operator;
	wire [1:0] multdiv_signed_mode;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_req_dec;
	wire data_req_allowed;
	wire no_flush_csr_addr;
	wire csr_pipe_flush;
	wire csr_cheriot_always_ok;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	wire instr_is_legal_cheriot;
	assign alu_op_a_mux_sel = (lsu_addr_incr_req_i ? 2'd1 : alu_op_a_mux_sel_dec);
	assign alu_op_b_mux_sel = (lsu_addr_incr_req_i ? 1'd1 : alu_op_b_mux_sel_dec);
	assign imm_b_mux_sel = (lsu_addr_incr_req_i ? 3'd6 : imm_b_mux_sel_dec);
	assign imm_a = (imm_a_mux_sel == 1'd0 ? zimm_rs1_type : {32 {1'sb0}});
	always @(*) begin : alu_operand_a_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_op_a_mux_sel)
			2'd0: alu_operand_a = rf_rdata_a_fwd;
			2'd1: alu_operand_a = lsu_addr_last_i;
			2'd2: alu_operand_a = pc_id_i;
			2'd3: alu_operand_a = imm_a;
			default: alu_operand_a = pc_id_i;
		endcase
	end
	generate
		if (BranchTargetALU) begin : g_btalu_muxes
			always @(*) begin : bt_operand_a_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_a_mux_sel)
					2'd0: bt_a_operand_o = rf_rdata_a_fwd;
					2'd2: bt_a_operand_o = pc_id_i;
					default: bt_a_operand_o = pc_id_i;
				endcase
			end
			always @(*) begin : bt_immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_b_mux_sel)
					3'd0: bt_b_operand_o = imm_i_type;
					3'd2: bt_b_operand_o = imm_b_type;
					3'd4: bt_b_operand_o = imm_j_type;
					3'd5: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					default: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
				endcase
			end
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd3: imm_b = imm_u_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
		else begin : g_nobtalu
			wire [1:0] unused_a_mux_sel;
			wire [2:0] unused_b_mux_sel;
			assign unused_a_mux_sel = bt_a_mux_sel;
			assign unused_b_mux_sel = bt_b_mux_sel;
			wire [32:1] sv2v_tmp_1FCCD;
			assign sv2v_tmp_1FCCD = 1'sb0;
			always @(*) bt_a_operand_o = sv2v_tmp_1FCCD;
			wire [32:1] sv2v_tmp_B876E;
			assign sv2v_tmp_B876E = 1'sb0;
			always @(*) bt_b_operand_o = sv2v_tmp_B876E;
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd2: imm_b = imm_b_type;
					3'd3: imm_b = imm_u_type;
					3'd4: imm_b = imm_j_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
	endgenerate
	assign alu_operand_b = (alu_op_b_mux_sel == 1'd1 ? imm_b : rf_rdata_b_fwd);
	genvar _gv_i_30;
	generate
		for (_gv_i_30 = 0; _gv_i_30 < 2; _gv_i_30 = _gv_i_30 + 1) begin : gen_intermediate_val_reg
			localparam i = _gv_i_30;
			always @(posedge clk_i or negedge rst_ni) begin : intermediate_val_reg
				if (!rst_ni)
					imd_val_q[(1 - i) * 34+:34] <= 1'sb0;
				else if (imd_val_we_ex_i[i])
					imd_val_q[(1 - i) * 34+:34] <= imd_val_d_ex_i[(1 - i) * 34+:34];
			end
		end
	endgenerate
	assign imd_val_q_ex_o = imd_val_q;
	assign rf_we_id_o = (rf_we_raw & instr_executing) & ~illegal_csr_insn_i;
	always @(*) begin : rf_wdata_id_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rf_wdata_sel)
			1'd0: rf_wdata_id_o = result_ex_i;
			1'd1: rf_wdata_id_o = csr_rdata_i;
			default: rf_wdata_id_o = result_ex_i;
		endcase
	end
	ibex_decoder #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.BaseIsa(BaseIsa)
	) decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn),
		.mret_insn_o(mret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.ecall_insn_o(ecall_insn_dec),
		.wfi_insn_o(wfi_insn_dec),
		.jump_set_o(jump_set_dec),
		.branch_taken_i(branch_taken),
		.icache_inval_o(icache_inval_o),
		.instr_first_cycle_i(instr_first_cycle),
		.instr_rdata_i(instr_rdata_i),
		.instr_rdata_alu_i(instr_rdata_alu_i),
		.illegal_c_insn_i(illegal_c_insn_i),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel_dec),
		.bt_a_mux_sel_o(bt_a_mux_sel),
		.bt_b_mux_sel_o(bt_b_mux_sel),
		.imm_i_type_o(imm_i_type),
		.imm_s_type_o(imm_s_type),
		.imm_b_type_o(imm_b_type),
		.imm_u_type_o(imm_u_type),
		.imm_j_type_o(imm_j_type),
		.zimm_rs1_type_o(zimm_rs1_type),
		.rf_wdata_sel_o(rf_wdata_sel),
		.rf_we_o(rf_we_dec),
		.rf_we_or_load_o(rf_we_or_load),
		.rf_raddr_a_o(rf_raddr_a_o),
		.rf_raddr_b_o(rf_raddr_b_o),
		.rf_waddr_o(rf_waddr_id_o),
		.rf_ren_a_o(rf_ren_a_dec),
		.rf_ren_b_o(rf_ren_b_dec),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel_dec),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel_dec),
		.alu_multicycle_o(alu_multicycle_dec),
		.mult_en_o(mult_en_dec),
		.div_en_o(div_en_dec),
		.mult_sel_o(mult_sel_ex_o),
		.div_sel_o(div_sel_ex_o),
		.multdiv_operator_o(multdiv_operator),
		.multdiv_signed_mode_o(multdiv_signed_mode),
		.csr_access_o(csr_access_o),
		.csr_op_o(csr_op_o),
		.csr_addr_o(csr_addr_o),
		.csr_cheriot_always_ok_o(csr_cheriot_always_ok),
		.data_req_o(lsu_req_dec),
		.cheriot_data_req_o(cheriot_lsu_req_dec),
		.data_we_o(lsu_we),
		.data_type_o(lsu_type),
		.data_sign_extension_o(lsu_sign_ext),
		.jump_in_dec_o(jump_in_dec),
		.branch_in_dec_o(branch_in_dec),
		.instr_is_cheriot_o(instr_is_cheriot_id_o),
		.instr_is_legal_cheriot_o(instr_is_legal_cheriot),
		.cheriot_imm12_o(cheriot_imm12_o),
		.cheriot_imm20_o(cheriot_imm20_o),
		.cheriot_imm21_o(cheriot_imm21_o),
		.cheriot_operator_o(cheriot_operator_o),
		.cheriot_cs2_dec_o(cheriot_cs2_dec_o),
		.cheriot_cap_field_sel_o(cheriot_cap_field_sel_o),
		.cheriot_adder_a_sel_o(cheriot_adder_a_sel_o),
		.cheriot_adder_b_sel_o(cheriot_adder_b_sel_o),
		.cheriot_setaddr_sel_o(cheriot_setaddr_sel_o),
		.cheriot_setbounds_sel_o(cheriot_setbounds_sel_o)
	);
	assign instr_is_rv32lsu_id_o = lsu_req_dec;
	assign ex_valid_all = (instr_is_cheriot_id_o ? cheriot_ex_valid_i : ex_valid_i);
	assign cheriot_load_o = cheriot_operator_o[15];
	assign cheriot_store_o = cheriot_operator_o[17];
	assign no_flush_csr_addr = |{csr_addr_o == 12'h340, csr_addr_o == 12'h341};
	assign csr_pipe_flush = ((csr_op_en_o == 1) && |{csr_op_o == 2'd1, csr_op_o == 2'd2, csr_op_o == 2'd3}) && !no_flush_csr_addr;
	assign illegal_dret_insn = dret_insn_dec & ~debug_mode_o;
	assign illegal_umode_insn = (priv_mode_i != 2'b11) & (mret_insn_dec | (csr_mstatus_tw_i & wfi_insn_dec));
	assign illegal_insn_o = instr_valid_i & (((illegal_insn_dec | illegal_csr_insn_i) | illegal_dret_insn) | illegal_umode_insn);
	assign mem_resp_intg_err = lsu_load_resp_intg_err_i | lsu_store_resp_intg_err_i;
	ibex_controller #(
		.BaseIsa(BaseIsa),
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC)
	) controller_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.ctrl_busy_o(ctrl_busy_o),
		.illegal_insn_i(illegal_insn_o),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.wfi_insn_i(wfi_insn_dec),
		.ebrk_insn_i(ebrk_insn),
		.csr_pipe_flush_i(csr_pipe_flush),
		.csr_access_i(csr_access_o),
		.csr_cheriot_always_ok_i(csr_cheriot_always_ok),
		.instr_valid_i(instr_valid_i),
		.instr_i(instr_rdata_i),
		.instr_compressed_i(instr_rdata_c_i),
		.instr_is_compressed_i(instr_is_compressed_i),
		.instr_gets_expanded_i(instr_gets_expanded_i),
		.instr_bp_taken_i(instr_bp_taken_i),
		.instr_fetch_err_i(instr_fetch_err_i),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2_i),
		.instr_fetch_cheriot_acc_vio_i(instr_fetch_cheriot_acc_vio_i),
		.instr_fetch_cheriot_bound_vio_i(instr_fetch_cheriot_bound_vio_i),
		.pc_id_i(pc_id_i),
		.instr_valid_clear_o(instr_valid_clear_o),
		.id_in_ready_o(id_in_ready_o),
		.controller_run_o(controller_run),
		.instr_exec_i(instr_exec_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.nt_branch_mispredict_o(nt_branch_mispredict_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.lsu_addr_last_i(lsu_addr_last_i),
		.load_err_i(lsu_load_err_i),
		.lsu_err_is_cheriot_i(lsu_err_is_cheriot_i),
		.mem_resp_intg_err_i(mem_resp_intg_err),
		.store_err_i(lsu_store_err_i),
		.wb_exception_o(wb_exception),
		.id_exception_o(unused_id_exception),
		.id_exception_nc_o(id_exception_nc),
		.branch_set_i(branch_set),
		.branch_not_set_i(branch_not_set),
		.jump_set_i(jump_set),
		.csr_mstatus_mie_i(csr_mstatus_mie_i),
		.irq_pending_i(irq_pending_i),
		.irqs_i(irqs_i),
		.irq_nm_ext_i(irq_nm_i),
		.nmi_mode_o(nmi_mode_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_save_wb_o(csr_save_wb_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_mepcc_clrtag_o(csr_mepcc_clrtag_o),
		.csr_mtval_o(csr_mtval_o),
		.priv_mode_i(priv_mode_i),
		.csr_pcc_perm_sr_i(csr_pcc_perm_sr_i),
		.debug_mode_o(debug_mode_o),
		.debug_mode_entering_o(debug_mode_entering_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.debug_ebreaku_i(debug_ebreaku_i),
		.trigger_match_i(trigger_match_i),
		.stall_id_i(stall_id),
		.stall_wb_i(stall_wb),
		.flush_id_o(flush_id),
		.ready_wb_i(ready_wb_i),
		.perf_jump_o(perf_jump_o),
		.perf_tbranch_o(perf_tbranch_o),
		.instr_is_cheriot_i(instr_is_cheriot_id_o),
		.cheriot_ex_valid_i(cheriot_ex_valid_i),
		.cheriot_ex_err_i(cheriot_ex_err_i),
		.cheriot_ex_err_info_i(cheriot_ex_err_info_i),
		.cheriot_wb_err_i(cheriot_wb_err_i),
		.cheriot_wb_err_info_i(cheriot_wb_err_info_i),
		.cheriot_branch_req_i(cheriot_branch_req_i),
		.cheriot_branch_target_i(cheriot_branch_target_i)
	);
	assign multdiv_en_dec = mult_en_dec | div_en_dec;
	assign lsu_req = (instr_executing ? data_req_allowed & lsu_req_dec : 1'b0);
	assign mult_en_id = (instr_executing ? mult_en_dec : 1'b0);
	assign div_en_id = (instr_executing ? div_en_dec : 1'b0);
	assign lsu_req_o = lsu_req;
	assign lsu_we_o = lsu_we;
	assign lsu_type_o = lsu_type;
	assign lsu_sign_ext_o = lsu_sign_ext;
	assign lsu_wdata_o = rf_rdata_b_fwd;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign csr_op_en_o = (csr_access_o & instr_executing) & ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? instr_first_cycle : instr_id_done_o);
	assign alu_operator_ex_o = alu_operator;
	assign alu_operand_a_ex_o = alu_operand_a;
	assign alu_operand_b_ex_o = alu_operand_b;
	assign mult_en_ex_o = mult_en_id;
	assign div_en_ex_o = div_en_id;
	assign multdiv_operator_ex_o = multdiv_operator;
	assign multdiv_signed_mode_ex_o = multdiv_signed_mode;
	assign multdiv_operand_a_ex_o = rf_rdata_a_fwd;
	assign multdiv_operand_b_ex_o = rf_rdata_b_fwd;
	generate
		if (BranchTargetALU && !DataIndTiming) begin : g_branch_set_direct
			assign branch_set_raw = branch_set_raw_d;
		end
		else begin : g_branch_set_flop
			reg branch_set_raw_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_set_raw_q <= 1'b0;
				else
					branch_set_raw_q <= branch_set_raw_d;
			assign branch_set_raw = (BranchTargetALU && !data_ind_timing_i ? branch_set_raw_d : branch_set_raw_q);
		end
	endgenerate
	assign branch_jump_set_done_d = ((branch_set_raw | jump_set_raw) | branch_jump_set_done_q) & ~instr_valid_clear_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			branch_jump_set_done_q <= 1'b0;
		else
			branch_jump_set_done_q <= branch_jump_set_done_d;
	assign jump_set = jump_set_raw & ~branch_jump_set_done_q;
	assign branch_set = branch_set_raw & ~branch_jump_set_done_q;
	generate
		if (DataIndTiming) begin : g_sec_branch_taken
			reg branch_taken_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_taken_q <= 1'b0;
				else
					branch_taken_q <= branch_decision_i;
			assign branch_taken = ~data_ind_timing_i | branch_taken_q;
		end
		else begin : g_nosec_branch_taken
			assign branch_taken = 1'b1;
		end
		if (BranchPredictor) begin : g_calc_nt_addr
			assign nt_branch_addr_o = pc_id_i + (instr_is_compressed_i ? 32'd2 : 32'd4);
		end
		else begin : g_n_calc_nt_addr
			assign nt_branch_addr_o = 32'd0;
		end
	endgenerate
	reg id_fsm_q;
	reg id_fsm_d;
	always @(posedge clk_i or negedge rst_ni) begin : id_pipeline_reg
		if (!rst_ni)
			id_fsm_q <= 1'd0;
		else if (instr_executing)
			id_fsm_q <= id_fsm_d;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		id_fsm_d = id_fsm_q;
		rf_we_raw = rf_we_dec;
		stall_multdiv = 1'b0;
		stall_jump = 1'b0;
		stall_branch = 1'b0;
		stall_alu = 1'b0;
		branch_set_raw_d = 1'b0;
		branch_not_set = 1'b0;
		jump_set_raw = 1'b0;
		perf_branch_o = 1'b0;
		if (instr_executing_spec)
			(* full_case, parallel_case *)
			case (id_fsm_q)
				1'd0:
					(* full_case, parallel_case *)
					case (1'b1)
						lsu_req_dec:
							if (!WritebackStage)
								id_fsm_d = 1'd1;
							else if (~lsu_req_done_i)
								id_fsm_d = 1'd1;
						cheriot_lsu_req_dec:
							if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
								if (!WritebackStage)
									id_fsm_d = 1'd1;
								else if (~lsu_req_done_i)
									id_fsm_d = 1'd1;
							end
						multdiv_en_dec:
							if (~ex_valid_i) begin
								id_fsm_d = 1'd1;
								rf_we_raw = 1'b0;
								stall_multdiv = 1'b1;
							end
						branch_in_dec: begin
							id_fsm_d = (data_ind_timing_i || (!BranchTargetALU && branch_decision_i) ? 1'd1 : 1'd0);
							stall_branch = (~BranchTargetALU & branch_decision_i) | data_ind_timing_i;
							branch_set_raw_d = branch_decision_i | data_ind_timing_i;
							if (BranchPredictor)
								branch_not_set = ~branch_decision_i;
							perf_branch_o = 1'b1;
						end
						jump_in_dec: begin
							id_fsm_d = (BranchTargetALU ? 1'd0 : 1'd1);
							stall_jump = ~BranchTargetALU;
							jump_set_raw = jump_set_dec;
						end
						alu_multicycle_dec: begin
							stall_alu = 1'b1;
							id_fsm_d = 1'd1;
							rf_we_raw = 1'b0;
						end
						default: id_fsm_d = 1'd0;
					endcase
				1'd1: begin
					if (multdiv_en_dec)
						rf_we_raw = rf_we_dec & ex_valid_i;
					if (multicycle_done & ready_wb_i)
						id_fsm_d = 1'd0;
					else begin
						stall_multdiv = multdiv_en_dec;
						stall_branch = branch_in_dec;
						stall_jump = jump_in_dec;
					end
				end
				default: id_fsm_d = 1'd0;
			endcase
	end
	assign multdiv_ready_id_o = ready_wb_i;
	assign stall_id = ((((stall_ld_hz | stall_mem) | stall_multdiv) | stall_jump) | stall_branch) | stall_alu;
	assign instr_done = (~stall_id & ~flush_id) & instr_executing;
	assign instr_first_cycle = instr_valid_i & (id_fsm_q == 1'd0);
	assign instr_first_cycle_id_o = instr_first_cycle;
	generate
		if (WritebackStage) begin : gen_stall_mem
			wire rf_rd_a_wb_match;
			wire rf_rd_b_wb_match;
			wire rf_rd_a_hz;
			wire rf_rd_b_hz;
			wire outstanding_memory_access;
			wire instr_kill;
			assign multicycle_done = (lsu_req_dec | cheriot_lsu_req_dec ? ~stall_mem : ex_valid_all);
			assign outstanding_memory_access = (outstanding_load_wb_i | outstanding_store_wb_i) & ~lsu_resp_valid_i;
			assign data_req_allowed = ~outstanding_memory_access;
			assign instr_kill = ((instr_fetch_err_i | wb_exception) | id_exception_nc) | ~controller_run;
			assign instr_executing_spec = ((instr_valid_i & ~instr_fetch_err_i) & controller_run) & ~stall_ld_hz;
			assign instr_executing = ((instr_valid_i & ~instr_kill) & ~stall_ld_hz) & ~outstanding_memory_access;
			assign cheriot_exec_id_o = (((((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & instr_valid_i) & ~instr_fetch_err_i) & instr_is_legal_cheriot) & controller_run) & ~wb_exception) & ~stall_ld_hz) & ~outstanding_memory_access;
			assign stall_mem = instr_valid_i & (outstanding_memory_access | ((lsu_req_dec | cheriot_lsu_req_dec) & ~lsu_req_done_i));
			assign rf_rd_a_wb_match = (rf_waddr_wb_i == rf_raddr_a_o) & |rf_raddr_a_o;
			assign rf_rd_b_wb_match = (rf_waddr_wb_i == rf_raddr_b_o) & |rf_raddr_b_o;
			assign rf_rd_a_wb_match_o = rf_rd_a_wb_match;
			assign rf_rd_b_wb_match_o = rf_rd_b_wb_match;
			assign rf_rd_a_hz = rf_rd_a_wb_match & rf_ren_a;
			assign rf_rd_b_hz = rf_rd_b_wb_match & rf_ren_b;
			assign rf_rdata_a_fwd = (rf_rd_a_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_a_i);
			assign rf_rdata_b_fwd = (rf_rd_b_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_b_i);
			assign stall_ld_hz = outstanding_load_wb_i & (rf_rd_a_hz | rf_rd_b_hz);
			wire unused_rf_we_or_load_valid;
			assign unused_rf_we_or_load_valid = ((rf_we_or_load & instr_valid_i) & ~instr_fetch_err_i) & ~illegal_insn_o;
			assign instr_type_wb_o = (~lsu_req_dec ? 2'd2 : (lsu_we ? 2'd1 : 2'd0));
			assign instr_id_done_o = en_wb_o & ready_wb_i;
			assign stall_wb = en_wb_o & ~ready_wb_i;
			assign perf_dside_wait_o = (instr_valid_i & ~instr_kill) & (outstanding_memory_access | stall_ld_hz);
			assign expecting_load_resp_o = 1'b0;
			assign expecting_store_resp_o = 1'b0;
		end
		else begin : gen_no_stall_mem
			assign multicycle_done = (cheriot_lsu_req_dec | lsu_req_dec ? lsu_resp_valid_i : ex_valid_all);
			assign data_req_allowed = instr_first_cycle;
			assign stall_mem = instr_valid_i & ((lsu_req_dec | cheriot_lsu_req_dec) & (~lsu_resp_valid_i | instr_first_cycle));
			assign stall_ld_hz = 1'b0;
			assign instr_executing_spec = (instr_valid_i & ~instr_fetch_err_i) & controller_run;
			assign instr_executing = instr_executing_spec;
			assign cheriot_exec_id_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn) & instr_executing;
			assign rf_rdata_a_fwd = rf_rdata_a_i;
			assign rf_rdata_b_fwd = rf_rdata_b_i;
			assign rf_rd_a_wb_match_o = 1'b0;
			assign rf_rd_b_wb_match_o = 1'b0;
			assign expecting_load_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & ~lsu_we;
			assign expecting_store_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & lsu_we;
			wire unused_data_req_done_ex;
			wire [4:0] unused_rf_waddr_wb;
			wire unused_rf_write_wb;
			wire unused_outstanding_load_wb;
			wire unused_outstanding_store_wb;
			wire unused_wb_exception;
			wire [31:0] unused_rf_wdata_fwd_wb;
			assign unused_data_req_done_ex = lsu_req_done_i;
			assign unused_rf_waddr_wb = rf_waddr_wb_i;
			assign unused_rf_write_wb = rf_write_wb_i;
			assign unused_outstanding_load_wb = outstanding_load_wb_i;
			assign unused_outstanding_store_wb = outstanding_store_wb_i;
			assign unused_wb_exception = wb_exception;
			assign unused_rf_wdata_fwd_wb = rf_wdata_fwd_wb_i;
			wire unused_cheriot_wb_signals;
			assign unused_cheriot_wb_signals = ^{id_exception_nc, rf_we_or_load, instr_is_legal_cheriot};
			assign instr_type_wb_o = 2'd2;
			assign stall_wb = 1'b0;
			assign perf_dside_wait_o = (instr_executing & lsu_req_dec) & ~lsu_resp_valid_i;
			assign instr_id_done_o = instr_done;
		end
	endgenerate
	wire minstret_write;
	assign minstret_write = (csr_access_o & |{csr_op_o == 2'd1, csr_op_o == 2'd2, csr_op_o == 2'd3}) & |{csr_addr_o == 12'hb02, csr_addr_o == 12'hb82};
	assign instr_perf_count_id_o = (((((~ebrk_insn & ~ecall_insn_dec) & ~illegal_insn_dec) & ~illegal_csr_insn_i) & ~instr_fetch_err_i) & ~minstret_write) & !(|{instr_gets_expanded_i == 2'd1, instr_gets_expanded_i == 2'd2});
	assign en_wb_o = instr_done;
	assign perf_mul_wait_o = stall_multdiv & mult_en_dec;
	assign perf_div_wait_o = stall_multdiv & div_en_dec;
	initial _sv2v_0 = 0;
endmodule
module ibex_if_stage (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	boot_addr_i,
	req_i,
	debug_mode_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_bus_err_i,
	instr_intg_err_o,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	instr_valid_id_o,
	instr_new_id_o,
	instr_rdata_id_o,
	instr_rdata_alu_id_o,
	instr_rdata_c_id_o,
	instr_is_compressed_id_o,
	instr_gets_expanded_id_o,
	instr_expanded_id_o,
	instr_bp_taken_o,
	instr_fetch_err_o,
	instr_fetch_err_plus2_o,
	illegal_c_insn_id_o,
	instr_fetch_cheriot_acc_vio_o,
	instr_fetch_cheriot_bound_vio_o,
	dummy_instr_id_o,
	pc_if_o,
	pc_id_o,
	pmp_err_if_i,
	pmp_err_if_plus2_i,
	instr_valid_clear_i,
	pc_set_i,
	pc_mux_i,
	nt_branch_mispredict_i,
	nt_branch_addr_i,
	exc_pc_mux_i,
	exc_cause,
	dummy_instr_en_i,
	dummy_instr_mask_i,
	dummy_instr_seed_en_i,
	dummy_instr_seed_i,
	icache_enable_i,
	icache_inval_i,
	icache_ecc_error_o,
	branch_target_ex_i,
	csr_mepc_i,
	csr_depc_i,
	csr_mtvec_i,
	csr_mtvec_init_o,
	id_in_ready_i,
	pc_mismatch_alert_o,
	if_busy_o,
	pcc_cap_i
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter integer RV32ZC = 32'sd3;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ICacheTweakInfection = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] PCIncrCheck = 1'b0;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [31:0] boot_addr_i;
	input wire req_i;
	input wire debug_mode_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_bus_err_i;
	output wire instr_intg_err_o;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	output wire instr_valid_id_o;
	output wire instr_new_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg [31:0] instr_rdata_alu_id_o;
	output reg [15:0] instr_rdata_c_id_o;
	output reg instr_is_compressed_id_o;
	output reg [1:0] instr_gets_expanded_id_o;
	output reg [15:0] instr_expanded_id_o;
	output wire instr_bp_taken_o;
	output reg instr_fetch_err_o;
	output reg instr_fetch_err_plus2_o;
	output reg illegal_c_insn_id_o;
	output reg instr_fetch_cheriot_acc_vio_o;
	output reg instr_fetch_cheriot_bound_vio_o;
	output reg dummy_instr_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	input wire pmp_err_if_i;
	input wire pmp_err_if_plus2_i;
	input wire instr_valid_clear_i;
	input wire pc_set_i;
	input wire [2:0] pc_mux_i;
	input wire nt_branch_mispredict_i;
	input wire [31:0] nt_branch_addr_i;
	input wire [1:0] exc_pc_mux_i;
	input wire [6:0] exc_cause;
	input wire dummy_instr_en_i;
	input wire [2:0] dummy_instr_mask_i;
	input wire dummy_instr_seed_en_i;
	input wire [31:0] dummy_instr_seed_i;
	input wire icache_enable_i;
	input wire icache_inval_i;
	output wire icache_ecc_error_o;
	input wire [31:0] branch_target_ex_i;
	input wire [31:0] csr_mepc_i;
	input wire [31:0] csr_depc_i;
	input wire [31:0] csr_mtvec_i;
	output wire csr_mtvec_init_o;
	input wire id_in_ready_i;
	output wire pc_mismatch_alert_o;
	output wire if_busy_o;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [111:0] pcc_cap_i;
	wire instr_valid_id_d;
	reg instr_valid_id_q;
	wire instr_new_id_d;
	reg instr_new_id_q;
	wire instr_err;
	wire instr_intg_err;
	wire prefetch_busy;
	wire branch_req;
	reg [31:0] fetch_addr_n;
	wire unused_fetch_addr_n0;
	wire prefetch_branch;
	wire [31:0] prefetch_addr;
	wire fetch_valid_raw;
	wire fetch_valid;
	wire fetch_ready;
	wire [31:0] fetch_rdata;
	wire [31:0] fetch_addr;
	wire fetch_err;
	wire fetch_err_plus2;
	wire [31:0] instr_decompressed;
	wire illegal_c_insn;
	wire instr_is_compressed;
	wire [1:0] instr_gets_expanded;
	wire if_instr_valid;
	wire [31:0] if_instr_rdata;
	wire [31:0] if_instr_addr;
	wire if_instr_bus_err;
	wire if_instr_pmp_err;
	wire if_instr_err;
	wire if_instr_err_plus2;
	reg [31:0] exc_pc;
	wire if_id_pipe_reg_we;
	wire stall_dummy_instr;
	wire [31:0] instr_out;
	wire instr_is_compressed_out;
	wire [1:0] instr_gets_expanded_out;
	wire illegal_c_instr_out;
	wire instr_err_out;
	wire predict_branch_taken;
	wire [31:0] predict_branch_pc;
	reg [4:0] irq_vec;
	wire [2:0] pc_mux_internal;
	wire [7:0] unused_boot_addr;
	wire [7:0] unused_csr_mtvec;
	wire unused_exc_cause;
	wire cheriot_acc_vio;
	wire cheriot_bound_vio;
	wire cheriot_force_uc;
	wire [111:0] unused_pcc_cap;
	wire unused_cheriot_force_uc;
	assign unused_boot_addr = boot_addr_i[7:0];
	assign unused_csr_mtvec = csr_mtvec_i[7:0];
	assign unused_exc_cause = |{exc_cause[5], exc_cause[6]};
	assign unused_pcc_cap = pcc_cap_i;
	assign unused_cheriot_force_uc = cheriot_force_uc;
	generate
		if (BaseIsa != 32'sd1) begin : gen_no_cheriot_if
			wire unused_cheriot_if_sigs;
			assign unused_cheriot_if_sigs = ^cheriot_enable_i | debug_mode_i;
		end
	endgenerate
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	always @(*) begin : exc_pc_mux
		if (_sv2v_0)
			;
		irq_vec = exc_cause[4-:5];
		if (exc_cause[6])
			irq_vec = ibex_pkg_ExcCauseIrqNm[4-:5];
		(* full_case, parallel_case *)
		case (exc_pc_mux_i)
			2'd0: exc_pc = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? {csr_mtvec_i[31:2], 2'b00} : {csr_mtvec_i[31:8], 8'h00});
			2'd1: exc_pc = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? {csr_mtvec_i[31:2], 2'b00} : {csr_mtvec_i[31:8], 1'b0, irq_vec, 2'b00});
			2'd2: exc_pc = DmHaltAddr;
			2'd3: exc_pc = DmExceptionAddr;
			default: exc_pc = {csr_mtvec_i[31:8], 8'h00};
		endcase
	end
	assign pc_mux_internal = ((BranchPredictor && predict_branch_taken) && !pc_set_i ? 3'd5 : pc_mux_i);
	always @(*) begin : fetch_addr_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (pc_mux_internal)
			3'd0: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
			3'd1: fetch_addr_n = branch_target_ex_i;
			3'd2: fetch_addr_n = exc_pc;
			3'd3: fetch_addr_n = csr_mepc_i;
			3'd4: fetch_addr_n = csr_depc_i;
			3'd5: fetch_addr_n = (BranchPredictor ? predict_branch_pc : {boot_addr_i[31:8], 8'h80});
			default: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
		endcase
	end
	assign csr_mtvec_init_o = (pc_mux_i == 3'd0) & pc_set_i;
	generate
		if (MemECC) begin : g_mem_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] instr_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(instr_rdata_i),
				.out_o(instr_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_instr_intg_dec(
				.data_i(instr_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign instr_intg_err = |ecc_err;
		end
		else begin : g_no_mem_ecc
			assign instr_intg_err = 1'b0;
		end
	endgenerate
	assign instr_err = instr_intg_err | instr_bus_err_i;
	assign instr_intg_err_o = instr_intg_err & instr_rvalid_i;
	assign prefetch_branch = branch_req | nt_branch_mispredict_i;
	assign prefetch_addr = (branch_req ? {fetch_addr_n[31:1], 1'b0} : nt_branch_addr_i);
	assign fetch_valid = fetch_valid_raw & ~nt_branch_mispredict_i;
	generate
		if (ICache) begin : gen_icache
			ibex_icache #(
				.ICacheECC(ICacheECC),
				.ResetAll(ResetAll),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC),
				.TweakInfection(ICacheTweakInfection)
			) icache_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.ic_tag_req_o(ic_tag_req_o),
				.ic_tag_write_o(ic_tag_write_o),
				.ic_tag_addr_o(ic_tag_addr_o),
				.ic_tag_wdata_o(ic_tag_wdata_o),
				.ic_tag_rdata_i(ic_tag_rdata_i),
				.ic_data_req_o(ic_data_req_o),
				.ic_data_write_o(ic_data_write_o),
				.ic_data_addr_o(ic_data_addr_o),
				.ic_data_wdata_o(ic_data_wdata_o),
				.ic_data_rdata_i(ic_data_rdata_i),
				.ic_scr_key_valid_i(ic_scr_key_valid_i),
				.ic_scr_key_req_o(ic_scr_key_req_o),
				.icache_enable_i(icache_enable_i),
				.icache_inval_i(icache_inval_i),
				.busy_o(prefetch_busy),
				.ecc_error_o(icache_ecc_error_o)
			);
		end
		else begin : gen_prefetch_buffer
			ibex_prefetch_buffer #(.ResetAll(ResetAll)) prefetch_buffer_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.cheriot_force_uc_i(cheriot_force_uc),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.busy_o(prefetch_busy)
			);
			wire unused_icen;
			wire unused_icinv;
			wire unused_scr_key_valid;
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] unused_tag_ram_input;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] unused_data_ram_input;
			assign unused_icen = icache_enable_i;
			assign unused_icinv = icache_inval_i;
			assign unused_tag_ram_input = ic_tag_rdata_i;
			assign unused_data_ram_input = ic_data_rdata_i;
			assign unused_scr_key_valid = ic_scr_key_valid_i;
			assign ic_tag_req_o = 'b0;
			assign ic_tag_write_o = 'b0;
			assign ic_tag_addr_o = 'b0;
			assign ic_tag_wdata_o = 'b0;
			assign ic_data_req_o = 'b0;
			assign ic_data_write_o = 'b0;
			assign ic_data_addr_o = 'b0;
			assign ic_data_wdata_o = 'b0;
			assign ic_scr_key_req_o = 'b0;
			assign icache_ecc_error_o = 'b0;
		end
	endgenerate
	assign unused_fetch_addr_n0 = fetch_addr_n[0];
	assign branch_req = pc_set_i | predict_branch_taken;
	assign pc_if_o = if_instr_addr;
	assign if_busy_o = prefetch_busy;
	assign if_instr_pmp_err = pmp_err_if_i | ((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i);
	assign if_instr_err = ((if_instr_bus_err | if_instr_pmp_err) | cheriot_acc_vio) | cheriot_bound_vio;
	assign if_instr_err_plus2 = (((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i) | fetch_err_plus2) & ~pmp_err_if_i;
	wire [33:0] instr_hdrm;
	wire hdrm_ge4;
	wire hdrm_ge2;
	wire hdrm_ok;
	wire base_ok;
	wire allow_all;
	assign allow_all = (pcc_cap_i[78-:32] == 0) & (pcc_cap_i[111-:33] == 33'h100000000);
	assign instr_hdrm = {1'b0, pcc_cap_i[111-:33]} - {2'b00, if_instr_addr};
	assign hdrm_ge4 = |instr_hdrm[32:2] & ~instr_hdrm[33];
	assign hdrm_ge2 = |instr_hdrm[32:1] & ~instr_hdrm[33];
	wire unused_hdrm_lsb;
	assign unused_hdrm_lsb = instr_hdrm[0];
	assign hdrm_ok = allow_all || (instr_is_compressed ? hdrm_ge2 : hdrm_ge4);
	assign base_ok = ~(if_instr_addr < pcc_cap_i[78-:32]);
	assign cheriot_bound_vio = (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~debug_mode_i) & (~base_ok || ~hdrm_ok);
	assign cheriot_force_uc = (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~allow_all) & (~base_ok | ~hdrm_ge4);
	assign cheriot_acc_vio = (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & ~debug_mode_i) & ((~pcc_cap_i[43] || ~pcc_cap_i[32]) || (pcc_cap_i[24-:3] != 0));
	wire flush_expanded;
	assign flush_expanded = pc_set_i & (pc_mux_i == 3'd2);
	ibex_compressed_decoder #(
		.RV32ZC(RV32ZC),
		.ResetAll(ResetAll),
		.BaseIsa(BaseIsa)
	) compressed_decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(fetch_valid & ~fetch_err),
		.id_in_ready_i(id_in_ready_i & ~pc_set_i),
		.instr_i(if_instr_rdata),
		.cheriot_enable_i(cheriot_enable_i),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_is_compressed),
		.gets_expanded_o(instr_gets_expanded),
		.flush_expanded_i(flush_expanded),
		.illegal_instr_o(illegal_c_insn)
	);
	generate
		if (DummyInstructions) begin : gen_dummy_instr
			wire insert_dummy_instr;
			wire [31:0] dummy_instr_data;
			ibex_dummy_instr #(
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm)
			) dummy_instr_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.dummy_instr_en_i(dummy_instr_en_i),
				.dummy_instr_mask_i(dummy_instr_mask_i),
				.dummy_instr_seed_en_i(dummy_instr_seed_en_i),
				.dummy_instr_seed_i(dummy_instr_seed_i),
				.fetch_valid_i(fetch_valid),
				.id_in_ready_i(id_in_ready_i),
				.insert_dummy_instr_o(insert_dummy_instr),
				.dummy_instr_data_o(dummy_instr_data)
			);
			assign instr_out = (insert_dummy_instr ? dummy_instr_data : instr_decompressed);
			assign instr_is_compressed_out = (insert_dummy_instr ? 1'b0 : instr_is_compressed);
			assign instr_gets_expanded_out = (insert_dummy_instr ? 2'd0 : instr_gets_expanded);
			assign illegal_c_instr_out = (insert_dummy_instr ? 1'b0 : illegal_c_insn);
			assign instr_err_out = (insert_dummy_instr ? 1'b0 : if_instr_err);
			assign stall_dummy_instr = insert_dummy_instr;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					dummy_instr_id_o <= 1'b0;
				else if (if_id_pipe_reg_we)
					dummy_instr_id_o <= insert_dummy_instr;
		end
		else begin : gen_no_dummy_instr
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			wire unused_dummy_seed_en;
			wire [31:0] unused_dummy_seed;
			assign unused_dummy_en = dummy_instr_en_i;
			assign unused_dummy_mask = dummy_instr_mask_i;
			assign unused_dummy_seed_en = dummy_instr_seed_en_i;
			assign unused_dummy_seed = dummy_instr_seed_i;
			assign instr_out = instr_decompressed;
			assign instr_is_compressed_out = instr_is_compressed;
			assign instr_gets_expanded_out = instr_gets_expanded;
			assign illegal_c_instr_out = illegal_c_insn;
			assign instr_err_out = if_instr_err;
			assign stall_dummy_instr = 1'b0;
			wire [1:1] sv2v_tmp_C8A0C;
			assign sv2v_tmp_C8A0C = 1'b0;
			always @(*) dummy_instr_id_o = sv2v_tmp_C8A0C;
		end
	endgenerate
	assign instr_valid_id_d = ((if_instr_valid & id_in_ready_i) & ~pc_set_i) | (instr_valid_id_q & ~instr_valid_clear_i);
	assign instr_new_id_d = (if_instr_valid & id_in_ready_i) & ~pc_set_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			instr_valid_id_q <= 1'b0;
			instr_new_id_q <= 1'b0;
		end
		else begin
			instr_valid_id_q <= instr_valid_id_d;
			instr_new_id_q <= instr_new_id_d;
		end
	assign instr_valid_id_o = instr_valid_id_q;
	assign instr_new_id_o = instr_new_id_q;
	assign if_id_pipe_reg_we = instr_new_id_d;
	generate
		if (ResetAll) begin : g_instr_rdata_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					instr_rdata_id_o <= 1'sb0;
					instr_rdata_alu_id_o <= 1'sb0;
					instr_fetch_err_o <= 1'sb0;
					instr_fetch_err_plus2_o <= 1'sb0;
					instr_rdata_c_id_o <= 1'sb0;
					instr_is_compressed_id_o <= 1'sb0;
					instr_gets_expanded_id_o <= 2'd0;
					instr_expanded_id_o <= 1'sb0;
					illegal_c_insn_id_o <= 1'sb0;
					pc_id_o <= 1'sb0;
				end
				else if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					instr_gets_expanded_id_o <= instr_gets_expanded_out;
					instr_expanded_id_o <= if_instr_rdata[15:0];
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		else begin : g_instr_rdata_nr
			always @(posedge clk_i)
				if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					instr_gets_expanded_id_o <= instr_gets_expanded_out;
					instr_expanded_id_o <= if_instr_rdata[15:0];
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		if (BaseIsa == 32'sd1) begin : gen_cheriot_vio_regs
			if (ResetAll) begin : g_cheriot_vio_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						instr_fetch_cheriot_acc_vio_o <= 1'sb0;
						instr_fetch_cheriot_bound_vio_o <= 1'sb0;
					end
					else if (if_id_pipe_reg_we) begin
						instr_fetch_cheriot_acc_vio_o <= cheriot_acc_vio;
						instr_fetch_cheriot_bound_vio_o <= cheriot_bound_vio;
					end
			end
			else begin : g_cheriot_vio_nr
				always @(posedge clk_i)
					if (if_id_pipe_reg_we) begin
						instr_fetch_cheriot_acc_vio_o <= cheriot_acc_vio;
						instr_fetch_cheriot_bound_vio_o <= cheriot_bound_vio;
					end
			end
		end
		else begin : gen_cheriot_vio_tieoff
			wire [1:1] sv2v_tmp_D9D09;
			assign sv2v_tmp_D9D09 = 1'b0;
			always @(*) instr_fetch_cheriot_acc_vio_o = sv2v_tmp_D9D09;
			wire [1:1] sv2v_tmp_A3CC8;
			assign sv2v_tmp_A3CC8 = 1'b0;
			always @(*) instr_fetch_cheriot_bound_vio_o = sv2v_tmp_A3CC8;
		end
		if (PCIncrCheck) begin : g_secure_pc
			wire [31:0] prev_instr_addr_incr;
			wire [31:0] prev_instr_addr_incr_buf;
			reg prev_instr_seq_q;
			wire prev_instr_seq_d;
			assign prev_instr_seq_d = ((((prev_instr_seq_q | instr_new_id_d) & ~branch_req) & ~if_instr_err) & ~stall_dummy_instr) & !(|{instr_gets_expanded == 2'd1, instr_gets_expanded == 2'd2});
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					prev_instr_seq_q <= 1'b0;
				else
					prev_instr_seq_q <= prev_instr_seq_d;
			assign prev_instr_addr_incr = pc_id_o + (instr_is_compressed_id_o ? 32'd2 : 32'd4);
			prim_buf #(.Width(32)) u_prev_instr_addr_incr_buf(
				.in_i(prev_instr_addr_incr),
				.out_o(prev_instr_addr_incr_buf)
			);
			assign pc_mismatch_alert_o = prev_instr_seq_q & (pc_if_o != prev_instr_addr_incr_buf);
		end
		else begin : g_no_secure_pc
			assign pc_mismatch_alert_o = 1'b0;
		end
		if (BranchPredictor) begin : g_branch_predictor
			reg [31:0] instr_skid_data_q;
			reg [31:0] instr_skid_addr_q;
			reg instr_skid_bp_taken_q;
			reg instr_skid_valid_q;
			wire instr_skid_valid_d;
			wire instr_skid_en;
			reg instr_bp_taken_q;
			wire instr_bp_taken_d;
			wire predict_branch_taken_raw;
			if (ResetAll) begin : g_bp_taken_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						instr_bp_taken_q <= 1'sb0;
					else if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			else begin : g_bp_taken_nr
				always @(posedge clk_i)
					if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			assign instr_skid_en = ((predict_branch_taken & ~pc_set_i) & ~id_in_ready_i) & ~instr_skid_valid_q;
			assign instr_skid_valid_d = (((instr_skid_valid_q & ~id_in_ready_i) & ~stall_dummy_instr) & !(|{instr_gets_expanded == 2'd1, instr_gets_expanded == 2'd2})) | instr_skid_en;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_skid_valid_q <= 1'b0;
				else
					instr_skid_valid_q <= instr_skid_valid_d;
			if (ResetAll) begin : g_instr_skid_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						instr_skid_bp_taken_q <= 1'sb0;
						instr_skid_data_q <= 1'sb0;
						instr_skid_addr_q <= 1'sb0;
					end
					else if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			else begin : g_instr_skid_nr
				always @(posedge clk_i)
					if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			ibex_branch_predict branch_predict_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.fetch_rdata_i(fetch_rdata),
				.fetch_pc_i(fetch_addr),
				.fetch_valid_i(fetch_valid),
				.predict_branch_taken_o(predict_branch_taken_raw),
				.predict_branch_pc_o(predict_branch_pc)
			);
			assign predict_branch_taken = (predict_branch_taken_raw & ~instr_skid_valid_q) & ~fetch_err;
			assign if_instr_valid = fetch_valid | (instr_skid_valid_q & ~nt_branch_mispredict_i);
			assign if_instr_rdata = (instr_skid_valid_q ? instr_skid_data_q : fetch_rdata);
			assign if_instr_addr = (instr_skid_valid_q ? instr_skid_addr_q : fetch_addr);
			assign if_instr_bus_err = ~instr_skid_valid_q & fetch_err;
			assign instr_bp_taken_d = (instr_skid_valid_q ? instr_skid_bp_taken_q : predict_branch_taken);
			assign fetch_ready = ((id_in_ready_i & ~stall_dummy_instr) & !(|{instr_gets_expanded == 2'd1, instr_gets_expanded == 2'd2})) & ~instr_skid_valid_q;
			assign instr_bp_taken_o = instr_bp_taken_q;
		end
		else begin : g_no_branch_predictor
			assign instr_bp_taken_o = 1'b0;
			assign predict_branch_taken = 1'b0;
			assign predict_branch_pc = 32'b00000000000000000000000000000000;
			assign if_instr_valid = fetch_valid;
			assign if_instr_rdata = fetch_rdata;
			assign if_instr_addr = fetch_addr;
			assign if_instr_bus_err = fetch_err;
			assign fetch_ready = (id_in_ready_i & ~stall_dummy_instr) & !(|{instr_gets_expanded == 2'd1, instr_gets_expanded == 2'd2});
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_load_store_unit (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_bus_err_i,
	data_pmp_err_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_tag_o,
	data_rdata_i,
	data_tag_i,
	lsu_we_i,
	lsu_is_cap_i,
	lsu_cheriot_err_i,
	lsu_type_i,
	lsu_wdata_i,
	lsu_wcap_i,
	lsu_lc_clrperm_i,
	lsu_sign_ext_i,
	lsu_rcap_o,
	lsu_rdata_o,
	lsu_rdata_valid_o,
	lsu_req_i,
	adder_result_ex_i,
	addr_incr_req_o,
	addr_last_o,
	lsu_req_done_o,
	lsu_resp_valid_o,
	load_err_o,
	load_resp_intg_err_o,
	store_err_o,
	store_resp_intg_err_o,
	lsu_err_is_cheriot_o,
	busy_o,
	perf_load_o,
	perf_store_o
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output reg data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_bus_err_i;
	input wire data_pmp_err_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	output wire data_tag_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_tag_i;
	input wire lsu_we_i;
	input wire lsu_is_cap_i;
	input wire lsu_cheriot_err_i;
	input wire [1:0] lsu_type_i;
	input wire [31:0] lsu_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] lsu_wcap_i;
	input wire [2:0] lsu_lc_clrperm_i;
	input wire lsu_sign_ext_i;
	output wire [34:0] lsu_rcap_o;
	output wire [31:0] lsu_rdata_o;
	output wire lsu_rdata_valid_o;
	input wire lsu_req_i;
	input wire [31:0] adder_result_ex_i;
	output reg addr_incr_req_o;
	output wire [31:0] addr_last_o;
	output wire lsu_req_done_o;
	output wire lsu_resp_valid_o;
	output wire load_err_o;
	output wire load_resp_intg_err_o;
	output wire store_err_o;
	output wire store_resp_intg_err_o;
	output wire lsu_err_is_cheriot_o;
	output wire busy_o;
	output reg perf_load_o;
	output reg perf_store_o;
	wire [31:0] data_addr;
	wire [31:0] data_addr_w_aligned;
	reg [31:0] addr_last_q;
	wire [31:0] addr_last_d;
	reg addr_update;
	reg ctrl_update;
	reg rdata_update;
	reg [31:8] rdata_q;
	reg [1:0] rdata_offset_q;
	reg [1:0] data_type_q;
	reg data_sign_ext_q;
	reg data_we_q;
	wire [1:0] data_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata_data;
	reg data_wdata_tag;
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	wire split_misaligned_access;
	reg handle_misaligned_q;
	reg handle_misaligned_d;
	reg pmp_err_q;
	reg pmp_err_d;
	reg lsu_err_q;
	reg lsu_err_d;
	wire data_intg_err;
	wire data_or_pmp_err;
	reg resp_is_cap_q;
	reg cheriot_err_d;
	reg cheriot_err_q;
	reg [2:0] resp_lc_clrperm_q;
	reg lsu_go;
	reg lsu_go_goodcap;
	wire cpu_req_erred;
	wire cpu_req_valid;
	reg [3:0] ls_fsm_cs;
	reg [3:0] ls_fsm_ns;
	reg [2:0] cap_rx_fsm_q;
	reg [2:0] cap_rx_fsm_d;
	reg cap_lsw_err_q;
	reg [31:0] cap_lsw_data_q;
	reg cap_lsw_tag_q;
	assign data_addr = adder_result_ex_i;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign data_offset = (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i ? 2'b00 : data_addr[1:0]);
	always @(*) begin
		if (_sv2v_0)
			;
		if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i)
			data_be = 4'b1111;
		else
			(* full_case, parallel_case *)
			case (lsu_type_i)
				2'b00:
					if (!handle_misaligned_q)
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b1111;
							2'b01: data_be = 4'b1110;
							2'b10: data_be = 4'b1100;
							2'b11: data_be = 4'b1000;
							default: data_be = 4'b1111;
						endcase
					else
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b0000;
							2'b01: data_be = 4'b0001;
							2'b10: data_be = 4'b0011;
							2'b11: data_be = 4'b0111;
							default: data_be = 4'b1111;
						endcase
				2'b01:
					if (!handle_misaligned_q)
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b0011;
							2'b01: data_be = 4'b0110;
							2'b10: data_be = 4'b1100;
							2'b11: data_be = 4'b1000;
							default: data_be = 4'b1111;
						endcase
					else
						data_be = 4'b0001;
				2'b10, 2'b11:
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0001;
						2'b01: data_be = 4'b0010;
						2'b10: data_be = 4'b0100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				default: data_be = 4'b1111;
			endcase
	end
	reg [31:0] wdata_int;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_offset)
			2'b00: wdata_int = lsu_wdata_i;
			2'b01: wdata_int = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
			2'b10: wdata_int = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
			2'b11: wdata_int = {lsu_wdata_i[7:0], lsu_wdata_i[31:8]};
			default: wdata_int = lsu_wdata_i;
		endcase
	end
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_cap_to_mem;
		input reg [34:0] cap;
		reg [34:0] cap_bits;
		reg [1:0] unused_cap_corr;
		begin
			cap_bits = cap;
			unused_cap_corr = cap_bits[34:33];
			ibex_cheriot_pkg_cheriot_cap_to_mem = cap_bits[32:0];
		end
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i) begin
			if (lsu_we_i & (ls_fsm_cs == 4'd6))
				{data_wdata_tag, data_wdata_data} = ibex_cheriot_pkg_cheriot_cap_to_mem(lsu_wcap_i);
			else if (lsu_we_i)
				{data_wdata_tag, data_wdata_data} = {lsu_wcap_i[32], lsu_wdata_i};
			else
				{data_wdata_tag, data_wdata_data} = {1'b1, lsu_wdata_i};
		end
		else
			{data_wdata_tag, data_wdata_data} = {1'b0, wdata_int};
	end
	wire [1:0] unused_lsu_wcap_cor;
	assign unused_lsu_wcap_cor = lsu_wcap_i[34-:2];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= 1'sb0;
		else if (rdata_update)
			rdata_q <= data_rdata_i[31:8];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rdata_offset_q <= 2'h0;
			data_type_q <= 2'h0;
			data_sign_ext_q <= 1'b0;
			data_we_q <= 1'b0;
		end
		else if (ctrl_update) begin
			rdata_offset_q <= data_offset;
			data_type_q <= lsu_type_i;
			data_sign_ext_q <= lsu_sign_ext_i;
			data_we_q <= lsu_we_i;
		end
	assign addr_last_d = (addr_incr_req_o ? data_addr_w_aligned : data_addr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			addr_last_q <= 1'sb0;
		else if (addr_update)
			addr_last_q <= addr_last_d;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00: rdata_w_ext = data_rdata_i[31:0];
			2'b01: rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
			default: rdata_w_ext = data_rdata_i[31:0];
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
				else
					rdata_h_ext = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
				else
					rdata_h_ext = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
				else
					rdata_h_ext = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
			default: rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
				else
					rdata_b_ext = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[15:8]};
				else
					rdata_b_ext = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[23:16]};
				else
					rdata_b_ext = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[31:24]};
				else
					rdata_b_ext = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
			default: rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
			default: data_rdata_ext = rdata_w_ext;
		endcase
	end
	generate
		if (MemECC) begin : g_mem_rdata_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] data_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(data_rdata_i),
				.out_o(data_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_data_intg_dec(
				.data_i(data_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign data_intg_err = |ecc_err;
		end
		else begin : g_no_mem_data_ecc
			assign data_intg_err = 1'b0;
		end
	endgenerate
	assign split_misaligned_access = ((lsu_type_i == 2'b00) && (data_offset != 2'b00)) || ((lsu_type_i == 2'b01) && (data_offset == 2'b11));
	assign cpu_req_valid = lsu_req_i & ~((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & lsu_cheriot_err_i);
	assign cpu_req_erred = (lsu_req_i & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_cheriot_err_i;
	always @(*) begin
		if (_sv2v_0)
			;
		ls_fsm_ns = ls_fsm_cs;
		data_req_o = 1'b0;
		addr_incr_req_o = 1'b0;
		handle_misaligned_d = handle_misaligned_q;
		pmp_err_d = pmp_err_q;
		lsu_err_d = lsu_err_q;
		cheriot_err_d = cheriot_err_q & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
		addr_update = 1'b0;
		ctrl_update = 1'b0;
		rdata_update = 1'b0;
		perf_load_o = 1'b0;
		perf_store_o = 1'b0;
		lsu_go = 1'b0;
		lsu_go_goodcap = 1'b0;
		(* full_case, parallel_case *)
		case (ls_fsm_cs)
			4'd0: begin
				pmp_err_d = 1'b0;
				cheriot_err_d = 1'b0;
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & cpu_req_erred) begin
					data_req_o = 1'b0;
					cheriot_err_d = 1'b1;
					ctrl_update = 1'b1;
					addr_update = 1'b1;
					pmp_err_d = 1'b0;
					lsu_err_d = 1'b0;
					perf_load_o = 1'b0;
					lsu_go = 1'b1;
					ls_fsm_ns = 4'd0;
				end
				else if ((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & cpu_req_valid) & lsu_is_cap_i) begin
					data_req_o = 1'b1;
					cheriot_err_d = 1'b0;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					lsu_go = 1'b1;
					lsu_go_goodcap = 1'b1;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						ls_fsm_ns = 4'd6;
					end
					else
						ls_fsm_ns = 4'd5;
				end
				else if (cpu_req_valid) begin
					data_req_o = 1'b1;
					cheriot_err_d = 1'b0;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					lsu_go = 1'b1;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						handle_misaligned_d = split_misaligned_access;
						ls_fsm_ns = (split_misaligned_access ? 4'd2 : 4'd0);
					end
					else
						ls_fsm_ns = (split_misaligned_access ? 4'd1 : 4'd3);
				end
			end
			4'd1: begin
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					addr_update = 1'b1;
					ctrl_update = 1'b1;
					handle_misaligned_d = 1'b1;
					ls_fsm_ns = 4'd2;
				end
			end
			4'd2: begin
				data_req_o = 1'b1;
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i || pmp_err_q) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i | pmp_err_q;
					rdata_update = ~data_we_q;
					ls_fsm_ns = (data_gnt_i ? 4'd0 : 4'd3);
					addr_update = data_gnt_i & ~(data_bus_err_i | pmp_err_q);
					handle_misaligned_d = ~data_gnt_i;
				end
				else if (data_gnt_i) begin
					ls_fsm_ns = 4'd4;
					handle_misaligned_d = 1'b0;
				end
			end
			4'd3: begin
				addr_incr_req_o = handle_misaligned_q;
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					ctrl_update = 1'b1;
					addr_update = ~lsu_err_q;
					ls_fsm_ns = 4'd0;
					handle_misaligned_d = 1'b0;
				end
			end
			4'd4: begin
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i;
					addr_update = ~data_bus_err_i;
					rdata_update = ~data_we_q;
					ls_fsm_ns = 4'd0;
				end
			end
			4'd5:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b0;
					data_req_o = 1'b1;
					if (data_gnt_i) begin
						ls_fsm_ns = 4'd6;
						ctrl_update = 1'b1;
						addr_update = 1'b1;
					end
				end
				else
					ls_fsm_ns = 4'd0;
			4'd6:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b1;
					data_req_o = 1'b1;
					if (data_gnt_i && (data_rvalid_i || (cap_rx_fsm_q == 3'd2)))
						ls_fsm_ns = 4'd0;
					else if (data_gnt_i)
						ls_fsm_ns = 4'd7;
				end
				else
					ls_fsm_ns = 4'd0;
			4'd7:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b1;
					data_req_o = 1'b0;
					if (data_rvalid_i)
						ls_fsm_ns = 4'd0;
				end
				else
					ls_fsm_ns = 4'd0;
			default: ls_fsm_ns = 4'd0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		cap_rx_fsm_d = cap_rx_fsm_q;
		(* full_case, parallel_case *)
		case (cap_rx_fsm_q)
			3'd0:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_go_goodcap)
					cap_rx_fsm_d = 3'd1;
			3'd1:
				if (data_rvalid_i)
					cap_rx_fsm_d = 3'd2;
			3'd2:
				if (data_rvalid_i && lsu_go_goodcap)
					cap_rx_fsm_d = 3'd1;
				else if (data_rvalid_i)
					cap_rx_fsm_d = 3'd0;
			default: cap_rx_fsm_d = 3'd0;
		endcase
	end
	wire lsu_req_done;
	assign lsu_req_done = (lsu_go | (ls_fsm_cs != 4'd0)) & (ls_fsm_ns == 4'd0);
	assign lsu_req_done_o = lsu_req_done;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ls_fsm_cs <= 4'd0;
			handle_misaligned_q <= 1'sb0;
			pmp_err_q <= 1'sb0;
			lsu_err_q <= 1'sb0;
			resp_is_cap_q <= 1'b0;
			resp_lc_clrperm_q <= 1'sb0;
			cheriot_err_q <= 1'b0;
			cap_rx_fsm_q <= 3'd0;
			cap_lsw_err_q <= 1'b0;
			cap_lsw_data_q <= 1'sb0;
			cap_lsw_tag_q <= 1'b0;
		end
		else begin
			ls_fsm_cs <= ls_fsm_ns;
			handle_misaligned_q <= handle_misaligned_d;
			pmp_err_q <= pmp_err_d;
			lsu_err_q <= lsu_err_d;
			cheriot_err_q <= cheriot_err_d;
			cap_rx_fsm_q <= cap_rx_fsm_d;
			if (lsu_go) begin
				resp_is_cap_q <= lsu_is_cap_i;
				resp_lc_clrperm_q <= lsu_lc_clrperm_i;
			end
			if (((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && (cap_rx_fsm_q == 3'd1)) && data_rvalid_i) && ~data_we_q) begin
				cap_lsw_data_q <= data_rdata_i[31:0];
				cap_lsw_tag_q <= data_tag_i;
			end
			if ((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && (cap_rx_fsm_q == 3'd1)) && data_rvalid_i)
				cap_lsw_err_q <= data_bus_err_i;
		end
	wire all_resp;
	assign data_or_pmp_err = ((lsu_err_q | data_bus_err_i) | pmp_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & (cheriot_err_q | (resp_is_cap_q & cap_lsw_err_q)));
	assign all_resp = (data_rvalid_i | pmp_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_err_q);
	assign lsu_resp_valid_o = all_resp & (ls_fsm_cs == 4'd0);
	assign lsu_rdata_valid_o = ((((ls_fsm_cs == 4'd0) & data_rvalid_i) & ~data_or_pmp_err) & ~data_we_q) & ~data_intg_err;
	function automatic [5:0] sv2v_cast_4142A;
		input reg [5:0] inp;
		sv2v_cast_4142A = inp;
	endfunction
	function automatic [2:0] sv2v_cast_582E4;
		input reg [2:0] inp;
		sv2v_cast_582E4 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_9125C;
		input reg [3:0] inp;
		sv2v_cast_9125C = inp;
	endfunction
	function automatic [8:0] sv2v_cast_69C01;
		input reg [8:0] inp;
		sv2v_cast_69C01 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_4142A(1'sb0), sv2v_cast_582E4(1'sb0), sv2v_cast_9125C(1'sb0), sv2v_cast_69C01(1'sb0), sv2v_cast_69C01(1'sb0)};
	localparam [31:0] ibex_cheriot_pkg_BASE_LO = 0;
	localparam [31:0] ibex_cheriot_pkg_TOP_LO = ibex_cheriot_pkg_BASE_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_CEXP_LO = ibex_cheriot_pkg_TOP_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_LO = ibex_cheriot_pkg_CEXP_LO + ibex_cheriot_pkg_CEXP_W;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_LO = ibex_cheriot_pkg_OTYPE_LO + ibex_cheriot_pkg_OTYPE_W;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
	localparam [31:0] ibex_cheriot_pkg_RSVD_LO = ibex_cheriot_pkg_CPERMS_LO + ibex_cheriot_pkg_CPERMS_W;
	function automatic [1:0] ibex_cheriot_pkg_cheriot_compute_corrections;
		input reg [8:0] top;
		input reg [8:0] base;
		input reg [8:0] addr;
		reg top_hi;
		reg addr_hi;
		begin
			top_hi = top < base;
			addr_hi = addr < base;
			ibex_cheriot_pkg_cheriot_compute_corrections = {top_hi ^ addr_hi, addr_hi};
		end
	endfunction
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_mask_loaded_cperms;
		input reg [5:0] cperms_in;
		input reg [2:0] clrperm;
		input reg valid_in;
		input reg sealed;
		reg [5:0] cperms_out;
		reg clr_gl;
		reg clr_lg;
		reg clr_sdlm;
		reg unused_ctag;
		begin
			unused_ctag = clrperm[2];
			clr_gl = clrperm[0] & valid_in;
			clr_lg = (clrperm[0] & valid_in) & ~sealed;
			clr_sdlm = (clrperm[1] & valid_in) & ~sealed;
			cperms_out = cperms_in;
			cperms_out[5] = cperms_in[5] & ~clr_gl;
			if (cperms_in[4:3] == 2'b11) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
				cperms_out[4:2] = (clr_sdlm ? 3'b101 : cperms_in[4:2]);
			end
			else if (cperms_in[4:2] == 3'b101) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			else if (cperms_in[4:0] == 5'b10000)
				cperms_out[4:0] = (clr_sdlm ? 5'h00 : cperms_in[4:0]);
			else if (cperms_in[4:2] == 3'b100) begin
				cperms_out[4] = ~(clr_sdlm & ~cperms_in[1]);
				cperms_out[0] = cperms_in[0] & ~clr_sdlm;
			end
			else if (cperms_in[4:3] == 2'b01) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			ibex_cheriot_pkg_cheriot_mask_loaded_cperms = cperms_out;
		end
	endfunction
	function automatic [8:0] sv2v_cast_1CF2E;
		input reg [8:0] inp;
		sv2v_cast_1CF2E = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_mem_to_cap;
		input reg [32:0] cap_mw;
		input reg [32:0] addr33;
		input reg [2:0] clrperm;
		reg [34:0] cap;
		reg [4:0] exp5;
		reg [5:0] cperms_mem;
		reg [8:0] addrmi9;
		reg sealed;
		reg valid_in;
		begin
			valid_in = cap_mw[32] & addr33[32];
			cap[32] = valid_in & ~clrperm[2];
			cap[8-:ibex_cheriot_pkg_CBOUND_W] = cap_mw[ibex_cheriot_pkg_BASE_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[17-:9] = cap_mw[ibex_cheriot_pkg_TOP_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[21-:4] = cap_mw[ibex_cheriot_pkg_CEXP_LO+:ibex_cheriot_pkg_CEXP_W];
			cap[24-:3] = cap_mw[ibex_cheriot_pkg_OTYPE_LO+:ibex_cheriot_pkg_OTYPE_W];
			sealed = cap[24-:3] != ibex_cheriot_pkg_OTYPE_UNSEALED;
			cperms_mem = cap_mw[ibex_cheriot_pkg_CPERMS_LO+:ibex_cheriot_pkg_CPERMS_W];
			cap[30-:6] = ibex_cheriot_pkg_cheriot_mask_loaded_cperms(cperms_mem, clrperm, cap[32], sealed);
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			addrmi9 = sv2v_cast_1CF2E(addr33[31:0] >> exp5);
			cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(cap[17-:9], cap[8-:ibex_cheriot_pkg_CBOUND_W], addrmi9);
			cap[31] = cap_mw[ibex_cheriot_pkg_RSVD_LO];
			ibex_cheriot_pkg_cheriot_mem_to_cap = cap;
		end
	endfunction
	generate
		if (BaseIsa == 32'sd1) begin : gen_memcap_rd
			assign lsu_rdata_o = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & resp_is_cap_q ? cap_lsw_data_q : data_rdata_ext);
			assign lsu_rcap_o = (((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && resp_is_cap_q) && data_rvalid_i) && (cap_rx_fsm_q == 3'd2)) && ~data_or_pmp_err ? ibex_cheriot_pkg_cheriot_mem_to_cap({data_tag_i, data_rdata_i[31:0]}, {cap_lsw_tag_q, cap_lsw_data_q}, resp_lc_clrperm_q) : ibex_cheriot_pkg_NULL_CAP);
		end
		else begin : gen_no_cap_rd
			assign lsu_rdata_o = data_rdata_ext;
			assign lsu_rcap_o = ibex_cheriot_pkg_NULL_CAP;
			wire unused_cap_rd_sigs;
			assign unused_cap_rd_sigs = ^{resp_lc_clrperm_q, cap_lsw_data_q, cap_lsw_tag_q, data_tag_i};
		end
	endgenerate
	assign data_addr_w_aligned = {data_addr[31:2], 2'b00};
	assign data_addr_o = data_addr_w_aligned;
	assign data_we_o = lsu_we_i;
	assign data_be_o = data_be;
	generate
		if (MemECC) begin : g_mem_wdata_ecc
			prim_secded_inv_39_32_enc u_data_gen(
				.data_i(data_wdata_data),
				.data_o(data_wdata_o)
			);
		end
		else begin : g_no_mem_wdata_ecc
			assign data_wdata_o = data_wdata_data;
		end
	endgenerate
	assign data_tag_o = data_wdata_tag;
	assign addr_last_o = addr_last_q;
	assign load_err_o = (data_or_pmp_err & ~data_we_q) & lsu_resp_valid_o;
	assign store_err_o = (data_or_pmp_err & data_we_q) & lsu_resp_valid_o;
	assign load_resp_intg_err_o = (data_intg_err & data_rvalid_i) & ~data_we_q;
	assign store_resp_intg_err_o = (data_intg_err & data_rvalid_i) & data_we_q;
	assign lsu_err_is_cheriot_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_err_q;
	assign busy_o = ls_fsm_cs != 4'd0;
	initial _sv2v_0 = 0;
endmodule
module ibex_lockstep (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	cheriot_enable_i,
	instr_req_i,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_i,
	instr_rdata_i,
	instr_err_i,
	data_req_i,
	data_gnt_i,
	data_rvalid_i,
	data_we_i,
	data_be_i,
	data_addr_i,
	data_wdata_i,
	data_tag_i,
	data_rdata_i,
	data_rdata_tag_i,
	data_err_i,
	rf_rdata_a_i,
	rf_rdata_b_i,
	rf_wcap_wb_i,
	rf_rcap_a_i,
	rf_rcap_b_i,
	ic_tag_req_i,
	ic_tag_write_i,
	ic_tag_addr_i,
	ic_tag_wdata_i,
	ic_tag_rdata_i,
	ic_data_req_i,
	ic_data_write_i,
	ic_data_addr_i,
	ic_data_wdata_i,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_i,
	debug_req_i,
	crash_dump_i,
	double_fault_seen_i,
	fetch_enable_i,
	mcounteren_writable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_i,
	test_en_i,
	scan_rst_ni,
	lockstep_cmp_en_o,
	data_req_shadow_o,
	data_we_shadow_o,
	data_be_shadow_o,
	data_addr_shadow_o,
	data_wdata_shadow_o,
	data_wdata_intg_shadow_o,
	instr_req_shadow_o,
	instr_addr_shadow_o
);
	parameter integer BaseIsa = 32'sd0;
	parameter [31:0] LockstepOffset = 1;
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RV32ZC = 32'sd3;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ICacheTweakInfection = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	parameter [31:0] RegFileDataEccWidth = 39;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	parameter [31:0] RegFileCapEccWidth = 42;
	parameter integer RegFile = 32'sd0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire instr_req_i;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_addr_i;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	input wire data_req_i;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_we_i;
	input wire [3:0] data_be_i;
	input wire [31:0] data_addr_i;
	input wire [31:0] data_wdata_i;
	input wire data_tag_i;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_rdata_tag_i;
	input wire data_err_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] rf_wcap_wb_i;
	input wire [34:0] rf_rcap_a_i;
	input wire [34:0] rf_rcap_b_i;
	input wire [1:0] ic_tag_req_i;
	input wire ic_tag_write_i;
	input wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_i;
	input wire [TagSizeECC - 1:0] ic_tag_wdata_i;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	input wire [1:0] ic_data_req_i;
	input wire ic_data_write_i;
	input wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_i;
	input wire [LineSizeECC - 1:0] ic_data_wdata_i;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	input wire ic_scr_key_req_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire irq_pending_i;
	input wire debug_req_i;
	input wire [159:0] crash_dump_i;
	input wire double_fault_seen_i;
	input wire [3:0] fetch_enable_i;
	input wire [3:0] mcounteren_writable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	input wire [3:0] core_busy_i;
	input wire test_en_i;
	input wire scan_rst_ni;
	output wire [3:0] lockstep_cmp_en_o;
	output wire data_req_shadow_o;
	output wire data_we_shadow_o;
	output wire [3:0] data_be_shadow_o;
	output wire [31:0] data_addr_shadow_o;
	output wire [31:0] data_wdata_shadow_o;
	output wire [6:0] data_wdata_intg_shadow_o;
	output wire instr_req_shadow_o;
	output wire [31:0] instr_addr_shadow_o;
	function automatic integer prim_util_pkg_vbits;
		input integer value;
		prim_util_pkg_vbits = (value == 1 ? 1 : $clog2(value));
	endfunction
	localparam [31:0] LockstepOffsetW = prim_util_pkg_vbits(LockstepOffset);
	localparam [31:0] OutputsOffset = LockstepOffset + 1;
	wire rst_shadow_cnt_err;
	wire [3:0] rst_shadow_set_d;
	wire [3:0] rst_shadow_set_q;
	wire rst_shadow_n;
	reg [3:0] enable_cmp_d;
	wire [3:0] enable_cmp_q;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	function automatic [LockstepOffsetW - 1:0] sv2v_cast_5A7C9;
		input reg [LockstepOffsetW - 1:0] inp;
		sv2v_cast_5A7C9 = inp;
	endfunction
	generate
		if (LockstepOffset > 1) begin : gen_reset_counter
			wire [LockstepOffsetW - 1:0] rst_shadow_cnt;
			localparam signed [31:0] sv2v_uu_u_rst_shadow_cnt_Width = LockstepOffsetW;
			localparam [sv2v_uu_u_rst_shadow_cnt_Width - 1:0] sv2v_uu_u_rst_shadow_cnt_ext_set_cnt_i_0 = 1'sb0;
			prim_count #(
				.Width(LockstepOffsetW),
				.ResetValue(sv2v_cast_5A7C9(1'b0))
			) u_rst_shadow_cnt(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clr_i(1'b0),
				.set_i(1'b0),
				.set_cnt_i(sv2v_uu_u_rst_shadow_cnt_ext_set_cnt_i_0),
				.incr_en_i(1'b1),
				.decr_en_i(1'b0),
				.step_i(sv2v_cast_5A7C9(1'b1)),
				.commit_i(1'b1),
				.cnt_o(rst_shadow_cnt),
				.cnt_after_commit_o(),
				.err_o(rst_shadow_cnt_err)
			);
			assign rst_shadow_set_d = (rst_shadow_cnt >= sv2v_cast_5A7C9(LockstepOffset - 1) ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
			wire [4:1] sv2v_tmp_62DA3;
			assign sv2v_tmp_62DA3 = rst_shadow_set_q;
			always @(*) enable_cmp_d = sv2v_tmp_62DA3;
		end
		else begin : gen_no_reset_counter
			assign rst_shadow_set_d = ibex_pkg_IbexMuBiOn;
			assign rst_shadow_cnt_err = 1'b0;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					enable_cmp_d <= ibex_pkg_IbexMuBiOff;
				else
					enable_cmp_d <= ibex_pkg_IbexMuBiOn;
			wire [2:0] unused_bits;
			assign unused_bits = rst_shadow_set_q[3:1];
		end
	endgenerate
	prim_flop #(
		.Width(ibex_pkg_IbexMuBiWidth),
		.ResetValue(ibex_pkg_IbexMuBiOff)
	) u_prim_rst_shadow_set_flop(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(rst_shadow_set_d),
		.q_o(rst_shadow_set_q)
	);
	prim_flop #(
		.Width(ibex_pkg_IbexMuBiWidth),
		.ResetValue(ibex_pkg_IbexMuBiOff)
	) u_prim_enable_cmp_flop(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(enable_cmp_d),
		.q_o(enable_cmp_q)
	);
	prim_clock_mux2 #(.NoFpgaBufG(1'b1)) u_prim_rst_shadow_n_mux2(
		.clk0_i(rst_shadow_set_q[0]),
		.clk1_i(scan_rst_ni),
		.sel_i(test_en_i),
		.clk_o(rst_shadow_n)
	);
	reg [(LockstepOffset * ((((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70)) - 1:0] shadow_inputs_q;
	wire [(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 69:0] shadow_inputs_in;
	wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] shadow_tag_rdata_delayed;
	wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] shadow_data_rdata_delayed;
	function automatic [(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 69:0] sv2v_cast_191E1;
		input reg [(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 69:0] inp;
		sv2v_cast_191E1 = inp;
	endfunction
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	generate
		if (LockstepOffset > 1) begin : gen_multi_cycle_delay
			reg [(LockstepOffset * TagSizeECC) - 1:0] shadow_tag_rdata_q [0:1];
			reg [(LockstepOffset * LineSizeECC) - 1:0] shadow_data_rdata_q [0:1];
			assign shadow_tag_rdata_delayed = shadow_tag_rdata_q[0];
			assign shadow_data_rdata_delayed = shadow_data_rdata_q[0];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin : sv2v_autoblock_1
					reg [31:0] i;
					for (i = 0; i < LockstepOffset; i = i + 1)
						begin
							shadow_inputs_q[i * ((((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70)+:(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70] <= sv2v_cast_191E1(1'sb0);
							shadow_tag_rdata_q[i] <= {LockstepOffset {sv2v_cast_0CBAD(0)}};
							shadow_data_rdata_q[i] <= {LockstepOffset {sv2v_cast_033B0(0)}};
						end
				end
				else begin
					begin : sv2v_autoblock_2
						reg [31:0] i;
						for (i = 0; i < (LockstepOffset - 1); i = i + 1)
							begin
								shadow_inputs_q[i * ((((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70)+:(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70] <= shadow_inputs_q[(i + 1) * ((((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70)+:(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70];
								shadow_tag_rdata_q[i] <= shadow_tag_rdata_q[i + 1];
								shadow_data_rdata_q[i] <= shadow_data_rdata_q[i + 1];
							end
					end
					shadow_inputs_q[(LockstepOffset - 1) * ((((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70)+:(((((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + 1) + ibex_pkg_IbexMuBiWidth) + 70] <= shadow_inputs_in;
					shadow_tag_rdata_q[LockstepOffset - 1] <= ic_tag_rdata_i;
					shadow_data_rdata_q[LockstepOffset - 1] <= ic_data_rdata_i;
				end
		end
		else begin : gen_single_cycle_delay
			reg [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] shadow_tag_rdata_q;
			reg [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] shadow_data_rdata_q;
			assign shadow_tag_rdata_delayed = shadow_tag_rdata_q;
			assign shadow_data_rdata_delayed = shadow_data_rdata_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					shadow_inputs_q <= sv2v_cast_191E1(1'sb0);
					shadow_tag_rdata_q <= {ibex_pkg_IC_NUM_WAYS {sv2v_cast_0CBAD(0)}};
					shadow_data_rdata_q <= {ibex_pkg_IC_NUM_WAYS {sv2v_cast_033B0(0)}};
				end
				else begin
					shadow_inputs_q <= shadow_inputs_in;
					shadow_tag_rdata_q <= ic_tag_rdata_i;
					shadow_data_rdata_q <= ic_data_rdata_i;
				end
		end
	endgenerate
	assign shadow_inputs_in[2 + (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))] = instr_gnt_i;
	assign shadow_inputs_in[1 + (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))] = instr_rvalid_i;
	assign shadow_inputs_in[MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))))-:((MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))))) >= (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103))))) ? ((MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))))) - (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103)))))) + 1 : ((3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103))))) - (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))) + 1)] = instr_rdata_i;
	assign shadow_inputs_in[3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))] = instr_err_i;
	assign shadow_inputs_in[2 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))] = data_gnt_i;
	assign shadow_inputs_in[1 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))] = data_rvalid_i;
	assign shadow_inputs_in[MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))-:((MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))) >= (2 + (RegFileDataWidth + (RegFileDataWidth + 103))) ? ((MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))) - (2 + (RegFileDataWidth + (RegFileDataWidth + 103)))) + 1 : ((2 + (RegFileDataWidth + (RegFileDataWidth + 103))) - (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))) + 1)] = data_rdata_i;
	assign shadow_inputs_in[2 + (RegFileDataWidth + (RegFileDataWidth + 102))] = data_rdata_tag_i;
	assign shadow_inputs_in[1 + (RegFileDataWidth + (RegFileDataWidth + 102))] = data_err_i;
	assign shadow_inputs_in[RegFileDataWidth + (RegFileDataWidth + 102)-:((RegFileDataWidth + (RegFileDataWidth + 102)) >= (RegFileDataWidth + 103) ? ((RegFileDataWidth + (RegFileDataWidth + 102)) - (RegFileDataWidth + 103)) + 1 : ((RegFileDataWidth + 103) - (RegFileDataWidth + (RegFileDataWidth + 102))) + 1)] = rf_rdata_a_i;
	assign shadow_inputs_in[RegFileDataWidth + 102-:((RegFileDataWidth + 102) >= 103 ? RegFileDataWidth : 104 - (RegFileDataWidth + 102))] = rf_rdata_b_i;
	assign shadow_inputs_in[102] = irq_software_i;
	assign shadow_inputs_in[101] = irq_timer_i;
	assign shadow_inputs_in[100] = irq_external_i;
	assign shadow_inputs_in[99-:15] = irq_fast_i;
	assign shadow_inputs_in[84] = irq_nm_i;
	assign shadow_inputs_in[83] = debug_req_i;
	assign shadow_inputs_in[82-:4] = fetch_enable_i;
	assign shadow_inputs_in[78-:4] = mcounteren_writable_i;
	assign shadow_inputs_in[74] = ic_scr_key_valid_i;
	assign shadow_inputs_in[73-:4] = cheriot_enable_i;
	assign shadow_inputs_in[69-:35] = rf_rcap_a_i;
	assign shadow_inputs_in[34-:35] = rf_rcap_b_i;
	reg [(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? (OutputsOffset * (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35)) - 1 : (OutputsOffset * (1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34))) + (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 33)):(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? 0 : ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34)] core_outputs_q;
	wire [((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34:0] core_outputs_in;
	wire [((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34:0] shadow_outputs_d;
	reg [((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34:0] shadow_outputs_q;
	assign core_outputs_in[104 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))] = instr_req_i;
	assign core_outputs_in[103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((106 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (74 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)] = instr_addr_i;
	assign core_outputs_in[71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))] = data_req_i;
	assign core_outputs_in[70 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))] = data_we_i;
	assign core_outputs_in[69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((72 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)] = data_be_i;
	assign core_outputs_in[65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)] = data_addr_i;
	assign core_outputs_in[33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (4 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)] = data_wdata_i;
	assign core_outputs_in[1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))] = data_tag_i;
	assign core_outputs_in[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))-:((3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))) - (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) + 1)] = ic_tag_req_i;
	assign core_outputs_in[1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))] = ic_tag_write_i;
	assign core_outputs_in[ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))-:((ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) >= (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) ? ((ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) + 1 : ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))) - (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))) + 1)] = ic_tag_addr_i;
	assign core_outputs_in[TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))-:((TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))) >= (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) ? ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) + 1)] = ic_tag_wdata_i;
	assign core_outputs_in[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))-:((3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))) >= (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))) - (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) + 1)] = ic_data_req_i;
	assign core_outputs_in[1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))] = ic_data_write_i;
	assign core_outputs_in[ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)-:((ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)) >= (LineSizeECC + 202) ? ((ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)) - (LineSizeECC + 202)) + 1 : ((LineSizeECC + 202) - (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))) + 1)] = ic_data_addr_i;
	assign core_outputs_in[LineSizeECC + 201-:((LineSizeECC + 201) >= 202 ? LineSizeECC : 203 - (LineSizeECC + 201))] = ic_data_wdata_i;
	assign core_outputs_in[201] = ic_scr_key_req_i;
	assign core_outputs_in[200] = irq_pending_i;
	assign core_outputs_in[199-:160] = crash_dump_i;
	assign core_outputs_in[39] = double_fault_seen_i;
	assign core_outputs_in[38-:4] = core_busy_i;
	assign core_outputs_in[34-:35] = rf_wcap_wb_i;
	always @(posedge clk_i) begin
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = 0; i < (OutputsOffset - 1); i = i + 1)
				core_outputs_q[(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? 0 : ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34) + (i * (((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34)))+:(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34))] <= core_outputs_q[(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? 0 : ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34) + ((i + 1) * (((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34)))+:(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34))];
		end
		core_outputs_q[(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? 0 : ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34) + ((OutputsOffset - 1) * (((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34)))+:(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34))] <= core_outputs_in;
	end
	wire [RegFileDataEccWidth - 1:0] shadow_rf_wdata_wb_ecc;
	wire [4:0] shadow_rf_raddr_a;
	wire [4:0] shadow_rf_raddr_b;
	wire [4:0] shadow_rf_waddr_wb;
	wire shadow_rf_we_wb;
	wire shadow_dummy_instr_id;
	wire shadow_dummy_instr_wb;
	wire [6:0] shadow_data_wdata_intg;
	wire [MemDataWidth - 1:0] shadow_data_wdata_full;
	wire shadow_alert_minor;
	wire shadow_alert_major_internal;
	wire shadow_alert_major_bus;
	wire [(RegFileDataEccWidth - RegFileDataWidth) - 1:0] shadow_rf_rdata_a_intg;
	wire [(RegFileDataEccWidth - RegFileDataWidth) - 1:0] shadow_rf_rdata_b_intg;
	wire [RegFileCapEccWidth - 1:0] shadow_rf_wcap_ecc_wb;
	wire [6:0] shadow_rf_rcap_a_ecc;
	wire [6:0] shadow_rf_rcap_b_ecc;
	function automatic [34:0] sv2v_cast_4FBCE;
		input reg [34:0] inp;
		sv2v_cast_4FBCE = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_regcap_to_vec;
		input reg [34:0] cap;
		ibex_cheriot_pkg_cheriot_regcap_to_vec = sv2v_cast_4FBCE(cap);
	endfunction
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.RV32ZC(RV32ZC),
		.BranchTargetALU(BranchTargetALU),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.ICacheTweakInfection(ICacheTweakInfection),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.BranchPredictor(BranchPredictor),
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.WritebackStage(WritebackStage),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.SecureIbex(SecureIbex),
		.DummyInstructions(DummyInstructions),
		.RegFileECC(RegFileECC),
		.RegFileDataWidth(RegFileDataEccWidth),
		.RegFileCapEccWidth(RegFileCapEccWidth),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.DmBaseAddr(DmBaseAddr),
		.DmAddrMask(DmAddrMask),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.CsrMvendorId(CsrMvendorId),
		.CsrMimpId(CsrMimpId),
		.BaseIsa(BaseIsa)
	) u_shadow_core(
		.clk_i(clk_i),
		.rst_ni(rst_shadow_n),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.cheriot_enable_i(shadow_inputs_q[73-:4]),
		.instr_req_o(shadow_outputs_d[104 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))]),
		.instr_gnt_i(shadow_inputs_q[2 + (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))]),
		.instr_rvalid_i(shadow_inputs_q[1 + (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))]),
		.instr_addr_o(shadow_outputs_d[103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((106 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (74 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)]),
		.instr_rdata_i(shadow_inputs_q[0 + (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))-:((MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))))) >= (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103))))) ? ((MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))))) - (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103)))))) + 1 : ((3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 103))))) - (MemDataWidth + (3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))))) + 1)]),
		.instr_err_i(shadow_inputs_q[3 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))]),
		.data_req_o(shadow_outputs_d[71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))]),
		.data_gnt_i(shadow_inputs_q[2 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))]),
		.data_rvalid_i(shadow_inputs_q[1 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))]),
		.data_we_o(shadow_outputs_d[70 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))]),
		.data_be_o(shadow_outputs_d[69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((72 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)]),
		.data_addr_o(shadow_outputs_d[65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)]),
		.data_wdata_o(shadow_data_wdata_full),
		.data_tag_o(shadow_outputs_d[1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))]),
		.data_rdata_i(shadow_inputs_q[0 + (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))-:((MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))) >= (2 + (RegFileDataWidth + (RegFileDataWidth + 103))) ? ((MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102)))) - (2 + (RegFileDataWidth + (RegFileDataWidth + 103)))) + 1 : ((2 + (RegFileDataWidth + (RegFileDataWidth + 103))) - (MemDataWidth + (2 + (RegFileDataWidth + (RegFileDataWidth + 102))))) + 1)]),
		.data_tag_i(shadow_inputs_q[2 + (RegFileDataWidth + (RegFileDataWidth + 102))]),
		.data_err_i(shadow_inputs_q[1 + (RegFileDataWidth + (RegFileDataWidth + 102))]),
		.dummy_instr_id_o(shadow_dummy_instr_id),
		.dummy_instr_wb_o(shadow_dummy_instr_wb),
		.rf_raddr_a_o(shadow_rf_raddr_a),
		.rf_raddr_b_o(shadow_rf_raddr_b),
		.rf_waddr_wb_o(shadow_rf_waddr_wb),
		.rf_we_wb_o(shadow_rf_we_wb),
		.rf_wdata_wb_ecc_o(shadow_rf_wdata_wb_ecc),
		.rf_rdata_a_ecc_i({shadow_rf_rdata_a_intg, shadow_inputs_q[0 + (RegFileDataWidth + (RegFileDataWidth + 102))-:((RegFileDataWidth + (RegFileDataWidth + 102)) >= (RegFileDataWidth + 103) ? ((RegFileDataWidth + (RegFileDataWidth + 102)) - (RegFileDataWidth + 103)) + 1 : ((RegFileDataWidth + 103) - (RegFileDataWidth + (RegFileDataWidth + 102))) + 1)]}),
		.rf_rdata_b_ecc_i({shadow_rf_rdata_b_intg, shadow_inputs_q[0 + (RegFileDataWidth + 102)-:((RegFileDataWidth + 102) >= 103 ? RegFileDataWidth : 104 - (RegFileDataWidth + 102))]}),
		.rf_wcap_ecc_wb_o(shadow_rf_wcap_ecc_wb),
		.rf_rcap_a_ecc_i({shadow_rf_rcap_a_ecc, ibex_cheriot_pkg_cheriot_regcap_to_vec(shadow_inputs_q[69-:35])}),
		.rf_rcap_b_ecc_i({shadow_rf_rcap_b_ecc, ibex_cheriot_pkg_cheriot_regcap_to_vec(shadow_inputs_q[34-:35])}),
		.ic_tag_req_o(shadow_outputs_d[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))-:((3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))) - (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) + 1)]),
		.ic_tag_write_o(shadow_outputs_d[1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))]),
		.ic_tag_addr_o(shadow_outputs_d[ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))-:((ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) >= (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) ? ((ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) + 1 : ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))) - (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))) + 1)]),
		.ic_tag_wdata_o(shadow_outputs_d[TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))-:((TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))) >= (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) ? ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) + 1)]),
		.ic_tag_rdata_i(shadow_tag_rdata_delayed),
		.ic_data_req_o(shadow_outputs_d[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))-:((3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))) >= (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))) - (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))) + 1)]),
		.ic_data_write_o(shadow_outputs_d[1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))]),
		.ic_data_addr_o(shadow_outputs_d[ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)-:((ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)) >= (LineSizeECC + 202) ? ((ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)) - (LineSizeECC + 202)) + 1 : ((LineSizeECC + 202) - (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))) + 1)]),
		.ic_data_wdata_o(shadow_outputs_d[LineSizeECC + 201-:((LineSizeECC + 201) >= 202 ? LineSizeECC : 203 - (LineSizeECC + 201))]),
		.ic_data_rdata_i(shadow_data_rdata_delayed),
		.ic_scr_key_valid_i(shadow_inputs_q[74]),
		.ic_scr_key_req_o(shadow_outputs_d[201]),
		.irq_software_i(shadow_inputs_q[102]),
		.irq_timer_i(shadow_inputs_q[101]),
		.irq_external_i(shadow_inputs_q[100]),
		.irq_fast_i(shadow_inputs_q[99-:15]),
		.irq_nm_i(shadow_inputs_q[84]),
		.irq_pending_o(shadow_outputs_d[200]),
		.debug_req_i(shadow_inputs_q[83]),
		.crash_dump_o(shadow_outputs_d[199-:160]),
		.double_fault_seen_o(shadow_outputs_d[39]),
		.fetch_enable_i(shadow_inputs_q[82-:4]),
		.mcounteren_writable_i(shadow_inputs_q[78-:4]),
		.alert_minor_o(shadow_alert_minor),
		.alert_major_internal_o(shadow_alert_major_internal),
		.alert_major_bus_o(shadow_alert_major_bus),
		.core_busy_o(shadow_outputs_d[38-:4])
	);
	function automatic [34:0] sv2v_cast_F2778;
		input reg [34:0] inp;
		sv2v_cast_F2778 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_vec_to_regcap;
		input reg [34:0] vec_in;
		ibex_cheriot_pkg_cheriot_vec_to_regcap = sv2v_cast_F2778(vec_in);
	endfunction
	assign shadow_outputs_d[34-:35] = ibex_cheriot_pkg_cheriot_vec_to_regcap(shadow_rf_wcap_ecc_wb[34:0]);
	assign shadow_outputs_d[33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (4 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)] = shadow_data_wdata_full[31:0];
	generate
		if (MemECC) begin : gen_shadow_wdata_ecc
			assign shadow_data_wdata_intg = shadow_data_wdata_full[MemDataWidth - 1:32];
		end
		else begin : gen_shadow_wdata_no_ecc
			assign shadow_data_wdata_intg = 1'sb0;
		end
	endgenerate
	always @(posedge clk_i) shadow_outputs_q <= shadow_outputs_d;
	wire [RegFileDataWidth - 1:0] unused_shadow_rf_wdata_wb_ecc;
	assign unused_shadow_rf_wdata_wb_ecc = shadow_rf_wdata_wb_ecc[RegFileDataWidth - 1:0];
	localparam [38:0] prim_secded_pkg_SecdedInv3932ZeroWord = 39'h2a00000000;
	localparam [6:0] prim_secded_pkg_SecdedInv6457ZeroEcc = 7'h2a;
	generate
		if (RegFile == 32'sd0) begin : gen_shadow_regfile_ff
			ibex_register_file_ff #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataEccWidth - RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(prim_secded_pkg_SecdedInv3932ZeroWord[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.CapWidth(7),
				.CapWordZeroVal(prim_secded_pkg_SecdedInv6457ZeroEcc)
			) register_file_shadow_i(
				.clk_i(clk_i),
				.rst_ni(rst_shadow_n),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(shadow_dummy_instr_id),
				.dummy_instr_wb_i(shadow_dummy_instr_wb),
				.cheriot_enable_i(shadow_inputs_q[73-:4]),
				.raddr_a_i(shadow_rf_raddr_a),
				.rdata_a_o(shadow_rf_rdata_a_intg),
				.rcap_a_o(shadow_rf_rcap_a_ecc),
				.raddr_b_i(shadow_rf_raddr_b),
				.rdata_b_o(shadow_rf_rdata_b_intg),
				.rcap_b_o(shadow_rf_rcap_b_ecc),
				.waddr_a_i(shadow_rf_waddr_wb),
				.wdata_a_i(shadow_rf_wdata_wb_ecc[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.wcap_a_i(shadow_rf_wcap_ecc_wb[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W]),
				.we_a_i(shadow_rf_we_wb)
			);
		end
		else if (RegFile == 32'sd1) begin : gen_regfile_fpga
			ibex_register_file_fpga #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataEccWidth - RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(prim_secded_pkg_SecdedInv3932ZeroWord[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.CapWidth(7),
				.CapWordZeroVal(prim_secded_pkg_SecdedInv6457ZeroEcc)
			) register_file_shadow_i(
				.clk_i(clk_i),
				.rst_ni(rst_shadow_n),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(shadow_dummy_instr_id),
				.dummy_instr_wb_i(shadow_dummy_instr_wb),
				.cheriot_enable_i(shadow_inputs_q[73-:4]),
				.raddr_a_i(shadow_rf_raddr_a),
				.rdata_a_o(shadow_rf_rdata_a_intg),
				.rcap_a_o(shadow_rf_rcap_a_ecc),
				.raddr_b_i(shadow_rf_raddr_b),
				.rdata_b_o(shadow_rf_rdata_b_intg),
				.rcap_b_o(shadow_rf_rcap_b_ecc),
				.waddr_a_i(shadow_rf_waddr_wb),
				.wdata_a_i(shadow_rf_wdata_wb_ecc[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.wcap_a_i(shadow_rf_wcap_ecc_wb[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W]),
				.we_a_i(shadow_rf_we_wb)
			);
		end
		else if (RegFile == 32'sd2) begin : gen_regfile_latch
			ibex_register_file_latch #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataEccWidth - RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(prim_secded_pkg_SecdedInv3932ZeroWord[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.CapWidth(7),
				.CapWordZeroVal(prim_secded_pkg_SecdedInv6457ZeroEcc)
			) register_file_shadow_i(
				.clk_i(clk_i),
				.rst_ni(rst_shadow_n),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(shadow_dummy_instr_id),
				.dummy_instr_wb_i(shadow_dummy_instr_wb),
				.cheriot_enable_i(shadow_inputs_q[73-:4]),
				.raddr_a_i(shadow_rf_raddr_a),
				.rdata_a_o(shadow_rf_rdata_a_intg),
				.rcap_a_o(shadow_rf_rcap_a_ecc),
				.raddr_b_i(shadow_rf_raddr_b),
				.rdata_b_o(shadow_rf_rdata_b_intg),
				.rcap_b_o(shadow_rf_rcap_b_ecc),
				.waddr_a_i(shadow_rf_waddr_wb),
				.wdata_a_i(shadow_rf_wdata_wb_ecc[RegFileDataEccWidth - 1:RegFileDataWidth]),
				.wcap_a_i(shadow_rf_wcap_ecc_wb[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W]),
				.we_a_i(shadow_rf_we_wb)
			);
		end
	endgenerate
	wire outputs_mismatch;
	assign outputs_mismatch = (enable_cmp_q != ibex_pkg_IbexMuBiOff) & (shadow_outputs_q != core_outputs_q[(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? 0 : ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34) + 0+:(((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + 3) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 201) >= 0 ? ((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 35 : 1 - (((((((((107 + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) + 34))]);
	assign alert_major_internal_o = (outputs_mismatch | shadow_alert_major_internal) | rst_shadow_cnt_err;
	assign alert_major_bus_o = shadow_alert_major_bus;
	assign alert_minor_o = shadow_alert_minor;
	assign lockstep_cmp_en_o = enable_cmp_q;
	assign data_req_shadow_o = shadow_outputs_d[71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))];
	assign data_we_shadow_o = shadow_outputs_d[70 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))];
	assign data_be_shadow_o = shadow_outputs_d[69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((72 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (69 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)];
	assign data_addr_shadow_o = shadow_outputs_d[65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((68 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (65 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)];
	assign data_wdata_shadow_o = shadow_outputs_d[33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((36 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (4 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((1 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (33 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)];
	assign data_wdata_intg_shadow_o = shadow_data_wdata_intg;
	assign instr_req_shadow_o = shadow_outputs_d[104 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))];
	assign instr_addr_shadow_o = shadow_outputs_d[103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))-:((106 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))) >= (74 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))) ? ((103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201))))))))) - (71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202)))))))))) + 1 : ((71 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 202))))))))) - (103 + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 201)))))))))) + 1)];
endmodule
module ibex_multdiv_fast (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	parameter integer RV32M = 32'sd2;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	wire signed [34:0] mac_res_signed;
	wire [34:0] mac_res_ext;
	reg [33:0] accum;
	reg sign_a;
	reg sign_b;
	reg mult_valid;
	wire signed_mult;
	reg [33:0] mac_res_d;
	reg [33:0] op_remainder_d;
	wire [33:0] mac_res;
	wire div_sign_a;
	wire div_sign_b;
	reg is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	wire [31:0] one_shift;
	wire [31:0] op_denominator_q;
	reg [31:0] op_numerator_q;
	reg [31:0] op_quotient_q;
	reg [31:0] op_denominator_d;
	reg [31:0] op_numerator_d;
	reg [31:0] op_quotient_d;
	wire [31:0] next_remainder;
	wire [32:0] next_quotient;
	wire [31:0] res_adder_h;
	reg div_valid;
	reg [4:0] div_counter_q;
	reg [4:0] div_counter_d;
	wire multdiv_en;
	reg mult_hold;
	reg div_hold;
	reg div_by_zero_d;
	reg div_by_zero_q;
	wire mult_en_internal;
	wire div_en_internal;
	wire sva_mul_fsm_idle;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire unused_mult_sel_i;
	assign unused_mult_sel_i = mult_sel_i;
	assign mult_en_internal = mult_en_i & ~mult_hold;
	assign div_en_internal = div_en_i & ~div_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			div_counter_q <= 1'sb0;
			md_state_q <= 3'd0;
			op_numerator_q <= 1'sb0;
			op_quotient_q <= 1'sb0;
			div_by_zero_q <= 1'sb0;
		end
		else if (div_en_internal) begin
			div_counter_q <= div_counter_d;
			op_numerator_q <= op_numerator_d;
			op_quotient_q <= op_quotient_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign multdiv_en = mult_en_internal | div_en_internal;
	assign imd_val_d_o[34+:34] = (div_sel_i ? op_remainder_d : mac_res_d);
	assign imd_val_we_o[0] = multdiv_en;
	assign imd_val_d_o[0+:34] = {2'b00, op_denominator_d};
	assign imd_val_we_o[1] = div_en_internal;
	assign op_denominator_q = imd_val_q_i[31-:32];
	wire [1:0] unused_imd_val;
	assign unused_imd_val = imd_val_q_i[33-:2];
	wire unused_mac_res_ext;
	assign unused_mac_res_ext = mac_res_ext[34];
	assign signed_mult = signed_mode_i != 2'b00;
	assign multdiv_result_o = (div_sel_i ? imd_val_q_i[65-:32] : mac_res_d[31:0]);
	generate
		if (RV32M == 32'sd3) begin : gen_mult_single_cycle
			reg mult_state_q;
			reg mult_state_d;
			wire signed [33:0] mult1_res;
			wire signed [33:0] mult2_res;
			wire signed [33:0] mult3_res;
			wire [33:0] mult1_res_uns;
			wire [33:32] unused_mult1_res_uns;
			wire [15:0] mult1_op_a;
			wire [15:0] mult1_op_b;
			wire [15:0] mult2_op_a;
			wire [15:0] mult2_op_b;
			reg [15:0] mult3_op_a;
			reg [15:0] mult3_op_b;
			wire mult1_sign_a;
			wire mult1_sign_b;
			wire mult2_sign_a;
			wire mult2_sign_b;
			reg mult3_sign_a;
			reg mult3_sign_b;
			reg [33:0] summand1;
			reg [33:0] summand2;
			reg [33:0] summand3;
			assign mult1_res = $signed({mult1_sign_a, mult1_op_a}) * $signed({mult1_sign_b, mult1_op_b});
			assign mult2_res = $signed({mult2_sign_a, mult2_op_a}) * $signed({mult2_sign_b, mult2_op_b});
			assign mult3_res = $signed({mult3_sign_a, mult3_op_a}) * $signed({mult3_sign_b, mult3_op_b});
			assign mac_res_signed = ($signed(summand1) + $signed(summand2)) + $signed(summand3);
			assign mult1_res_uns = $unsigned(mult1_res);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			wire [1:1] sv2v_tmp_5ADA8;
			assign sv2v_tmp_5ADA8 = signed_mode_i[0] & op_a_i[31];
			always @(*) sign_a = sv2v_tmp_5ADA8;
			wire [1:1] sv2v_tmp_C5449;
			assign sv2v_tmp_C5449 = signed_mode_i[1] & op_b_i[31];
			always @(*) sign_b = sv2v_tmp_C5449;
			assign mult1_sign_a = 1'b0;
			assign mult1_sign_b = 1'b0;
			assign mult1_op_a = op_a_i[15:0];
			assign mult1_op_b = op_b_i[15:0];
			assign mult2_sign_a = 1'b0;
			assign mult2_sign_b = sign_b;
			assign mult2_op_a = op_a_i[15:0];
			assign mult2_op_b = op_b_i[31:16];
			wire [18:1] sv2v_tmp_6FF3F;
			assign sv2v_tmp_6FF3F = imd_val_q_i[67-:18];
			always @(*) accum[17:0] = sv2v_tmp_6FF3F;
			wire [16:1] sv2v_tmp_A7770;
			assign sv2v_tmp_A7770 = {16 {signed_mult & imd_val_q_i[67]}};
			always @(*) accum[33:18] = sv2v_tmp_A7770;
			always @(*) begin
				if (_sv2v_0)
					;
				mult3_sign_a = sign_a;
				mult3_sign_b = 1'b0;
				mult3_op_a = op_a_i[31:16];
				mult3_op_b = op_b_i[15:0];
				summand1 = {18'h00000, mult1_res_uns[31:16]};
				summand2 = $unsigned(mult2_res);
				summand3 = $unsigned(mult3_res);
				mac_res_d = {2'b00, mac_res[15:0], mult1_res_uns[15:0]};
				mult_valid = mult_en_i;
				mult_state_d = 1'd0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					1'd0:
						if (operator_i != 2'd0) begin
							mac_res_d = mac_res;
							mult_valid = 1'b0;
							mult_state_d = 1'd1;
						end
						else
							mult_hold = ~multdiv_ready_id_i;
					1'd1: begin
						mult3_sign_a = sign_a;
						mult3_sign_b = sign_b;
						mult3_op_a = op_a_i[31:16];
						mult3_op_b = op_b_i[31:16];
						mac_res_d = mac_res;
						summand1 = 1'sb0;
						summand2 = accum;
						summand3 = $unsigned(mult3_res);
						mult_state_d = 1'd0;
						mult_valid = 1'b1;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 1'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 1'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign unused_mult1_res_uns = mult1_res_uns[33:32];
			assign sva_mul_fsm_idle = mult_state_q == 1'd0;
		end
		else begin : gen_mult_fast
			reg [15:0] mult_op_a;
			reg [15:0] mult_op_b;
			reg [1:0] mult_state_q;
			reg [1:0] mult_state_d;
			assign mac_res_signed = ($signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b})) + $signed(accum);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			always @(*) begin
				if (_sv2v_0)
					;
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[15:0];
				sign_a = 1'b0;
				sign_b = 1'b0;
				accum = imd_val_q_i[34+:34];
				mac_res_d = mac_res;
				mult_state_d = mult_state_q;
				mult_valid = 1'b0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					2'd0: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[15:0];
						sign_a = 1'b0;
						sign_b = 1'b0;
						accum = 1'sb0;
						mac_res_d = mac_res;
						mult_state_d = 2'd1;
					end
					2'd1: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[31:16];
						sign_a = 1'b0;
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
						if (operator_i == 2'd0)
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
						else
							mac_res_d = mac_res;
						mult_state_d = 2'd2;
					end
					2'd2: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[15:0];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = 1'b0;
						if (operator_i == 2'd0) begin
							accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
							mult_valid = 1'b1;
							mult_state_d = 2'd0;
							mult_hold = ~multdiv_ready_id_i;
						end
						else begin
							accum = imd_val_q_i[34+:34];
							mac_res_d = mac_res;
							mult_state_d = 2'd3;
						end
					end
					2'd3: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[31:16];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum[17:0] = imd_val_q_i[67-:18];
						accum[33:18] = {16 {signed_mult & imd_val_q_i[67]}};
						mac_res_d = mac_res;
						mult_valid = 1'b1;
						mult_state_d = 2'd0;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 2'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 2'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign sva_mul_fsm_idle = mult_state_q == 2'd0;
		end
	endgenerate
	assign res_adder_h = alu_adder_ext_i[32:1];
	wire [1:0] unused_alu_adder_ext;
	assign unused_alu_adder_ext = {alu_adder_ext_i[33], alu_adder_ext_i[0]};
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : imd_val_q_i[65-:32]);
	assign next_quotient = (is_greater_equal ? {1'b0, op_quotient_q} | {1'b0, one_shift} : {1'b0, op_quotient_q});
	assign one_shift = 32'b00000000000000000000000000000001 << div_counter_q;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((imd_val_q_i[65] ^ op_denominator_q[31]) == 1'b0)
			is_greater_equal = res_adder_h[31] == 1'b0;
		else
			is_greater_equal = imd_val_q_i[65];
	end
	assign div_sign_a = op_a_i[31] & signed_mode_i[0];
	assign div_sign_b = op_b_i[31] & signed_mode_i[1];
	assign div_change_sign = (div_sign_a ^ div_sign_b) & ~div_by_zero_q;
	assign rem_change_sign = div_sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		div_counter_d = div_counter_q - 5'h01;
		op_remainder_d = imd_val_q_i[34+:34];
		op_quotient_d = op_quotient_q;
		md_state_d = md_state_q;
		op_numerator_d = op_numerator_q;
		op_denominator_d = op_denominator_q;
		alu_operand_a_o = 33'h000000001;
		alu_operand_b_o = {~op_b_i, 1'b1};
		div_valid = 1'b0;
		div_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		(* full_case, parallel_case *)
		case (md_state_q)
			3'd0: begin
				if (operator_i == 2'd2) begin
					op_remainder_d = 1'sb1;
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
					div_by_zero_d = equal_to_zero_i;
				end
				else begin
					op_remainder_d = {2'b00, op_a_i};
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
				end
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
				div_counter_d = 5'd31;
			end
			3'd1: begin
				op_quotient_d = 1'sb0;
				op_numerator_d = (div_sign_a ? alu_adder_i : op_a_i);
				md_state_d = 3'd2;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_a_i, 1'b1};
			end
			3'd2: begin
				op_remainder_d = {33'h000000000, op_numerator_q[31]};
				op_denominator_d = (div_sign_b ? alu_adder_i : op_b_i);
				md_state_d = 3'd3;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
			end
			3'd3: begin
				op_remainder_d = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_d]};
				op_quotient_d = next_quotient[31:0];
				md_state_d = (div_counter_q == 5'd1 ? 3'd4 : 3'd3);
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
			end
			3'd4: begin
				if (operator_i == 2'd2)
					op_remainder_d = {1'b0, next_quotient};
				else
					op_remainder_d = {2'b00, next_remainder[31:0]};
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
				md_state_d = 3'd5;
			end
			3'd5: begin
				md_state_d = 3'd6;
				if (operator_i == 2'd2)
					op_remainder_d = (div_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				else
					op_remainder_d = (rem_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~imd_val_q_i[65-:32], 1'b1};
			end
			3'd6: begin
				md_state_d = 3'd0;
				div_hold = ~multdiv_ready_id_i;
				div_valid = 1'b1;
			end
			default: md_state_d = 3'd0;
		endcase
	end
	assign valid_o = mult_valid | div_valid;
	wire unused_sva_mul_fsm_idle;
	assign unused_sva_mul_fsm_idle = sva_mul_fsm_idle;
	initial _sv2v_0 = 0;
endmodule
module ibex_multdiv_slow (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire [32:0] accum_window_q;
	reg [32:0] accum_window_d;
	wire unused_imd_val0;
	wire [1:0] unused_imd_val1;
	wire [32:0] res_adder_l;
	wire [32:0] res_adder_h;
	reg [4:0] multdiv_count_q;
	reg [4:0] multdiv_count_d;
	reg [32:0] op_b_shift_q;
	reg [32:0] op_b_shift_d;
	reg [32:0] op_a_shift_q;
	reg [32:0] op_a_shift_d;
	wire [32:0] op_a_ext;
	wire [32:0] op_b_ext;
	wire [32:0] one_shift;
	wire [32:0] op_a_bw_pp;
	wire [32:0] op_a_bw_last_pp;
	wire [31:0] b_0;
	wire sign_a;
	wire sign_b;
	wire [32:0] next_quotient;
	wire [31:0] next_remainder;
	wire [31:0] op_numerator_q;
	reg [31:0] op_numerator_d;
	wire is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	reg div_by_zero_d;
	reg div_by_zero_q;
	reg multdiv_hold;
	wire multdiv_en;
	assign res_adder_l = alu_adder_ext_i[32:0];
	assign res_adder_h = alu_adder_ext_i[33:1];
	assign imd_val_d_o[34+:34] = {1'b0, accum_window_d};
	assign imd_val_we_o[0] = ~multdiv_hold;
	assign accum_window_q = imd_val_q_i[66-:33];
	assign unused_imd_val0 = imd_val_q_i[67];
	assign imd_val_d_o[0+:34] = {2'b00, op_numerator_d};
	assign imd_val_we_o[1] = multdiv_en;
	assign op_numerator_q = imd_val_q_i[31-:32];
	assign unused_imd_val1 = imd_val_q_i[33-:2];
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operand_a_o = accum_window_q;
		(* full_case, parallel_case *)
		case (operator_i)
			2'd0: alu_operand_b_o = op_a_bw_pp;
			2'd1: alu_operand_b_o = (md_state_q == 3'd4 ? op_a_bw_last_pp : op_a_bw_pp);
			2'd2, 2'd3:
				(* full_case, parallel_case *)
				case (md_state_q)
					3'd0: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd1: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_a_i, 1'b1};
					end
					3'd2: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd5: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~accum_window_q[31:0], 1'b1};
					end
					default: begin
						alu_operand_a_o = {accum_window_q[31:0], 1'b1};
						alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
					end
				endcase
			default: begin
				alu_operand_a_o = accum_window_q;
				alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
			end
		endcase
	end
	assign b_0 = {32 {op_b_shift_q[0]}};
	assign op_a_bw_pp = {~(op_a_shift_q[32] & op_b_shift_q[0]), op_a_shift_q[31:0] & b_0};
	assign op_a_bw_last_pp = {op_a_shift_q[32] & op_b_shift_q[0], ~(op_a_shift_q[31:0] & b_0)};
	assign sign_a = op_a_i[31] & signed_mode_i[0];
	assign sign_b = op_b_i[31] & signed_mode_i[1];
	assign op_a_ext = {sign_a, op_a_i};
	assign op_b_ext = {sign_b, op_b_i};
	assign is_greater_equal = (accum_window_q[31] == op_b_shift_q[31] ? ~res_adder_h[31] : accum_window_q[31]);
	assign one_shift = 33'b000000000000000000000000000000001 << multdiv_count_q;
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : accum_window_q[31:0]);
	assign next_quotient = (is_greater_equal ? op_a_shift_q | one_shift : op_a_shift_q);
	assign div_change_sign = (sign_a ^ sign_b) & ~div_by_zero_q;
	assign rem_change_sign = sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		multdiv_count_d = multdiv_count_q;
		accum_window_d = accum_window_q;
		op_b_shift_d = op_b_shift_q;
		op_a_shift_d = op_a_shift_q;
		op_numerator_d = op_numerator_q;
		md_state_d = md_state_q;
		multdiv_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		if (mult_sel_i || div_sel_i)
			(* full_case, parallel_case *)
			case (md_state_q)
				3'd0: begin
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							op_a_shift_d = op_a_ext << 1;
							accum_window_d = {~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:0] & {32 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = (!data_ind_timing_i && ((op_b_ext >> 1) == 0) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							op_a_shift_d = op_a_ext;
							accum_window_d = {1'b1, ~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:1] & {31 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = 3'd3;
						end
						2'd2: begin
							accum_window_d = {33 {1'b1}};
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
							div_by_zero_d = equal_to_zero_i;
						end
						2'd3: begin
							accum_window_d = op_a_ext;
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
						end
						default:
							;
					endcase
					multdiv_count_d = 5'd31;
				end
				3'd1: begin
					op_a_shift_d = 1'sb0;
					op_numerator_d = (sign_a ? alu_adder_i : op_a_i);
					md_state_d = 3'd2;
				end
				3'd2: begin
					accum_window_d = {32'h00000000, op_numerator_q[31]};
					op_b_shift_d = (sign_b ? {1'b0, alu_adder_i} : {1'b0, op_b_i});
					md_state_d = 3'd3;
				end
				3'd3: begin
					multdiv_count_d = multdiv_count_q - 5'h01;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							op_a_shift_d = op_a_shift_q << 1;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = ((!data_ind_timing_i && (op_b_shift_d == 0)) || (multdiv_count_q == 5'd1) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							accum_window_d = res_adder_h;
							op_a_shift_d = op_a_shift_q;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						2'd2, 2'd3: begin
							accum_window_d = {next_remainder[31:0], op_numerator_q[multdiv_count_d]};
							op_a_shift_d = next_quotient;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						default:
							;
					endcase
				end
				3'd4:
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd1: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd2: begin
							accum_window_d = next_quotient;
							md_state_d = 3'd5;
						end
						2'd3: begin
							accum_window_d = {1'b0, next_remainder[31:0]};
							md_state_d = 3'd5;
						end
						default:
							;
					endcase
				3'd5: begin
					md_state_d = 3'd6;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd2: accum_window_d = (div_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						2'd3: accum_window_d = (rem_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						default:
							;
					endcase
				end
				3'd6: begin
					md_state_d = 3'd0;
					multdiv_hold = ~multdiv_ready_id_i;
				end
				default: md_state_d = 3'd0;
			endcase
	end
	assign multdiv_en = (mult_en_i | div_en_i) & ~multdiv_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			multdiv_count_q <= 5'h00;
			op_b_shift_q <= 33'h000000000;
			op_a_shift_q <= 33'h000000000;
			md_state_q <= 3'd0;
			div_by_zero_q <= 1'b0;
		end
		else if (multdiv_en) begin
			multdiv_count_q <= multdiv_count_d;
			op_b_shift_q <= op_b_shift_d;
			op_a_shift_q <= op_a_shift_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign valid_o = (md_state_q == 3'd6) | ((md_state_q == 3'd4) & ((operator_i == 2'd0) | (operator_i == 2'd1)));
	assign multdiv_result_o = (div_en_i ? accum_window_q[31:0] : res_adder_l[31:0]);
	initial _sv2v_0 = 0;
endmodule
module ibex_pmp (
	csr_pmp_cfg_i,
	csr_pmp_addr_i,
	csr_pmp_mseccfg_i,
	debug_mode_i,
	priv_mode_i,
	pmp_req_addr_i,
	pmp_req_type_i,
	pmp_req_err_o
);
	reg _sv2v_0;
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumChan = 2;
	parameter [31:0] PMPNumRegions = 4;
	input wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_i;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	input wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_i;
	input wire [2:0] csr_pmp_mseccfg_i;
	input wire debug_mode_i;
	input wire [(PMPNumChan * 2) - 1:0] priv_mode_i;
	input wire [(PMPNumChan * 34) - 1:0] pmp_req_addr_i;
	input wire [(PMPNumChan * 2) - 1:0] pmp_req_type_i;
	output wire [0:PMPNumChan - 1] pmp_req_err_o;
	wire [ibex_pkg_PMP_ADDR_MSB:0] region_start_addr [0:PMPNumRegions - 1];
	localparam [31:0] ibex_pkg_PMP_ADDR_LSB = 2;
	wire [ibex_pkg_PMP_ADDR_MSB:PMPGranularity + ibex_pkg_PMP_ADDR_LSB] region_addr_mask [0:PMPNumRegions - 1];
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_gt;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_lt;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_eq;
	reg [(PMPNumChan * PMPNumRegions) - 1:0] region_match_all;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_basic_perm_check;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_perm_check;
	wire [PMPNumChan - 1:0] access_fault_check_res;
	wire [PMPNumChan - 1:0] debug_mode_allowed_access;
	function automatic mml_perm_check;
		input reg [5:0] region_csr_pmp_cfg;
		input reg [1:0] pmp_req_type;
		input reg [1:0] priv_mode;
		input reg permission_check;
		reg result;
		reg unused_cfg;
		begin
			result = 1'b0;
			unused_cfg = |region_csr_pmp_cfg[4-:2];
			if (!region_csr_pmp_cfg[0] && region_csr_pmp_cfg[1])
				(* full_case, parallel_case *)
				case ({region_csr_pmp_cfg[5], region_csr_pmp_cfg[2]})
					2'b00: result = (pmp_req_type == 2'b10) | ((pmp_req_type == 2'b01) & (priv_mode == 2'b11));
					2'b01: result = (pmp_req_type == 2'b10) | (pmp_req_type == 2'b01);
					2'b10: result = pmp_req_type == 2'b00;
					2'b11: result = (pmp_req_type == 2'b00) | ((pmp_req_type == 2'b10) & (priv_mode == 2'b11));
					default:
						;
				endcase
			else if (((region_csr_pmp_cfg[0] & region_csr_pmp_cfg[1]) & region_csr_pmp_cfg[2]) & region_csr_pmp_cfg[5])
				result = pmp_req_type == 2'b10;
			else
				result = permission_check & (priv_mode == 2'b11 ? region_csr_pmp_cfg[5] : ~region_csr_pmp_cfg[5]);
			mml_perm_check = result;
		end
	endfunction
	function automatic orig_perm_check;
		input reg pmp_cfg_lock;
		input reg [1:0] priv_mode;
		input reg permission_check;
		orig_perm_check = (priv_mode == 2'b11 ? ~pmp_cfg_lock | permission_check : permission_check);
	endfunction
	function automatic perm_check_wrapper;
		input reg csr_pmp_mseccfg_mml;
		input reg [5:0] region_csr_pmp_cfg;
		input reg [1:0] pmp_req_type;
		input reg [1:0] priv_mode;
		input reg permission_check;
		perm_check_wrapper = (csr_pmp_mseccfg_mml ? mml_perm_check(region_csr_pmp_cfg, pmp_req_type, priv_mode, permission_check) : orig_perm_check(region_csr_pmp_cfg[5], priv_mode, permission_check));
	endfunction
	function automatic access_fault_check;
		input reg csr_pmp_mseccfg_mmwp;
		input reg csr_pmp_mseccfg_mml;
		input reg [1:0] pmp_req_type;
		input reg [PMPNumRegions - 1:0] match_all;
		input reg [1:0] priv_mode;
		input reg [PMPNumRegions - 1:0] final_perm_check;
		reg access_fail;
		reg matched;
		begin
			access_fail = (csr_pmp_mseccfg_mmwp | (priv_mode != 2'b11)) | (csr_pmp_mseccfg_mml && (pmp_req_type == 2'b00));
			matched = 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] r;
				for (r = 0; r < PMPNumRegions; r = r + 1)
					if (!matched && match_all[r]) begin
						access_fail = ~final_perm_check[r];
						matched = 1'b1;
					end
			end
			access_fault_check = access_fail;
		end
	endfunction
	genvar _gv_r_1;
	generate
		for (_gv_r_1 = 0; _gv_r_1 < PMPNumRegions; _gv_r_1 = _gv_r_1 + 1) begin : g_addr_exp
			localparam r = _gv_r_1;
			if (r == 0) begin : g_entry0
				assign region_start_addr[r] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] == 2'b01 ? 34'h000000000 : csr_pmp_addr_i[0 + (((PMPNumRegions - 1) - r) * 34)+:34]);
			end
			else begin : g_oth
				assign region_start_addr[r] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] == 2'b01 ? csr_pmp_addr_i[0 + (((PMPNumRegions - 1) - (r - 1)) * 34)+:34] : csr_pmp_addr_i[0 + (((PMPNumRegions - 1) - r) * 34)+:34]);
			end
			genvar _gv_b_2;
			for (_gv_b_2 = PMPGranularity + ibex_pkg_PMP_ADDR_LSB; _gv_b_2 < 34; _gv_b_2 = _gv_b_2 + 1) begin : g_bitmask
				localparam b = _gv_b_2;
				if (b == ibex_pkg_PMP_ADDR_LSB) begin : g_bit0
					assign region_addr_mask[r][b] = csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11;
				end
				else begin : g_others
					if (PMPGranularity == 0) begin : g_region_addr_mask_zero_granularity
						assign region_addr_mask[r][b] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11) | ~&csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + ((b - 1) >= ibex_pkg_PMP_ADDR_LSB ? b - 1 : ((b - 1) + ((b - 1) >= ibex_pkg_PMP_ADDR_LSB ? ((b - 1) - ibex_pkg_PMP_ADDR_LSB) + 1 : (ibex_pkg_PMP_ADDR_LSB - (b - 1)) + 1)) - 1)-:((b - 1) >= ibex_pkg_PMP_ADDR_LSB ? ((b - 1) - ibex_pkg_PMP_ADDR_LSB) + 1 : (ibex_pkg_PMP_ADDR_LSB - (b - 1)) + 1)];
					end
					else begin : g_region_addr_mask_other_granularity
						assign region_addr_mask[r][b] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11) | ~&csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + ((b - 1) >= (PMPGranularity + 1) ? b - 1 : ((b - 1) + ((b - 1) >= (PMPGranularity + 1) ? ((b - 1) - (PMPGranularity + 1)) + 1 : ((PMPGranularity + 1) - (b - 1)) + 1)) - 1)-:((b - 1) >= (PMPGranularity + 1) ? ((b - 1) - (PMPGranularity + 1)) + 1 : ((PMPGranularity + 1) - (b - 1)) + 1)];
					end
				end
			end
		end
	endgenerate
	genvar _gv_c_1;
	generate
		for (_gv_c_1 = 0; _gv_c_1 < PMPNumChan; _gv_c_1 = _gv_c_1 + 1) begin : g_access_check
			localparam c = _gv_c_1;
			genvar _gv_r_2;
			for (_gv_r_2 = 0; _gv_r_2 < PMPNumRegions; _gv_r_2 = _gv_r_2 + 1) begin : g_regions
				localparam r = _gv_r_2;
				assign region_match_eq[(c * PMPNumRegions) + r] = (pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? ibex_pkg_PMP_ADDR_MSB : (ibex_pkg_PMP_ADDR_MSB + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)) - 1)-:(ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)] & region_addr_mask[r]) == (region_start_addr[r][ibex_pkg_PMP_ADDR_MSB:PMPGranularity + ibex_pkg_PMP_ADDR_LSB] & region_addr_mask[r]);
				assign region_match_gt[(c * PMPNumRegions) + r] = pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? ibex_pkg_PMP_ADDR_MSB : (ibex_pkg_PMP_ADDR_MSB + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)) - 1)-:(ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)] > region_start_addr[r][ibex_pkg_PMP_ADDR_MSB:PMPGranularity + ibex_pkg_PMP_ADDR_LSB];
				assign region_match_lt[(c * PMPNumRegions) + r] = pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? ibex_pkg_PMP_ADDR_MSB : (ibex_pkg_PMP_ADDR_MSB + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)) - 1)-:(ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)] < csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? ibex_pkg_PMP_ADDR_MSB : (ibex_pkg_PMP_ADDR_MSB + (ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)) - 1)-:(ibex_pkg_PMP_ADDR_MSB >= (PMPGranularity + ibex_pkg_PMP_ADDR_LSB) ? (ibex_pkg_PMP_ADDR_MSB - (PMPGranularity + ibex_pkg_PMP_ADDR_LSB)) + 1 : ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - ibex_pkg_PMP_ADDR_MSB) + 1)];
				always @(*) begin
					if (_sv2v_0)
						;
					region_match_all[(c * PMPNumRegions) + r] = 1'b0;
					(* full_case, parallel_case *)
					case (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2])
						2'b00: region_match_all[(c * PMPNumRegions) + r] = 1'b0;
						2'b10: region_match_all[(c * PMPNumRegions) + r] = region_match_eq[(c * PMPNumRegions) + r];
						2'b11: region_match_all[(c * PMPNumRegions) + r] = region_match_eq[(c * PMPNumRegions) + r];
						2'b01: region_match_all[(c * PMPNumRegions) + r] = (region_match_eq[(c * PMPNumRegions) + r] | region_match_gt[(c * PMPNumRegions) + r]) & region_match_lt[(c * PMPNumRegions) + r];
						default: region_match_all[(c * PMPNumRegions) + r] = 1'b0;
					endcase
				end
				assign region_basic_perm_check[(c * PMPNumRegions) + r] = (((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b00) & csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 2]) | ((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b01) & csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 1])) | ((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b10) & csr_pmp_cfg_i[((PMPNumRegions - 1) - r) * 6]);
				assign region_perm_check[(c * PMPNumRegions) + r] = perm_check_wrapper(csr_pmp_mseccfg_i[0], csr_pmp_cfg_i[((PMPNumRegions - 1) - r) * 6+:6], pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2], priv_mode_i[((PMPNumChan - 1) - c) * 2+:2], region_basic_perm_check[(c * PMPNumRegions) + r]);
				wire unused_sigs;
				assign unused_sigs = ^{region_start_addr[r][(PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - 1:0], pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + ((PMPGranularity + ibex_pkg_PMP_ADDR_LSB) - 1)-:PMPGranularity + ibex_pkg_PMP_ADDR_LSB]};
			end
			assign debug_mode_allowed_access[c] = debug_mode_i & ((pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + 31-:32] & ~DmAddrMask) == DmBaseAddr);
			assign access_fault_check_res[c] = access_fault_check(csr_pmp_mseccfg_i[1], csr_pmp_mseccfg_i[0], pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2], region_match_all[c * PMPNumRegions+:PMPNumRegions], priv_mode_i[((PMPNumChan - 1) - c) * 2+:2], region_perm_check[c * PMPNumRegions+:PMPNumRegions]);
			assign pmp_req_err_o[c] = ~debug_mode_allowed_access[c] & access_fault_check_res[c];
		end
	endgenerate
	wire unused_csr_pmp_mseccfg_rlb;
	assign unused_csr_pmp_mseccfg_rlb = csr_pmp_mseccfg_i[2];
	initial _sv2v_0 = 0;
endmodule
module ibex_prefetch_buffer (
	clk_i,
	rst_ni,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	err_o,
	err_plus2_o,
	cheriot_force_uc_i,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	instr_rvalid_i,
	busy_o
);
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output wire err_o;
	output wire err_plus2_o;
	input wire cheriot_force_uc_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_rvalid_i;
	output wire busy_o;
	localparam [31:0] NUM_REQS = 2;
	wire valid_new_req;
	wire valid_req;
	wire valid_req_d;
	reg valid_req_q;
	wire discard_req_d;
	reg discard_req_q;
	wire [1:0] rdata_outstanding_n;
	wire [1:0] rdata_outstanding_s;
	reg [1:0] rdata_outstanding_q;
	wire [1:0] branch_discard_n;
	wire [1:0] branch_discard_s;
	reg [1:0] branch_discard_q;
	wire [1:0] rdata_outstanding_rev;
	wire [31:0] stored_addr_d;
	reg [31:0] stored_addr_q;
	wire stored_addr_en;
	wire [31:0] fetch_addr_d;
	reg [31:0] fetch_addr_q;
	wire fetch_addr_en;
	wire [31:0] instr_addr;
	wire [31:0] instr_addr_w_aligned;
	wire fifo_valid;
	wire [31:0] fifo_addr;
	wire fifo_ready;
	wire fifo_clear;
	wire [1:0] fifo_busy;
	assign busy_o = |rdata_outstanding_q | instr_req_o;
	assign fifo_clear = branch_i;
	genvar _gv_i_31;
	generate
		for (_gv_i_31 = 0; _gv_i_31 < NUM_REQS; _gv_i_31 = _gv_i_31 + 1) begin : gen_rd_rev
			localparam i = _gv_i_31;
			assign rdata_outstanding_rev[i] = rdata_outstanding_q[1 - i];
		end
	endgenerate
	assign fifo_ready = ~&(fifo_busy | rdata_outstanding_rev);
	ibex_fetch_fifo #(
		.NUM_REQS(NUM_REQS),
		.ResetAll(ResetAll)
	) fifo_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(fifo_clear),
		.busy_o(fifo_busy),
		.in_valid_i(fifo_valid),
		.in_addr_i(fifo_addr),
		.in_rdata_i(instr_rdata_i),
		.in_err_i(instr_err_i),
		.cheriot_force_uc_i(cheriot_force_uc_i),
		.out_valid_o(valid_o),
		.out_ready_i(ready_i),
		.out_rdata_o(rdata_o),
		.out_addr_o(addr_o),
		.out_err_o(err_o),
		.out_err_plus2_o(err_plus2_o)
	);
	assign valid_new_req = (req_i & (fifo_ready | branch_i)) & ~rdata_outstanding_q[1];
	assign valid_req = valid_req_q | valid_new_req;
	assign valid_req_d = valid_req & ~instr_gnt_i;
	assign discard_req_d = valid_req_q & (branch_i | discard_req_q);
	assign stored_addr_en = (valid_new_req & ~valid_req_q) & ~instr_gnt_i;
	assign stored_addr_d = instr_addr;
	generate
		if (ResetAll) begin : g_stored_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					stored_addr_q <= 1'sb0;
				else if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
		else begin : g_stored_addr_nr
			always @(posedge clk_i)
				if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
	endgenerate
	assign fetch_addr_en = branch_i | (valid_new_req & ~valid_req_q);
	assign fetch_addr_d = (branch_i ? addr_i : {fetch_addr_q[31:2], 2'b00}) + {{29 {1'b0}}, valid_new_req & ~valid_req_q, 2'b00};
	generate
		if (ResetAll) begin : g_fetch_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					fetch_addr_q <= 1'sb0;
				else if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
		else begin : g_fetch_addr_nr
			always @(posedge clk_i)
				if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
	endgenerate
	assign instr_addr = (valid_req_q ? stored_addr_q : (branch_i ? addr_i : fetch_addr_q));
	assign instr_addr_w_aligned = {instr_addr[31:2], 2'b00};
	genvar _gv_i_32;
	generate
		for (_gv_i_32 = 0; _gv_i_32 < NUM_REQS; _gv_i_32 = _gv_i_32 + 1) begin : g_outstanding_reqs
			localparam i = _gv_i_32;
			if (i == 0) begin : g_req0
				assign rdata_outstanding_n[i] = (valid_req & instr_gnt_i) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = (((valid_req & instr_gnt_i) & discard_req_d) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
			else begin : g_reqtop
				assign rdata_outstanding_n[i] = ((valid_req & instr_gnt_i) & rdata_outstanding_q[i - 1]) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = ((((valid_req & instr_gnt_i) & discard_req_d) & rdata_outstanding_q[i - 1]) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
		end
	endgenerate
	assign rdata_outstanding_s = (instr_rvalid_i ? {1'b0, rdata_outstanding_n[1:1]} : rdata_outstanding_n);
	assign branch_discard_s = (instr_rvalid_i ? {1'b0, branch_discard_n[1:1]} : branch_discard_n);
	assign fifo_valid = instr_rvalid_i & ~branch_discard_q[0];
	assign fifo_addr = addr_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			valid_req_q <= 1'b0;
			discard_req_q <= 1'b0;
			rdata_outstanding_q <= 'b0;
			branch_discard_q <= 'b0;
		end
		else begin
			valid_req_q <= valid_req_d;
			discard_req_q <= discard_req_d;
			rdata_outstanding_q <= rdata_outstanding_s;
			branch_discard_q <= branch_discard_s;
		end
	assign instr_req_o = valid_req;
	assign instr_addr_o = instr_addr_w_aligned;
endmodule
module ibex_register_file_ff (
	clk_i,
	rst_ni,
	test_en_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	cheriot_enable_i,
	raddr_a_i,
	rdata_a_o,
	rcap_a_o,
	raddr_b_i,
	rdata_b_o,
	rcap_b_o,
	waddr_a_i,
	wdata_a_i,
	wcap_a_i,
	we_a_i
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] RV32E = 0;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] DummyInstructions = 0;
	parameter [DataWidth - 1:0] WordZeroVal = 1'sb0;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	parameter [31:0] CapWidth = ibex_cheriot_pkg_REGCAP_W;
	parameter [CapWidth - 1:0] CapWordZeroVal = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [4:0] raddr_a_i;
	output wire [DataWidth - 1:0] rdata_a_o;
	output wire [CapWidth - 1:0] rcap_a_o;
	input wire [4:0] raddr_b_i;
	output wire [DataWidth - 1:0] rdata_b_o;
	output wire [CapWidth - 1:0] rcap_b_o;
	input wire [4:0] waddr_a_i;
	input wire [DataWidth - 1:0] wdata_a_i;
	input wire [CapWidth - 1:0] wcap_a_i;
	input wire we_a_i;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
	function automatic [CapWidth - 1:0] sv2v_cast_A5509;
		input reg [CapWidth - 1:0] inp;
		sv2v_cast_A5509 = inp;
	endfunction
	function automatic [DataWidth - 1:0] sv2v_cast_8536A;
		input reg [DataWidth - 1:0] inp;
		sv2v_cast_8536A = inp;
	endfunction
	generate
		if (BaseIsa == 32'sd1) begin : g_cheriot_rf
			wire cheriot_enabled;
			assign cheriot_enabled = cheriot_enable_i == ibex_pkg_IbexMuBiOn;
			wire [DataWidth - 1:0] rf_data [0:15];
			wire [CapWidth - 1:0] rf_shared [0:15];
			reg [15:0] we_a_dec;
			always @(*) begin : we_a_decoder
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_1
					reg [31:0] i;
					for (i = 0; i < 16; i = i + 1)
						we_a_dec[i] = (waddr_a_i[3:0] == sv2v_cast_4(i) ? we_a_i : 1'b0);
				end
			end
			wire [CapWidth - 1:0] wshared_data;
			assign wshared_data = (cheriot_enabled ? wcap_a_i : sv2v_cast_A5509(wdata_a_i));
			genvar _gv_i_33;
			for (_gv_i_33 = 1; _gv_i_33 < 16; _gv_i_33 = _gv_i_33 + 1) begin : g_rf_data_flops
				localparam i = _gv_i_33;
				reg [DataWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= WordZeroVal;
					else if (we_a_dec[i] && !waddr_a_i[4])
						rf_reg_q <= wdata_a_i;
				assign rf_data[i] = rf_reg_q;
			end
			genvar _gv_i_34;
			for (_gv_i_34 = 1; _gv_i_34 < 16; _gv_i_34 = _gv_i_34 + 1) begin : g_rf_shared_flops
				localparam i = _gv_i_34;
				reg [CapWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= CapWordZeroVal;
					else if (((cheriot_enabled && we_a_dec[i]) && !waddr_a_i[4]) || (((!cheriot_enabled && !RV32E) && we_a_dec[i]) && waddr_a_i[4]))
						rf_reg_q <= wshared_data;
				assign rf_shared[i] = rf_reg_q;
			end
			wire [CapWidth - 1:0] rcap_r0;
			if (DummyInstructions) begin : g_dummy_r0
				wire we_data_r0;
				wire we_shared_r0;
				assign we_data_r0 = (we_a_dec[0] && !waddr_a_i[4]) && dummy_instr_wb_i;
				assign we_shared_r0 = (cheriot_enabled ? we_data_r0 : (!RV32E && we_a_dec[0]) && waddr_a_i[4]);
				reg [DataWidth - 1:0] rf_data_r0_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_data_r0_q <= WordZeroVal;
					else if (we_data_r0)
						rf_data_r0_q <= wdata_a_i;
				assign rf_data[0] = (dummy_instr_id_i ? rf_data_r0_q : WordZeroVal);
				reg [CapWidth - 1:0] rf_shared_r0_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_shared_r0_q <= CapWordZeroVal;
					else if (we_shared_r0)
						rf_shared_r0_q <= wshared_data;
				assign rf_shared[0] = rf_shared_r0_q;
				assign rcap_r0 = (dummy_instr_id_i ? rf_shared[0] : CapWordZeroVal);
			end
			else begin : g_normal_r0
				assign rf_data[0] = WordZeroVal;
				assign rcap_r0 = CapWordZeroVal;
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				if (!RV32E) begin : g_rf_shared0_x16
					reg [DataWidth - 1:0] rf_shared_r0_q;
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							rf_shared_r0_q <= WordZeroVal;
						else if ((!cheriot_enabled && we_a_dec[0]) && waddr_a_i[4])
							rf_shared_r0_q <= wdata_a_i;
					assign rf_shared[0] = sv2v_cast_A5509(rf_shared_r0_q);
				end
				else begin : g_rf_shared0_no_x16
					assign rf_shared[0] = CapWordZeroVal;
					wire unused_we_a_dec0;
					assign unused_we_a_dec0 = we_a_dec[0];
				end
			end
			assign rdata_a_o = (raddr_a_i[4] && !cheriot_enabled ? sv2v_cast_8536A(rf_shared[raddr_a_i[3:0]]) : rf_data[raddr_a_i[3:0]]);
			assign rdata_b_o = (raddr_b_i[4] && !cheriot_enabled ? sv2v_cast_8536A(rf_shared[raddr_b_i[3:0]]) : rf_data[raddr_b_i[3:0]]);
			assign rcap_a_o = (cheriot_enabled ? (raddr_a_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_a_i[3:0]]) : CapWordZeroVal);
			assign rcap_b_o = (cheriot_enabled ? (raddr_b_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_b_i[3:0]]) : CapWordZeroVal);
			wire unused_test_en;
			assign unused_test_en = test_en_i;
		end
		else begin : g_plain_rf
			localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
			localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
			wire [DataWidth - 1:0] rf_reg [0:NUM_WORDS - 1];
			reg [NUM_WORDS - 1:0] we_a_dec;
			always @(*) begin : we_a_decoder
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_2
					reg [31:0] i;
					for (i = 0; i < NUM_WORDS; i = i + 1)
						we_a_dec[i] = (waddr_a_i == sv2v_cast_5(i) ? we_a_i : 1'b0);
				end
			end
			wire unused_strobe;
			assign unused_strobe = we_a_dec[0];
			genvar _gv_i_35;
			for (_gv_i_35 = 1; _gv_i_35 < NUM_WORDS; _gv_i_35 = _gv_i_35 + 1) begin : g_rf_flops
				localparam i = _gv_i_35;
				reg [DataWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= WordZeroVal;
					else if (we_a_dec[i])
						rf_reg_q <= wdata_a_i;
				assign rf_reg[i] = rf_reg_q;
			end
			if (DummyInstructions) begin : g_dummy_r0
				wire we_r0_dummy;
				reg [DataWidth - 1:0] rf_r0_q;
				assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_r0_q <= WordZeroVal;
					else if (we_r0_dummy)
						rf_r0_q <= wdata_a_i;
				assign rf_reg[0] = (dummy_instr_id_i ? rf_r0_q : WordZeroVal);
			end
			else begin : g_normal_r0
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				assign rf_reg[0] = WordZeroVal;
			end
			assign rdata_a_o = rf_reg[raddr_a_i[ADDR_WIDTH - 1:0]];
			assign rdata_b_o = rf_reg[raddr_b_i[ADDR_WIDTH - 1:0]];
			if (RV32E) begin : g_unused_raddr_msb
				wire [1:0] unused_raddr_msb;
				assign unused_raddr_msb = {raddr_a_i[4], raddr_b_i[4]};
			end
			wire unused_test_en;
			assign unused_test_en = test_en_i;
			assign rcap_a_o = CapWordZeroVal;
			assign rcap_b_o = CapWordZeroVal;
			wire unused_wcap_a;
			assign unused_wcap_a = ^wcap_a_i;
			wire unused_cheriot_enable;
			assign unused_cheriot_enable = ^cheriot_enable_i;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_top (
	clk_i,
	rst_ni,
	test_en_i,
	ram_cfg_icache_tag_i,
	ram_cfg_icache_tag_o,
	ram_cfg_icache_data_i,
	ram_cfg_icache_data_o,
	cheriot_enable_i,
	hart_id_i,
	boot_addr_i,
	trvk_heap_base_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rdata_intg_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_wdata_intg_o,
	data_tag_o,
	data_rdata_i,
	data_rdata_intg_i,
	data_tag_i,
	data_err_i,
	trvk_revbm_req_o,
	trvk_revbm_gnt_i,
	trvk_revbm_rvalid_i,
	trvk_revbm_addr_o,
	trvk_revbm_rdata_i,
	trvk_revbm_rdata_intg_i,
	trvk_revbm_err_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	scramble_key_valid_i,
	scramble_key_i,
	scramble_nonce_i,
	scramble_req_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	mcounteren_writable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_sleep_o,
	scan_rst_ni,
	lockstep_cmp_en_o,
	data_req_shadow_o,
	data_we_shadow_o,
	data_be_shadow_o,
	data_addr_shadow_o,
	data_wdata_shadow_o,
	data_wdata_intg_shadow_o,
	instr_req_shadow_o,
	instr_addr_shadow_o
);
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] CheriotRevBitmapAddrWidth = 32'd11;
	parameter [31:0] CheriotRevBitmapBaseAddr = 32'h00000000;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RV32ZC = 32'sd3;
	parameter integer RegFile = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [31:0] LockstepOffset = 1;
	parameter [0:0] MemECC = SecureIbex;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [0:0] ICacheScramble = 1'b0;
	parameter [31:0] ICacheScrNumPrinceRoundsHalf = 2;
	parameter [0:0] ICacheTweakInfection = SecureIbex;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	localparam [31:0] ibex_pkg_SCRAMBLE_KEY_W = 128;
	localparam [127:0] ibex_pkg_RndCnstIbexKeyDefault = 128'h14e8cecae3040d5e12286bb3cc113298;
	parameter [127:0] RndCnstIbexKey = ibex_pkg_RndCnstIbexKeyDefault;
	localparam [31:0] ibex_pkg_SCRAMBLE_NONCE_W = 64;
	localparam [63:0] ibex_pkg_RndCnstIbexNonceDefault = 64'hf79780bc735f3843;
	parameter [63:0] RndCnstIbexNonce = ibex_pkg_RndCnstIbexNonceDefault;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] prim_ram_1p_pkg_Ram1pReqWidth = 32'd12;
	input wire [(ibex_pkg_IC_NUM_WAYS * prim_ram_1p_pkg_Ram1pReqWidth) - 1:0] ram_cfg_icache_tag_i;
	localparam [31:0] prim_ram_1p_pkg_Ram1pRspWidth = 32'd1;
	output wire [(ibex_pkg_IC_NUM_WAYS * prim_ram_1p_pkg_Ram1pRspWidth) - 1:0] ram_cfg_icache_tag_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * prim_ram_1p_pkg_Ram1pReqWidth) - 1:0] ram_cfg_icache_data_i;
	output wire [(ibex_pkg_IC_NUM_WAYS * prim_ram_1p_pkg_Ram1pRspWidth) - 1:0] ram_cfg_icache_data_o;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] trvk_heap_base_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire [6:0] instr_rdata_intg_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	output wire [6:0] data_wdata_intg_o;
	output wire data_tag_o;
	input wire [31:0] data_rdata_i;
	input wire [6:0] data_rdata_intg_i;
	input wire data_tag_i;
	input wire data_err_i;
	output wire trvk_revbm_req_o;
	input wire trvk_revbm_gnt_i;
	input wire trvk_revbm_rvalid_i;
	output wire [31:0] trvk_revbm_addr_o;
	input wire [31:0] trvk_revbm_rdata_i;
	input wire [6:0] trvk_revbm_rdata_intg_i;
	input wire trvk_revbm_err_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire scramble_key_valid_i;
	input wire [127:0] scramble_key_i;
	input wire [63:0] scramble_nonce_i;
	output wire scramble_req_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	input wire [3:0] fetch_enable_i;
	input wire [3:0] mcounteren_writable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire core_sleep_o;
	input wire scan_rst_ni;
	output wire [3:0] lockstep_cmp_en_o;
	output wire data_req_shadow_o;
	output wire data_we_shadow_o;
	output wire [3:0] data_be_shadow_o;
	output wire [31:0] data_addr_shadow_o;
	output wire [31:0] data_wdata_shadow_o;
	output wire [6:0] data_wdata_intg_shadow_o;
	output wire instr_req_shadow_o;
	output wire [31:0] instr_addr_shadow_o;
	localparam [0:0] Lockstep = SecureIbex;
	localparam [0:0] ResetAll = Lockstep;
	localparam [0:0] DummyInstructions = SecureIbex;
	localparam [0:0] RegFileECC = 1'b0;
	localparam [0:0] RegFileLockstepECC = Lockstep;
	localparam [31:0] RegFileDataWidth = 32;
	localparam [31:0] RegFileDataEccWidth = 39;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	localparam [31:0] RegFileCapEccWidth = 42;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	localparam [31:0] ibex_pkg_IC_DATA_ECC_SIZE = 7;
	localparam [31:0] BusSizeECC = (ICacheECC ? ibex_pkg_BUS_SIZE + ibex_pkg_IC_DATA_ECC_SIZE : ibex_pkg_BUS_SIZE);
	localparam [31:0] ibex_pkg_BUS_BYTES = 4;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS = ibex_pkg_IC_LINE_BYTES / ibex_pkg_BUS_BYTES;
	localparam [31:0] LineSizeECC = BusSizeECC * ibex_pkg_IC_LINE_BEATS;
	localparam [31:0] ibex_pkg_IC_TAG_ECC_SIZE = 6;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	localparam [31:0] TagSizeECC = (ICacheECC ? ibex_pkg_IC_TAG_SIZE + ibex_pkg_IC_TAG_ECC_SIZE : ibex_pkg_IC_TAG_SIZE);
	localparam [31:0] NumAddrScrRounds = (ICacheScramble ? 2 : 0);
	localparam [31:0] MaxOutstandingDSideAccesses = 2;
	wire clk;
	wire [3:0] core_busy_d;
	reg [3:0] core_busy_q;
	wire clock_en;
	wire irq_pending;
	wire dummy_instr_id;
	wire dummy_instr_wb;
	wire [4:0] rf_raddr_a;
	wire [4:0] rf_raddr_b;
	wire [4:0] rf_waddr_wb;
	wire rf_we_wb;
	wire [31:0] rf_wdata_wb;
	wire [31:0] rf_rdata_a;
	wire [31:0] rf_rdata_b;
	wire [34:0] rf_rcap_a;
	wire [34:0] rf_rcap_b;
	wire [34:0] rf_wcap;
	wire [MemDataWidth - 1:0] data_wdata_core;
	wire [MemDataWidth - 1:0] data_rdata_core;
	wire [MemDataWidth - 1:0] instr_rdata_core;
	wire trvk_req;
	wire trvk_gnt;
	wire trvk_rvalid;
	wire trvk_we;
	wire [3:0] trvk_be;
	wire [31:0] trvk_addr;
	wire [31:0] trvk_wdata;
	wire [6:0] trvk_wdata_intg;
	wire trvk_wtag;
	wire [31:0] trvk_rdata;
	wire [6:0] trvk_rdata_intg;
	wire trvk_rtag;
	wire trvk_err;
	wire trvk_revbm_data_intg_error;
	wire trvk_revbm_device_error;
	wire [1:0] ic_tag_req;
	wire ic_tag_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr;
	wire [TagSizeECC - 1:0] ic_tag_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata;
	wire [1:0] ic_data_req;
	wire ic_data_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr;
	wire [LineSizeECC - 1:0] ic_data_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata;
	wire ic_scr_key_req;
	wire core_alert_major_internal;
	wire core_alert_major_bus;
	wire core_alert_minor;
	wire lockstep_alert_major_internal;
	wire lockstep_alert_major_bus;
	wire lockstep_alert_minor;
	reg [127:0] scramble_key_q;
	reg [63:0] scramble_nonce_q;
	wire scramble_key_valid_d;
	reg scramble_key_valid_q;
	wire scramble_req_d;
	reg scramble_req_q;
	wire [3:0] fetch_enable_buf;
	wire [3:0] mcounteren_writable_buf;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	generate
		if (SecureIbex) begin : g_clock_en_secure
			wire [4:1] sv2v_tmp_u_prim_core_busy_flop_q_o;
			always @(*) core_busy_q = sv2v_tmp_u_prim_core_busy_flop_q_o;
			prim_flop #(
				.Width(ibex_pkg_IbexMuBiWidth),
				.ResetValue(ibex_pkg_IbexMuBiOff)
			) u_prim_core_busy_flop(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d_i(core_busy_d),
				.q_o(sv2v_tmp_u_prim_core_busy_flop_q_o)
			);
			assign clock_en = (((core_busy_q != ibex_pkg_IbexMuBiOff) | debug_req_i) | irq_pending) | irq_nm_i;
		end
		else begin : g_clock_en_non_secure
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					core_busy_q <= ibex_pkg_IbexMuBiOff;
				else
					core_busy_q <= core_busy_d;
			assign clock_en = ((core_busy_q[0] | debug_req_i) | irq_pending) | irq_nm_i;
			wire unused_core_busy;
			assign unused_core_busy = ^core_busy_q[3:1];
		end
	endgenerate
	assign core_sleep_o = ~clock_en;
	prim_clock_gating core_clock_gate_i(
		.clk_i(clk_i),
		.en_i(clock_en),
		.test_en_i(test_en_i),
		.clk_o(clk)
	);
	prim_buf #(.Width(ibex_pkg_IbexMuBiWidth)) u_fetch_enable_buf(
		.in_i(fetch_enable_i),
		.out_o(fetch_enable_buf)
	);
	prim_buf #(.Width(ibex_pkg_IbexMuBiWidth)) u_mcounteren_writable_buf(
		.in_i(mcounteren_writable_i),
		.out_o(mcounteren_writable_buf)
	);
	assign data_rdata_core[31:0] = trvk_rdata;
	assign instr_rdata_core[31:0] = instr_rdata_i;
	generate
		if (MemECC) begin : gen_mem_rdata_ecc
			assign data_rdata_core[MemDataWidth - 1:32] = trvk_rdata_intg;
			assign instr_rdata_core[MemDataWidth - 1:32] = instr_rdata_intg_i;
		end
		else begin : gen_non_mem_rdata_ecc
			wire unused_intg;
			assign unused_intg = ^{instr_rdata_intg_i, trvk_rdata_intg};
		end
	endgenerate
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.RV32ZC(RV32ZC),
		.BranchTargetALU(BranchTargetALU),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.ICacheTweakInfection(ICacheTweakInfection),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.BranchPredictor(BranchPredictor),
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.WritebackStage(WritebackStage),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.SecureIbex(SecureIbex),
		.DummyInstructions(DummyInstructions),
		.RegFileECC(RegFileECC),
		.RegFileDataWidth(RegFileDataWidth),
		.RegFileCapEccWidth(ibex_cheriot_pkg_REGCAP_W),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.DmBaseAddr(DmBaseAddr),
		.DmAddrMask(DmAddrMask),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.CsrMvendorId(CsrMvendorId),
		.CsrMimpId(CsrMimpId),
		.BaseIsa(BaseIsa)
	) u_ibex_core(
		.clk_i(clk),
		.rst_ni(rst_ni),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.cheriot_enable_i(cheriot_enable_i),
		.instr_req_o(instr_req_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_addr_o(instr_addr_o),
		.instr_rdata_i(instr_rdata_core),
		.instr_err_i(instr_err_i),
		.data_req_o(trvk_req),
		.data_gnt_i(trvk_gnt),
		.data_rvalid_i(trvk_rvalid),
		.data_we_o(trvk_we),
		.data_be_o(trvk_be),
		.data_addr_o(trvk_addr),
		.data_wdata_o(data_wdata_core),
		.data_tag_o(trvk_wtag),
		.data_rdata_i(data_rdata_core),
		.data_tag_i(trvk_rtag),
		.data_err_i(trvk_err),
		.dummy_instr_id_o(dummy_instr_id),
		.dummy_instr_wb_o(dummy_instr_wb),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_we_wb_o(rf_we_wb),
		.rf_wdata_wb_ecc_o(rf_wdata_wb),
		.rf_rdata_a_ecc_i(rf_rdata_a),
		.rf_rdata_b_ecc_i(rf_rdata_b),
		.rf_wcap_ecc_wb_o(rf_wcap),
		.rf_rcap_a_ecc_i(rf_rcap_a),
		.rf_rcap_b_ecc_i(rf_rcap_b),
		.ic_tag_req_o(ic_tag_req),
		.ic_tag_write_o(ic_tag_write),
		.ic_tag_addr_o(ic_tag_addr),
		.ic_tag_wdata_o(ic_tag_wdata),
		.ic_tag_rdata_i(ic_tag_rdata),
		.ic_data_req_o(ic_data_req),
		.ic_data_write_o(ic_data_write),
		.ic_data_addr_o(ic_data_addr),
		.ic_data_wdata_o(ic_data_wdata),
		.ic_data_rdata_i(ic_data_rdata),
		.ic_scr_key_valid_i(scramble_key_valid_q),
		.ic_scr_key_req_o(ic_scr_key_req),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.irq_nm_i(irq_nm_i),
		.irq_pending_o(irq_pending),
		.debug_req_i(debug_req_i),
		.crash_dump_o(crash_dump_o),
		.double_fault_seen_o(double_fault_seen_o),
		.fetch_enable_i(fetch_enable_buf),
		.mcounteren_writable_i(mcounteren_writable_buf),
		.alert_minor_o(core_alert_minor),
		.alert_major_internal_o(core_alert_major_internal),
		.alert_major_bus_o(core_alert_major_bus),
		.core_busy_o(core_busy_d)
	);
	localparam [38:0] prim_secded_pkg_SecdedInv3932ZeroWord = 39'h2a00000000;
	function automatic [31:0] sv2v_cast_DEBC9;
		input reg [31:0] inp;
		sv2v_cast_DEBC9 = inp;
	endfunction
	generate
		if (RegFile == 32'sd0) begin : gen_regfile_ff
			ibex_register_file_ff #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(sv2v_cast_DEBC9(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.cheriot_enable_i(cheriot_enable_i),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a),
				.rcap_a_o(rf_rcap_a),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b),
				.rcap_b_o(rf_rcap_b),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb),
				.wcap_a_i(rf_wcap),
				.we_a_i(rf_we_wb)
			);
		end
		else if (RegFile == 32'sd1) begin : gen_regfile_fpga
			ibex_register_file_fpga #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(sv2v_cast_DEBC9(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.cheriot_enable_i(cheriot_enable_i),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a),
				.rcap_a_o(rf_rcap_a),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b),
				.rcap_b_o(rf_rcap_b),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb),
				.wcap_a_i(rf_wcap),
				.we_a_i(rf_we_wb)
			);
		end
		else if (RegFile == 32'sd2) begin : gen_regfile_latch
			ibex_register_file_latch #(
				.BaseIsa(BaseIsa),
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WordZeroVal(sv2v_cast_DEBC9(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.cheriot_enable_i(cheriot_enable_i),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a),
				.rcap_a_o(rf_rcap_a),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b),
				.rcap_b_o(rf_rcap_b),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb),
				.wcap_a_i(rf_wcap),
				.we_a_i(rf_we_wb)
			);
		end
		if (ICacheScramble) begin : gen_scramble
			assign scramble_key_valid_d = (scramble_req_q ? scramble_key_valid_i : (ic_scr_key_req ? 1'b0 : scramble_key_valid_q));
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_q <= RndCnstIbexKey;
					scramble_nonce_q <= RndCnstIbexNonce;
				end
				else if (scramble_key_valid_i) begin
					scramble_key_q <= scramble_key_i;
					scramble_nonce_q <= scramble_nonce_i;
				end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_valid_q <= 1'b1;
					scramble_req_q <= 1'sb0;
				end
				else begin
					scramble_key_valid_q <= scramble_key_valid_d;
					scramble_req_q <= scramble_req_d;
				end
			assign scramble_req_d = (scramble_req_q ? ~scramble_key_valid_i : ic_scr_key_req);
			assign scramble_req_o = scramble_req_q;
		end
		else begin : gen_noscramble
			reg unused_scramble_inputs = (((((((((((scramble_key_valid_i & |scramble_key_i) & |RndCnstIbexKey) & |scramble_nonce_i) & |RndCnstIbexNonce) & scramble_req_q) & ic_scr_key_req) & scramble_key_valid_d) & scramble_req_d) & |scramble_key_q) & |scramble_nonce_q) & scramble_key_valid_q) & scramble_key_valid_d;
			assign scramble_req_d = 1'b0;
			wire [1:1] sv2v_tmp_2E9FB;
			assign sv2v_tmp_2E9FB = 1'b0;
			always @(*) scramble_req_q = sv2v_tmp_2E9FB;
			assign scramble_req_o = 1'b0;
			wire [128:1] sv2v_tmp_E270A;
			assign sv2v_tmp_E270A = 1'sb0;
			always @(*) scramble_key_q = sv2v_tmp_E270A;
			wire [64:1] sv2v_tmp_F758A;
			assign sv2v_tmp_F758A = 1'sb0;
			always @(*) scramble_nonce_q = sv2v_tmp_F758A;
			wire [1:1] sv2v_tmp_604FC;
			assign sv2v_tmp_604FC = 1'b1;
			always @(*) scramble_key_valid_q = sv2v_tmp_604FC;
			assign scramble_key_valid_d = 1'b1;
		end
	endgenerate
	wire [1:0] icache_tag_alert;
	wire [1:0] icache_data_alert;
	localparam [0:0] prim_ram_1p_pkg_RAM_1P_CFG_RSP_DEFAULT = 1'sb0;
	function automatic [0:0] sv2v_cast_97975;
		input reg [0:0] inp;
		sv2v_cast_97975 = inp;
	endfunction
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	generate
		if (ICache) begin : gen_rams
			genvar _gv_way_5;
			for (_gv_way_5 = 0; _gv_way_5 < ibex_pkg_IC_NUM_WAYS; _gv_way_5 = _gv_way_5 + 1) begin : gen_rams_inner
				localparam way = _gv_way_5;
				if (ICacheScramble) begin : gen_scramble_rams
					prim_ram_1p_scr #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) tag_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_tag_req[way]),
						.gnt_o(),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_icache_tag_i[way * prim_ram_1p_pkg_Ram1pReqWidth+:prim_ram_1p_pkg_Ram1pReqWidth]),
						.cfg_o(ram_cfg_icache_tag_o[way * prim_ram_1p_pkg_Ram1pRspWidth+:prim_ram_1p_pkg_Ram1pRspWidth]),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_tag_alert[way])
					);
					prim_ram_1p_scr #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC),
						.ReplicateKeyStream(1),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) data_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_data_req[way]),
						.gnt_o(),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_icache_data_i[way * prim_ram_1p_pkg_Ram1pReqWidth+:prim_ram_1p_pkg_Ram1pReqWidth]),
						.cfg_o(ram_cfg_icache_data_o[way * prim_ram_1p_pkg_Ram1pRspWidth+:prim_ram_1p_pkg_Ram1pRspWidth]),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_data_alert[way])
					);
				end
				else begin : gen_noscramble_rams
					prim_ram_1p #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC)
					) tag_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.req_i(ic_tag_req[way]),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.cfg_i(ram_cfg_icache_tag_i[way * prim_ram_1p_pkg_Ram1pReqWidth+:prim_ram_1p_pkg_Ram1pReqWidth]),
						.cfg_o(ram_cfg_icache_tag_o[way * prim_ram_1p_pkg_Ram1pRspWidth+:prim_ram_1p_pkg_Ram1pRspWidth])
					);
					prim_ram_1p #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC)
					) data_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.req_i(ic_data_req[way]),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.cfg_i(ram_cfg_icache_data_i[way * prim_ram_1p_pkg_Ram1pReqWidth+:prim_ram_1p_pkg_Ram1pReqWidth]),
						.cfg_o(ram_cfg_icache_data_o[way * prim_ram_1p_pkg_Ram1pRspWidth+:prim_ram_1p_pkg_Ram1pRspWidth])
					);
					assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
					assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
				end
			end
		end
		else begin : gen_norams
			wire unused_ram_cfg;
			wire unused_ram_inputs;
			assign unused_ram_cfg = |{ram_cfg_icache_tag_i, ram_cfg_icache_data_i};
			assign ram_cfg_icache_tag_o = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_97975(prim_ram_1p_pkg_RAM_1P_CFG_RSP_DEFAULT)}};
			assign ram_cfg_icache_data_o = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_97975(prim_ram_1p_pkg_RAM_1P_CFG_RSP_DEFAULT)}};
			assign unused_ram_inputs = (((((((|ic_tag_req & ic_tag_write) & |ic_tag_addr) & |ic_tag_wdata) & |ic_data_req) & ic_data_write) & |ic_data_addr) & |ic_data_wdata) & |NumAddrScrRounds;
			assign ic_tag_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_0CBAD('b0)}};
			assign ic_data_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_033B0('b0)}};
			assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
			assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
		end
	endgenerate
	assign trvk_wdata = data_wdata_core[31:0];
	generate
		if (MemECC) begin : gen_mem_wdata_ecc
			prim_buf #(.Width(7)) u_prim_buf_data_wdata_intg(
				.in_i(data_wdata_core[MemDataWidth - 1:32]),
				.out_o(trvk_wdata_intg)
			);
		end
		else begin : gen_no_mem_ecc
			assign trvk_wdata_intg = 1'sb0;
		end
	endgenerate
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	function automatic [34:0] sv2v_cast_F2778;
		input reg [34:0] inp;
		sv2v_cast_F2778 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_vec_to_regcap;
		input reg [34:0] vec_in;
		ibex_cheriot_pkg_cheriot_vec_to_regcap = sv2v_cast_F2778(vec_in);
	endfunction
	generate
		if (Lockstep) begin : gen_lockstep
			localparam [31:0] NumBufferBits = (((((((((((((((((((((99 + MemDataWidth) + 74) + MemDataWidth) + 2) + RegFileDataWidth) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 184) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth) + ibex_cheriot_pkg_REGCAP_W) + ibex_cheriot_pkg_REGCAP_W) + ibex_cheriot_pkg_REGCAP_W;
			wire [NumBufferBits - 1:0] buf_in;
			wire [NumBufferBits - 1:0] buf_out;
			wire [31:0] hart_id_local;
			wire [31:0] boot_addr_local;
			wire instr_req_local;
			wire instr_gnt_local;
			wire instr_rvalid_local;
			wire [31:0] instr_addr_local;
			wire [MemDataWidth - 1:0] instr_rdata_local;
			wire instr_err_local;
			wire data_req_local;
			wire data_gnt_local;
			wire data_rvalid_local;
			wire data_we_local;
			wire [3:0] data_be_local;
			wire [31:0] data_addr_local;
			wire [31:0] data_wdata_local;
			wire data_tag_local;
			wire [MemDataWidth - 1:0] data_rdata_local;
			wire data_rdata_tag_local;
			wire data_err_local;
			wire [31:0] rf_rdata_a_local;
			wire [31:0] rf_rdata_b_local;
			wire [3:0] cheriot_enable_local;
			wire [34:0] rf_wcap_vec_local;
			wire [34:0] rf_rcap_a_vec_local;
			wire [34:0] rf_rcap_b_vec_local;
			wire [34:0] rf_wcap_local;
			wire [34:0] rf_rcap_a_local;
			wire [34:0] rf_rcap_b_local;
			wire [1:0] ic_tag_req_local;
			wire ic_tag_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_local;
			wire [TagSizeECC - 1:0] ic_tag_wdata_local;
			wire [1:0] ic_data_req_local;
			wire ic_data_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_local;
			wire [LineSizeECC - 1:0] ic_data_wdata_local;
			wire scramble_key_valid_local;
			wire ic_scr_key_req_local;
			wire irq_software_local;
			wire irq_timer_local;
			wire irq_external_local;
			wire [14:0] irq_fast_local;
			wire irq_nm_local;
			wire irq_pending_local;
			wire debug_req_local;
			wire [159:0] crash_dump_local;
			wire double_fault_seen_local;
			wire [3:0] fetch_enable_local;
			wire [3:0] mcounteren_writable_local;
			wire [3:0] core_busy_local;
			assign buf_in = {hart_id_i, boot_addr_i, instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o, instr_rdata_core, instr_err_i, trvk_req, trvk_gnt, trvk_rvalid, trvk_we, trvk_be, trvk_addr, trvk_wdata, trvk_wtag, data_rdata_core, trvk_rtag, trvk_err, rf_rdata_a, rf_rdata_b, ic_tag_req, ic_tag_write, ic_tag_addr, ic_tag_wdata, ic_data_req, ic_data_write, ic_data_addr, ic_data_wdata, scramble_key_valid_q, ic_scr_key_req, irq_software_i, irq_timer_i, irq_external_i, irq_fast_i, irq_nm_i, irq_pending, debug_req_i, crash_dump_o, double_fault_seen_o, fetch_enable_i, mcounteren_writable_i, core_busy_d, cheriot_enable_i, rf_wcap, rf_rcap_a, rf_rcap_b};
			assign {hart_id_local, boot_addr_local, instr_req_local, instr_gnt_local, instr_rvalid_local, instr_addr_local, instr_rdata_local, instr_err_local, data_req_local, data_gnt_local, data_rvalid_local, data_we_local, data_be_local, data_addr_local, data_wdata_local, data_tag_local, data_rdata_local, data_rdata_tag_local, data_err_local, rf_rdata_a_local, rf_rdata_b_local, ic_tag_req_local, ic_tag_write_local, ic_tag_addr_local, ic_tag_wdata_local, ic_data_req_local, ic_data_write_local, ic_data_addr_local, ic_data_wdata_local, scramble_key_valid_local, ic_scr_key_req_local, irq_software_local, irq_timer_local, irq_external_local, irq_fast_local, irq_nm_local, irq_pending_local, debug_req_local, crash_dump_local, double_fault_seen_local, fetch_enable_local, mcounteren_writable_local, core_busy_local, cheriot_enable_local, rf_wcap_vec_local, rf_rcap_a_vec_local, rf_rcap_b_vec_local} = buf_out;
			assign rf_wcap_local = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_wcap_vec_local);
			assign rf_rcap_a_local = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_a_vec_local);
			assign rf_rcap_b_local = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_b_vec_local);
			prim_buf #(.Width(NumBufferBits)) u_signals_prim_buf(
				.in_i(buf_in),
				.out_o(buf_out)
			);
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_local;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_local;
			genvar _gv_k_2;
			for (_gv_k_2 = 0; _gv_k_2 < ibex_pkg_IC_NUM_WAYS; _gv_k_2 = _gv_k_2 + 1) begin : gen_ways
				localparam k = _gv_k_2;
				prim_buf #(.Width(TagSizeECC)) u_tag_prim_buf(
					.in_i(ic_tag_rdata[(1 - k) * TagSizeECC+:TagSizeECC]),
					.out_o(ic_tag_rdata_local[(1 - k) * TagSizeECC+:TagSizeECC])
				);
				prim_buf #(.Width(LineSizeECC)) u_data_prim_buf(
					.in_i(ic_data_rdata[(1 - k) * LineSizeECC+:LineSizeECC]),
					.out_o(ic_data_rdata_local[(1 - k) * LineSizeECC+:LineSizeECC])
				);
			end
			wire lockstep_alert_minor_local;
			wire lockstep_alert_major_internal_local;
			wire lockstep_alert_major_bus_local;
			ibex_lockstep #(
				.PMPEnable(PMPEnable),
				.PMPGranularity(PMPGranularity),
				.PMPNumRegions(PMPNumRegions),
				.PMPRstCfg(PMPRstCfg),
				.PMPRstAddr(PMPRstAddr),
				.PMPRstMsecCfg(PMPRstMsecCfg),
				.MHPMCounterNum(MHPMCounterNum),
				.MHPMCounterWidth(MHPMCounterWidth),
				.RV32E(RV32E),
				.RV32M(RV32M),
				.RV32B(RV32B),
				.RV32ZC(RV32ZC),
				.BranchTargetALU(BranchTargetALU),
				.ICache(ICache),
				.ICacheECC(ICacheECC),
				.ICacheTweakInfection(ICacheTweakInfection),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC),
				.BranchPredictor(BranchPredictor),
				.DbgTriggerEn(DbgTriggerEn),
				.DbgHwBreakNum(DbgHwBreakNum),
				.WritebackStage(WritebackStage),
				.ResetAll(ResetAll),
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm),
				.SecureIbex(SecureIbex),
				.LockstepOffset(LockstepOffset),
				.DummyInstructions(DummyInstructions),
				.RegFileECC(RegFileLockstepECC),
				.RegFileDataWidth(RegFileDataWidth),
				.RegFileDataEccWidth(RegFileDataEccWidth),
				.RegFileCapEccWidth(RegFileCapEccWidth),
				.RegFile(RegFile),
				.MemECC(MemECC),
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.DmHaltAddr(DmHaltAddr),
				.DmExceptionAddr(DmExceptionAddr),
				.CsrMvendorId(CsrMvendorId),
				.CsrMimpId(CsrMimpId),
				.BaseIsa(BaseIsa)
			) u_ibex_lockstep(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.hart_id_i(hart_id_local),
				.boot_addr_i(boot_addr_local),
				.cheriot_enable_i(cheriot_enable_local),
				.instr_req_i(instr_req_local),
				.instr_gnt_i(instr_gnt_local),
				.instr_rvalid_i(instr_rvalid_local),
				.instr_addr_i(instr_addr_local),
				.instr_rdata_i(instr_rdata_local),
				.instr_err_i(instr_err_local),
				.data_req_i(data_req_local),
				.data_gnt_i(data_gnt_local),
				.data_rvalid_i(data_rvalid_local),
				.data_we_i(data_we_local),
				.data_be_i(data_be_local),
				.data_addr_i(data_addr_local),
				.data_wdata_i(data_wdata_local),
				.data_tag_i(data_tag_local),
				.data_rdata_i(data_rdata_local),
				.data_rdata_tag_i(data_rdata_tag_local),
				.data_err_i(data_err_local),
				.rf_rdata_a_i(rf_rdata_a_local),
				.rf_rdata_b_i(rf_rdata_b_local),
				.rf_wcap_wb_i(rf_wcap_local),
				.rf_rcap_a_i(rf_rcap_a_local),
				.rf_rcap_b_i(rf_rcap_b_local),
				.ic_tag_req_i(ic_tag_req_local),
				.ic_tag_write_i(ic_tag_write_local),
				.ic_tag_addr_i(ic_tag_addr_local),
				.ic_tag_wdata_i(ic_tag_wdata_local),
				.ic_tag_rdata_i(ic_tag_rdata_local),
				.ic_data_req_i(ic_data_req_local),
				.ic_data_write_i(ic_data_write_local),
				.ic_data_addr_i(ic_data_addr_local),
				.ic_data_wdata_i(ic_data_wdata_local),
				.ic_data_rdata_i(ic_data_rdata_local),
				.ic_scr_key_valid_i(scramble_key_valid_local),
				.ic_scr_key_req_i(ic_scr_key_req_local),
				.irq_software_i(irq_software_local),
				.irq_timer_i(irq_timer_local),
				.irq_external_i(irq_external_local),
				.irq_fast_i(irq_fast_local),
				.irq_nm_i(irq_nm_local),
				.irq_pending_i(irq_pending_local),
				.debug_req_i(debug_req_local),
				.crash_dump_i(crash_dump_local),
				.double_fault_seen_i(double_fault_seen_local),
				.fetch_enable_i(fetch_enable_local),
				.mcounteren_writable_i(mcounteren_writable_local),
				.alert_minor_o(lockstep_alert_minor_local),
				.alert_major_internal_o(lockstep_alert_major_internal_local),
				.alert_major_bus_o(lockstep_alert_major_bus_local),
				.core_busy_i(core_busy_local),
				.test_en_i(test_en_i),
				.scan_rst_ni(scan_rst_ni),
				.lockstep_cmp_en_o(lockstep_cmp_en_o),
				.data_req_shadow_o(data_req_shadow_o),
				.data_we_shadow_o(data_we_shadow_o),
				.data_be_shadow_o(data_be_shadow_o),
				.data_addr_shadow_o(data_addr_shadow_o),
				.data_wdata_shadow_o(data_wdata_shadow_o),
				.data_wdata_intg_shadow_o(data_wdata_intg_shadow_o),
				.instr_req_shadow_o(instr_req_shadow_o),
				.instr_addr_shadow_o(instr_addr_shadow_o)
			);
			prim_buf u_prim_buf_alert_minor(
				.in_i(lockstep_alert_minor_local),
				.out_o(lockstep_alert_minor)
			);
			prim_buf u_prim_buf_alert_major_internal(
				.in_i(lockstep_alert_major_internal_local),
				.out_o(lockstep_alert_major_internal)
			);
			prim_buf u_prim_buf_alert_major_bus(
				.in_i(lockstep_alert_major_bus_local),
				.out_o(lockstep_alert_major_bus)
			);
		end
		else begin : gen_no_lockstep
			assign lockstep_alert_major_internal = 1'b0;
			assign lockstep_alert_major_bus = 1'b0;
			assign lockstep_alert_minor = 1'b0;
			assign lockstep_cmp_en_o = ibex_pkg_IbexMuBiOff;
			assign data_req_shadow_o = 1'b0;
			assign data_we_shadow_o = 1'b0;
			assign data_be_shadow_o = 1'sb0;
			assign data_addr_shadow_o = 1'sb0;
			assign data_wdata_shadow_o = 1'sb0;
			assign data_wdata_intg_shadow_o = 1'sb0;
			assign instr_req_shadow_o = 1'b0;
			assign instr_addr_shadow_o = 1'sb0;
			wire unused_scan;
			assign unused_scan = scan_rst_ni;
		end
		if (BaseIsa == 32'sd1) begin : gen_cheriot_trvk
			ibex_trvk #(
				.NumOutstanding(MaxOutstandingDSideAccesses),
				.MemECC(MemECC),
				.RevBitmapAddrWidth(CheriotRevBitmapAddrWidth),
				.RevBitmapBaseAddr(CheriotRevBitmapBaseAddr)
			) i_ibex_trvk(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.heap_base_addr_i(trvk_heap_base_addr_i),
				.upstream_req_i(trvk_req),
				.upstream_gnt_o(trvk_gnt),
				.upstream_rvalid_o(trvk_rvalid),
				.upstream_we_i(trvk_we),
				.upstream_be_i(trvk_be),
				.upstream_addr_i(trvk_addr),
				.upstream_wdata_i(trvk_wdata),
				.upstream_wdata_intg_i(trvk_wdata_intg),
				.upstream_rdata_o(trvk_rdata),
				.upstream_rdata_intg_o(trvk_rdata_intg),
				.upstream_err_o(trvk_err),
				.upstream_tag_i(trvk_wtag),
				.upstream_tag_o(trvk_rtag),
				.downstream_req_o(data_req_o),
				.downstream_gnt_i(data_gnt_i),
				.downstream_rvalid_i(data_rvalid_i),
				.downstream_we_o(data_we_o),
				.downstream_be_o(data_be_o),
				.downstream_addr_o(data_addr_o),
				.downstream_wdata_o(data_wdata_o),
				.downstream_wdata_intg_o(data_wdata_intg_o),
				.downstream_rdata_i(data_rdata_i),
				.downstream_rdata_intg_i(data_rdata_intg_i),
				.downstream_err_i(data_err_i),
				.downstream_tag_o(data_tag_o),
				.downstream_tag_i(data_tag_i),
				.revbm_req_o(trvk_revbm_req_o),
				.revbm_gnt_i(trvk_revbm_gnt_i),
				.revbm_rvalid_i(trvk_revbm_rvalid_i),
				.revbm_addr_o(trvk_revbm_addr_o),
				.revbm_rdata_i(trvk_revbm_rdata_i),
				.revbm_rdata_intg_i(trvk_revbm_rdata_intg_i),
				.revbm_err_i(trvk_revbm_err_i),
				.revbm_data_intg_error_o(trvk_revbm_data_intg_error),
				.revbm_device_error_o(trvk_revbm_device_error)
			);
		end
		else begin : gen_no_cheriot_trvk
			wire unused_trvk;
			assign trvk_revbm_req_o = 1'sb0;
			assign trvk_revbm_addr_o = 1'sb0;
			assign trvk_rtag = 1'b0;
			assign data_tag_o = 1'b0;
			assign trvk_revbm_data_intg_error = 1'b0;
			assign trvk_revbm_device_error = 1'b0;
			assign unused_trvk = ^{trvk_heap_base_addr_i, trvk_revbm_gnt_i, trvk_revbm_rvalid_i, trvk_revbm_rdata_i, trvk_revbm_rdata_intg_i, trvk_revbm_err_i, trvk_wtag, data_tag_i};
			assign data_req_o = trvk_req;
			assign trvk_gnt = data_gnt_i;
			assign trvk_rvalid = data_rvalid_i;
			assign data_we_o = trvk_we;
			assign data_be_o = trvk_be;
			assign data_addr_o = trvk_addr;
			assign data_wdata_o = trvk_wdata;
			assign data_wdata_intg_o = trvk_wdata_intg;
			assign trvk_rdata = data_rdata_i;
			assign trvk_rdata_intg = data_rdata_intg_i;
			assign trvk_err = data_err_i;
		end
	endgenerate
	wire icache_alert_major_internal;
	assign icache_alert_major_internal = |icache_tag_alert | (|icache_data_alert);
	assign alert_major_internal_o = (core_alert_major_internal | lockstep_alert_major_internal) | icache_alert_major_internal;
	assign alert_major_bus_o = ((core_alert_major_bus | lockstep_alert_major_bus) | trvk_revbm_data_intg_error) | trvk_revbm_device_error;
	assign alert_minor_o = core_alert_minor | lockstep_alert_minor;
endmodule
module ibex_trvk (
	clk_i,
	rst_ni,
	heap_base_addr_i,
	upstream_req_i,
	upstream_gnt_o,
	upstream_rvalid_o,
	upstream_we_i,
	upstream_be_i,
	upstream_addr_i,
	upstream_wdata_i,
	upstream_wdata_intg_i,
	upstream_rdata_o,
	upstream_rdata_intg_o,
	upstream_err_o,
	upstream_tag_i,
	upstream_tag_o,
	downstream_req_o,
	downstream_gnt_i,
	downstream_rvalid_i,
	downstream_we_o,
	downstream_be_o,
	downstream_addr_o,
	downstream_wdata_o,
	downstream_wdata_intg_o,
	downstream_rdata_i,
	downstream_rdata_intg_i,
	downstream_err_i,
	downstream_tag_o,
	downstream_tag_i,
	revbm_req_o,
	revbm_gnt_i,
	revbm_rvalid_i,
	revbm_addr_o,
	revbm_rdata_i,
	revbm_rdata_intg_i,
	revbm_err_i,
	revbm_data_intg_error_o,
	revbm_device_error_o
);
	parameter [31:0] NumOutstanding = 32'd4;
	parameter [31:0] RevBitmapAddrWidth = 32'd11;
	parameter [31:0] RevBitmapBaseAddr = 32'h00000000;
	parameter [0:0] MemECC = 1'b1;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] heap_base_addr_i;
	input wire upstream_req_i;
	output wire upstream_gnt_o;
	output wire upstream_rvalid_o;
	input wire upstream_we_i;
	input wire [3:0] upstream_be_i;
	input wire [31:0] upstream_addr_i;
	input wire [31:0] upstream_wdata_i;
	input wire [6:0] upstream_wdata_intg_i;
	output wire [31:0] upstream_rdata_o;
	output wire [6:0] upstream_rdata_intg_o;
	output wire upstream_err_o;
	input wire upstream_tag_i;
	output wire upstream_tag_o;
	output wire downstream_req_o;
	input wire downstream_gnt_i;
	input wire downstream_rvalid_i;
	output wire downstream_we_o;
	output wire [3:0] downstream_be_o;
	output wire [31:0] downstream_addr_o;
	output wire [31:0] downstream_wdata_o;
	output wire [6:0] downstream_wdata_intg_o;
	input wire [31:0] downstream_rdata_i;
	input wire [6:0] downstream_rdata_intg_i;
	input wire downstream_err_i;
	output wire downstream_tag_o;
	input wire downstream_tag_i;
	output wire revbm_req_o;
	input wire revbm_gnt_i;
	input wire revbm_rvalid_i;
	output wire [31:0] revbm_addr_o;
	input wire [31:0] revbm_rdata_i;
	input wire [6:0] revbm_rdata_intg_i;
	input wire revbm_err_i;
	output wire revbm_data_intg_error_o;
	output wire revbm_device_error_o;
	localparam [31:0] RevBitmapWordAddrWidth = RevBitmapAddrWidth - 32'd2;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	wire align_fork_valid;
	wire align_fork_ready;
	wire misalign_flag_out;
	wire misalign_flag_out_valid;
	wire misalign_flag_out_ready;
	reg [31:0] ptr_storage_q;
	reg ptr_storage_valid_q;
	wire ptr_storage_enable;
	wire [40:0] downstream_rsp_in;
	wire [40:0] downstream_rsp_out;
	wire downstream_rsp_out_valid;
	wire downstream_rsp_out_ready;
	wire downstream_rsp_wready;
	wire unused_downstream_rsp_wready;
	wire [(((ibex_cheriot_pkg_EXP_W + ibex_cheriot_pkg_CBOUND_W) + ibex_cheriot_pkg_OTYPE_W) + ibex_cheriot_pkg_CPERMS_W) - 1:0] cap_meta;
	wire unused_cap_meta;
	wire is_sealing_cap;
	wire [32:0] cap_base_33;
	wire unused_cap_base_33;
	wire [31:0] cap_base;
	wire [8:0] addr_mid;
	wire [1:0] cap_correction;
	wire unused_cap_correction;
	wire [31:0] revbm_cap_addr;
	wire [31:0] revbm_bit_addr;
	wire [4:0] revbm_bit_select;
	wire [RevBitmapWordAddrWidth - 1:0] revbm_addr;
	wire revbm_out_of_range;
	wire revbm_req_required;
	wire revbm_rsp_ready;
	reg revbm_outstanding_q;
	wire revbm_revoked;
	wire [1:0] revbm_rsp_data_intg_error;
	stream_fork #(.N_OUP(32'd2)) u_stream_fork_us2ds(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(upstream_req_i),
		.ready_o(upstream_gnt_o),
		.valid_o({align_fork_valid, downstream_req_o}),
		.ready_i({align_fork_ready, downstream_gnt_i})
	);
	stream_join_dynamic #(.N_INP(32'd2)) u_stream_join_dynamic_ds2us(
		.inp_valid_i({revbm_rvalid_i, downstream_rsp_out_valid}),
		.inp_ready_o({revbm_rsp_ready, downstream_rsp_out_ready}),
		.sel_i({revbm_req_required, 1'b1}),
		.oup_valid_o(upstream_rvalid_o),
		.oup_ready_i(1'b1)
	);
	assign downstream_we_o = upstream_we_i;
	assign downstream_be_o = upstream_be_i;
	assign downstream_addr_o = upstream_addr_i;
	assign downstream_wdata_o = upstream_wdata_i;
	assign downstream_wdata_intg_o = upstream_wdata_intg_i;
	assign upstream_rdata_o = downstream_rsp_out[40-:32];
	assign upstream_rdata_intg_o = downstream_rsp_out[8-:7];
	assign upstream_err_o = downstream_rsp_out[0];
	assign downstream_tag_o = upstream_tag_i;
	assign upstream_tag_o = (revbm_rvalid_i ? !revbm_revoked : 1'b1) & downstream_rsp_out[1];
	prim_fifo_sync #(
		.Width(32'd1),
		.Pass(1'b0),
		.Depth(NumOutstanding),
		.NeverClears(1'b1),
		.Secure(1'b0)
	) u_prim_fifo_sync_align(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(align_fork_valid),
		.wready_o(align_fork_ready),
		.wdata_i(upstream_addr_i[2]),
		.rvalid_o(misalign_flag_out_valid),
		.rready_i(misalign_flag_out_ready),
		.rdata_o(misalign_flag_out),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	assign misalign_flag_out_ready = upstream_rvalid_o;
	assign ptr_storage_enable = (downstream_rsp_out[1] && !misalign_flag_out) && misalign_flag_out_valid;
	always @(posedge clk_i or negedge rst_ni) begin : proc_pointer_store
		if (!rst_ni)
			ptr_storage_q <= 1'sb0;
		else if (misalign_flag_out_ready && ptr_storage_enable)
			ptr_storage_q <= downstream_rsp_out[40-:32];
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_pointer_valid_store
		if (!rst_ni)
			ptr_storage_valid_q <= 1'b0;
		else if (misalign_flag_out_ready)
			ptr_storage_valid_q <= ptr_storage_enable;
	end
	assign downstream_rsp_in = {downstream_rdata_i, downstream_rdata_intg_i, downstream_tag_i, downstream_err_i};
	prim_fifo_sync #(
		.Width(41),
		.Pass(1'b1),
		.Depth(NumOutstanding),
		.NeverClears(1'b1),
		.Secure(1'b0)
	) u_prim_fifo_ds_rsp_store(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(downstream_rvalid_i),
		.wready_o(downstream_rsp_wready),
		.wdata_i(downstream_rsp_in),
		.rvalid_o(downstream_rsp_out_valid),
		.rready_i(downstream_rsp_out_ready),
		.rdata_o(downstream_rsp_out),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	function automatic [4:0] sv2v_cast_C6CBD;
		input reg [4:0] inp;
		sv2v_cast_C6CBD = inp;
	endfunction
	function automatic [8:0] sv2v_cast_1CF2E;
		input reg [8:0] inp;
		sv2v_cast_1CF2E = inp;
	endfunction
	function automatic [2:0] sv2v_cast_E4109;
		input reg [2:0] inp;
		sv2v_cast_E4109 = inp;
	endfunction
	function automatic [5:0] sv2v_cast_A63C5;
		input reg [5:0] inp;
		sv2v_cast_A63C5 = inp;
	endfunction
	assign cap_meta = {sv2v_cast_C6CBD(ibex_cheriot_pkg_cheriot_expand_exp(downstream_rsp_out[30:27])), sv2v_cast_1CF2E(downstream_rsp_out[17:9]), sv2v_cast_E4109(downstream_rsp_out[33:31]), sv2v_cast_A63C5(downstream_rsp_out[39:34])};
	assign unused_cap_meta = ^{cap_meta[8-:3], cap_meta[5]};
	function automatic ibex_cheriot_pkg_cheriot_is_sealing_cap;
		input reg [5:0] cperms;
		reg unused_cperms_gl;
		begin
			unused_cperms_gl = cperms[5];
			ibex_cheriot_pkg_cheriot_is_sealing_cap = (cperms[4:3] == 2'b00) && |cperms[2:0];
		end
	endfunction
	assign is_sealing_cap = ibex_cheriot_pkg_cheriot_is_sealing_cap(cap_meta[5-:ibex_cheriot_pkg_CPERMS_W]);
	assign addr_mid = sv2v_cast_1CF2E(ptr_storage_q >> cap_meta[22-:5]);
	function automatic [1:0] ibex_cheriot_pkg_cheriot_compute_corrections;
		input reg [8:0] top;
		input reg [8:0] base;
		input reg [8:0] addr;
		reg top_hi;
		reg addr_hi;
		begin
			top_hi = top < base;
			addr_hi = addr < base;
			ibex_cheriot_pkg_cheriot_compute_corrections = {top_hi ^ addr_hi, addr_hi};
		end
	endfunction
	assign cap_correction = ibex_cheriot_pkg_cheriot_compute_corrections(1'sb0, cap_meta[17-:9], addr_mid);
	function automatic [32:0] ibex_cheriot_pkg_cheriot_expand_bound33;
		input reg [8:0] mant;
		input reg [1:0] cor;
		input reg [4:0] exp5;
		input reg [31:0] addr;
		reg [32:0] cor_val;
		reg [32:0] mask;
		reg [32:0] bound;
		reg [32:0] mant_ext;
		begin
			if (cor[1])
				cor_val = {33 {1'b1}};
			else
				cor_val = {32'h00000000, cor[0]};
			cor_val = (cor_val << exp5) << ibex_cheriot_pkg_CBOUND_W;
			mask = (33'h1ffffffff << exp5) << ibex_cheriot_pkg_CBOUND_W;
			bound = ({1'b0, addr} & mask) + cor_val;
			mant_ext = {24'h000000, mant};
			bound = bound | (mant_ext << exp5);
			ibex_cheriot_pkg_cheriot_expand_bound33 = bound;
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_base_correction;
		input reg [1:0] cap_cor;
		reg unused_top_cor_bit;
		begin
			unused_top_cor_bit = cap_cor[1];
			ibex_cheriot_pkg_cheriot_get_base_correction = {2 {cap_cor[0]}};
		end
	endfunction
	assign cap_base_33 = ibex_cheriot_pkg_cheriot_expand_bound33(cap_meta[17-:9], ibex_cheriot_pkg_cheriot_get_base_correction(cap_correction), cap_meta[22-:5], ptr_storage_q);
	assign unused_cap_correction = ^cap_correction;
	assign {unused_cap_base_33, cap_base} = cap_base_33;
	assign revbm_cap_addr = cap_base - heap_base_addr_i;
	assign revbm_bit_addr = revbm_cap_addr >> 3;
	assign revbm_addr = revbm_bit_addr[RevBitmapWordAddrWidth + 4:5];
	assign revbm_bit_select = revbm_bit_addr[4:0];
	assign revbm_out_of_range = |revbm_bit_addr[31:RevBitmapWordAddrWidth + 5];
	assign revbm_req_required = (((((!is_sealing_cap && ptr_storage_valid_q) && downstream_rsp_out[1]) && downstream_rsp_out_valid) && misalign_flag_out) && misalign_flag_out_valid) && !revbm_out_of_range;
	assign revbm_req_o = revbm_req_required && !revbm_outstanding_q;
	assign revbm_addr_o = RevBitmapBaseAddr + {{(32 - RevBitmapWordAddrWidth) - 2 {1'b0}}, revbm_addr, 2'b00};
	assign revbm_revoked = (revbm_rdata_i[revbm_bit_select] || revbm_err_i) || |revbm_rsp_data_intg_error;
	assign revbm_device_error_o = revbm_rvalid_i && revbm_err_i;
	generate
		if (MemECC) begin : gen_revbm_intg_check
			prim_secded_inv_39_32_dec u_prim_secded_inv_39_32_dec_bm_rsp_data(
				.data_i({revbm_rdata_intg_i, revbm_rdata_i}),
				.data_o(),
				.syndrome_o(),
				.err_o(revbm_rsp_data_intg_error)
			);
			assign revbm_data_intg_error_o = revbm_rvalid_i && |revbm_rsp_data_intg_error;
		end
		else begin : gen_no_revbm_intg_check
			wire unused_revbm_rdata_intg;
			assign unused_revbm_rdata_intg = ^revbm_rdata_intg_i;
			assign revbm_rsp_data_intg_error = 2'b00;
			assign revbm_data_intg_error_o = 1'b0;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni) begin : proc_rev_req_store
		if (!rst_ni)
			revbm_outstanding_q <= 1'b0;
		else if (revbm_rvalid_i && revbm_rsp_ready)
			revbm_outstanding_q <= 1'b0;
		else if (revbm_req_o && revbm_gnt_i)
			revbm_outstanding_q <= 1'b1;
	end
	assign unused_downstream_rsp_wready = downstream_rsp_wready;
endmodule
module ibex_wb_stage (
	clk_i,
	rst_ni,
	en_wb_i,
	instr_type_wb_i,
	pc_id_i,
	instr_is_compressed_id_i,
	instr_perf_count_id_i,
	instr_is_cheriot_i,
	cheriot_load_i,
	cheriot_store_i,
	ready_wb_o,
	rf_write_wb_o,
	outstanding_load_wb_o,
	outstanding_store_wb_o,
	pc_wb_o,
	perf_instr_ret_wb_o,
	perf_instr_ret_compressed_wb_o,
	perf_instr_ret_wb_spec_o,
	perf_instr_ret_compressed_wb_spec_o,
	rf_waddr_id_i,
	rf_wdata_id_i,
	rf_we_id_i,
	cheriot_rf_we_i,
	cheriot_rf_wdata_i,
	cheriot_rf_wcap_i,
	dummy_instr_id_i,
	rf_wdata_lsu_i,
	rf_wcap_lsu_i,
	rf_we_lsu_i,
	rf_wdata_fwd_wb_o,
	rf_wcap_fwd_wb_o,
	rf_waddr_wb_o,
	rf_wdata_wb_o,
	rf_wcap_wb_o,
	rf_we_wb_o,
	dummy_instr_wb_o,
	lsu_resp_valid_i,
	lsu_resp_err_i,
	instr_done_wb_o
);
	parameter [0:0] ResetAll = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire en_wb_i;
	input wire [1:0] instr_type_wb_i;
	input wire [31:0] pc_id_i;
	input wire instr_is_compressed_id_i;
	input wire instr_perf_count_id_i;
	input wire instr_is_cheriot_i;
	input wire cheriot_load_i;
	input wire cheriot_store_i;
	output wire ready_wb_o;
	output wire rf_write_wb_o;
	output wire outstanding_load_wb_o;
	output wire outstanding_store_wb_o;
	output wire [31:0] pc_wb_o;
	output wire perf_instr_ret_wb_o;
	output wire perf_instr_ret_compressed_wb_o;
	output wire perf_instr_ret_wb_spec_o;
	output wire perf_instr_ret_compressed_wb_spec_o;
	input wire [4:0] rf_waddr_id_i;
	input wire [31:0] rf_wdata_id_i;
	input wire rf_we_id_i;
	input wire cheriot_rf_we_i;
	input wire [31:0] cheriot_rf_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] cheriot_rf_wcap_i;
	input wire dummy_instr_id_i;
	input wire [31:0] rf_wdata_lsu_i;
	input wire [34:0] rf_wcap_lsu_i;
	input wire rf_we_lsu_i;
	output wire [31:0] rf_wdata_fwd_wb_o;
	output wire [34:0] rf_wcap_fwd_wb_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire [31:0] rf_wdata_wb_o;
	output wire [34:0] rf_wcap_wb_o;
	output wire rf_we_wb_o;
	output wire dummy_instr_wb_o;
	input wire lsu_resp_valid_i;
	input wire lsu_resp_err_i;
	output wire instr_done_wb_o;
	wire [31:0] rf_wdata_wb_mux [0:1];
	wire [1:0] rf_wdata_wb_mux_we;
	wire [34:0] rf_wcap_wb;
	function automatic [5:0] sv2v_cast_F2A12;
		input reg [5:0] inp;
		sv2v_cast_F2A12 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_00AAE;
		input reg [2:0] inp;
		sv2v_cast_00AAE = inp;
	endfunction
	function automatic [3:0] sv2v_cast_B37C4;
		input reg [3:0] inp;
		sv2v_cast_B37C4 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_E1D39;
		input reg [8:0] inp;
		sv2v_cast_E1D39 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_F2A12(1'sb0), sv2v_cast_00AAE(1'sb0), sv2v_cast_B37C4(1'sb0), sv2v_cast_E1D39(1'sb0), sv2v_cast_E1D39(1'sb0)};
	generate
		if (WritebackStage) begin : g_writeback_stage
			reg [31:0] rf_wdata_wb_q;
			reg rf_we_wb_q;
			reg [4:0] rf_waddr_wb_q;
			wire wb_done;
			reg wb_valid_q;
			reg [31:0] wb_pc_q;
			reg wb_compressed_q;
			reg wb_count_q;
			reg [1:0] wb_instr_type_q;
			wire wb_valid_d;
			reg wb_is_cheriot_q;
			reg wb_cheriot_load_q;
			reg wb_cheriot_store_q;
			reg cheriot_rf_we_q;
			reg [31:0] cheriot_rf_wdata_q;
			reg [34:0] cheriot_rf_wcap_q;
			assign wb_valid_d = (en_wb_i & ready_wb_o) | (wb_valid_q & ~wb_done);
			assign wb_done = ((wb_instr_type_q == 2'd2) && ~(wb_is_cheriot_q && (wb_cheriot_load_q | wb_cheriot_store_q))) | lsu_resp_valid_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					wb_valid_q <= 1'b0;
				else
					wb_valid_q <= wb_valid_d;
			if (ResetAll) begin : g_wb_regs_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rf_we_wb_q <= 1'sb0;
						rf_waddr_wb_q <= 1'sb0;
						rf_wdata_wb_q <= 1'sb0;
						wb_instr_type_q <= 2'd0;
						wb_pc_q <= 1'sb0;
						wb_compressed_q <= 1'sb0;
						wb_count_q <= 1'sb0;
						wb_is_cheriot_q <= 1'b0;
						wb_cheriot_load_q <= 1'b0;
						wb_cheriot_store_q <= 1'b0;
						cheriot_rf_we_q <= 1'b0;
						cheriot_rf_wdata_q <= 1'sb0;
						cheriot_rf_wcap_q <= ibex_cheriot_pkg_NULL_CAP;
					end
					else if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
						wb_is_cheriot_q <= instr_is_cheriot_i;
						wb_cheriot_load_q <= cheriot_load_i;
						wb_cheriot_store_q <= cheriot_store_i;
						cheriot_rf_we_q <= cheriot_rf_we_i;
						cheriot_rf_wdata_q <= cheriot_rf_wdata_i;
						cheriot_rf_wcap_q <= cheriot_rf_wcap_i;
					end
			end
			else begin : g_wb_regs_nr
				always @(posedge clk_i)
					if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
						wb_is_cheriot_q <= instr_is_cheriot_i;
						wb_cheriot_load_q <= cheriot_load_i;
						wb_cheriot_store_q <= cheriot_store_i;
						cheriot_rf_we_q <= cheriot_rf_we_i;
						cheriot_rf_wdata_q <= cheriot_rf_wdata_i;
						cheriot_rf_wcap_q <= cheriot_rf_wcap_i;
					end
			end
			assign rf_waddr_wb_o = rf_waddr_wb_q;
			assign rf_wdata_wb_mux[0] = (wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q);
			assign rf_wdata_wb_mux_we[0] = (wb_is_cheriot_q ? cheriot_rf_we_q : rf_we_wb_q) & wb_valid_q;
			assign ready_wb_o = ~wb_valid_q | wb_done;
			assign rf_write_wb_o = wb_valid_q & (((rf_we_wb_q | (wb_is_cheriot_q & cheriot_rf_we_q)) | (wb_instr_type_q == 2'd0)) | wb_cheriot_load_q);
			assign outstanding_load_wb_o = wb_valid_q & ((wb_instr_type_q == 2'd0) | wb_cheriot_load_q);
			assign outstanding_store_wb_o = wb_valid_q & ((wb_instr_type_q == 2'd1) | wb_cheriot_store_q);
			assign pc_wb_o = wb_pc_q;
			assign instr_done_wb_o = wb_valid_q & wb_done;
			assign perf_instr_ret_wb_spec_o = wb_count_q & wb_valid_q;
			assign perf_instr_ret_compressed_wb_spec_o = perf_instr_ret_wb_spec_o & wb_compressed_q;
			assign perf_instr_ret_wb_o = (instr_done_wb_o & wb_count_q) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & wb_compressed_q;
			assign rf_wdata_fwd_wb_o = (wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q);
			assign rf_wcap_fwd_wb_o = (wb_is_cheriot_q ? cheriot_rf_wcap_q : ibex_cheriot_pkg_NULL_CAP);
			assign rf_wcap_wb = (wb_is_cheriot_q && ~wb_cheriot_load_q ? cheriot_rf_wcap_q : ibex_cheriot_pkg_NULL_CAP);
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			if (DummyInstructions) begin : g_dummy_instr_wb
				reg dummy_instr_wb_q;
				if (ResetAll) begin : g_dummy_instr_wb_regs_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							dummy_instr_wb_q <= 1'b0;
						else if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				else begin : g_dummy_instr_wb_regs_nr
					always @(posedge clk_i)
						if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				assign dummy_instr_wb_o = dummy_instr_wb_q;
			end
			else begin : g_no_dummy_instr_wb
				wire unused_dummy_instr_id;
				assign unused_dummy_instr_id = dummy_instr_id_i;
				assign dummy_instr_wb_o = 1'b0;
			end
		end
		else begin : g_bypass_wb
			assign rf_waddr_wb_o = rf_waddr_id_i;
			assign rf_wdata_wb_mux[0] = (instr_is_cheriot_i ? cheriot_rf_wdata_i : rf_wdata_id_i);
			assign rf_wdata_wb_mux_we[0] = (instr_is_cheriot_i ? cheriot_rf_we_i : rf_we_id_i);
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			assign rf_wcap_wb = (instr_is_cheriot_i && ~cheriot_load_i ? cheriot_rf_wcap_i : ibex_cheriot_pkg_NULL_CAP);
			assign dummy_instr_wb_o = dummy_instr_id_i;
			assign perf_instr_ret_wb_spec_o = 1'b0;
			assign perf_instr_ret_compressed_wb_spec_o = 1'b0;
			assign perf_instr_ret_wb_o = (instr_perf_count_id_i & en_wb_i) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & instr_is_compressed_id_i;
			assign ready_wb_o = 1'b1;
			wire unused_clk;
			wire unused_rst;
			wire [1:0] unused_instr_type_wb;
			wire [31:0] unused_pc_id;
			wire unused_dummy_instr_id;
			wire unused_cheriot_store;
			assign unused_clk = clk_i;
			assign unused_rst = rst_ni;
			assign unused_instr_type_wb = instr_type_wb_i;
			assign unused_pc_id = pc_id_i;
			assign unused_dummy_instr_id = dummy_instr_id_i;
			assign unused_cheriot_store = cheriot_store_i;
			assign outstanding_load_wb_o = 1'b0;
			assign outstanding_store_wb_o = 1'b0;
			assign pc_wb_o = 1'sb0;
			assign rf_write_wb_o = 1'b0;
			assign rf_wdata_fwd_wb_o = 32'b00000000000000000000000000000000;
			assign rf_wcap_fwd_wb_o = ibex_cheriot_pkg_NULL_CAP;
			assign instr_done_wb_o = 1'b0;
		end
	endgenerate
	assign rf_wdata_wb_mux[1] = rf_wdata_lsu_i;
	assign rf_wdata_wb_o = ({32 {rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) | ({32 {rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]);
	assign rf_we_wb_o = |rf_wdata_wb_mux_we;
	assign rf_wcap_wb_o = (rf_wdata_wb_mux_we[0] ? rf_wcap_wb : (rf_wdata_wb_mux_we[1] ? rf_wcap_lsu_i : ibex_cheriot_pkg_NULL_CAP));
endmodule
module prim_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	wire [Width - 1:0] inv;
	assign inv = ~in_i;
	assign out_o = ~inv;
endmodule
module prim_flop (
	clk_i,
	rst_ni,
	d_i,
	q_o
);
	parameter signed [31:0] Width = 1;
	parameter [Width - 1:0] ResetValue = 0;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d_i;
	output reg [Width - 1:0] q_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			q_o <= ResetValue;
		else
			q_o <= d_i;
endmodule
module prim_and2 (
	in0_i,
	in1_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in0_i;
	input [Width - 1:0] in1_i;
	output wire [Width - 1:0] out_o;
	assign out_o = in0_i & in1_i;
endmodule
module prim_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	assign clk_o = (sel_i & clk1_i) | (~sel_i & clk0_i);
endmodule
module prim_count (
	clk_i,
	rst_ni,
	clr_i,
	set_i,
	set_cnt_i,
	incr_en_i,
	decr_en_i,
	step_i,
	commit_i,
	cnt_o,
	cnt_after_commit_o,
	err_o
);
	parameter signed [31:0] Width = 2;
	parameter [Width - 1:0] ResetValue = 1'sb0;
	parameter [0:0] EnableAlertTriggerSVA = 1;
	parameter [3:0] PossibleActions = {4 {1'b1}};
	input clk_i;
	input rst_ni;
	input clr_i;
	input set_i;
	input [Width - 1:0] set_cnt_i;
	input incr_en_i;
	input decr_en_i;
	input [Width - 1:0] step_i;
	input commit_i;
	output wire [Width - 1:0] cnt_o;
	output wire [Width - 1:0] cnt_after_commit_o;
	output wire err_o;
	localparam signed [31:0] NumCnt = 2;
	localparam [(NumCnt * Width) - 1:0] ResetValues = {{Width {1'b1}} - ResetValue, ResetValue};
	wire [(NumCnt * Width) - 1:0] cnt_d;
	wire [(NumCnt * Width) - 1:0] cnt_d_committed;
	wire [(NumCnt * Width) - 1:0] cnt_q;
	wire [(NumCnt * Width) - 1:0] fpv_force;
	assign fpv_force = 1'sb0;
	genvar _gv_k_3;
	generate
		for (_gv_k_3 = 0; _gv_k_3 < NumCnt; _gv_k_3 = _gv_k_3 + 1) begin : gen_cnts
			localparam k = _gv_k_3;
			wire incr_en;
			wire decr_en;
			wire [Width - 1:0] set_val;
			if (k == 0) begin : gen_up_cnt
				assign incr_en = incr_en_i;
				assign decr_en = decr_en_i;
				assign set_val = set_cnt_i;
			end
			else begin : gen_dn_cnt
				assign incr_en = decr_en_i;
				assign decr_en = incr_en_i;
				assign set_val = {Width {1'b1}} - set_cnt_i;
			end
			wire [Width:0] ext_cnt;
			assign ext_cnt = (decr_en ? {1'b0, cnt_q[k * Width+:Width]} - {1'b0, step_i} : (incr_en ? {1'b0, cnt_q[k * Width+:Width]} + {1'b0, step_i} : {1'b0, cnt_q[k * Width+:Width]}));
			wire uflow;
			wire oflow;
			assign oflow = incr_en && ext_cnt[Width];
			assign uflow = decr_en && ext_cnt[Width];
			wire [Width - 1:0] cnt_sat;
			assign cnt_sat = (uflow ? {Width {1'sb0}} : (oflow ? {Width {1'b1}} : ext_cnt[Width - 1:0]));
			wire cnt_en;
			assign cnt_en = (incr_en ^ decr_en) && ((incr_en && !(&cnt_q[k * Width+:Width])) || (decr_en && (cnt_q[k * Width+:Width] != {Width * 1 {1'sb0}})));
			assign cnt_d[k * Width+:Width] = (clr_i ? ResetValues[k * Width+:Width] : (set_i ? set_val : (cnt_en ? cnt_sat : cnt_q[k * Width+:Width])));
			assign cnt_d_committed[k * Width+:Width] = (commit_i ? cnt_d[k * Width+:Width] : cnt_q[k * Width+:Width]);
			wire [Width - 1:0] cnt_unforced_q;
			prim_flop #(
				.Width(Width),
				.ResetValue(ResetValues[k * Width+:Width])
			) u_cnt_flop(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d_i(cnt_d_committed[k * Width+:Width]),
				.q_o(cnt_unforced_q)
			);
			assign cnt_q[k * Width+:Width] = fpv_force[k * Width+:Width] + cnt_unforced_q;
		end
	endgenerate
	wire [Width:0] sum;
	assign sum = cnt_q[0+:Width] + cnt_q[Width+:Width];
	wire err_d;
	reg err_q;
	assign err_d = sum != {1'b0, {Width {1'b1}}};
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			err_q <= 1'b0;
		else
			err_q <= err_d;
	assign err_o = err_q;
	assign cnt_o = cnt_q[0+:Width];
	assign cnt_after_commit_o = cnt_d[0+:Width];
endmodule
module prim_lfsr (
	clk_i,
	rst_ni,
	seed_en_i,
	seed_i,
	lfsr_en_i,
	entropy_i,
	state_o
);
	reg _sv2v_0;
	parameter LfsrType = "GAL_XOR";
	parameter [31:0] LfsrDw = 32;
	localparam [31:0] LfsrIdxDw = $clog2(LfsrDw);
	parameter [31:0] EntropyDw = 8;
	parameter [31:0] StateOutDw = 8;
	function automatic signed [LfsrDw - 1:0] sv2v_cast_C2EBB_signed;
		input reg signed [LfsrDw - 1:0] inp;
		sv2v_cast_C2EBB_signed = inp;
	endfunction
	parameter [LfsrDw - 1:0] DefaultSeed = sv2v_cast_C2EBB_signed(1);
	parameter [LfsrDw - 1:0] CustomCoeffs = 1'sb0;
	parameter [0:0] StatePermEn = 1'b0;
	parameter [(LfsrDw * LfsrIdxDw) - 1:0] StatePerm = 1'sb0;
	parameter [0:0] MaxLenSVA = 1'b1;
	parameter [0:0] LockupSVA = 1'b1;
	parameter [0:0] ExtSeedSVA = 1'b1;
	parameter [0:0] NonLinearOut = 1'b0;
	input clk_i;
	input rst_ni;
	input seed_en_i;
	input [LfsrDw - 1:0] seed_i;
	input lfsr_en_i;
	input [EntropyDw - 1:0] entropy_i;
	output wire [StateOutDw - 1:0] state_o;
	localparam [31:0] LUT_OFF = 3;
	localparam [27887:0] LFSR_COEFFS = 27888'h600000000000000000000000000000000000000000c0000000000000000000000000000000000000000140000000000000000000000000000000000000000300000000000000000000000000000000000000000600000000000000000000000000000000000000000b800000000000000000000000000000000000000011000000000000000000000000000000000000000024000000000000000000000000000000000000000050000000000000000000000000000000000000000082900000000000000000000000000000000000000100d00000000000000000000000000000000000000201500000000000000000000000000000000000000600000000000000000000000000000000000000000d008000000000000000000000000000000000000012000000000000000000000000000000000000000020400000000000000000000000000000000000000040023000000000000000000000000000000000000090000000000000000000000000000000000000000140000000000000000000000000000000000000000300000000000000000000000000000000000000000420000000000000000000000000000000000000000e1000000000000000000000000000000000000000120000000000000000000000000000000000000000200002300000000000000000000000000000000000400001300000000000000000000000000000000000900000000000000000000000000000000000000001400000000000000000000000000000000000000002000002900000000000000000000000000000000004800000000000000000000000000000000000000008020000300000000000000000000000000000000010008000000000000000000000000000000000000020400000300000000000000000000000000000000050000000000000000000000000000000000000000080100000000000000000000000000000000000000100000001f00000000000000000000000000000000200000003100000000000000000000000000000000440000000000000000000000000000000000000000a0001400000000000000000000000000000000000120000000000000000000000000000000000000000300000c00000000000000000000000000000000000630000000000000000000000000000000000000000c00000300000000000000000000000000000000001b0000000000000000000000000000000000000000300003000000000000000000000000000000000000420000000000000000000000000000000000000000c00000180000000000000000000000000000000001008000000000000000000000000000000000000003000000c00000000000000000000000000000000006000c000000000000000000000000000000000000090000000000000000000000000000000000000000180030000000000000000000000000000000000000300000000300000000000000000000000000000000400000400000000000000000000000000000000000c0000600000000000000000000000000000000000102000000000000000000000000000000000000000200004000000000000000000000000000000000000600003000000000000000000000000000000000000c0000000000000000000000000000000000000000180030000000000000000000000000000000000000300000000000003000000000000000000000000000600000000000000000000000000000000000000000d80000000000000000000000000000000000000001000040000000000000000000000000000000000003018000000000000000000000000000000000000006030000000000000000000000000000000000000008040000000000000000000000000000000000000014000002800000000000000000000000000000000030006000000000000000000000000000000000000041000000000000000000000000000000000000000082000000000104000000000000000000000000000100000080000000000000000000000000000000000300060000000000000000000000000000000000000601800000000000000000000000000000000000000c0000000180000000000000000000000000000000180000006000000000000000000000000000000000300006000000000000000000000000000000000000402000000000000000000000000000000000000000c000000006000000000000000000000000000000011000000000000000000000000000000000000000024000000048000000000000000000000000000000060000000000300000000000000000000000000000080040000000000000000000000000000000000000180000030000000000000000000000000000000000300300000000000000000000000000000000000000400200000000000000000000000000000000000000c000000000000000018000000000000000000000010000000004000000000000000000000000000000030000c000000000000000000000000000000000000600000000000000000000c00000000000000000000c00c0000000000000000000000000000000000000140000000000000000000000000000000000000000200001000000000000000000000000000000000000400800000000000000000000000000000000000000a00000000001400000000000000000000000000001040000000000000000000000000000000000000002004000000000000000000000000000000000000005000000000028000000000000000000000000000008000000004000000000000000000000000000000018600000000000000000000000000000000000000030000000000000000c000000000000000000000000402000000000000000000000000000000000000000c03000000000000000000000000000000000000001000100000000000000000000000000000000000002000400000000000000000000000000000000000005000000000000000a000000000000000000000000080000001000000000000000000000000000000000186000000000000000000000000000000000000000300300000000000000000000000000000000000000401000000000000000000000000000000000000000a0000000001400000000000000000000000000000100800000000000000000000000000000000000000300000000000000000001800000000000000000000600180000000000000000000000000000000000000c00000000000000003000000000000000000000001400050000000000000000000000000000000000002000000010000000000000000000000000000000004040000000000000000000000000000000000000008100000000000000000000000001020000000000010000400000000000000000000000000000000000030000000000000060000000000000000000000000050000000000000000000000000000000000000000080000000040000000000000000000000000000000180000000000000000000000000300000000000000300000000300000000000000000000000000000000600000000000000000000000000000000000000000a0000014000000000000000000000000000000000108000000000000000000000000000000000000000240000000000000000000000000000000000000000600000000000c0000000000000000000000000000080000004000000000000000000000000000000000180000000000030000000000000000000000000000200000000000001000000000000000000000000000400800000000000000000000000000000000000000c00000000000000000000000000000060000000001000008000000000000000000000000000000000003060000000000000000000000000000000000000004a400000000000000000000000000000000000000080000004000000000000000000000000000000000180000003000000000000000000000000000000000200001000000000000000000000000000000000000600006000000000000000000000000000000000000c0000000000000000600000000000000000000000100000000000010000000000000000000000000000300000000000000600000000000000000000000000600000000300000000000000000000000000000000800000100000000000000000000000000000000001800000000000000000000000000c0000000000000200000000000010000000000000000000000000000480000000000000000000000000000000000000000c000000000000000600000000000000000000000018000000000000000000000000000000000000000028000000000000000000000000000000500000000060000000c000000000000000000000000000000000c00000000000000000000000000018000000000001800000600000000000000000000000000000000003000000c0000000000000000000000000000000000400000008000000000000000000000000000000000c0003000000000000000000000000000000000000100004000000000000000000000000000000000000300000000000000000000060000000000000000000600000000000000c00000000000000000000000000c00600000000000000000000000000000000000001800000060000000000000000000000000000000003000000000c0000000000000000000000000000000410000000000000000000000000000000000000000a00140000000000000000000000000000000000000;
	wire lockup;
	wire [LfsrDw - 1:0] lfsr_d;
	reg [LfsrDw - 1:0] lfsr_q;
	wire [LfsrDw - 1:0] next_lfsr_state;
	wire [LfsrDw - 1:0] coeffs;
	localparam [LfsrDw - 1:0] DefaultSeedLocal = DefaultSeed;
	function automatic [LfsrDw - 1:0] sv2v_cast_C2EBB;
		input reg [LfsrDw - 1:0] inp;
		sv2v_cast_C2EBB = inp;
	endfunction
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	generate
		if (sv2v_cast_64(LfsrType) == 64'd20056519619399506) begin : gen_gal_xor
			if (CustomCoeffs > 0) begin : gen_custom
				assign coeffs = CustomCoeffs[LfsrDw - 1:0];
			end
			else begin : gen_lut
				assign coeffs = LFSR_COEFFS[((165 - (LfsrDw - LUT_OFF)) * 168) + (LfsrDw - 1)-:LfsrDw];
			end
			assign next_lfsr_state = (sv2v_cast_C2EBB(entropy_i) ^ ({LfsrDw {lfsr_q[0]}} & coeffs)) ^ (lfsr_q >> 1);
			assign lockup = ~(|lfsr_q);
		end
		else if (sv2v_cast_64(LfsrType) == "FIB_XNOR") begin : gen_fib_xnor
			if (CustomCoeffs > 0) begin : gen_custom
				assign coeffs = CustomCoeffs[LfsrDw - 1:0];
			end
			else begin : gen_lut
				assign coeffs = LFSR_COEFFS[((165 - (LfsrDw - LUT_OFF)) * 168) + (LfsrDw - 1)-:LfsrDw];
			end
			assign next_lfsr_state = sv2v_cast_C2EBB(entropy_i) ^ {lfsr_q[LfsrDw - 2:0], ~(^(lfsr_q & coeffs))};
			assign lockup = &lfsr_q;
		end
		else begin : gen_unknown_type
			assign coeffs = 1'sb0;
			assign next_lfsr_state = 1'sb0;
			assign lockup = 1'b0;
		end
	endgenerate
	assign lfsr_d = (seed_en_i ? seed_i : (lfsr_en_i && lockup ? DefaultSeedLocal : (lfsr_en_i ? next_lfsr_state : lfsr_q)));
	wire [LfsrDw - 1:0] sbox_out;
	localparam [63:0] prim_cipher_pkg_PRINCE_SBOX4 = 64'h4d5e087619ca23fb;
	generate
		if (NonLinearOut) begin : gen_out_non_linear
			localparam signed [31:0] NumSboxes = LfsrDw / 4;
			wire [((4 * NumSboxes) * LfsrIdxDw) - 1:0] matrix_indices;
			genvar _gv_j_1;
			for (_gv_j_1 = 0; _gv_j_1 < LfsrDw; _gv_j_1 = _gv_j_1 + 1) begin : gen_input_idx_map
				localparam j = _gv_j_1;
				assign matrix_indices[(((j / NumSboxes) * NumSboxes) + (j % NumSboxes)) * LfsrIdxDw+:LfsrIdxDw] = j;
			end
			reg [((4 * NumSboxes) * LfsrIdxDw) - 1:0] matrix_rotrev_indices;
			function automatic [(NumSboxes * LfsrIdxDw) - 1:0] lrotcol;
				input reg [(NumSboxes * LfsrIdxDw) - 1:0] col;
				input integer shift;
				reg [(NumSboxes * LfsrIdxDw) - 1:0] out;
				begin
					begin : sv2v_autoblock_1
						reg signed [31:0] k;
						for (k = 0; k < NumSboxes; k = k + 1)
							out[((k + shift) % NumSboxes) * LfsrIdxDw+:LfsrIdxDw] = col[k * LfsrIdxDw+:LfsrIdxDw];
					end
					lrotcol = out;
				end
			endfunction
			function automatic [(NumSboxes * LfsrIdxDw) - 1:0] revcol;
				input reg [(NumSboxes * LfsrIdxDw) - 1:0] col;
				reg [(0 + (NumSboxes * LfsrIdxDw)) - 1:0] _sv2v_strm_45112_inp;
				reg [(0 + (NumSboxes * LfsrIdxDw)) - 1:0] _sv2v_strm_45112_out;
				integer _sv2v_strm_45112_idx;
				begin
					_sv2v_strm_45112_inp = {col};
					for (_sv2v_strm_45112_idx = 0; _sv2v_strm_45112_idx <= ((0 + (NumSboxes * LfsrIdxDw)) - LfsrIdxDw); _sv2v_strm_45112_idx = _sv2v_strm_45112_idx + LfsrIdxDw)
						_sv2v_strm_45112_out[((0 + (NumSboxes * LfsrIdxDw)) - 1) - _sv2v_strm_45112_idx-:LfsrIdxDw] = _sv2v_strm_45112_inp[_sv2v_strm_45112_idx+:LfsrIdxDw];
					if (((0 + (NumSboxes * LfsrIdxDw)) % LfsrIdxDw) > 0)
						_sv2v_strm_45112_out[0+:(0 + (NumSboxes * LfsrIdxDw)) % LfsrIdxDw] = _sv2v_strm_45112_inp[_sv2v_strm_45112_idx+:(0 + (NumSboxes * LfsrIdxDw)) % LfsrIdxDw];
					revcol = ((0 + (NumSboxes * LfsrIdxDw)) <= (NumSboxes * LfsrIdxDw) ? _sv2v_strm_45112_out << ((NumSboxes * LfsrIdxDw) - (0 + (NumSboxes * LfsrIdxDw))) : _sv2v_strm_45112_out >> ((0 + (NumSboxes * LfsrIdxDw)) - (NumSboxes * LfsrIdxDw)));
				end
			endfunction
			always @(*) begin : p_rotrev
				if (_sv2v_0)
					;
				matrix_rotrev_indices[0+:LfsrIdxDw * NumSboxes] = matrix_indices[0+:LfsrIdxDw * NumSboxes];
				matrix_rotrev_indices[LfsrIdxDw * NumSboxes+:LfsrIdxDw * NumSboxes] = lrotcol(matrix_indices[LfsrIdxDw * NumSboxes+:LfsrIdxDw * NumSboxes], NumSboxes / 2);
				matrix_rotrev_indices[LfsrIdxDw * (2 * NumSboxes)+:LfsrIdxDw * NumSboxes] = revcol(matrix_indices[LfsrIdxDw * (2 * NumSboxes)+:LfsrIdxDw * NumSboxes]);
				matrix_rotrev_indices[LfsrIdxDw * (3 * NumSboxes)+:LfsrIdxDw * NumSboxes] = revcol(lrotcol(matrix_indices[LfsrIdxDw * (3 * NumSboxes)+:LfsrIdxDw * NumSboxes], 1));
			end
			wire [(LfsrDw * LfsrIdxDw) - 1:0] sbox_in_indices;
			genvar _gv_k_4;
			for (_gv_k_4 = 0; _gv_k_4 < LfsrDw; _gv_k_4 = _gv_k_4 + 1) begin : gen_reverse_upper
				localparam k = _gv_k_4;
				assign sbox_in_indices[k * LfsrIdxDw+:LfsrIdxDw] = matrix_rotrev_indices[(((k % 4) * NumSboxes) + (k / 4)) * LfsrIdxDw+:LfsrIdxDw];
			end
			genvar _gv_k_5;
			for (_gv_k_5 = 0; _gv_k_5 < NumSboxes; _gv_k_5 = _gv_k_5 + 1) begin : gen_sboxes
				localparam k = _gv_k_5;
				wire [3:0] sbox_in;
				assign sbox_in = {lfsr_q[sbox_in_indices[((k * 4) + 3) * LfsrIdxDw+:LfsrIdxDw]], lfsr_q[sbox_in_indices[((k * 4) + 2) * LfsrIdxDw+:LfsrIdxDw]], lfsr_q[sbox_in_indices[((k * 4) + 1) * LfsrIdxDw+:LfsrIdxDw]], lfsr_q[sbox_in_indices[((k * 4) + 0) * LfsrIdxDw+:LfsrIdxDw]]};
				assign sbox_out[k * 4+:4] = prim_cipher_pkg_PRINCE_SBOX4[sbox_in * 4+:4];
			end
		end
		else begin : gen_out_passthru
			assign sbox_out = lfsr_q;
		end
	endgenerate
	function automatic [StateOutDw - 1:0] sv2v_cast_7F415;
		input reg [StateOutDw - 1:0] inp;
		sv2v_cast_7F415 = inp;
	endfunction
	generate
		if (StatePermEn) begin : gen_state_perm
			genvar _gv_k_6;
			for (_gv_k_6 = 0; _gv_k_6 < StateOutDw; _gv_k_6 = _gv_k_6 + 1) begin : gen_perm_loop
				localparam k = _gv_k_6;
				assign state_o[k] = sbox_out[StatePerm[k * LfsrIdxDw+:LfsrIdxDw]];
			end
			if (LfsrDw > StateOutDw) begin : gen_tieoff_unused
				wire unused_sbox_out;
				assign unused_sbox_out = ^sbox_out;
			end
		end
		else begin : gen_no_state_perm
			assign state_o = sv2v_cast_7F415(sbox_out);
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni) begin : p_reg
		if (!rst_ni)
			lfsr_q <= DefaultSeedLocal;
		else
			lfsr_q <= lfsr_d;
	end
	initial _sv2v_0 = 0;
endmodule
module prim_secded_inv_39_32_dec (
	data_i,
	data_o,
	syndrome_o,
	err_o
);
	reg _sv2v_0;
	input [38:0] data_i;
	output reg [31:0] data_o;
	output reg [6:0] syndrome_o;
	output reg [1:0] err_o;
	always @(*) begin : p_encode
		if (_sv2v_0)
			;
		syndrome_o[0] = ^((data_i ^ 39'h2a00000000) & 39'h012606bd25);
		syndrome_o[1] = ^((data_i ^ 39'h2a00000000) & 39'h02deba8050);
		syndrome_o[2] = ^((data_i ^ 39'h2a00000000) & 39'h04413d89aa);
		syndrome_o[3] = ^((data_i ^ 39'h2a00000000) & 39'h0831234ed1);
		syndrome_o[4] = ^((data_i ^ 39'h2a00000000) & 39'h10c2c1323b);
		syndrome_o[5] = ^((data_i ^ 39'h2a00000000) & 39'h202dcc624c);
		syndrome_o[6] = ^((data_i ^ 39'h2a00000000) & 39'h4098505586);
		data_o[0] = (syndrome_o == 7'h19) ^ data_i[0];
		data_o[1] = (syndrome_o == 7'h54) ^ data_i[1];
		data_o[2] = (syndrome_o == 7'h61) ^ data_i[2];
		data_o[3] = (syndrome_o == 7'h34) ^ data_i[3];
		data_o[4] = (syndrome_o == 7'h1a) ^ data_i[4];
		data_o[5] = (syndrome_o == 7'h15) ^ data_i[5];
		data_o[6] = (syndrome_o == 7'h2a) ^ data_i[6];
		data_o[7] = (syndrome_o == 7'h4c) ^ data_i[7];
		data_o[8] = (syndrome_o == 7'h45) ^ data_i[8];
		data_o[9] = (syndrome_o == 7'h38) ^ data_i[9];
		data_o[10] = (syndrome_o == 7'h49) ^ data_i[10];
		data_o[11] = (syndrome_o == 7'h0d) ^ data_i[11];
		data_o[12] = (syndrome_o == 7'h51) ^ data_i[12];
		data_o[13] = (syndrome_o == 7'h31) ^ data_i[13];
		data_o[14] = (syndrome_o == 7'h68) ^ data_i[14];
		data_o[15] = (syndrome_o == 7'h07) ^ data_i[15];
		data_o[16] = (syndrome_o == 7'h1c) ^ data_i[16];
		data_o[17] = (syndrome_o == 7'h0b) ^ data_i[17];
		data_o[18] = (syndrome_o == 7'h25) ^ data_i[18];
		data_o[19] = (syndrome_o == 7'h26) ^ data_i[19];
		data_o[20] = (syndrome_o == 7'h46) ^ data_i[20];
		data_o[21] = (syndrome_o == 7'h0e) ^ data_i[21];
		data_o[22] = (syndrome_o == 7'h70) ^ data_i[22];
		data_o[23] = (syndrome_o == 7'h32) ^ data_i[23];
		data_o[24] = (syndrome_o == 7'h2c) ^ data_i[24];
		data_o[25] = (syndrome_o == 7'h13) ^ data_i[25];
		data_o[26] = (syndrome_o == 7'h23) ^ data_i[26];
		data_o[27] = (syndrome_o == 7'h62) ^ data_i[27];
		data_o[28] = (syndrome_o == 7'h4a) ^ data_i[28];
		data_o[29] = (syndrome_o == 7'h29) ^ data_i[29];
		data_o[30] = (syndrome_o == 7'h16) ^ data_i[30];
		data_o[31] = (syndrome_o == 7'h52) ^ data_i[31];
		err_o[0] = ^syndrome_o;
		err_o[1] = ~err_o[0] & |syndrome_o;
	end
	initial _sv2v_0 = 0;
endmodule
module prim_secded_inv_39_32_enc (
	data_i,
	data_o
);
	reg _sv2v_0;
	input [31:0] data_i;
	output reg [38:0] data_o;
	function automatic [38:0] sv2v_cast_39;
		input reg [38:0] inp;
		sv2v_cast_39 = inp;
	endfunction
	always @(*) begin : p_encode
		if (_sv2v_0)
			;
		data_o = sv2v_cast_39(data_i);
		data_o[32] = ^(data_o & 39'h002606bd25);
		data_o[33] = ^(data_o & 39'h00deba8050);
		data_o[34] = ^(data_o & 39'h00413d89aa);
		data_o[35] = ^(data_o & 39'h0031234ed1);
		data_o[36] = ^(data_o & 39'h00c2c1323b);
		data_o[37] = ^(data_o & 39'h002dcc624c);
		data_o[38] = ^(data_o & 39'h0098505586);
		data_o = data_o ^ 39'h2a00000000;
	end
	initial _sv2v_0 = 0;
endmodule
