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

