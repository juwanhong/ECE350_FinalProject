module pipeControl(D, X, M, W, branchTaken, hold, nop, bypass, clock//);
	,busy_stage,bp_reqX, XM_val, MW_val, DX_val, exc_piped);
	input [31:0] D;
	input [31:0] X;
	input [31:0] M;
	input [31:0] W;
	input [16:0] busy_stage;
	input [16:0] bp_reqX;
	input branchTaken, XM_val, MW_val, DX_val; // for XX_val, '1' = IS NOP
	input clock, exc_piped;
	output [7:0] hold; // default = 1
	output [7:0] nop; //default = 0
	output [7:0] bypass;
	
	wire [31:0] Dhot;
	wire [31:0] Xhot;
	wire [31:0] Mhot;
	wire [31:0] Whot;
	wire [4:0] D_op;
	wire [4:0] X_op;
	wire [4:0] M_op;
	wire [4:0] W_op;
	decoder5B dec00(.Enc(D_op),.out(Dhot));	
	decoder5B dec01(.Enc(X_op),.out(Xhot));	
	decoder5B dec02(.Enc(M_op),.out(Mhot));	
	decoder5B dec03(.Enc(W_op),.out(Whot));
	
	wire WWrites, MWrites, XWrites;
	wire DReadsRD, DReadsRS, DReadsRT;
	wire XReadsRD, XReadsRS, XReadsRT;
	//regWriteOps = ALU=0, addi=5, lw=8, jal=3
	assign WWrites = Whot[0]|Whot[5]|Whot[3]|Whot[8]|Whot[10];
	assign MWrites = Mhot[0]|Mhot[5]|Mhot[3]|Mhot[8]|Mhot[10];//1
	assign XWrites = Xhot[0]|Xhot[5]|Xhot[3]|Xhot[8]|Xhot[10];//1
	//read RD on bne=2, blt=6, sw=7, jr=4
	assign XReadsRD = Xhot[2]|Xhot[4]|Xhot[6]|Xhot[7];//0
	assign DReadsRD = Dhot[2]|Dhot[4]|Dhot[6]|Dhot[7];//1
	//read RS on ALU=0, addi=5, bne=2, blt=6, sw=7, lw=8
	assign XReadsRS = Xhot[0]|Xhot[5]|Xhot[2]|Xhot[6]|Xhot[7]|Xhot[8];//1
	assign DReadsRS = Dhot[0]|Dhot[5]|Dhot[2]|Dhot[6]|Dhot[7]|Dhot[8];//1
	//read RT on ALU=0
	assign XReadsRT = Xhot[0];//0
	assign DReadsRT = Dhot[0];//1
	wire [4:0] rdX;
	wire [4:0] rsX;
	wire [4:0] rtX;
	wire [4:0] rdM;
	wire [4:0] rdW;
	wire [4:0] rtD;
	wire [4:0] rsD;
	wire [4:0] rdD;
	genvar i;
	generate
	for (i = 0; i < 5; i = i + 1)begin: loop1
		assign D_op[i] = D[i+27];
		assign X_op[i] = X[i+27];
		assign M_op[i] = M[i+27];
		assign W_op[i] = W[i+27];
		//jal=3 write register = '11111
		TRI jalX0(.in('b1), .out(rdX[i]), .oe(Xhot[3]));
		TRI jalX1(.in(X[i+22]), .out(rdX[i]), .oe(~Xhot[3]));//2
		TRI jalM0(.in('b1), .out(rdM[i]), .oe(Mhot[3]));
		TRI jalM1(.in(M[i+22]), .out(rdM[i]), .oe(~Mhot[3]));//1
		TRI jalW0(.in('b1), .out(rdW[i]), .oe(Whot[3]));
		TRI jalW1(.in(W[i+22]), .out(rdW[i]), .oe(~Whot[3]));//0
		assign rdD[i] = D[i+22];
		assign rsD[i] = D[i+17];
		assign rtD[i] = D[i+12];
		assign rsX[i] = X[i+17];//0
		assign rtX[i] = X[i+12];//2
	end
	wire [15:0] multdiv_bpx;
	for (i = 0; i < 16; i = i + 1)begin: multPipe
		assign multdiv_bpx[i] = bp_reqX[i];
	end
	endgenerate
	wire [8:0] RAW;
	fiveBitEquals Feq1(.A(rdX), .B(rdM), .eq(RAW[5]));//
	fiveBitEquals Feq2(.A(rsX), .B(rdM), .eq(RAW[4]));
	fiveBitEquals Feq4(.A(rtX), .B(rdM), .eq(RAW[3]));
	fiveBitEquals Feq5(.A(rdX), .B(rdW), .eq(RAW[2]));
	fiveBitEquals Feq7(.A(rsX), .B(rdW), .eq(RAW[1]));
	fiveBitEquals Feq8(.A(rtX), .B(rdW), .eq(RAW[0]));
	wire rep;
	fiveBitEquals rep1(.A(rdM), .B(rdW), .eq(rep));
	
	//data is currently in Memory Stage
	assign bypass[0] = (XReadsRD&RAW[5] | XReadsRS&RAW[4]&(~XReadsRD))&MWrites;//ALU_A MX
	assign bypass[2] = (RAW[4]&XReadsRS&XReadsRD | XReadsRT&RAW[3])&MWrites;//ALU_B MX
	
	//data is currently in WriteBack Stage
	assign bypass[1] = (XReadsRD&RAW[2] | XReadsRS&RAW[1]&(~XReadsRD))&WWrites&(~(MWrites&rep));//ALU_A WX
	assign bypass[3] = (XReadsRS&RAW[1]&(XReadsRD) | XReadsRT&RAW[0])&WWrites&(~(MWrites&rep));//ALU_B WX
	
	//data is currently in WriteBack, instr is sw
	assign bypass[4] = Mhot[7]&WWrites&rep; 
	
	// status bit currently being set, bypass from M to X
	assign bypass[5] = (Mhot[21])&Xhot[22]; // M = setx, X = bex
	
	
	assign bypass[6] = 'b0;
	
	//lw case
	//hold prevents a latch from changing
	wire loadConflict;
	wire holdPC;
	wire [2:0] LC;
	fiveBitEquals FLC1(.A(rtD), .B(rdX), .eq(LC[0]));
	fiveBitEquals FLC2(.A(rsD), .B(rdX), .eq(LC[1]));
	fiveBitEquals FLC3(.A(rdD), .B(rdX), .eq(LC[2]));
	assign loadConflict = (~Dhot[7])&Xhot[8]&((LC[0]&DReadsRT)|(LC[1]&DReadsRS)|(LC[2]&DReadsRD));
	//if loadConflict = 1, a stall IS required
	
	//when to stall:
	//case 1. MUL/DIV in P15-16 AND
	// 			 a. if MW!=NOP, hold MW
	// 			 b. if XM!=NOP, hold XM
	//           c. if DX!=NOP, hold DX
	wire MW_hold;
	assign MW_hold = busy_stage[16]&bp_reqX[16];
	//case 2. MUL/DIV in P0P1->P14P15 AND DX needs data AND it's not from $r0
	//           a. hold (a) iMem, (b) PC, (c) FD, (d) DX
	wire data_req;
	assign data_req = (|multdiv_bpx);
	//case 3. MUL/DIV in P0-16 (RD) == DX (RD)
	
	//case 4. DX = bex and there are unresolved mul.div
	wire wait_exc;
	assign wait_exc = exc_piped&(Xhot[22]);

	wire canGoThrough; //instruction in X can move through
	wire isMultiCyc_X;// noStrucHaz;
	assign isMultiCyc_X = (~X[6])&(~X[5])&X[4]&X[3]&Xhot[0];
	//assign noStrucHaz = ~(mul_stage[15]|div_stage[15]);
	

	//assign canGoThrough = noConf_X&(isMultiCyc_X|noStrucHaz);
	
	// 1'b1 = "let through", do not hold and do continue as normal
	assign holdPC = (~loadConflict)&(hold[0]);//|(~hold[0]); // PC
	assign hold[0] = (~loadConflict)&(hold[1]);//|(~hold[1]); // F.D
	assign hold[1] = (DX_val)&(~hold[2])|(~data_req)&(~wait_exc)&hold[2]; // D.X
	assign hold[2] = (XM_val)&(~hold[3])|hold[3]; // X.M
	assign hold[3] = (~MW_hold)|(MW_hold&~MW_val); // M.W
	assign hold[4] = holdPC;
	assign hold[5] = (~branchTaken) & (~loadConflict);

    //XM_val, MW_val, DX_val=1 means DX_val=NOP
	
	//nop "neuters" an instruction already in the pipe
	assign nop[0] = 1'b0; // PC
	assign nop[1] = branchTaken;//branchTaken; // F.D
	assign nop[2] = branchTaken|loadConflict;//|branchTaken; // D.X
	assign nop[3] = 1'b0; // X.M
	assign nop[4] = 1'b0; // M.W
	assign nop[5] = 1'b0;
	//DFFx Correction(.d(branchTaken),.q(nop[5]),.clk(~clock),.en(1'b1), .clrn());
endmodule

module control(I, signals);
	input [31:0] I;
	output [31:0] signals;
		
	wire [4:0] opcode;
	wire [4:0] ALU_opcode;
	wire [31:0] h;
	wire [31:0] op;

	genvar i;
	generate
		for (i = 0; i < 5; i = i + 1) begin: loop1
		assign opcode[i] = I[i+27];
		assign ALU_opcode[i] = I[i+2];
		end
	endgenerate
	decoder5B dec01(.Enc(opcode),.out(h));
	decoder5B dec02(.Enc(ALU_opcode), .out(op));
	assign signals[0] = h[5]|h[7]|h[8];//addi, lw, sw // send immed to ALU
	assign signals[1] = h[0]|h[3]|h[5]|h[8]|h[10];//ALU, addi, jal, lw // reg File WREN
	//the following make a subtract if its blt=6 or bne=2, h[2]|h[6]
	//make an add if it is lw=8,sw=7,addi=5, h[5]|h[7]|h[8]
	wire blt_bne, addi_lw_sw;
	assign blt_bne = h[2]|h[6];
	assign addi_lw_sw = h[5]|h[7]|h[8];
	TRI ALUop00(.in(ALU_opcode[0]), .out(signals[2]), .oe(~(blt_bne|addi_lw_sw))); 
	TRI ALUop01(.in('b1), .out(signals[2]), .oe(blt_bne)); 
	TRI ALUop02(.in('b0), .out(signals[2]), .oe(addi_lw_sw));  
	TRI ALUop10(.in(ALU_opcode[1]), .out(signals[3]), .oe(~(blt_bne|addi_lw_sw))); 
	TRI ALUop11(.in('b0), .out(signals[3]), .oe(blt_bne)); 
	TRI ALUop12(.in('b0), .out(signals[3]), .oe(addi_lw_sw)); 
	TRI ALUop20(.in(ALU_opcode[2]), .out(signals[4]), .oe(~(blt_bne|addi_lw_sw))); 
	TRI ALUop21(.in('b0), .out(signals[4]), .oe(blt_bne)); 
	TRI ALUop22(.in('b0), .out(signals[4]), .oe(addi_lw_sw)); 
	TRI ALUop30(.in(ALU_opcode[3]), .out(signals[5]), .oe(~(blt_bne|addi_lw_sw))); 
	TRI ALUop31(.in('b0), .out(signals[5]), .oe(blt_bne)); 
	TRI ALUop32(.in('b0), .out(signals[5]), .oe(addi_lw_sw)); 
	TRI ALUop40(.in(ALU_opcode[4]), .out(signals[6]), .oe(~(blt_bne|addi_lw_sw))); 
	TRI ALUop41(.in('b0), .out(signals[6]), .oe(blt_bne));
	TRI ALUop42(.in('b0), .out(signals[6]), .oe(addi_lw_sw)); 
	
	assign signals[7] = h[2];// neq
	assign signals[8] = h[6];//blt
	assign signals[9] = h[22];// bex
	assign signals[10] = h[7];// mem write - sw
	assign signals[11] = h[8];//mem read - lw
	assign signals[12] = h[0]&(op[6]|op[7])|h[21];//exception write enable
	assign signals[13] = h[3];//jal
	assign signals[14] = ~(h[2]|h[4]|h[6]|h[7]|h[9]);//read $rd - sw=7,jr=4,bne=2,blt=6
	assign signals[15] = h[1]|h[3];//|h[4];//jal, jr, j - omit jr
	
	//set write register to $r31 if instr. is jal
	TRI writeReg00(.in(I[22]), .out(signals[16]), .oe(~(h[3]|h[10]))); 
	TRI writeReg01(.in('b1), .out(signals[16]), .oe(h[3]|h[10]));	
	TRI writeReg10(.in(I[23]), .out(signals[17]), .oe(~(h[3]|h[10]))); 
	TRI writeReg11(.in('b1), .out(signals[17]), .oe(h[3]|h[10]));	
	TRI writeReg20(.in(I[24]), .out(signals[18]), .oe(~(h[3]|h[10]))); 
	TRI writeReg21(.in('b1), .out(signals[18]), .oe(h[3]|h[10]));	
	TRI writeReg30(.in(I[25]), .out(signals[19]), .oe(~(h[3]|h[10]))); 
	TRI writeReg31(.in('b1), .out(signals[19]), .oe(h[3]|h[10]));	
	TRI writeReg40(.in(I[26]), .out(signals[20]), .oe(~(h[3]|h[10]))); 
	TRI writeReg41(.in('b1), .out(signals[20]), .oe(h[3]|h[10]));
	assign signals[21] = h[4];//jr
	assign signals[22] = ~h[0];//only with regular  ops do we use $rt
	assign signals[23] = 1'b1; //signal is/is not a NOP
	assign signals[24] = signals[25]|h[7]|h[9];//insn. that don't use M stage
	assign signals[25] = (h[0]&(op[6]|op[7]))&h[1]|h[2]|h[4]|h[22]|h[6]|h[9];//insn that don't use W stage
	assign signals[26] = h[21];//setx
	assign signals[27]= h[9]; // MOV
	assign signals[28] = h[10]; // LX
endmodule