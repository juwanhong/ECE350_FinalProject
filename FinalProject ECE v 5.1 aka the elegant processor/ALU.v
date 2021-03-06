module ALU(opA, opB, res, shiftamt, opcode, lt, ne, ex, res_RDY, inp_RDY, clock);
	input [31:0] opA;
	input [31:0] opB;
	input [4:0] opcode;
	input [4:0] shiftamt;
	input clock;
	output [31:0] res;
	output lt, ne, res_RDY, inp_RDY;
	output [31:0] ex;

	wire [31:0] outAdd;
	wire [31:0] outMult;
	wire mul, div;
	
	assign mul = (~opcode[4])&(~opcode[3])&opcode[2]&opcode[1]&(~opcode[0]);
	assign div = (~opcode[4])&(~opcode[3])&opcode[2]&opcode[1]&(opcode[0]);
	
	singleCycle addsub(.data_operandA(opA)
						,.data_operandB(opB)
						,.ctrl_ALUopcode(opcode)
						,.ctrl_shiftamt(shiftamt)
						,.data_result(outAdd)
						,.isNotEqual(ne)
						,.isLessThan(lt)
			);
	
	wire ex_temp;
	multdiv md(.data_operandA(opA)
					,.data_operandB(opB)
					,.ctrl_MULT(mul)
					,.ctrl_DIV(div)
					,.data_result(outMult)
					,.data_inputRDY(inp_RDY)
					,.data_resultRDY(res_RDY)
					,.clock(clock)
					,.data_exception(ex_temp));
	

			
	genvar i;
	generate
			for (i = 0; i < 32; i = i + 1) begin: loop1
			
			if (i == 0) begin 
				assign ex[i] = ex_temp;
			end
			else begin
				assign ex[i] = 1'b0;
			end
			TRI ALURes1(.in(outMult[i]), .out(res[i]), .oe((mul|div)));
			TRI ALURes2(.in(outAdd[i]), .out(res[i]), .oe(~(mul|div)));
			end
	endgenerate
endmodule

module singleCycle(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan);
   input [31:0] data_operandA, data_operandB;
   input [4:0] ctrl_ALUopcode, ctrl_shiftamt;
   output [31:0] data_result;
   output isNotEqual, isLessThan;
	wire [31:0]outSum;
	wire [31:0]outShift;
	wire tempNeq, tempLT;
	wire neqLog;
	wire [1:0]op;
	
	assign op[0] = ctrl_ALUopcode[0];	
	assign op[1] = ctrl_ALUopcode[1];
	assign neqLog = ~ctrl_ALUopcode[4] & ~ctrl_ALUopcode[3] & ~ctrl_ALUopcode[2] & ~ctrl_ALUopcode[1] & ctrl_ALUopcode[0];
	
	AddSubAndOr ALU_internal(.A(data_operandA), .B(data_operandB), .out(outSum), .sel(op), .neq(tempNeq), .LT(tempLT));
	barrelShifter ALU_shift(.A(data_operandA),.op(op),.shift_amt(ctrl_shiftamt), .out(outShift));
	
	genvar i;
	generate
	for (i = 0; i < 32; i = i + 1)
	begin: loop1
			TRI my_tri(.in(outSum[i]), .out(data_result[i]), .oe(~ctrl_ALUopcode[2]));
			TRI my_tri1(.in(outShift[i]), .out(data_result[i]), .oe(ctrl_ALUopcode[2]));
	end
	endgenerate
	TRI my_tri2(.in(tempNeq), .out(isNotEqual), .oe(neqLog));
	TRI my_tri3(.in(tempLT), .out(isLessThan), .oe(neqLog));
endmodule

