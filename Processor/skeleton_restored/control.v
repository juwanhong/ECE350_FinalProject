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
	assign signals[0] = h[5]|h[7]|h[8];//addi, lw, sw
	assign signals[1] = h[0]|h[3]|h[5]|h[7];//ALU, addi, jal, sw
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
	assign signals[14] = ~(h[2]|h[4]|h[6]|h[7]);//read $rd - sw=7,jr=4,bne=2,blt=6
	assign signals[15] = h[1]|h[3];//|h[4];//jal, jr, j - omit jr
	
	//set write register to $r31 if instr. is jal
	TRI writeReg00(.in(I[22]), .out(signals[16]), .oe(~h[3])); 
	TRI writeReg01(.in('b1), .out(signals[16]), .oe(h[3]));	
	TRI writeReg10(.in(I[23]), .out(signals[17]), .oe(~h[3])); 
	TRI writeReg11(.in('b1), .out(signals[17]), .oe(h[3]));	
	TRI writeReg20(.in(I[24]), .out(signals[18]), .oe(~h[3])); 
	TRI writeReg21(.in('b1), .out(signals[18]), .oe(h[3]));	
	TRI writeReg30(.in(I[25]), .out(signals[19]), .oe(~h[3])); 
	TRI writeReg31(.in('b1), .out(signals[19]), .oe(h[3]));	
	TRI writeReg40(.in(I[26]), .out(signals[20]), .oe(~h[3])); 
	TRI writeReg41(.in('b1), .out(signals[20]), .oe(h[3]));
	assign signals[21] = h[4];//jr
	assign signals[22] = ~h[0];//only with regular ALU ops do we use $rt
	assign signals[23] = 1'b1; //signal is/is not a NOP
	assign signals[24] = signals[25]|h[7];//insn. that don't use M stage
	assign signals[25] = (h[0]&(op[6]|op[7]))&h[1]|h[2]|h[4]|h[22]|h[6];//insn that don't use W stage
	assign signals[26] = h[21];//setx
endmodule