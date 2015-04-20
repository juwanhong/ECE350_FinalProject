module processor(clock, reset, ps2_key_pressed, ps2_out, lcd_write, lcd_data, debug_data, debug_addr,
					but_left1,but_right1, but_left2, but_right2,
					paint_val_play,paint_val_wall,player_pos_paint,new_wall_pos_paint,super_enable
					,play_1_x_debug, play_1_y_debug, play_2_x_debug, play_2_y_debug, ex_Reg, PC_F, reg31_debug, regWriteData_W);
					//,test1, test2, test3, test4, test5, test6, test7, test8,test9);
	parameter md_stages = 16; //add one
	input 			clock, reset, ps2_key_pressed;
	input 	[7:0]	ps2_out;
	input 			but_left1,but_right1, but_left2, but_right2;
	output 			lcd_write;
	output 	[31:0] 	lcd_data;
	
	output [3:0] paint_val_play;
	output [3:0] paint_val_wall;
	output [11:0] player_pos_paint;
	output [11:0] new_wall_pos_paint;
	
	output [31:0] ex_Reg;
	
	output [3:0] reg31_debug;
	
	output super_enable;
	
	output [3:0] play_1_x_debug;
	output [3:0] play_1_y_debug;
	output [3:0] play_2_x_debug;
	output [3:0] play_2_y_debug;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	debug_data;
	//output 	[31:0] 	test1;
	//output 	[31:0] 	test2;
	//output 	[31:0] 	test3;
	//output 	[31:0] 	test4;
	//output 	[31:0] 	test5;
	//output 	[31:0] 	test6;
	//output 	[31:0] 	test7;
	//output 	[31:0] 	test8;
	//output 	[31:0] 	test9;
	output	[11:0]	debug_addr;
	
	// your processor here
	wire [31:0] instr_Holder;
	wire [31:0] instr_F;
	wire [31:0] instr_D;
	wire [31:0] instr_X;
	wire [31:0] instr_M;
	wire [31:0] instr_W;
	wire [31:0] instr_W_t;
	wire [31:0] curr_PC;
	wire [31:0] next_PC;	
	wire [31:0] immed_D;
	wire [31:0] immed_X;
	wire [31:0] addr_D;
	wire [31:0] addr_X;
	output [31:0] PC_F;
	wire [31:0] PC_D;
	wire [31:0] PC_X;
	wire [31:0] PC_M;
	wire [31:0] PC_W;
	wire [31:0] PC_alu_D;
	wire [31:0] PC_alu_X;
	wire [31:0] signals_D;
	wire [31:0] signals_X;
	wire [31:0] signals_M;
	wire [31:0] signals_W;
	wire [31:0] signals_W_t;
	wire [31:0] readRegA_D;
	wire [31:0] readRegB_D;
	wire [31:0] readRegA_X;
	wire [31:0] readRegA_M;
	wire [31:0] readRegB_X;
	wire [31:0] dataOpOne;
	wire [31:0] dataOpTwo;
	wire [31:0] ALU_result_X;
	wire [31:0] ALU_result_M;
	wire [31:0] ALU_result_W;
	wire [31:0] ALU_result_W_t;
	wire [31:0] MemRead_result_M;
	wire [31:0] MemRead_result_W;
	output [31:0] regWriteData_W;
	
	wire [31:0] regA_correct_X;
	wire [31:0] regA_correct_M;
	wire [31:0] regB_correct_X;
	
	wire [4:0] writeReg_D;
	wire [4:0] writeReg_X;
	wire [4:0] writeReg_M;
	wire [4:0] writeReg_W;
	wire [4:0] shiftamt_D;
	wire [4:0] shiftamt_X;
	wire [4:0] ALUOP_Data_X;	
	wire [4:0] readA;
	wire [4:0] readB;
	//Instantiate components
	wire statOut;
	wire [31:0] ex_Reg;
	wire ex_used;
	wire write_Status;
	wire [16:0] exc_waiting;
	wire rs;
	wire [4:0] wReg_W;
	assign rs = reset;
	wire exc_coming;
	assign write_Status = mdPipe[md_stages].exc_valid_t | signals_X[26] | (grid_ex_X[0]|key_exc[0]);
	assign exc_coming = (|exc_waiting);
	
	assign ex_used = statOut;
	//TRI STATUS_Write0(.in(ex_W),.out(ex_Reg), .oe(~signals_X[26]));// write from exception
	//TRI STATUS_Write1(.in(instr_X[0]),.out(ex_Reg), .oe(signals_X[26])); // write from setX
	
	wire [31:0] stat_out_X;
	wire [31:0] game_ex;
	wire [30:0] in_exception_grid, out_exception_grid;
	register32B STATUS(.wrE(write_Status)
							,.din(ex_Reg)
							,.rs(rs)//|nop[0])
							,.dout(stat_out_X)
							//,.dout({statOut,out_exception_grid})
							,.clock(~clock));//change reset to "reset"

	assign statOut = ~stat_out_X[31]&(|stat_out_X[30:0]);
	//DFFx status(.d(ex_Reg), .q(statOut), .clk(~clock),.en(write_Status),.clrn(rs));//unsure about clocking this register
	// changed clocking to ~clock
	
	// Grid.v //
	wire [31:0] grid_ex_X;
	Grid myGrid(.play_x(readRegA_D)
	,.play_y(readRegB_D)
	,.super_enable(signals_D[27]) 
	,.play_num(immed_D[0])
	,.exc_out(grid_ex_X)
	,.clock(clock),.reset(rs)
	,.player_pos_paint(player_pos_paint)
	,.new_wall_pos_paint(new_wall_pos_paint)
	,.paint_val_play(paint_val_play)
	,.paint_val_wall(paint_val_wall)
	,.super_enable_out(super_enable));
	
	assign play_1_x_debug = p1_cont|p2_cont;
	assign play_1_y_debug = paint_val_play;
	assign play_2_x_debug = stat_out_X;

	wire super_enable;
	wire [31:0] key_exc;
	wire [1:0] p1_buff;
	wire [31:0] p1_cont;
	assign p1_buff[0] = but_left1;
	assign p1_buff[1] = but_right1;
	assign p1_button = p1_cont[0]|p1_cont[1];
	register32B PlayerOne_buff(.wrE(1'b1)//(but_left1|but_right1))
								,.din(p1_buff)
								,.rs(rs)//|nop[0])
								,.dout(p1_cont)
								,.clock(~clock));//change reset to "reset"
	wire [1:0] p2_buff;
	wire [31:0] p2_cont;
	wire p2_button;
	assign p2_buff[0] = but_left2;
	assign p2_buff[1] = but_right2;	
	register32B PlayerTwo_buff(.wrE(1'b1)//(but_left2|but_right2))
								,.din(p2_buff)
								,.rs(rs)//|nop[0])
								,.dout(p2_cont)
								,.clock(~clock));//change reset to "reset"
	
	assign key_exc[3] = p1_cont[0]|p2_cont[0];
	assign key_exc[2] = 1'b0;
	assign key_exc[1] = p2_cont[1]|p2_cont[0];
	assign key_exc[0] = p2_cont[1]|p2_cont[0]|p1_cont[1]|p1_cont[0];
	
	assign p2_button = p2_cont[0]|p2_cont[1];
	register32B program_counter(.wrE(op[4])
								,.din(next_PC)
								,.rs(rs)//|nop[0])
								,.dout(curr_PC)
								,.clock(clock));//change reset to "reset"
	
	wire [3:0] reg31_debug;
	
	regFile registers(.clock(~clock)
	,.ctrl_writeEnable(signals_W[1])
	,.ctrl_reset(rs)
	,.ctrl_writeReg(wReg_W)
	,.ctrl_readRegA(readA)
	,.ctrl_readRegB(readB)
	,.data_writeReg(regWriteData_W)
	,.data_readRegA(readRegA_D)
	,.data_readRegB(readRegB_D)	 
	,.play_1_x_debug()
	,.play_1_y_debug()
	,.play_2_x_debug()
	,.play_2_y_debug(reg31_debug)	
	);


	
	wire [31:0] pSignals;
	wire [7:0] op;
	wire [7:0] nop;
	wire [7:0] bp;
	
	wire isNOP_M, isNOP_W, isNOP_X; // isNOP = 1 means IS NOP
	assign isNOP_X = ~(signals_X[23]);
	assign isNOP_M = ~(signals_M[23]&signals_M[24]);
	assign isNOP_W = ~(signals_W[23]&signals_W[24]);
	wire takeBranch_X, pc_control_x;
	assign takeBranch_X = neq_X&signals_X[7] | lt_X&signals_X[8] | ex_used&signals_X[9];
	assign pc_control_x = (takeBranch_X)|(signals_X[15])|(signals_X[21]);
	control Controller(.I(instr_D)
						,.signals(signals_D));
	
	pipeControl Controller2(.D(instr_D)
					,.X(instr_X)
					,.M(instr_M)
					,.W(instr_W)
					,.exc_piped(exc_coming)
					,.branchTaken(pc_control_x)
					,.hold(op)//hold
					,.nop(nop)
					,.XM_val(isNOP_M)
					,.MW_val(isNOP_W)
					,.DX_val(isNOP_X)
					,.bypass(bp)
					,.clock(clock)
					,.busy_stage(stageOp_X)
					,.bp_reqX(bpX_request));
	
	wire neq_X, lt_X;
	wire [31:0] ex_W;
	wire [4:0] op_X;//=signals_X[6:2]
	wire [31:0] ALU_res_temp_X;
	ALU data_ALU(.opA(dataOpOne)
				,.opB(dataOpTwo)
				,.opcode(op_X)
				,.shiftamt(shiftamt_X)
				,.res(ALU_res_temp_X)
				,.ne(neq_X)
				,.lt(lt_X)
				,.ex(ex_W)
				,.res_RDY()
				,.inp_RDY()
				,.clock(clock)
	);

	//should result in NOP for instruction1back

	Adder branch_ALU(.A(PC_D)
				,.B(immed_D)
				,.Cin(1'b0)
				,.out(PC_alu_D)
	);
	
	Adder PC_plus_one(.A(curr_PC)
				,.B(0)
				,.Cin(1'b1)
				,.out(PC_F)
	);
	//make address from jumps
	assign addr_D[31] = PC_D[31];
	assign addr_D[30] = PC_D[30];
	assign addr_D[29] = PC_D[29];
	assign addr_D[28] = PC_D[28];
	assign addr_D[27] = PC_D[27];
	genvar i;
	genvar j;
	//write back on negative edge
	generate
		//muxes here
		for (i = 0; i < 27; i = i + 1) begin: loopy
			assign addr_D[i] = instr_D[i];
		end
		for (i = 0; i < 16; i = i + 1) begin: loop2
			assign immed_D[i] = instr_D[i];
			assign immed_D[i+16] = instr_D[16];
		end
		for (i = 0; i < 5; i = i + 1) begin: loopx
			TRI ReadA01(.in(instr_D[i+17]), .out(readA[i]), .oe(signals_D[14]));//RS
			TRI ReadA02(.in(instr_D[i+22]), .out(readA[i]), .oe(~signals_D[14]));//RD
			
			TRI ReadB01(.in(instr_D[i+12]), .out(readB[i]), .oe(~signals_D[22]));//RT
			TRI ReadB02(.in(instr_D[i+17]), .out(readB[i]), .oe(signals_D[22]));//RS
			
			assign shiftamt_D[i] = instr_D[i+7];
			assign op_X[i] = signals_X[i+2];
			assign wReg_W[i] = signals_W[i+16];
		end			
		for (i = 0; i < 32; i = i + 1) begin: loop1
			TRI stat_keyvgrid0(.in(grid_ex_X[i]),.out(game_ex[i]), .oe(grid_ex_X[0])); // grid
			TRI stat_keyvgrid1(.in(key_exc[i]),.out(game_ex[i]), .oe(~grid_ex_X[0])); // key
			
			TRI stat_setvgame0(.in(immed_X[i]),.out(ex_Reg[i]), .oe(signals_X[26])); // set or game			
			TRI stat_setvgame1(.in(game_ex[i]),.out(ex_Reg[i]), .oe((~signals_X[26])&(grid_ex_X[0]|key_exc[0]))); // set or game
			TRI stat_setvgame2(.in(ex_W[i]),.out(ex_Reg[i]), .oe((~signals_X[26])&(~(grid_ex_X[0]|key_exc[0])))); // multiplier stuff
			//assign instr_F[i] = instr_Holder[i];//&(~nop[1]);
			
			//select ALU_result
			TRI read_status0(.in(ALU_res_temp_X[i]),.out(ALU_result_X[i]), .oe(~signals_X[28]));
			TRI read_status1(.in(stat_out_X[i]),.out(ALU_result_X[i]), .oe(signals_X[28]));
			
			//choose A normally, choose B only when A is going to sw.
			TRI ALUOperandA01(.in(regA_correct_X[i]),.out(dataOpOne[i]), .oe(~signals_X[10]));
			TRI ALUOperandA02(.in(regB_correct_X[i]),.out(dataOpOne[i]), .oe(signals_X[10]));
			
			TRI RegAData01(.in(readRegA_X[i]),.out(regA_correct_X[i]), .oe(~(bp[0]|bp[1])));			
			TRI RegAData02(.in(ALU_result_M[i]),.out(regA_correct_X[i]), .oe(bp[0]));//MX bypass
			TRI RegAData03(.in(regWriteData_W[i]),.out(regA_correct_X[i]), .oe(bp[1]));//WX bypass
			
			TRI ALUOperandB01(.in(regB_correct_X[i]), .out(dataOpTwo[i]), .oe(~signals_X[0])); //if not addi,sw,lw
			TRI ALUOperandB02(.in(immed_X[i]), .out(dataOpTwo[i]), .oe(signals_X[0]));
			
			TRI RegBData01(.in(readRegB_X[i]), .out(regB_correct_X[i]), .oe(~(bp[2]|bp[3])));			
			TRI RegBData02(.in(ALU_result_M[i]), .out(regB_correct_X[i]), .oe(bp[2]));//MX bypass
			TRI RegBData03(.in(regWriteData_W[i]), .out(regB_correct_X[i]), .oe(bp[3]));//WX bypass
			
			TRI MemWriteData01(.in(regA_correct_M[i]), .out(debug_data[i]), .oe(~bp[4]));
			TRI MemWriteData02(.in(regWriteData_W[i]), .out(debug_data[i]), .oe(bp[4]));//WM bypass
			
			TRI RegW1(.in(ALU_result_W[i]), .out(regWriteData_W[i]), .oe((~signals_W[13])&(~signals_W[11])));//ALU Result		
			TRI RegW2(.in(MemRead_result_W[i]), .out(regWriteData_W[i]), .oe(signals_W[11]));//memory read
			TRI RegW3(.in(PC_W[i]), .out(regWriteData_W[i]), .oe(signals_W[13]));//jal
			
			TRI nextPC1(.in(PC_alu_X[i]), .out(next_PC[i]), .oe(takeBranch_X));
			TRI nextPC2(.in(PC_F[i]), .out(next_PC[i]), .oe((~takeBranch_X)&(~signals_X[15])&(~signals_X[21])));
			TRI nextPC3(.in(addr_X[i]), .out(next_PC[i]), .oe(signals_X[15]));
			TRI nextPC4(.in(regA_correct_X[i]), .out(next_PC[i]), .oe(signals_X[21]));//bypass logic in dataOpOne MUX
			
			TRI mult_bp_data0(.in(ALU_result_X[i]), .out(ALU_result_W[i]), .oe(~op[3]));
			TRI mult_bp_data1(.in(ALU_result_W_t[i]), .out(ALU_result_W[i]), .oe(op[3]));//mult_div result bypassed
			
			TRI mult_bp_addr0(.in(mdPipe[md_stages].signals_P[i]), .out(signals_W[i]), .oe(~op[3]));
			TRI mult_bp_addr1(.in(signals_W_t[i]), .out(signals_W[i]), .oe(op[3]));//mult_div addr bypassed			
			
			TRI mult_bp_insn0(.in(mdPipe[md_stages].instr[i]), .out(instr_W[i]), .oe(~op[3]));
			TRI mult_bp_insn1(.in(instr_W_t[i]), .out(instr_W[i]), .oe(op[3]));//mult_div addr bypassed
		end
		//Latches for Pipeline start here
		for (i = 0; i < 32; i = i + 1) begin: Latches1
			DFFx fd_PC(.d(PC_F[i]), .q(PC_D[i]), .clk(clock), .en(op[0]),.clrn(rs));
			DFFx fd_instr(.d(instr_F[i]&(~nop[1])), .q(instr_D[i]), .clk(clock), .en(op[0]),.clrn(rs));
			
			//DFFx fd_PC(.d(PC_F[i]), .q(PC_D[i]), .clk(clock), .en(1'b1),.clrn(rs));
			//DFFx fd_instr(.d(instr_F[i]), .q(instr_D[i]), .clk(clock), .en(1'b1),.clrn(rs));
	
			DFFx dx_regA(.d(readRegA_D[i]), .q(readRegA_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_regB(.d(readRegB_D[i]), .q(readRegB_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_Immed(.d(immed_D[i]), .q(immed_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_PC(.d(PC_D[i]), .q(PC_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_PC_alu(.d(PC_alu_D[i]), .q(PC_alu_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_sign(.d(signals_D[i]&(~nop[2])),.q(signals_X[i]),.clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_instr(.d(instr_D[i]&(~nop[2])), .q(instr_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			DFFx dx_addr(.d(addr_D[i]), .q(addr_X[i]), .clk(clock),.en(op[1]),.clrn(rs));
			
			DFFx xm_alu_res(.d(ALU_result_X[i]), .q(ALU_result_M[i]), .clk(clock),.en(op[2]),.clrn(rs));
			DFFx xm_readRegA(.d(regA_correct_X[i]), .q(regA_correct_M[i]), .clk(clock),.en(op[2]),.clrn(rs));
			DFFx xm_PC(.d(PC_X[i]), .q(PC_M[i]), .clk(clock),.en(op[2]),.clrn(rs));
			DFFx xm_instr(.d(instr_X[i]&(~nop[3])&(~(mdPipe[0].ismulCyc))), .q(instr_M[i]), .clk(clock),.en(op[2]),.clrn(rs));
			DFFx xm_sign(.d(signals_X[i]&(~nop[3])&(~(mdPipe[0].ismulCyc))),.q(signals_M[i]),.clk(clock),.en(op[2]),.clrn(rs));
			
			DFFx mw_Data(.d(MemRead_result_M[i]), .q(MemRead_result_W[i]), .clk(clock),.en(op[3]),.clrn(rs));
			DFFx mw_ALU(.d(ALU_result_M[i]), .q(ALU_result_W_t[i]), .clk(clock),.en(op[3]),.clrn(rs));
			DFFx mw_instr(.d(instr_M[i]&(~nop[4])), .q(instr_W_t[i]), .clk(clock),.en(op[3]),.clrn(rs));
			DFFx mw_PC(.d(PC_M[i]), .q(PC_W[i]), .clk(clock),.en(op[3]),.clrn(rs));
			DFFx mw_sign(.d(signals_M[i]&(~nop[4])), .q(signals_W_t[i]), .clk(clock),.en(op[3]),.clrn(rs));
		end
		wire stallMD;
		assign stallMD = 1'b1;
		wire [16:0] mul_stage_X;
		wire [16:0] div_stage_X;
		wire [16:0] stageOp_X;
		wire [16:0] bpX_request;
		//multiplier pipeline starts here
		for (i = 0; i <= md_stages; i = i + 1)begin: mdPipe
			wire isMul, isDiv;
			wire temp_bpx, N_OP, next_N_OP;
			wire exc_valid, exc_valid_t;
			wire [31:0] instr;
			wire [31:0] signals_P;
			assign exc_waiting[i] = mdPipe[i].exc_valid;
			//assign mul_stage_X[i] = mdPipe[i].isMul;
			//assign div_stage_X[i] = mdPipe[i].isDiv;
			assign stageOp_X[i] = mdPipe[i].isDiv|mdPipe[i].isMul;
			multdiv_pipeControl mdp(.P(mdPipe[i].instr)
									, .isNOP(mdPipe[i].next_N_OP)
									, .is_exc_valid(mdPipe[i].exc_valid)
									, .X(instr_X)
									, .D(instr_D)
									, .bpX(mdPipe[i].temp_bpx)
									,.DONT_WRITE(mdPipe[i].N_OP)
									,.exc_reset(mdPipe[i].exc_valid_t));
			assign bpX_request[i] = mdPipe[i].temp_bpx;
			if (i==0) begin //first Stage
					wire isMulTemp, isDivTemp, ismulCyc;
					assign isMulTemp = (~op_X[4])&(~op_X[3])&op_X[2]&op_X[1]&(~op_X[0])&(~signals_X[22]);
					assign isDivTemp = (~op_X[4])&(~op_X[3])&op_X[2]&op_X[1]&(op_X[0])&(~signals_X[22]);
					assign ismulCyc = isMulTemp | isDivTemp;
					DFFx P_isNop(.d(1'b0), .q(mdPipe[i].next_N_OP), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_exc_v(.d(isMulTemp|isDivTemp), .q(mdPipe[i].exc_valid), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_isMul(.d(isMulTemp), .q(mdPipe[i].isMul), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_isDiv(.d(isDivTemp), .q(mdPipe[i].isDiv), .clk(clock),.en(stallMD),.clrn(rs));
				for (j = 0; j < 32; j = j + 1)begin: instrStore
					DFFx P_instr(.d(instr_X[j]&ismulCyc), .q(mdPipe[i].instr[j]), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_contr(.d(signals_X[j]&ismulCyc), .q(mdPipe[i].signals_P[j]), .clk(clock),.en(stallMD),.clrn(rs));
					
				end
			end
			else if (i == md_stages) 
				begin //final Stage
						DFFx P_isMul(.d(mdPipe[i-1].isMul), .q(mdPipe[i].isMul), .clk(clock),.en(stallMD),.clrn(rs));
						DFFx P_isDiv(.d(mdPipe[i-1].isDiv), .q(mdPipe[i].isDiv), .clk(clock),.en(stallMD),.clrn(rs));
						DFFx P_isNop(.d(mdPipe[i-1].N_OP), .q(mdPipe[i].next_N_OP), .clk(clock),.en(stallMD),.clrn(rs));
						DFFx P_exc_v(.d(mdPipe[i-1].exc_valid_t), .q(mdPipe[i].exc_valid), .clk(clock),.en(stallMD),.clrn(rs));
					for (j = 0; j < 32; j = j + 1)begin: instrStore
						DFFx P_instr(.d(mdPipe[i-1].instr[j]), .q(mdPipe[i].instr[j]), .clk(clock),.en(stallMD),.clrn(rs));
						DFFx P_contr(.d(mdPipe[i-1].signals_P[j]), .q(mdPipe[i].signals_P[j]), .clk(clock),.en(stallMD),.clrn(rs));
					end
			end
			else begin
					DFFx P_isMul(.d(mdPipe[i-1].isMul), .q(mdPipe[i].isMul), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_isDiv(.d(mdPipe[i-1].isDiv), .q(mdPipe[i].isDiv), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_isNop(.d(mdPipe[i-1].N_OP), .q(mdPipe[i].next_N_OP), .clk(clock),.en(stallMD),.clrn(rs));
						DFFx P_exc_v(.d(mdPipe[i-1].exc_valid_t), .q(mdPipe[i].exc_valid), .clk(clock),.en(stallMD),.clrn(rs));
				for (j = 0; j < 32; j = j + 1) begin: instrStore
					DFFx P_instr(.d(mdPipe[i-1].instr[j]), .q(mdPipe[i].instr[j]), .clk(clock),.en(stallMD),.clrn(rs));
					DFFx P_contr(.d(mdPipe[i-1].signals_P[j]), .q(mdPipe[i].signals_P[j]), .clk(clock),.en(stallMD),.clrn(rs));
				end
			end
		end
		// multiplier pipeline ends here
		for (i = 0; i < 5; i = i + 1) begin: Latches2
			DFFx dx_shiftAmt(.d(shiftamt_D[i]), .q(shiftamt_X[i]), .clk(clock),.en(op[1]),.clrn(rs));//opcode in 6:2
		end
		for (i = 0; i < 12; i = i + 1)begin: memdata
			assign debug_addr[i] = ALU_result_M[i];
		end
		
		for(i = 0; i < 32; i = i + 1)begin: debugLoop
			//assign test1[i] = PC_F[i];
			//assign test2[i] = instr_D[i];
			//assign test3[i] = instr_X[i];
			//assign test4[i] = instr_M[i];
			//assign test5[i] = instr_W[i];
		end
		for (i = 0; i < 17; i = i + 1)begin: debugLoop2
			//assign test6[i] = exc_waiting[i];
			//assign test7[i] = stageOp_X[i];
			//assign test8[i] = bpX_request[i];
		end
		for (i = 0; i < 8; i = i + 1)begin: debugLoop3
			//assign test9[i] = op[i];
			//assign test9[i+8] = nop[i];
			//assign test9[i+16] = bp[i];
		end
			//assign test9[30] = clock;
			//assign test9[31] = pc_control_x;
endgenerate

	
	
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
	//assign debug_addr = ALU_result_M;//(12'b000000000001);
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
	//assign debug_data = regA_correct_M;
	////////////////////////////////////////////////////////////
	
		
	// You'll need to change where the dmem and imem read and write...
	dmem mydmem(	.address	(debug_addr),
					.clock		(clock), // negative clock?
					.data		(debug_data),
					.wren		(1'b1),//((~instr_M[31])&(~instr_M[30])&instr_M[29]&instr_M[28]&instr_M[27])
					.q			(MemRead_result_M) // change where output q goes...
	);
	
	imem myimem(	.address 	(curr_PC),//set to 12'b000000000000
					.clken		(1'b1),
					.clock		(~clock),
					.q 			(instr_F) // change where output q goes...
	); 
	
endmodule


module fiveBitEquals(A, B, eq);
	input [4:0] A;
	input [4:0] B;
	output eq;
	wire isZero, areDiff;
	assign isZero = ~(A[4]|A[3]|A[2]|A[1]|A[0]);
	assign areDiff = (A[4]^B[4])|(A[3]^B[3])|(A[2]^B[2])|(A[1]^B[1])|(A[0]^B[0]);
	assign eq= (~areDiff)&(~isZero);
endmodule
