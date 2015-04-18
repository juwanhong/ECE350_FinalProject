module ALU(opA, opB, res, shiftamt, opcode, lt, ne, ex, res_RDY, inp_RDY, clock);
	input [31:0] opA;
	input [31:0] opB;
	input [4:0] opcode;
	input [4:0] shiftamt;
	input clock;
	output [31:0] res;
	output lt, ne, ex, res_RDY, inp_RDY;

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
	
	multdiv md(.data_operandA(opA)
					,.data_operandB(opB)
					,.ctrl_MULT(mul)
					,.ctrl_DIV(div)
					,.data_result(outMult)
					,.data_inputRDY(inp_RDY)
					,.data_resultRDY(res_RDY)
					,.clock(clock)
					,.data_exception(ex)
			);
			
	genvar i;
	generate
			for (i = 0; i < 32; i = i + 1) begin: loop1
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
	
	AddSubAndOr(.A(data_operandA), .B(data_operandB), .out(outSum), .sel(op), .neq(tempNeq), .LT(tempLT));
	barrelShifter (.A(data_operandA),.op(op),.shift_amt(ctrl_shiftamt), .out(outShift));
	
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

module Adder(A, B, Cin, out);
	input [31:0]A;
	input [31:0]B;
	input Cin;
	output [31:0]out;
	wire [6:0]G;
	wire [6:0]P;
	wire [7:0]Co;
	wire [6:0]Ci; //integrates logic
	wire ovFlow;
	
	FourBitSlice my_slice00(.A(A[3:0]), .B(B[3:0]), .out(out[3:0]), .Cin(Cin), .Cout(Co[0]), .Po(P[0]), .Go(G[0]));
	genvar i;
	generate
	for (i=1; i < 7; i = i + 1)
	begin: loop1
	FourBitSlice my_slice(.A(A[(4*i+3):4*i])
						,.B(B[(4*i+3):4*i])
						,.out(out[(4*i+3):4*i])
						,.Cin(Ci[i-1])
						,.Cout(Co[i])
						,.Po(P[i])
						,.Go(G[i]));
	end
	endgenerate
	FourBitSlice my_slice2(.A(A[31:28]), .B(B[31:28]), .out(out[31:28]), .Cin(Ci[6]), .Cout(Co[7]), .ov(ovFlow));
	
	assign Ci[0] = Cin&P[0]|G[0];
	assign Ci[1] = (Cin&P[0]|G[0])&P[1]|G[1];	
	assign Ci[2] = ((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2];
	assign Ci[3] = (((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3];	
	assign Ci[4] = ((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4];
	assign Ci[5] = (((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4])&P[5]|G[5];	
	assign Ci[6] = ((((((Cin&P[0]|G[0])&P[1]|G[1])&P[2]|G[2])&P[3]|G[3])&P[4]|G[4])&P[5]|G[5])&P[6]|G[6];
endmodule

module FourBitSlice (A, B, Cin, out, Cout, ov, Go, Po);
	input [3:0]A;
	input [3:0]B;
	input Cin;
	output [3:0]out;
	output Cout, ov, Go, Po;

	wire [3:0]G;
	wire [3:0]P;
	wire [4:0]C;
	
	assign C[0]=Cin;
	
	genvar i;
	generate
	for (i = 0; i < 4; i = i + 1) 
	begin: loop1
			assign G[i] = A[i] & B[i];
			assign P[i] = A[i] ^ B[i];
			assign out[i] = C[i] ^ A[i] ^ B[i];
	end
	endgenerate
	assign C[1] = (C[0]& P[0]) | G[0];
	assign C[2] = (((C[0]& P[0]) | G[0])& P[1]) | G[1];
	assign C[3] = (((((C[0]& P[0]) | G[0])& P[1]) | G[1])& P[2]) | G[2];
	assign C[4] = (((((((C[0]& P[0]) | G[0])& P[1]) | G[1])& P[2]) | G[2])& P[3]) | G[3];
	assign Cout = C[4];
	assign Po = P[0]&P[1]&P[2]&P[3]; 
	assign Go = G[0]&P[1]&P[2]&P[3] | G[1]&P[2]&P[3] | G[2]&P[3] | G[3];
	xor xor1(ov, C[3], C[4]); 
endmodule



module decoder5B (Enc, out);
	input [4:0] Enc;
	output [31:0] out;
	wire [4:0] EncN;
	
	not n1(EncN[0], Enc[0]);
	not n2(EncN[1], Enc[1]);
	not n3(EncN[2], Enc[2]);
	not n4(EncN[3], Enc[3]);
	not n5(EncN[4], Enc[4]);
	
	and and00(out[0], EncN[4], EncN[3], EncN[2], EncN[1], EncN[0]);
	and and01(out[1], EncN[4], EncN[3], EncN[2], EncN[1], Enc[0]);
	and and02(out[2], EncN[4], EncN[3], EncN[2], Enc[1], EncN[0]);
	and and03(out[3], EncN[4], EncN[3], EncN[2], Enc[1], Enc[0]);
	and and04(out[4], EncN[4], EncN[3], Enc[2], EncN[1], EncN[0]);
	and and05(out[5], EncN[4], EncN[3], Enc[2], EncN[1], Enc[0]);
	and and06(out[6], EncN[4], EncN[3], Enc[2], Enc[1], EncN[0]);
	and and07(out[7], EncN[4], EncN[3], Enc[2], Enc[1], Enc[0]);
	and and08(out[8], EncN[4], Enc[3], EncN[2], EncN[1], EncN[0]);
	and and09(out[9], EncN[4], Enc[3], EncN[2], EncN[1], Enc[0]);
	and and10(out[10], EncN[4], Enc[3], EncN[2], Enc[1], EncN[0]);
	and and11(out[11], EncN[4], Enc[3], EncN[2], Enc[1], Enc[0]);
	and and12(out[12], EncN[4], Enc[3], Enc[2], EncN[1], EncN[0]);
	and and13(out[13], EncN[4], Enc[3], Enc[2], EncN[1], Enc[0]);
	and and14(out[14], EncN[4], Enc[3], Enc[2], Enc[1], EncN[0]);
	and and15(out[15], EncN[4], Enc[3], Enc[2], Enc[1], Enc[0]);
	and and16(out[16], Enc[4], EncN[3], EncN[2], EncN[1], EncN[0]);
	and and17(out[17], Enc[4], EncN[3], EncN[2], EncN[1], Enc[0]);
	and and18(out[18], Enc[4], EncN[3], EncN[2], Enc[1], EncN[0]);
	and and19(out[19], Enc[4], EncN[3], EncN[2], Enc[1], Enc[0]);
	and and20(out[20], Enc[4], EncN[3], Enc[2], EncN[1], EncN[0]);
	and and21(out[21], Enc[4], EncN[3], Enc[2], EncN[1], Enc[0]);
	and and22(out[22], Enc[4], EncN[3], Enc[2], Enc[1], EncN[0]);
	and and23(out[23], Enc[4], EncN[3], Enc[2], Enc[1], Enc[0]);
	and and24(out[24], Enc[4], Enc[3], EncN[2], EncN[1], EncN[0]);
	and and25(out[25], Enc[4], Enc[3], EncN[2], EncN[1], Enc[0]);
	and and26(out[26], Enc[4], Enc[3], EncN[2], Enc[1], EncN[0]);
	and and27(out[27], Enc[4], Enc[3], EncN[2], Enc[1], Enc[0]);
	and and28(out[28], Enc[4], Enc[3], Enc[2], EncN[1], EncN[0]);
	and and29(out[29], Enc[4], Enc[3], Enc[2], EncN[1], Enc[0]);
	and and30(out[30], Enc[4], Enc[3], Enc[2], Enc[1], EncN[0]);
	and and31(out[31], Enc[4], Enc[3], Enc[2], Enc[1], Enc[0]);
endmodule