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

