module regFile (clock, ctrl_writeEnable, ctrl_reset, ctrl_writeReg, ctrl_readRegA, ctrl_readRegB, data_writeReg, data_readRegA, data_readRegB);
	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg;
	input [4:0] ctrl_readRegA; 
	input [4:0] ctrl_readRegB;
	input [31:0] data_writeReg;
	output [31:0] data_readRegA;
	output [31:0] data_readRegB;
	//control local vars
	wire [31:0] oneHotW;
	wire [31:0] oneHotRA;
	wire [31:0] oneHotRB;
	
	decoder5B decW(ctrl_writeReg, oneHotW);
	decoder5B decRA(ctrl_readRegA, oneHotRA);
	decoder5B decRB(ctrl_readRegB, oneHotRB);

	genvar i;
	generate
		for (i = 1; i < 32 ; i = i + 1) begin: loop1
			wire [31:0] myW;
			register32B my_reg(.clock(clock)
								,.wrE(ctrl_writeEnable & oneHotW[i])
								,.din(data_writeReg)
								,.rs(ctrl_reset)
								,.dout(myW));
			tri_set tri_a(.inp(myW), .outp(data_readRegA), .en(oneHotRA[i]));
			tri_set tri_b(.inp(myW), .outp(data_readRegB), .en(oneHotRB[i]));
		end 
	endgenerate
	wire [31:0] myWx;
	register32B my_reg0(.clock(clock),.wrE('b0), .din(data_writeReg), .rs('b1), .dout(myWx));			
	tri_set tri_a(.inp(myWx), .outp(data_readRegA), .en(oneHotRA[0]));
	tri_set tri_b(.inp(myWx), .outp(data_readRegB), .en(oneHotRB[0]));
			
endmodule


module register32B (wrE, din, rs, dout, clock);
	input wrE, rs, clock;
	input [31:0] din;
	output [31:0] dout;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop1
			DFFx a_dff(.d(din[i]), .clk(clock), .q(dout[i]), .clrn(rs), .en(wrE));
		end
	endgenerate
endmodule

module tri_set(inp, en, outp);
	input [31:0] inp, en;
	output [31:0] outp;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop1
			TRI a_tri(.in(inp[i]), .out(outp[i]), .oe(en));
		end
	endgenerate
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
