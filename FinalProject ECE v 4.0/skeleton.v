module skeleton(	inclock, resetn, ps2_clock, ps2_data, //debug_word, debug_addr,//, leds, 
					//lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon, 	
					//HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
					//LEDG,LEDR,LCD_DATA,LCD_EN,CLOCK_50, CLOCK2_50,
					//VGA_B, VGA_BLANK_N, VGA_CLK, VGA_G, VGA_R, VGA_HS, VGA_VS, VGA_SYNC_N, KEY
					test1, test2,test3,test4,test5,test6,test7,test8, test9, PC_F, reg31_debug, ex_Reg, regWriteData_W
					,instr_F, instr_D, instr_X, instr_M, instr_W);

//////////// CLOCK //////////
	input inclock, resetn;
	wire		          		CLOCK_50;
	wire		          		CLOCK2_50;
	//input [3:0] KEY;
	inout 			ps2_data, ps2_clock;
	wire 			but_left1,but_right1, but_left2, but_right2;
	//assign but_left1 = ~KEY[3];
	//assign but_right1 = ~KEY[2];
	//assign but_left2 = ~KEY[1];
	//assign but_right2 = ~KEY[0];
//	wire [7:0] LCD_DATA;
//	wire 			lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon;
//	wire 	[7:0] 	leds, lcd_data,LEDG,LEDR;
//	wire 	[6:0] 	HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
//	wire LCD_EN;
//	//assign LCD_EN = 1'b1;
//	wire		   [7:0]		VGA_B;
//	wire		        		VGA_BLANK_N;
//	wire		        		VGA_CLK;
//	wire		   [7:0]		VGA_G;
//	wire	          		VGA_HS;
//	wire	      [7:0]		VGA_R;
//	wire	         		VGA_SYNC_N;
//	wire	          		VGA_VS;	
	output [7:0] test1;
	output [15:0] test2;
	output [15:0] test3;
	output [15:0] test4;
	output [15:0] test5;
	output [7:0] test6;
	output [31:0] test7;
	output [31:0] test8;
	output [31:0] test9;
	output [31:0] instr_F;
	output [31:0] instr_D;
	output [31:0] instr_X;
	output [31:0] instr_M;
	output [31:0] instr_W;
	//wire resetn = ~reset;
	
	wire 	[31:0] 	debug_word;	
	//output 	[31:0] 	debug_word;
	wire  [11:0]  debug_addr;
	//output  [11:0]  debug_addr;
	output [31:0] reg31_debug;
	output [31:0] regWriteData_W;

	wire [7:0] LCD_DATA;
	wire 			lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon;
	wire 	[7:0] 	leds, lcd_data,LEDG,LEDR;
	wire 	[6:0] 	HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	wire LCD_EN;
	//assign LCD_EN = 1'b1;
	wire		   [7:0]		VGA_B;
	wire		        		VGA_BLANK_N;
	wire		        		VGA_CLK;
	wire		   [7:0]		VGA_G;
	wire	          		VGA_HS;
	wire	      [7:0]		VGA_R;
	wire	         		VGA_SYNC_N;
	wire	          		VGA_VS;
	
	wire reset;
	assign reset = resetn;
	
	wire			clock;
	wire			lcd_write_en;
	wire 	[31:0]	lcd_write_data;
	wire	[7:0]	ps2_key_data;
	wire			ps2_key_pressed;
	wire	[7:0]	ps2_out;	

	wire [3:0] red, green, blue;

// generate 100 Hz from 50 MHz
reg [31:0] count_reg = 0;
reg out_100hz = 0;

//always @(posedge CLOCK_50) begin
//            if (count_reg < 5000000) begin
//            count_reg <= count_reg + 1;
//        end else begin
//            count_reg <= 0;
//            out_100hz <= ~out_100hz;
//     end
//end
	// DE2-115 Default//
	//	Reset Delay Timer
	//Reset_Delay			r0	(	.iCLK(CLOCK_50),.oRESET(DLY_RST)	);
	wire DLY_RST, VGA_CTRL_CLK, AUD_CTRL_CLK,mVGA_CLK;
	//assign VGA_CTRL_CLK = CLOCK_50;
	//VGA_Audio_PLL 		p1	(	.areset(~DLY_RST),.inclk0(CLOCK2_50),.c0(VGA_CTRL_CLK),.c1(AUD_CTRL_CLK),.c2(mVGA_CLK)	);

	//	VGA Controller
	//assign VGA_BLANK_N = !cDEN;
	//wire VGA_CLK;
	assign VGA_CLK = VGA_CTRL_CLK;
	wire [3:0] paint_val_play;
	wire [3:0] paint_val_wall;
	wire [11:0] player_pos_paint;
	wire [11:0] new_wall_pos_paint;
	wire super_enable;
	wire [18:0] debug_vga_addr;
	wire [3:0] color_data_debug;
