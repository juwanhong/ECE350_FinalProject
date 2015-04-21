module Branch_Control(PC_in, instr_D, STATUS_in, REG_A, REG_B, lag, address_jb, jb_control);
	input [31:0] PC_in;
	input [31:0] instr_D;
	input [31:0] STATUS_in;
	input [31:0] REG_A;
	input [31:0] REG_B;
	input lag;
	output jb_control;
	output [31:0]  address_jb;

wire [31:0] immed_add;
wire [31:0] addr_jump;
wire [31:0] addr_branch;
genvar i;
generate
	for (i = 0; i < 16; i = i + 1)begin: selectImmed
		assign immed_add[i] = instr_D[i];
		assign immed_add[i+16] = instr_D[16];
	end
	for (i = 0; i < 27; i = i + 1)begin: selectAddr
		assign addr_jump[i] = instr_D[i];
	end
	assign addr_jump[27] = PC_in[27];
	assign addr_jump[28] = PC_in[28];
	assign addr_jump[29] = PC_in[29];
	assign addr_jump[30] = PC_in[30];
	assign addr_jump[31] = PC_in[31];
	
	for (i = 0; i < 32; i = i + 1)begin: selectOut
		TRI sel_PC0(.in(addr_branch[i]), .out(address_jb[i]), .oe(take_branch));
		TRI sel_PC1(.in(addr_jump[i]), .out(address_jb[i]), .oe(~take_branch));
	end
endgenerate
Adder branch_alu(.A(PC_in), .B(immed_add), .Cin(1'b0), .out(addr_branch));
//blt, bne
wire blt, bne;
assign blt = (~instr_D[31])&(~instr_D[30])&(instr_D[29])&(instr_D[28])&(~instr_D[27]);
assign bne = (~instr_D[31])&(~instr_D[30])&(~instr_D[29])&(instr_D[28])&(~instr_D[27]);

wire isLT, isEQ;
comparator comp(.A(REG_A),.B(REG_B),.LT_out(isLT),.EQ_out(isEQ));
//bex
wire bex;
assign bex = (instr_D[31])&(~instr_D[30])&(instr_D[29])&(instr_D[28])&(~instr_D[27]);

wire isEX;
assign isEX = ~STATUS_in[31]&(|STATUS_in[30:0]);
//j, jal
wire j, jal, jr;

assign j = (~instr_D[31])&(~instr_D[30])&(~instr_D[29])&(~instr_D[28])&(instr_D[27]);
assign jal = (~instr_D[31])&(~instr_D[30])&(~instr_D[29])&(instr_D[28])&(instr_D[27]);
assign jr = (~instr_D[31])&(~instr_D[30])&(instr_D[29])&(~instr_D[28])&(~instr_D[27]);

//jr
wire take_branch, take_jump;
assign take_branch = bex&isEX | blt&isLT | bne&(~isEQ);
assign take_jump = j | jal | jr;



endmodule

module comparator(A, B, LT_out, EQ_out);
	input [31:0] A;
	input [31:0] B;
	output LT_out;
	output EQ_out;

wire negA, negB;
assign negA = A[31];
assign negB = B[31];

wire [7:0] A3, A2, A1, A0;
wire [7:0] B3, B2, B1, B0;
wire LT_t_3, LT_t_2, LT_t_1, LT_t_0;
wire EQ_t_3, EQ_t_2, EQ_t_1, EQ_t_0;


comparator_module comp31to24(.A(A3)
							,.B(B3)
							,.LT_in()
							,.EQ_in()
							,.LT_out(LT_t_3)
							,.EQ_out(EQ_t_3));
							
comparator_module comp23to16(.A(A2)
							,.B(B2)
							,.LT_in(LT_t_3)
							,.EQ_in(EQ_t_3)
							,.LT_out(LT_t_2)
							,.EQ_out(EQ_t_2));
							
comparator_module comp15to08(.A(A1)
							,.B(B1)
							,.LT_in(LT_t_2)
							,.EQ_in(EQ_t_2)
							,.LT_out(LT_t_1)
							,.EQ_out(EQ_t_1));
							
comparator_module comp07to00(.A(A0)
							,.B(B0)
							,.LT_in(LT_t_1)
							,.EQ_in(EQ_t_1)
							,.LT_out(LT_t_0)
							,.EQ_out(EQ_t_0));
			
assign LT_out = LT_t_0;
assign EQ_out = EQ_t_0;

endmodule


module comparator_module(A, B, LT_in, EQ_in, LT_out, EQ_out);
	input [7:0] A;
	input [7:0] B;
	input LT_in, EQ_in;
	output LT_out, EQ_out;
//LESS THAN  means A < B
wire [7:0] EQ_temp;
genvar i;
generate
	for (i = 0; i < 8; i = i + 1)begin: compareLoop
		assign EQ_temp[i] = A[i] ^ B[i];
	end
endgenerate
wire [7:0] LT_temp;
assign LT_temp[7]=(A[7])&(~B[7]);
assign LT_temp[6]=(~(A[7]^B[7]))&((A[6])&(~B[6]));
assign LT_temp[5]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&((A[5])&(~B[5]));
assign LT_temp[4]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&(~(A[5]^B[5]))&((A[4])&(~B[4]));
assign LT_temp[3]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&(~(A[5]^B[5]))&(~(A[4]^B[4]))&((A[3])&(~B[3]));
assign LT_temp[2]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&(~(A[5]^B[5]))&(~(A[4]^B[4]))&(~(A[3]^B[3]))&((A[2])&(~B[2]));
assign LT_temp[1]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&(~(A[5]^B[5]))
				&(~(A[4]^B[4]))&(~(A[3]^B[3]))&(~(A[2]^B[2]))&((A[1])&(~B[1]));
assign LT_temp[0]=(~(A[7]^B[7]))&(~(A[6]^B[6]))&(~(A[5]^B[5]))
				&(~(A[4]^B[4]))&(~(A[3]^B[3]))&(~(A[2]^B[2]))&(~(A[1]^B[1]))&((A[0])&(~B[0]));
assign LT_out = LT_in | (~EQ_out)&(|LT_temp);
assign EQ_out = EQ_in & ~(|EQ_temp);
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