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

module DFFx(d, clrn, clk, q, en); 
	input d, clrn, clk, en;
	output q; 
	reg q;
	
always @(posedge clk or posedge clrn) 
	begin 
		if(clrn) 
			begin q = 1'b0;
			end 
		else if (en) 
			begin q = d;	
			end
	end
endmodule