//	vga_controller vga_ins(.KEY0(KEY[0]),.KEY1(KEY[1]),
//                      .iRST_n(DLY_RST),
//                      .iVGA_CLK(VGA_CTRL_CLK),
//                      .oBLANK_n(VGA_BLANK_N),
//                      .oHS(VGA_HS),
//                      .oVS(VGA_VS),
//                      .b_data(VGA_B),
//                      .g_data(VGA_G),
//                      .r_data(VGA_R),
//                      .wren_gridData(super_enable),
//                      .data_gridData(paint_val_play),
//                      .wraddress_gridData(player_pos_paint),
//                      .debug_vga_addr(debug_vga_addr),
//                      .color_data(color_data_debug),
//                      .color_data_in(blue));
					
	
	
	// clock divider (by 5, i.e., 10 MHz)
	//pll div(inclock,clock);
	
	// UNCOMMENT FOLLOWING LINE AND COMMENT ABOVE LINE TO RUN AT 50 MHz
	assign clock = inclock;
	
	// UNCOMMENT FOLLOWING LINE AND COMMENT ABOVE LINE TO RUN AT 50 MHz
	//assign clock = CLOCK_50;
	//assign clock = VGA_CTRL_CLK;
	//assign clock = out_100hz;
	
	// your processor
	wire [3:0] play_1_x_debug;
	wire [3:0] play_1_y_debug;
	wire [3:0] play_2_x_debug;
	wire [3:0] play_2_y_debug;
	output [31:0] ex_Reg;
	output [31:0] PC_F;
	//wire [3:0] regWriteData_W;
	processor myprocessor(.clock(clock), .reset(reset), .ps2_key_pressed(ps2_key_pressed),
		.ps2_out(ps2_out), .debug_data(debug_word), .debug_addr(debug_addr),.but_left1(but_left1)
		,.but_right1(but_right1),.but_left2(but_left2),.but_right2(but_right2),.paint_val_play(paint_val_play)
		,.paint_val_wall(paint_val_wall),.player_pos_paint(player_pos_paint),.new_wall_pos_paint(new_wall_pos_paint)
		,.super_enable(super_enable),.play_1_x_debug(play_1_x_debug),.play_1_y_debug(play_1_y_debug)
		,.play_2_x_debug(play_2_x_debug),.play_2_y_debug(play_2_y_debug), .ex_Reg(ex_Reg),.PC_F(PC_F)
		,.reg31_debug(reg31_debug), .regWriteData_W(regWriteData_W)
		,.test1(test1),.test2(test2),.test3(test3),.test4(test4),.test5(test5)
		,.test6(test6),.test7(test7),.test8(test8),.test9(test9)
		,.instr_F(instr_F),.instr_D(instr_D),.instr_X(instr_X),.instr_M(instr_M),.instr_W(instr_W));

	wire [3:0] reg31_debug;
	
	// keyboard controller
	//PS2_Interface myps2(clock, resetn, ps2_clock, ps2_data, ps2_key_data, ps2_key_pressed, ps2_out);
	
	// lcd controller
	//lcd mylcd(clock, ~resetn, 1'b1, , LCD_DATA, lcd_rw, LCD_EN, lcd_rs, lcd_on, lcd_blon);
	
	//example for sending ps2 data to the first two seven segment displays
	//Hexadecimal_To_Seven_Segment hex1(ps2_out[3:0], seg1);
	//Hexadecimal_To_Seven_Segment hex2(ps2_out[7:4], seg2);
	
	//Hexadecimal_To_Seven_Segment hex1(play_2_x_debug, HEX0);
	//Hexadecimal_To_Seven_Segment hex2(play_1_y_debug, HEX1);
	// the other seven segment displays are currently set to 0
	//Hexadecimal_To_Seven_Segment hex3(red, HEX2);
	//Hexadecimal_To_Seven_Segment hex4(green, HEX3);
	//Hexadecimal_To_Seven_Segment hex5(super_enable, HEX4);
	//Hexadecimal_To_Seven_Segment hex6(reg31_debug, HEX5);
	//Hexadecimal_To_Seven_Segment hex7(regWriteData_W, HEX6);
	//Hexadecimal_To_Seven_Segment hex8(blue, HEX7);
	
	

	// some LEDs that you could use for debugging if you wanted

	genvar i;
	generate
	for (i = 0; i < 4; i = i + 1) begin: lcdDebugLoop
	assign LEDG[i] = debug_vga_addr[i+4];
	//assign LEDG[i+1] = debug_vga_addr[2*i];
	//assign LCD_DATA[i] = play_1_x_debug[i];
	//assign LCD_DATA[i+4] = play_1_y_debug[i];
	//assign red[i] = PC_F[i];
	//assign green[i] = PC_F[i+4];
	//assign green[i] = VGA_G[i];
	//assign blue[i] = VGA_B[i];
	//assign LEDG[i+4] = VGA_R[i];
	//assign LEDR[i] = VGA_G[i];
	//assign LEDR[i+4] = VGA_B[i];
	end
	endgenerate
	
	//assign LEDR[0] = VGA_CTRL_CLK;
	//assign LEDR[1] = CLOCK_50;
endmodule
