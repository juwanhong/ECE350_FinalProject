module skeleton(	CLOCK_50, CLOCK2_50, resetn, ps2_clock, ps2_data, debug_word, debug_addr, leds, 
					lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon, 	
					seg1, seg2, seg3, seg4, seg5, seg6, seg7, seg8, but_left1,but_right1, but_left2, but_right2,
					VGA_B, VGA_BLANK_N, VGA_CLK, VGA_G, VGA_R, VGA_HS, VGA_VS, VGA_SYNC_N, KEY);

//////////// CLOCK //////////
	input		          		CLOCK_50;
	input		          		CLOCK2_50;
	input [3:0] KEY;
	input 			 resetn;
	inout 			ps2_data, ps2_clock;
	input 			but_left1,but_right1, but_left2, but_right2;
	
	output 			lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon;
	output 	[7:0] 	leds, lcd_data;
	output 	[6:0] 	seg1, seg2, seg3, seg4, seg5, seg6, seg7, seg8;
	output 	[31:0] 	debug_word;
	output  [11:0]  debug_addr;
	
	output		   [7:0]		VGA_B;
	output		        		VGA_BLANK_N;
	output		        		VGA_CLK;
	output		   [7:0]		VGA_G;
	output	          		VGA_HS;
	output	      [7:0]		VGA_R;
	output	         		VGA_SYNC_N;
	output	          		VGA_VS;
	
	wire			clock;
	wire			lcd_write_en;
	wire 	[31:0]	lcd_write_data;
	wire	[7:0]	ps2_key_data;
	wire			ps2_key_pressed;
	wire	[7:0]	ps2_out;	

	// DE2-115 Default//
	//	Reset Delay Timer
	Reset_Delay			r0	(	.iCLK(CLOCK_50),.oRESET(DLY_RST)	);
	wire DLY_RST, VGA_CTRL_CLK, AUD_CTRL_CLK,mVGA_CLK;
	//assign VGA_CTRL_CLK = CLOCK_50;
	VGA_Audio_PLL 		p1	(	.areset(~DLY_RST),.inclk0(CLOCK2_50),.c0(VGA_CTRL_CLK),.c1(AUD_CTRL_CLK),.c2(mVGA_CLK)	);

	//	VGA Controller
	//assign VGA_BLANK_N = !cDEN;
	wire VGA_CLK;
	wire wren_gridData;
	wire [3:0] data_gridData;
	wire [11:0] wraddress_gridData;
	assign VGA_CLK = VGA_CTRL_CLK;
	vga_controller vga_ins(.KEY0(KEY[0]),.KEY1(KEY[1]),
                      .iRST_n(DLY_RST),
                      .iVGA_CLK(VGA_CTRL_CLK),
                      .oBLANK_n(VGA_BLANK_N),
                      .oHS(VGA_HS),
                      .oVS(VGA_VS),
                      .b_data(VGA_B),
                      .g_data(VGA_G),
                      .r_data(VGA_R),
                      .wren_gridData(super_enable),
                      .data_gridData(paint_val_play),
                      .wraddress_gridData(player_pos_paint));
					
	
	
	// clock divider (by 5, i.e., 10 MHz)
	//pll div(inclock,clock);
	
	// UNCOMMENT FOLLOWING LINE AND COMMENT ABOVE LINE TO RUN AT 50 MHz
	assign clock = CLOCK_50;
	
	// your processor
	processor myprocessor(clock, resetn, ps2_key_pressed, ps2_out, lcd_write_en, lcd_write_data, debug_word, debug_addr
	 ,but_left1,but_right1, but_left2, but_right2, wren_gridData, data_gridData, wradress_gridData,paint_val_play,paint_val_wall,player_pos_paint,new_wall_pos_paint,super_enable);
	wire [3:0] paint_val_play;
	wire [3:0] paint_val_wall;
	wire [11:0] player_pos_paint;
	wire [11:0] new_wall_pos_paint;
	wire super_enable;
	
	// keyboard controller
	PS2_Interface myps2(clock, resetn, ps2_clock, ps2_data, ps2_key_data, ps2_key_pressed, ps2_out);
	
	// lcd controller
	lcd mylcd(clock, ~resetn, lcd_write_en, lcd_write_data[7:0], lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon);
	
	// example for sending ps2 data to the first two seven segment displays
	Hexadecimal_To_Seven_Segment hex1(ps2_out[3:0], seg1);
	Hexadecimal_To_Seven_Segment hex2(ps2_out[7:4], seg2);
	
	// the other seven segment displays are currently set to 0
	Hexadecimal_To_Seven_Segment hex3(4'b0, seg3);
	Hexadecimal_To_Seven_Segment hex4(4'b0, seg4);
	Hexadecimal_To_Seven_Segment hex5(4'b0, seg5);
	Hexadecimal_To_Seven_Segment hex6(4'b0, seg6);
	Hexadecimal_To_Seven_Segment hex7(4'b0, seg7);
	Hexadecimal_To_Seven_Segment hex8(4'b0, seg8);
	
	// some LEDs that you could use for debugging if you wanted
	assign leds = 8'b00101011;
	
endmodule
