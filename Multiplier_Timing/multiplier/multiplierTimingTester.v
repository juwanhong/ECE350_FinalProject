module multiplierTimingTester(data_operandA, data_operandB, ctrl_MULT, ctrl_DIV, clock, data_result, data_exception, data_inputRDY, data_resultRDY, rs);
//,test1,test2,test3,test4,test5,test6,test7,test8);
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
