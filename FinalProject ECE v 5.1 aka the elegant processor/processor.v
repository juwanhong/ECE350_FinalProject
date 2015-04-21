module processor(clock, reset, ps2_key_pressed, ps2_out, lcd_write, lcd_data, debug_data, debug_addr, ALU_operand_A
ALU_operand_B, ALU_RESULT_X, RESULT_X_STAGE, RESULT_M_STAGE, RESULT_W_STAGE);

	input 			clock, reset, ps2_key_pressed;
	input 	[7:0]	ps2_out;
	
	output 			lcd_write;
	output 	[31:0] 	lcd_data;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	debug_data;
	output	[11:0]	debug_addr;
	
	
	wire rs;
	assign rs = reset;
	wire wrE = 1'b1;
	// your processor here
	//
wire [31:0] curr_PC;
wire [31:0] next_PC;
wire [31:0] PC_F;
wire [31:0] PC_D;
wire [31:0] PC_X;
register32B program_counter(.wrE(1'b1)
						,.din(next_PC)
						,.rs(rs)
						,.dout(curr_PC)
						,.clock(clock));
						

Adder PC_plus_one(.A(curr_PC)
				,.B(0)
				,.Cin(1'b1)
				,.out(PC_F)
);

wire [31:0] STATUS_out;
wire [31:0] NEW_STATUS;
register32B STATUS(.wrE(D_contrl_D[0] | EX_W)
					,.din(NEW_STATUS)
					,.rs(rs)
					,.dout(STATUS_out)
					,.clock(clock));

wire [31:0] RSA_DATA_D;
wire [31:0] RSB_DATA_D;
wire [31:0] RSA_DATA_X;
wire [31:0] RSB_DATA_X;
wire TAKE_BRANCHJUMP;
wire [31:0] JUMPBRANCH_PC;
wire [31:0] REG_WRITE_DATA_W;
regFile registerFile(.clock(clock)
					,.ctrl_writeEnable(W_contrl_W[0])
					,.ctrl_reset(rs)
					,.ctrl_writeReg(RegNums_W[14:10])
					,.ctrl_readRegA(RegNums_D[9:5])
					,.ctrl_readRegB(RegNums_D[4:0])
					,.data_writeReg(RESULT_W_STAGE)
					,.data_readRegA(RSA_DATA_D)
					,.data_readRegB(RSB_DATA_D));



wire [31:0] BRANCH_DATA_IN_A;
wire [31:0] BRANCH_DATA_IN_B;
Branch_Control PC_CONTROLLER(.PC_in(PC_D)
				,.instr_D(instr_D)
				,.STATUS_in(STATUS_out)
				,.REG_A(BRANCH_DATA_IN_A)
				,.REG_B(BRANCH_DATA_IN_B)
				,.lag()
				,.jb_control(TAKE_BRANCHJUMP)
				,.address_jb(JUMPBRANCH_PC));

wire [7:0] D_contrl_D;
wire [7:0] X_contrl_D;
wire [7:0] X_contrl_X;
wire [7:0] M_contrl_D;
wire [7:0] M_contrl_X;
wire [7:0] M_contrl_M;
wire [7:0] W_contrl_D;
wire [7:0] W_contrl_X;
wire [7:0] W_contrl_M;
wire [7:0] W_contrl_W;
wire [15:0] RegNums_D;
wire [15:0] RegNums_X;
wire [15:0] RegNums_M;
wire [15:0] RegNums_W;


wire [11:0] bypass_en;
wire [7:0] stall_en;
wire [31:0] oneH_signals_D;
Control Controller(.instr_D(instr_D)
					,.DSignals(D_contrl_D)
					,.RegNums(RegNums_D)
					,.oneH(oneH_signals_D)
					,.XSignals(X_contrl_D)
					,.WSignals(W_contrl_D)
					,.MSignals(M_contrl_D));

StallBypassControl(.D(instr_D)
					,.X(instr_X)
					,.M(instr_M)
					,.W(instr_W)
					,.branchTaken(TAKE_BRANCHJUMP)
					,.RegNums_D(RegNums_D)
					,.RegNums_X(RegNums_X)
					,.RegNums_M(RegNums_M)
					,.RegNums_W(RegNums_W)
					, .stall(stall_en)
					,.nop()
					,.bypass(bypass_en)
					,.clock(clock)
					,.busy_stage()
					,.bp_reqX()
					,.exc_piped());
wire [31:0] EX_W;
output [31:0] ALU_operand_A;
output [31:0] ALU_operand_B;
output [31:0] ALU_RESULT_X;
output [31:0] RESULT_X_STAGE;
output [31:0] RESULT_M_STAGE;
output [31:0] RESULT_W_STAGE;
wire [31:0] RESULT_W_STAGE_t;
ALU datapath_ALU(.opA(ALU_operand_A)
				,.opB(ALU_operand_B)
				,.res(ALU_RESULT_X)
				,.shiftamt(instr_X[11:7])
				,.opcode(instr_X[6:2])
				,.lt()
				,.ne()
				,.ex(EX_W)
				,.res_RDY()
				,.inp_RDY()
				,.clock(clock));
				

wire [31:0] MEMREAD_RESULT_W;
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
	assign debug_addr = RESULT_M_STAGE;
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
	assign debug_data = MEM_DATA_INPUT;
	////////////////////////////////////////////////////////////
	// You'll need to change where the dmem and imem read and write...
	dmem mydmem(	.address	(RESULT_M_STAGE),
					.clock		(clock),
					.data		(MEM_DATA_INPUT),
					.wren		(M_contrl_M[0]), // 1'b1
					.q			(MEMREAD_RESULT_W)//);
	);
	
	imem myimem(	.address 	(PC_F),
					.clken		(1'b1),
					.clock		(~clock),
					.q 			(instr_F)
	); 

wire [31:0] immed_D;
wire [31:0] immed_X;
wire [31:0] RSA_CORR_X;
wire [31:0] RSB_CORR_X;
wire [31:0] MEM_DATA_INPUT;
wire [31:0] RSA_DATA_M;
genvar i;
generate
for (i = 0; i < 32; i = i + 1)begin: TRISTATES32

			TRI PC_BRANCHJ00(.in(PC_F[i]), .out(next_PC[i]), .oe(~JUMPBRANCH_PC)); //BRANCH OR JUMP			
			TRI PC_BRANCHJ11(.in(JUMPBRANCH_PC[i]), .out(next_PC[i]), .oe(JUMPBRANCH_PC)); //

			TRI STATUS_sel0(.in(EX_W[i]), .out(NEW_STATUS[i]), .oe(~D_contrl_D[0])); //BYPASS			
			TRI STATUS_sel1(.in(immed_D[i]), .out(NEW_STATUS[i]), .oe(D_contrl_D[0])); //BYPASS
			
	
			TRI RSA_Sel00_X(.in(RSA_DATA_X[i]), .out(RSA_CORR_X[i]), .oe(~(bypass_en[6]|bypass_en[7]))); //NO BYPASS TO X
			TRI RSA_Sel01_X(.in(RESULT_W_STAGE[i]), .out(RSA_CORR_X[i]), .oe(bypass_en[6])); //BYPASS TO X
			TRI RSA_Sel10_X(.in(RESULT_M_STAGE[i]), .out(RSA_CORR_X[i]), .oe(bypass_en[7])); //BYPASS TO X
			
			
			TRI RSB_Sel00_X(.in(RSB_DATA_X[i]), .out(RSB_CORR_X[i]), .oe(~(bypass_en[9]|bypass_en[8]))); //BYPASS TO X
			TRI RSB_Sel01_X(.in(RESULT_W_STAGE[i]), .out(RSB_CORR_X[i]), .oe(bypass_en[8])); //BYPASS TO X
			TRI RSB_Sel10_X(.in(RESULT_M_STAGE[i]), .out(RSB_CORR_X[i]), .oe(bypass_en[9])); //BYPASS TO X

		
		TRI DATA_A_BRANCH_INPUT00(.in(RSA_DATA_D[i]), .out(BRANCH_DATA_IN_A[i]), .oe(~(bypass_en[0]|bypass_en[1]|bypass_en[2]))); //BYPASS TO X
		TRI DATA_A_BRANCH_INPUT01(.in(RESULT_W_STAGE[i]), .out(BRANCH_DATA_IN_A[i]), .oe(bypass_en[0])); //BYPASS TO X
		TRI DATA_A_BRANCH_INPUT10(.in(RESULT_M_STAGE[i]), .out(BRANCH_DATA_IN_A[i]), .oe(bypass_en[1])); //BYPASS TO X
		TRI DATA_A_BRANCH_INPUT11(.in(RESULT_X_STAGE[i]), .out(BRANCH_DATA_IN_A[i]), .oe(bypass_en[2])); //BYPASS TO X
		
		
		TRI DATA_B_BRANCH_INPUT00(.in(RSB_DATA_D[i]), .out(BRANCH_DATA_IN_B[i]), .oe(~(bypass_en[3]|bypass_en[4]|bypass_en[5]))); //BYPASS TO X
		TRI DATA_B_BRANCH_INPUT01(.in(RESULT_W_STAGE[i]), .out(BRANCH_DATA_IN_B[i]), .oe(bypass_en[3])); //BYPASS TO X
		TRI DATA_B_BRANCH_INPUT10(.in(RESULT_M_STAGE[i]), .out(BRANCH_DATA_IN_B[i]), .oe(bypass_en[4])); //BYPASS TO X
		TRI DATA_B_BRANCH_INPUT11(.in(RESULT_X_STAGE[i]), .out(BRANCH_DATA_IN_B[i]), .oe(bypass_en[5])); //BYPASS TO X

			TRI MEM_DATA_IN0(.in(RSA_DATA_M[i]), .out(MEM_DATA_INPUT[i]), .oe(~bypass_en[10])); //MEM_DATA_IN				
			TRI MEM_DATA_IN1(.in(RESULT_W_STAGE[i]), .out(MEM_DATA_INPUT[i]), .oe(bypass_en[10])); //MEM_DATA_IN	
		
			TRI ALU_OPERAND_A_SEL0(.in(RSA_CORR_X[i]), .out(ALU_operand_A[i]), .oe(~X_contrl_X[0])); //ALU_OPERAND				
			TRI ALU_OPERAND_A_SEL1(.in(RSB_CORR_X[i]), .out(ALU_operand_A[i]), .oe(X_contrl_X[0])); //ALU_OPERAND	
			
			TRI ALU_OPERAND_B_SEL0(.in(RSB_CORR_X[i]), .out(ALU_operand_B[i]), .oe(~X_contrl_X[0])); //ALU_OPERAND
			TRI ALU_OPERAND_B_SEL1(.in(immed_X[i]), .out(ALU_operand_B[i]), .oe(X_contrl_X[0])); //ALU_OPERAND
			

			TRI JalOrNormal0(.in(ALU_RESULT_X[i]), .out(RESULT_X_STAGE[i]), .oe(~X_contrl_X[3])); //keep ALUres
			TRI JalOrNormal1(.in(PC_X[i]), .out(RESULT_X_STAGE[i]), .oe(X_contrl_X[3])); //keep PC (jal)
			
			TRI MemReadOrNormal0(.in(RESULT_W_STAGE_t[i]), .out(RESULT_W_STAGE[i]), .oe(~X_contrl_X[0])); //REGFILE_WRITEDATA
			TRI MemReadOrNormal1(.in(MEMREAD_RESULT_W[i]), .out(RESULT_W_STAGE[i]), .oe(X_contrl_X[0])); //REGFILE_WRITEDATA

end
for (i = 0; i < 16; i = i + 1)begin: Setter
	assign immed_D[i] = instr_D[i];
	assign immed_D[i+16] = instr_D[16];
end
for (i = 0; i < 8; i = i + 1)begin: Latches8
	DFFx dx_XCont(.d(X_contrl_D[i]), .clk(clock), .q(X_contrl_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_MCont(.d(M_contrl_D[i]), .clk(clock), .q(M_contrl_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_WCont(.d(W_contrl_D[i]), .clk(clock), .q(W_contrl_X[i]), .clrn(rs), .en(wrE));
	
	DFFx dx_regI1(.d(RegNums_D[i]), .clk(clock), .q(RegNums_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_regI2(.d(RegNums_D[i+8]), .clk(clock), .q(RegNums_X[i+8]), .clrn(rs), .en(wrE));

	DFFx xm_MContx(.d(M_contrl_X[i]), .clk(clock), .q(M_contrl_M[i]), .clrn(rs), .en(wrE));
	DFFx xm_WContx(.d(W_contrl_X[i]), .clk(clock), .q(W_contrl_M[i]), .clrn(rs), .en(wrE));
	
	DFFx xm_regI1(.d(RegNums_X[i]), .clk(clock), .q(RegNums_M[i]), .clrn(rs), .en(wrE));
	DFFx xm_regI2(.d(RegNums_X[i+8]), .clk(clock), .q(RegNums_M[i+8]), .clrn(rs), .en(wrE));
	
	DFFx mw_regI1(.d(RegNums_M[i]), .clk(clock), .q(RegNums_W[i]), .clrn(rs), .en(wrE));
	DFFx mw_regI2(.d(RegNums_M[i+8]), .clk(clock), .q(RegNums_W[i+8]), .clrn(rs), .en(wrE));
	DFFx xm_WContm(.d(W_contrl_M[i]), .clk(clock), .q(W_contrl_W[i]), .clrn(rs), .en(wrE));
end
for (i = 0; i < 32; i = i + 1)begin: Latches32
	DFFx fd_PC(.d(PC_F[i]), .clk(clock), .q(PC_D[i]), .clrn(rs), .en(wrE));
	DFFx fd_instr(.d(instr_F[i]), .clk(clock), .q(instr_D[i]), .clrn(rs), .en(wrE));
	
	DFFx dx_PC(.d(PC_D[i]), .clk(clock), .q(PC_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_RSDA(.d(RSA_DATA_D[i]), .clk(clock), .q(RSA_DATA_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_RSDB(.d(RSB_DATA_D[i]), .clk(clock), .q(RSB_DATA_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_immed(.d(immed_D[i]), .clk(clock), .q(immed_X[i]), .clrn(rs), .en(wrE));
	DFFx dx_instr(.d(instr_D[i]), .clk(clock), .q(instr_X[i]), .clrn(rs), .en(wrE));
	
	//DFFx xm_PC(.d(PC_X[i]), .clk(clock), .q(PC_M[i]), .clrn(rs), .en(wrE));
	DFFx xm_ALURES(.d(RESULT_X_STAGE[i]), .clk(clock), .q(RESULT_M_STAGE[i]), .clrn(rs), .en(wrE));
	DFFx xm_RSDA(.d(RSA_DATA_X[i]), .clk(clock), .q(RSA_DATA_M[i]), .clrn(rs), .en(wrE));
	DFFx xm_instr(.d(instr_X[i]), .clk(clock), .q(instr_M[i]), .clrn(rs), .en(wrE));
	
	//DFFx mw_PC(.d(PC_M[i]), .clk(clock), .q(PC_W[i]), .clrn(rs), .en(wrE));
	DFFx mw_PC(.d(RESULT_M_STAGE[i]), .clk(clock), .q(RESULT_W_STAGE_t[i]), .clrn(rs), .en(wrE));
	DFFx mw_instr(.d(instr_M[i]), .clk(clock), .q(instr_W[i]), .clrn(rs), .en(wrE));
	
	
end
endgenerate


wire [31:0] instr_F;
wire [31:0] instr_D;
wire [31:0] instr_X;
wire [31:0] instr_M;
wire [31:0] instr_W;
endmodule