module AddSubAndOr(A, B, out, sel, neq, LT);
	input [31:0]A;
	input [31:0]B;
	input [1:0]sel;
	output [31:0]out;
	output neq, LT;
	wire [6:0]G;
	wire [6:0]P;
	wire [7:0]Co;
	wire [7:0]Ci;
	wire [31:0]temp;
	wire ovFlow;
	wire Cin;
	assign Cin = sel[0];
	
	FourBitSliceComp my_slice00(.A(A[3:0])
			,.B(B[3:0])
			,.out(temp[3:0])
			,.Cin(Cin)
			,.Cout(Co[0])
			,.Po(P[0])
			,.Go(G[0])
			,.sel(sel));
	genvar i;
	generate
	for (i=1; i < 7; i = i + 1)
	begin: loop1
	FourBitSliceComp my_slice(.A(A[(4*i+3):4*i])
						,.B(B[(4*i+3):4*i])
						,.out(temp[(4*i+3):4*i])
						,.Cin(Ci[i-1])
						,.Cout(Co[i])
						,.Po(P[i])
						,.Go(G[i])
						,.sel(sel));
	end
	endgenerate
	
	
	FourBitSliceComp my_slice2(.A(A[31:28]), .B(B[31:28]), .out(temp[31:28]), .Cin(Ci[6]), .Cout(Co[7]) ,.sel(sel), .ov(ovFlow));
	assign Ci[0] = Cin&P[0]|G[0];
	assign Ci[1] = (Cin&P[0]|G[0])&P[1]|G[1];	
	assign Ci[2] = ((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2];
	assign Ci[3] = (((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3];	
	assign Ci[4] = ((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4];
	assign Ci[5] = (((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4])&P[5]|G[5];	
	assign Ci[6] = ((((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4])&P[5]|G[5])&P[6]|G[6];
	
	wire [3:0]neqCheck;
	generate
	for (i = 0; i < 4; i = i + 1)
	begin: loop2
		assign neqCheck[i] = temp[8*i] | temp[8*i+1] | temp[8*i+2] | temp [8*i+3] | temp [8*i+4] | temp [8*i+5] | temp [8*i+6] | temp [8*i+7];
	end
	endgenerate
	or or1(neq, neqCheck[0], neqCheck[1], neqCheck[2], neqCheck[3]);
	or or2(LT, temp[31], ovFlow);
	assign out = temp;
endmodule

module FourBitSliceComp (A, B, Cin, out, Cout, sel, Po, Go, ov);
	input [3:0]A;
	input [3:0]B;
	input [1:0]sel; 
	input Cin;
	output [3:0]out;
	output Cout, ov, Po, Go;

	wire [3:0]G;
	wire [3:0]P;
	wire [4:0]C;
	wire [3:0]Bs;
	wire [3:0]simp;
	wire [3:0]S;
	
	assign C[0] = Cin;
	assign C[1] = (C[0]& P[0]) | G[0];
	assign C[2] = (((C[0]& P[0]) | G[0])& P[1]) | G[1];
	assign C[3] = (((((C[0]& P[0]) | G[0])& P[1]) | G[1])& P[2]) | G[2];
	assign C[4] = (((((((C[0]& P[0]) | G[0])& P[1]) | G[1])& P[2]) | G[2])& P[3]) | G[3];
	assign Cout = C[4];
	assign Po = P[0]&P[1]&P[2]&P[3]; 
	assign Go = G[0]&P[1]&P[2]&P[3] | G[1]&P[2]&P[3] | G[2]&P[3] | G[3];
	genvar i;
	generate
	for (i = 0; i < 4; i = i + 1) 
	begin: loop1
			TRI my_tri(.in(B[i]), .out(Bs[i]), .oe(~sel[0]));
			TRI my_tri1(.in(~B[i]), .out(Bs[i]), .oe(sel[0]));
			assign G[i] = A[i] & Bs[i];
			assign P[i] = A[i] ^ Bs[i];
			assign S[i] = C[i] ^ A[i] ^ Bs[i];
			TRI my_tri2(.in(B[i] & A[i]), .out(simp[i]), .oe(~sel[0]));
			TRI my_tri3(.in(B[i] | A[i]), .out(simp[i]), .oe(sel[0]));
			TRI my_tri4(.in(S[i]), .out(out[i]), .oe(~sel[1]));
			TRI my_tri5(.in(simp[i]), .out(out[i]), .oe(sel[1]));
	end
	endgenerate
	assign Cout = C[4];
	xor xor1(ov, C[3], C[4]); 
endmodule

module barrelShifter (A,op,shift_amt, out);
	input [31:0] A;
	input [1:0] op;
	input [4:0] shift_amt;
	output [31:0] out;
	
	wire [31:0] w4;
	wire [31:0] w3;
	wire [31:0] w2;
	wire [31:0] w1;
	wire [31:0] w0;
	
	genvar i;
	generate
	for (i = 0; i < 32; i = i + 1)
	begin: loop1
		TRI my_tri4not(.in(A[i]), .out(w4[i]), .oe(~shift_amt[4]));
		TRI my_tri3not(.in(w4[i]), .out(w3[i]), .oe(~shift_amt[3]));
		TRI my_tri2not(.in(w3[i]), .out(w2[i]), .oe(~shift_amt[2]));
		TRI my_tri1not(.in(w2[i]), .out(w1[i]), .oe(~shift_amt[1]));
		TRI my_tri0not(.in(w1[i]), .out(w0[i]), .oe(~shift_amt[0]));
		assign out[i]=w0[i];
	end
	for (i = 0; i < 16; i = i + 1)
	begin: loop2
		//right shift
		TRI my_triR16(.in(A[i+16]), .out(w4[i]), .oe(shift_amt[4] & op[0]));
		TRI my_triR16_2(.in(A[31]), .out(w4[i+16]), .oe(shift_amt[4] & op[0]));
		//left shift
		TRI my_triL16(.in(A[i]), .out(w4[i+16]), .oe(shift_amt[4] & ~op[0]));
		TRI my_triL16_2(.in(1'b0), .out(w4[i]), .oe(shift_amt[4] & ~op[0]));
	end
	for (i = 0; i < 24; i = i + 1)
	begin: loop3
		//right shift
		TRI my_triR8_0(.in(w4[i+8]), .out(w3[i]), .oe(shift_amt[3] & op[0]));
		//left shift
		TRI my_triL8_0(.in(w4[i]), .out(w3[i+8]), .oe(shift_amt[3] & ~op[0]));
	end
	
	for (i = 0; i < 8; i= i + 1)
	begin: loop4
		TRI my_triR(.in(w4[31]), .out(w3[i+24]), .oe(shift_amt[3] & op[0]));
		TRI my_triL(.in(1'b0), .out(w3[i]), .oe(shift_amt[3] & ~op[0]));
	end
	for (i = 0; i < 28; i = i + 1)
	begin: loop5
		//right shift
		TRI my_triR4_0(.in(w3[i+4]), .out(w2[i]), .oe(shift_amt[2] & op[0]));
		//left shift
		TRI my_triL4_0(.in(w3[i]), .out(w2[i+4]), .oe(shift_amt[2] & ~op[0]));
	end
	for (i = 0; i < 4; i = i + 1)
	begin: loop6
		TRI my_triR(.in(w3[31]), .out(w2[i+28]), .oe(shift_amt[2] & op[0]));
		TRI my_triL(.in(1'b0), .out(w2[i]), .oe(shift_amt[2] & ~op[0]));
	end
	for (i = 0; i < 30; i = i + 1)
	begin: loop7
		//right shift
		TRI my_triR2_0(.in(w2[i+2]), .out(w1[i]), .oe(shift_amt[1] & op[0]));
		//left shift
		TRI my_triL2_0(.in(w2[i]), .out(w1[i+2]), .oe(shift_amt[1] & ~op[0]));
	end
	for (i = 0; i < 2; i = i + 1)
	begin: loop8
		TRI my_triR(.in(w2[31]), .out(w1[i+30]), .oe(shift_amt[1] & op[0]));
		TRI my_triL(.in(1'b0), .out(w1[i]), .oe(shift_amt[1] & ~op[0]));
	end
	for (i = 0; i < 31; i = i + 1)
	begin: loop9
		//right shift
		TRI my_triR2_0(.in(w1[i+1]), .out(w0[i]), .oe(shift_amt[0] & op[0]));
		//left shift
		TRI my_triL2_0(.in(w1[i]), .out(w0[i+1]), .oe(shift_amt[0] & ~op[0]));
	end
	endgenerate
	TRI my_triR(.in(w1[31]), .out(w0[31]), .oe(shift_amt[0] & op[0]));
	TRI my_triL2_0(.in(1'b0), .out(w0[0]), .oe(shift_amt[0] & ~op[0]));
endmodule

module multdiv(data_operandA, data_operandB, ctrl_MULT, ctrl_DIV, clock, data_result, data_exception, data_inputRDY, data_resultRDY, rs);
////,test1,test2,test3,test4,test5,test6,test7,test8);
   input [31:0] data_operandA;
   input [31:0] data_operandB;
   input ctrl_MULT, ctrl_DIV, clock, rs;             
   output [31:0] data_result; 
   output data_exception, data_inputRDY, data_resultRDY;
   //output [31:0] test1;
   //output [31:0] test2;
   //output [31:0] test3;
   //output [31:0] test4;
   //output [31:0] test5;
   //output [31:0] test6;
   //output [31:0] test7;
   //output [31:0] test8;
//
//17 stage multiplier/divider. To reduce one stage, make last division do 7 simultaneous subtractions and give the result for the largest number whose
//result was positive. At the beginning we have:
// OOZ, OZZ, ZOZ, can get ZOO=OOZ>>1,ZZO=ZOZ>>1 by shifting, must compute OZO and OOO. Could also subtract twice: Num - OOZ - ZZO = Num - OOO
// Num - OZO = Num - OZZ - ZZO
//this allows moving first multiplier to i=0 stage, and lastDiv to i=15 stage, and now we have a 16 stage multiplier.

//Multiplier
wire [31:0] cumulLog;

genvar i;
genvar j;
generate
for (i = 0; i < 17; i = i + 1) begin: pipe
	//multiplication
	wire [31:0] A;
	wire [63:0] B_in;
	wire [63:0] B_out;
	wire extraBit, nextExtraBit, isMult, MulResNeg;
	
	//division
	wire [31:0] rem_in;
	wire [31:0] rem_out;
	wire [31:0] quot_in;
	wire [31:0] quot_out;
	wire [63:0] BOO_in;
	wire [63:0] BOZ_in;
	wire [63:0] BZO_in;
	wire [63:0] BOO_out;
	wire [63:0] BOZ_out;
	wire [63:0] BZO_out;
	wire ctrl_neg, isExc, isDiv;
	
if (i == 0) begin // first stage
		// multiplication
		for (j = 0; j < 32; j = j + 1) begin: setupLoop
			assign pipe[i].A[j] = data_operandA[j];
		end
		for (j = 0; j < 32; j = j + 1) begin: setupLoop2
			assign pipe[i].B_out[j] = data_operandB[j];
			assign pipe[i].B_out[j+32] = 1'b0;
		end
		//assign pipe[0].B_in[31] = 1'b0;
		assign pipe[i].extraBit = 1'b0;
		assign pipe[i].isMult = ctrl_MULT;
		assign pipe[i].MulResNeg = ~(data_operandB[31] ^ data_operandA[31])&(|data_operandA)&(|data_operandB);
		//division
		for (j = 0; j < 32; j = j + 1) begin: setupDivLoop
		end
		assign pipe[i].isDiv = ctrl_DIV;
			DivisionSetup divOne(.tops(data_operandA)
							,.bottoms(data_operandB)
							,.newTops(pipe[i].rem_out)
							,.newBottomsOZ(pipe[i].BOZ_out)
							,.newBottomsOO(pipe[i].BOO_out)
							,.newBottomsZO(pipe[i].BZO_out)
							,.data_exc(pipe[i].isExc)
							,.quot_neg(pipe[i].ctrl_neg)
							,.resZero());
end
else if (i == 16) begin //last pipe stage
	//multiplication
	for (j = 0; j < 32; j = j + 1) begin: multBitNumLast
		DFFx mul_opA(.d(pipe[i-1].A[j]), .q(pipe[i].A[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_opB_1(.d(pipe[i-1].B_out[j]), .q(pipe[i].B_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_opB_2(.d(pipe[i-1].B_out[j+32]), .q(pipe[i].B_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
	end
		DFFx mul_extra(.d(pipe[i-1].nextExtraBit), .q(pipe[i].extraBit), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_ctrlMULT(.d(pipe[i-1].isMult), .q(pipe[i].isMult), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_mulNeg(.d(pipe[i-1].MulResNeg), .q(pipe[i].MulResNeg), .clk(clock),.en(1'b1),.clrn(rs));
	wire [31:0] mul_result;
	for (j = 0; j < 32; j = j + 1)begin: endLoopEverything
		TRI data_div(.in(pipe[i].quot_out[j]), .out(data_result[j]), .oe(pipe[i].isDiv));
		TRI data_mul(.in(pipe[i].mul_result[j]), .out(data_result[j]), .oe(pipe[i].isMult));
		assign cumulLog[j] = pipe[i].B_in[j+32]^pipe[i].B_in[31];
	end
		wire isMulExc;
		assign isMulExc = (pipe[i].MulResNeg^pipe[i].B_in[31])&(|cumulLog);
		TRI data_exc0(.in(isMulExc), .out(data_exception), .oe(pipe[i].isMult));
		TRI data_exc1(.in(pipe[i].isExc), .out(data_exception), .oe(pipe[i].isDiv));
		assign data_resultRDY = pipe[i].isMult | pipe[i].isDiv;
		multStage mm(.operand(pipe[i].A)
					,.resLarge(pipe[i].B_in)
					,.extra(pipe[i].extraBit)
					,.out(pipe[i].mul_result)
					,.enable(pipe[i].isMult)
					,.nextExtra(pipe[i].nextExtraBit)); // 16th addition
	//division
	for (j = 0; j < 32; j = j + 1) begin: DivBitNumLast
		DFFx div_BOZ(.d(pipe[i-1].BOZ_out[j]), .q(pipe[i].BOZ_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BOZ2(.d(pipe[i-1].BOZ_out[j+32]), .q(pipe[i].BOZ_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_rem(.d(pipe[i-1].rem_out[j]), .q(pipe[i].rem_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_qtn(.d(pipe[i-1].quot_out[j]), .q(pipe[i].quot_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
	end
		DFFx div_neg(.d(pipe[i-1].ctrl_neg), .q(pipe[i].ctrl_neg), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_exc(.d(pipe[i-1].isExc), .q(pipe[i].isExc), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_ctrlDiv(.d(pipe[i-1].isDiv), .q(pipe[i].isDiv), .clk(clock),.en(1'b1),.clrn(rs));

    lastDiv ld(.prevRem(pipe[i].rem_in)
			,.BcurrOZ(pipe[i].BOZ_in)
			,.isOperant(pipe[i].isDiv)
			,.QuotCurrent(pipe[i].quot_in)
			,.newQuot(pipe[i].quot_out)
			,.newRem(pipe[i].rem_out)
			,.isNeg(pipe[i].ctrl_neg));
end
else begin
	// multiplication
	for (j = 0; j < 32; j = j + 1) begin: multBitNum
		DFFx mul_opA(.d(pipe[i-1].A[j]), .q(pipe[i].A[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_opB_1(.d(pipe[i-1].B_out[j]), .q(pipe[i].B_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_opB_2(.d(pipe[i-1].B_out[j+32]), .q(pipe[i].B_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
	end
		DFFx mul_extra(.d(pipe[i-1].nextExtraBit), .q(pipe[i].extraBit), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_ctrlMULT(.d(pipe[i-1].isMult), .q(pipe[i].isMult), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx mul_mulNeg(.d(pipe[i-1].MulResNeg), .q(pipe[i].MulResNeg), .clk(clock),.en(1'b1),.clrn(rs));
		
		multStage mm(.operand(pipe[i].A)
					,.resLarge(pipe[i].B_in)
					,.extra(pipe[i].extraBit)
					,.out(pipe[i].B_out)
					,.enable(pipe[i].isMult)
					,.nextExtra(pipe[i].nextExtraBit));
	// division
	for (j = 0; j < 32; j = j + 1) begin: DivBitNum
		DFFx div_BOO(.d(pipe[i-1].BOO_out[j]), .q(pipe[i].BOO_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BZO(.d(pipe[i-1].BZO_out[j]), .q(pipe[i].BZO_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BOZ(.d(pipe[i-1].BOZ_out[j]), .q(pipe[i].BOZ_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BOO2(.d(pipe[i-1].BOO_out[j+32]), .q(pipe[i].BOO_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BZO2(.d(pipe[i-1].BZO_out[j+32]), .q(pipe[i].BZO_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_BOZ2(.d(pipe[i-1].BOZ_out[j+32]), .q(pipe[i].BOZ_in[j+32]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_rem(.d(pipe[i-1].rem_out[j]), .q(pipe[i].rem_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_qtn(.d(pipe[i-1].quot_out[j]), .q(pipe[i].quot_in[j]), .clk(clock),.en(1'b1),.clrn(rs));
	end
		DFFx div_neg(.d(pipe[i-1].ctrl_neg), .q(pipe[i].ctrl_neg), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_exc(.d(pipe[i-1].isExc), .q(pipe[i].isExc), .clk(clock),.en(1'b1),.clrn(rs));
		DFFx div_ctrlDiv(.d(pipe[i-1].isDiv), .q(pipe[i].isDiv), .clk(clock),.en(1'b1),.clrn(rs));
		
		divStage dd(.prevRem(pipe[i].rem_in)
					,.BcurrOZ(pipe[i].BOZ_in)
					,.BcurrZO(pipe[i].BZO_in)
					,.BcurrOO(pipe[i].BOO_in)
					,.isOperant((~pipe[i].isExc)&(pipe[i].isDiv))
					,.QuotCurrent(pipe[i].quot_in)
					,.newRem(pipe[i].rem_out)
					,.newQuot(pipe[i].quot_out)
					,.BnextOZ(pipe[i].BOZ_out)
					,.BnextZO(pipe[i].BZO_out)
					,.BnextOO(pipe[i].BOO_out));
end
end
for (i = 0; i < 32; i = i + 1) begin: debugLoop
		//assign test1[i] = pipe[3].B_out[i];
		//assign test2[i] = pipe[3].B_out[i+32];
		//assign test3[i] = pipe[7].B_out[i];
		//assign test4[i] = pipe[7].B_out[i+32];
		//assign test5[i] = pipe[11].B_out[i];
		//assign test6[i] = pipe[11].B_out[i+32];
		//assign test7[i] = pipe[15].B_out[i];
		//assign test8[i] = pipe[15].B_out[i+32];
end
endgenerate
endmodule

module divStage(prevRem, BcurrOZ, BcurrZO, BcurrOO, isOperant, QuotCurrent, newRem, newQuot
			, BnextOZ, BnextZO,BnextOO);
	input [31:0] prevRem;
	input [63:0] BcurrOO;
	input [63:0] BcurrOZ;
	input [63:0] BcurrZO;
	input [31:0] QuotCurrent;
	input isOperant;
	output [31:0] newRem;
	output [63:0] BnextZO;
	output [63:0] BnextOO;
	output [63:0] BnextOZ;
	output [31:0] newQuot;
	
	wire [31:0] TempZOres;
	//wire [31:0] BcurrZO_t;
	wire [31:0] TempOOres;
	//wire [31:0] BcurrOO_t;
	wire [31:0] TempOZres;
	//wire [31:0] BcurrOZ_t;
	wire [31:0] nBcurrOZ_t;
	wire [31:0] nBcurrOO_t;
	wire [31:0] nBcurrZO_t;
	wire OZ_hasOnes, ZO_hasOnes, OO_hasOnes, selectOO, selectOZ, selectZO, selectZZ;
	assign OZ_hasOnes = |BcurrOZ[62:31];
	assign ZO_hasOnes = |BcurrZO[62:31];
	assign OO_hasOnes = |BcurrOO[62:31];
	assign selectOO = (~OO_hasOnes)&(~TempOOres[31])&isOperant;
	assign selectOZ = (~OZ_hasOnes)&(~TempOZres[31])&(~((~OO_hasOnes)&(~TempOOres[31])))&isOperant;
	assign selectZO = (~ZO_hasOnes)&(~TempZOres[31])&(~((~OO_hasOnes)&(~TempOOres[31])))&(~((~OZ_hasOnes)&(~TempOZres[31])))&isOperant;
	assign selectZZ = (~((~OZ_hasOnes)&(~TempOZres[31])))&(~((~ZO_hasOnes)&(~TempZOres[31])))&(~((~OO_hasOnes)&(~TempOOres[31])))|~isOperant;
	
	Adder subBZO(.A(prevRem), .B(nBcurrZO_t), .Cin(1'b1), .out(TempZOres));
	Adder subBOZ(.A(prevRem), .B(nBcurrOZ_t), .Cin(1'b1), .out(TempOZres));
	Adder subBOO(.A(prevRem), .B(nBcurrOO_t), .Cin(1'b1), .out(TempOOres));
	genvar i;
	generate
		for (i = 0; i < 31; i = i + 1) begin: setupSubs
			assign nBcurrZO_t[i] = ~BcurrZO[i];
			assign nBcurrOZ_t[i] = ~BcurrOZ[i];
			assign nBcurrOO_t[i] = ~BcurrOO[i];
		end
			assign nBcurrZO_t[31] = 1'b1;
			assign nBcurrOZ_t[31] = 1'b1;
			assign nBcurrOO_t[31] = 1'b1;
		for (i = 0; i < 62; i = i + 1) begin: shiftNums
			assign BnextZO[i] = BcurrZO[i+2];
			assign BnextOO[i] = BcurrOO[i+2];
			assign BnextOZ[i] = BcurrOZ[i+2];
		end
			assign BnextZO[62] = 1'b0;
			assign BnextOO[62] = 1'b0;
			assign BnextOZ[62] = 1'b0;
			assign BnextZO[63] = 1'b0;
			assign BnextOO[63] = 1'b0;
			assign BnextOZ[63] = 1'b0;
		for (i = 0; i < 32; i = i + 1) begin: RemLoop
			TRI triB0(.in(TempZOres[i]), .out(newRem[i]), .oe(selectZO));
			TRI triB1(.in(TempOOres[i]), .out(newRem[i]), .oe(selectOO));
			TRI triB2(.in(TempOZres[i]), .out(newRem[i]), .oe(selectOZ));
			TRI triB3(.in(prevRem[i]), .out(newRem[i]), .oe(selectZZ));
		end
		for (i = 0; i < 30; i = i + 1) begin: QuotLoop
				assign newQuot[i+2] = QuotCurrent[i];
		end
			TRI triB0(.in(1'b1), .out(newQuot[0]), .oe(selectZO));
			TRI triB1(.in(1'b0), .out(newQuot[1]), .oe(selectZO));
			TRI triB2(.in(1'b1), .out(newQuot[0]), .oe(selectOO));
			TRI triB3(.in(1'b1), .out(newQuot[1]), .oe(selectOO));
			TRI triB4(.in(1'b0), .out(newQuot[0]), .oe(selectOZ));
			TRI triB5(.in(1'b1), .out(newQuot[1]), .oe(selectOZ));
			TRI triB6(.in(1'b0), .out(newQuot[0]), .oe(selectZZ));
			TRI triB7(.in(1'b0), .out(newQuot[1]), .oe(selectZZ));
	endgenerate
	
	//FiveSumSub newOps(.A(opsLeft), .B(5'b00001), .ctrl(1'b1), .out(newOpsLeft), .ov(negOneOpsLeft));
	//assign divDone = ~isOperant ;
endmodule

module DivisionSetup(tops, bottoms, newTops, newBottomsOZ, newBottomsOO, newBottomsZO, data_exc, quot_neg, resZero);
	input [31:0] tops;
	input [31:0] bottoms;
	output [31:0] newTops;
	output [63:0] newBottomsOZ;
	output [63:0] newBottomsZO;
	output [63:0] newBottomsOO;
	//output [4:0] numOps;
	output data_exc, quot_neg, resZero;
	
	wire [31:0] TopTemp;
	wire [31:0] BotTemp;
	wire [31:0] BotTemp2;
	wire [31:0] BotTemp3;
	wire [31:0] BotTempOO;
	wire [31:0] BotTempOZ;
	wire [31:0] BotTempZO;
	wire [31:0] TwoBotTempOZ;
	wire [31:0] nBotTempOZ;
	wire [31:0] ThreeBotTempOZ;
	wire [31:0] fourBotTempOZ;
	genvar i;
	
	generate
	//step one -> quadruple BotTempOZ, and double BotTempOZ
	//step two -> subtract 4BotTempOZ - BotTempOZ
	//step three -> newBOT_OO = 3BotTempOZ >> 1 (store from 31 to 62)
	// newBot_ZO = 2BotTempOZ >> 2 (store from 31 to 62)
		for (i = 0; i < 30; i = i + 1) begin: shifterLoop
			assign TwoBotTempOZ[i+1] = BotTempOZ[i];
			assign fourBotTempOZ[i+2] = BotTempOZ[i];
		end
			assign TwoBotTempOZ[0] = 1'b0;
			assign fourBotTempOZ[0] = 1'b0;
			assign fourBotTempOZ[1] = 1'b0;
			assign TwoBotTempOZ[31] = BotTempOZ[30];
			Adder threeOZ(.A(fourBotTempOZ), .B(nBotTempOZ), .Cin(1'b1), .out(ThreeBotTempOZ));
		for (i = 0; i < 32; i = i + 1)begin: shifterLoop2
			assign newBottomsOO[i+29] = ThreeBotTempOZ[i];
			assign newBottomsZO[i+29] = BotTempOZ[i];
			assign newBottomsOZ[i+30] = BotTempOZ[i];
		end
		for (i = 0; i < 29; i = i + 1) begin: makeOOandZO
			assign newBottomsOO[i] = 1'b0;
			assign newBottomsZO[i] = 1'b0;
			assign newBottomsOZ[i] = 1'b0;
		end
			assign newBottomsOZ[62] = 1'b0;
			assign newBottomsOZ[63] = 1'b0;
			assign newBottomsOO[61] = 1'b0;
			assign newBottomsZO[61] = 1'b0;
			assign newBottomsOO[62] = 1'b0;
			assign newBottomsZO[62] = 1'b0;
			assign newBottomsOO[63] = 1'b0;
			assign newBottomsZO[63] = 1'b0;
		for (i = 0; i < 32; i = i + 1)begin: loop1
			//shifter neg
			assign nBotTempOZ[i] = ~BotTempOZ[i];
		
			assign TopTemp[i] = tops[i] ^ tops[31];
			assign BotTemp[i] = bottoms[i] ^ bottoms[31];
		end
	endgenerate
	Adder topsNeg(.A(0), .B(TopTemp), .Cin(tops[31]), .out(newTops));
	Adder botsNeg(.A(0), .B(BotTemp), .Cin(bottoms[31]), .out(BotTempOZ));
	Adder botsOO(.A(BotTempOZ), .B(BotTempZO), .Cin(1'b0), .out(BotTempOO));
	
	assign quot_neg = tops[31] ^ bottoms[31];
	assign data_exc = ~|bottoms;
endmodule

module lastDiv(prevRem, BcurrOZ, isOperant, newRem, QuotCurrent, newQuot, isNeg);
	input [31:0] prevRem;
	input [63:0] BcurrOZ;
	input [31:0] QuotCurrent;
	input isNeg, isOperant;
	output [31:0] newRem;
	output [31:0] newQuot;
	
	//perform last subtraction
	wire [31:0] TempOZres;
	wire [31:0] BcurrOZ_t;
	wire [31:0] nBcurrOZ_t;
	wire OZ_hasOnes, selectOZ;
	assign OZ_hasOnes = |BcurrOZ[62:31];
	assign selectOZ = (~OZ_hasOnes)&(~TempOZres[31]);
	assign selectZZ = ~((~OZ_hasOnes)&(~TempOZres[31]));
	Adder subBOZ(.A(prevRem), .B(nBcurrOZ_t), .Cin(1'b1), .out(TempOZres));
	
	wire [31:0] quot_with_fit;
	wire [31:0] quot_with_fit_neg;
	wire [31:0] quot_with_fit_neg_out;
	wire [31:0] quot_no_fit;
	wire [31:0] quot_no_fit_neg;
	wire [31:0] quot_no_fit_neg_out;
	Adder neg_with_fit(.A(0), .B(quot_with_fit_neg), .Cin(1'b1), .out(quot_with_fit_neg_out));
	Adder neg_no_fit(.A(0), .B(quot_no_fit_neg), .Cin(1'b1), .out(quot_no_fit_neg_out));
	genvar i;
	generate
		for (i = 0; i < 31; i = i + 1) begin: setupNegs
			assign quot_with_fit[i+1] = QuotCurrent[i];
			assign quot_with_fit_neg[i+1] = ~QuotCurrent[i];
			assign quot_no_fit[i+1] = QuotCurrent[i];
			assign quot_no_fit_neg[i+1] = ~QuotCurrent[i];
			assign nBcurrOZ_t[i] = ~BcurrOZ_t[i];
		end
			assign nBcurrOZ_t[31] = ~BcurrOZ_t[31];
			assign quot_with_fit[0] = 1'b1;
			assign quot_no_fit[0] = 1'b0;
			assign quot_with_fit_neg[0] = 1'b0;
			assign quot_no_fit_neg[0] = 1'b1;
		for (i = 0; i < 31; i = i + 1) begin: setupSubs
			assign BcurrOZ_t[i] = BcurrOZ[i];
		end
			assign BcurrOZ_t[31] = 1'b0;
		for (i = 0; i < 32; i = i + 1) begin: select_result
			TRI sel_res00(.in(quot_with_fit_neg_out[i]), .out(newQuot[i]), .oe(selectOZ&(isNeg)));
			TRI sel_res01(.in(quot_no_fit_neg_out[i]), .out(newQuot[i]), .oe(selectZZ&(isNeg)));
			TRI sel_res10(.in(quot_with_fit[i]), .out(newQuot[i]), .oe(selectOZ&(~isNeg)));
			TRI sel_res11(.in(quot_no_fit[i]), .out(newQuot[i]), .oe(selectZZ&(~isNeg)));
			
			TRI triB2(.in(TempOZres[i]), .out(newRem[i]), .oe(selectOZ));
			TRI triB3(.in(prevRem[i]), .out(newRem[i]), .oe(selectZZ));
		end
	endgenerate
endmodule

module multStage (operand, resLarge, extra, out, enable, nextExtra);
	input [31:0] operand;
	input [63:0] resLarge;
	input extra, enable;
	output [63:0] out;
	output nextExtra;
	
	wire [31:0] Val;
	wire [2:0]c1;
	//constructs 8+1 bit array for Booth's to iterate over.
	assign c1[0] = extra;
	assign c1[1] = resLarge[0];
	assign c1[2] = resLarge[1];
	assign nextExtra = resLarge[1];
	wire contOneTwo, contDoSth, AddOrSub;
	//the lines below are based the opcode for the adder:
		// 0xx -> do nothingo
		// 11x -> use add, 10x use subtract
		// 1x1 -> use shifted (2x) number, 1x0 -> use regular number
	assign contOneTwo = (~c1[2] & c1[1] & c1[0] )| (c1[2] & ~c1[1] & ~c1[0]);
	assign addOrSub =  ~c1[2]&enable;
	assign contDoSth = ~((c1[2] & c1[1] & c1[0]) | (~c1[2] & ~c1[1] & ~c1[0]));
	oneAddShift oneAdd(.addend(Val), .largeNum(resLarge), .ctrl(addOrSub), .out(out));
	
	wire once, twice, notimes;
	assign once = contDoSth&(~contOneTwo)&enable;
	assign twice = contDoSth&(contOneTwo)&enable;
	assign notimes = ~contDoSth|~enable;
	genvar i;
	generate
	for (i = 0; i < 32; i = i + 1) begin: doNothing
			TRI doNothing(.in('b0), .out(Val[i]), .oe(notimes));
	end
	for (i = 1; i < 31; i = i + 1) begin: loop2
			TRI OnceSum(.in(operand[i]),.out(Val[i]), .oe(once));
			TRI TwiceSum(.in(operand[i-1]),.out(Val[i]), .oe(twice));
	end
			TRI OnceSumF(.in(operand[0]),.out(Val[0]), .oe(once));
			TRI TwiceSumF(.in(1'b0),.out(Val[0]), .oe(twice));
			TRI OnceSumL(.in(operand[31]),.out(Val[31]), .oe(once));
			TRI TwiceSumL(.in(operand[30]),.out(Val[31]), .oe(twice));
	endgenerate
endmodule

module oneAddShift(addend, largeNum, ctrl, out);
	input [31:0] addend;
	input [63:0] largeNum;
	input ctrl;
	output [63:0]out;
	
	//addOrSub
	wire [31:0] tempRes;
	wire [31:0] toAdder;
	wire [63:0] AddRes;
	wire [31:0] partWeAdd;
	wire neg;
	assign neg = ~ctrl;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)begin: loop98
			assign partWeAdd[i] = largeNum[i+32];
			assign toAdder[i] = (addend[i]^neg);//(~addend[i])&(~ctrl)|(addend[i])&ctrl;
			assign AddRes[i] = largeNum[i];
			assign AddRes[i+32] = tempRes[i];
		end
			Adder addsub(.A(partWeAdd), .B(toAdder), .Cin(neg), .out(tempRes));
//Adder(A, B, Cin, out)
		for (i = 0; i < 62; i = i + 1) begin: shiftR2
			assign out[i] = AddRes[i+2];
		end
			assign out[62] = AddRes[63];
			assign out[63] = AddRes[63];
	endgenerate
endmodule