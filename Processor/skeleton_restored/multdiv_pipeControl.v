module multdiv_pipeControl(P, X, D, bpX, bpD, 
is_exc_valid,isNOP, DONT_WRITE, exc_reset);
	input [31:0] P;
	input [31:0] X;
	input [31:0] D;
	input isNOP;
	input is_exc_valid;
	output bpX;
	output bpD;
	output DONT_WRITE;
	output exc_reset;
	
	wire [31:0] Dhot;
	wire [31:0] Xhot;
	wire [4:0] D_op;
	wire [4:0] X_op;
	decoder5B dec00(.Enc(D_op),.out(Dhot));	
	decoder5B dec01(.Enc(X_op),.out(Xhot));	

	wire [4:0] rdX;
	wire [4:0] rsX;
	wire [4:0] rtX;
	wire [4:0] rtD;
	wire [4:0] rsD;
	wire [4:0] rdD;
	wire [4:0] rdP;
	wire DReadsRD, DReadsRS, DReadsRT;
	wire XReadsRD, XReadsRS, XReadsRT;
	wire XWrites;
	//read RD on bne=2, blt=6, sw=7, jr=4
	assign XReadsRD = Xhot[2]|Xhot[4]|Xhot[6]|Xhot[7];//0
	assign DReadsRD = Dhot[2]|Dhot[4]|Dhot[6]|Dhot[7];//1
	//read RS on ALU=0, addi=5, bne=2, blt=6, sw=7, lw=8
	assign XReadsRS = Xhot[0]|Xhot[5]|Xhot[2]|Xhot[6]|Xhot[7]|Xhot[8];//1
	assign DReadsRS = Dhot[0]|Dhot[5]|Dhot[2]|Dhot[6]|Dhot[7]|Dhot[8];//1
	//read RT on ALU=0
	assign XReadsRT = Xhot[0];//0
	assign DReadsRT = Dhot[0];//1

	wire isMulCyc_X;
	assign isMulCyc_X = (~X[6])&(~X[5])&X[4]&X[3]&Xhot[0];
	assign XWrites = Xhot[0]|Xhot[5]|Xhot[3]|Xhot[8];//1
genvar i;
generate
	for (i = 0; i < 5; i = i + 1)begin: decLoop
		assign D_op[i] = D[i+27];
		assign X_op[i] = X[i+27];
		
		assign rdX[i] = X[i+22];
		assign rsX[i] = X[i+17];
		assign rtX[i] = X[i+12];
		
		assign rdD[i] = D[i+22];
		assign rsD[i] = D[i+17];
		assign rtD[i] = D[i+12];
		
		assign rdP[i] = P[i+22];
	end

	wire [8:0] RAW;
	fiveBitEquals Feq1(.A(rdX), .B(rdP), .eq(RAW[5]));
	fiveBitEquals Feq2(.A(rsX), .B(rdP), .eq(RAW[4]));
	fiveBitEquals Feq4(.A(rtX), .B(rdP), .eq(RAW[3]));
	fiveBitEquals Feq5(.A(rdD), .B(rdP), .eq(RAW[2]));
	fiveBitEquals Feq7(.A(rsD), .B(rdP), .eq(RAW[1]));
	fiveBitEquals Feq8(.A(rtD), .B(rdP), .eq(RAW[0]));
	
	//data is needed in execute Stage
	//assign bpX[0] = (XReadsRD&RAW[5] | XReadsRS&RAW[4]&(~XReadsRD));//ALU_A MX
	//assign bpX[1] = (RAW[4]&XReadsRS&XReadsRD | XReadsRT&RAW[3]);//ALU_B MX
	assign bpX = (~isNOP)&(XReadsRD&RAW[5]|XReadsRS&RAW[4]|XReadsRT&RAW[3]);
	assign DONT_WRITE = XWrites&RAW[5]|isNOP;
	assign exc_reset = (~Xhot[22]|~isMulCyc_X)&is_exc_valid;
	//assign bpD = 
	//data is needed in Decode Stage
	//assign bpD[0] = (XReadsRD&RAW[2] | XReadsRS&RAW[1]&(~XReadsRD));//ALU_A WX
	//assign bpD[1] = (XReadsRS&RAW[1]&(XReadsRD) | XReadsRT&RAW[0]);//ALU_B WX
endgenerate
endmodule