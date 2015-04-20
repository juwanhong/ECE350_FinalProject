module vga_controller(KEY0,KEY1,
					  iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data,
                      wren_gridData,
                      data_gridData,
                      wraddress_gridData,
                      debug_vga_addr);


//parameter width = 640;
//parameter height = 640;
input KEY0,KEY1;
input iRST_n;
input iVGA_CLK;
input wren_gridData;
input [3:0] data_gridData;
input [11:0] wraddress_gridData;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
reg [7:0] g_datai;
reg [7:0] b_datai;
reg [7:0] r_datai;
output [7:0] g_data;
output [7:0] r_data;                        
///////// ////                     
reg [18:0] ADDR;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n,cHS,cVS,rst;
////
assign rst = ~iRST_n;
output [18:0] debug_vga_addr;
assign debug_vga_addr = ADDR;

video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS));
////
////Addresss generator
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
     ADDR<=19'd0;
  else if (cHS==1'b0 && cVS==1'b0)
     ADDR<=19'd0;
  else if (cBLANK_n==1'b1)
     ADDR<=ADDR+1;
end

/////////////////ADDR Processing for GridData//////////
wire [18:0] GridDataReadAddress;
assign GridDataReadAddress = (ADDR/6400)*64+((ADDR%6400)%640)/10;
////////////////GridData///////////////////
wire [3:0] color_ADDR;
GridData AccessGrid(.aclr(1'b0),.clock(iVGA_CLK),.data(data_GridData),.rdaddress(GridDataReadAddress[11:0]),.wraddress(wraddress_gridData),.wren(wren_GridData),.q(color_ADDR));
///////////////ColorData/////////////
wire[31:0] Color_raw;
ColorData AccessColor(.address({{1'b0},color_ADDR}),.clock(iVGA_CLK),.q(Color_raw));
assign b_data = Color_raw[23:16];
assign g_data = Color_raw[15:8];
assign r_data = Color_raw[7:0];


//////////////////////////
//////INDEX addr.
assign VGA_CLK_n = ~iVGA_CLK;
//img_data	img_data_inst (
//	.address ( ADDR ),
//	.clock ( VGA_CLK_n ),
//	.q ( index )
//	);
//////Color table output
//img_index	img_index_inst (
//	.address ( index ),
//	.clock ( iVGA_CLK ),
//	.q ( bgr_data_raw)
//	);	
//	assign bgr_data_raw = {24{1'b0}};
	
//////
//////latch valid data at falling edge;
//always@(posedge VGA_CLK_n) bgr_data <= bgr_data_raw;
//assign b_data = bgr_data[23:16];
//assign g_data = bgr_data[15:8];
//assign r_data = bgr_data[7:0];

//reg a, b;
//always@(posedge VGA_CLK_n) a<=b+1;
//register reg_counter(VGA_CLK_n, 0,0,a,b);

//always@(posedge VGA_CLK_n)
//begin
//	//reg rem = ADDR%640;
//	//reg quot = ADDR/640;
//	//if (10*x0+640*(y0+y) <= ADDR && ADDR < 10*(x0+1)-1 + 640*(y0+y))
//		if (ADDR%640 >= 10*x0 && ADDR%640 < 10*x0+10 && ADDR/640 >= 10*y0 && ADDR/640 < 10*(y0+1))
//			begin
//			 g_datai<=8'b00000000;
//			 b_datai<=8'b00000000;
//			 r_datai<=8'b11111111;
//			end
//		  else begin
//			g_datai<=8'b00000000;
//			b_datai<=8'b00000000;
//			r_datai<=8'b00000000;
//		end
//	end
//assign g_data=g_datai;
//assign b_data=b_datai;
//assign r_data=r_datai;

///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
always@(negedge iVGA_CLK)
begin
  oHS<=cHS;
  oVS<=cVS;
  oBLANK_n<=cBLANK_n;
end
//register reg_a(VGA_CLK_n, 0, 0, g_datai, g_dataii);
//wire [7:0] g_dataii;
//assign g_dataii=g_datai+1;
endmodule
 	

module register(clock, ctrl_writeEnable, ctrl_reset, data_writeReg, data_readReg); //register should work
	input clock, ctrl_writeEnable, ctrl_reset;
	input [31:0] data_writeReg;
    output [31:0] data_readReg;
    wire clrn;
    wire [31:0] en_d;
    
    not (clrn,ctrl_reset);
    twomuxthirtytwo enablemux(.x0(data_writeReg),.x1(data_readReg),.s(ctrl_writeEnable),.f(en_d));
    
    genvar c;
    generate
		for (c=0;c<=31;c=c+1) begin: loop2
			DFF a_dff(.d(en_d[c]), .clk(clock), .q(data_readReg[c]), .clrn(clrn));
		end
	endgenerate
endmodule

module twomux(x0,x1,s,f); //twomux works
	input x0;
	input x1;
	input s;
	output f;
	wire w1,w2,w3;
	and (w1,x1,s);
	and (w2,x0,w3);
	not (w3,s);
	or (f,w1,w2);
endmodule

module twomuxthirtytwo(x0,x1,s,f); //twomuxthirtytwo works
	input [31:0] x0;
	input [31:0] x1;
	input s;
	output [31:0] f;
	genvar c;
	generate
		for (c=0;c<=31;c=c+1) begin: loop5
			twomux a_twomux(x0[c],x1[c],s,f[c]);
		end
	endgenerate
endmodule















