module skeleton(	CLOCK_50, CLOCK2_50, reset, ps2_clock, ps2_data, debug_word, debug_addr, leds, 
					lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon, 	
					HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7, HEX8,
					LEDG,//but_left1,but_right1, but_left2, but_right2,
					VGA_B, VGA_BLANK_N, VGA_CLK, VGA_G, VGA_R, VGA_HS, VGA_VS, VGA_SYNC_N, KEY);

//////////// CLOCK //////////
	input		          		CLOCK_50;
	input		          		CLOCK2_50;
	input [3:0] KEY;
	input 			 reset;
	inout 			ps2_data, ps2_clock;
	wire 			but_left1,but_right1, but_left2, but_right2;
	assign but_left1 = KEY[3];
	assign but_right1 = KEY[2];
	assign but_left2 = KEY[1];
	assign but_right2 = KEY[0];
	output 			lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon;
	output 	[7:0] 	leds, lcd_data,LEDG,LEDR0;
	output 	[6:0] 	HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7, HEX8;
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
	
	wire resetn;
	assign resetn = 1'b0;
	
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
	assign VGA_CLK = VGA_CTRL_CLK;
	wire [3:0] paint_val_play;
	wire [3:0] paint_val_wall;
	wire [11:0] player_pos_paint;
	wire [11:0] new_wall_pos_paint;
	wire super_enable;
	wire [18:0] debug_vga_addr;
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
                      .wraddress_gridData(player_pos_paint),
                      .debug_vga_addr(debug_vga_addr));
					
	
	
	// clock divider (by 5, i.e., 10 MHz)
	//pll div(inclock,clock);
	
	// UNCOMMENT FOLLOWING LINE AND COMMENT ABOVE LINE TO RUN AT 50 MHz
	//assign clock = CLOCK_50;
	assign clock = VGA_CTRL_CLK;
	
	// your processor
	wire [3:0] play_1_x_debug;
	wire [3:0] play_1_y_debug;
	wire [3:0] play_2_x_debug;
	wire [3:0] play_2_y_debug;
	processor myprocessor(clock, resetn, ps2_key_pressed, ps2_out, lcd_write_en, lcd_write_data, debug_word, debug_addr
	 ,but_left1,but_right1, but_left2, but_right2,paint_val_play,paint_val_wall,player_pos_paint,new_wall_pos_paint,super_enable
	 ,play_1_x_debug, play_1_y_debug, play_2_x_debug, play_2_y_debug);


	
	// keyboard controller
	PS2_Interface myps2(clock, resetn, ps2_clock, ps2_data, ps2_key_data, ps2_key_pressed, ps2_out);
	
	// lcd controller
	lcd mylcd(clock, ~resetn, lcd_write_en, lcd_write_data[7:0], lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon);
	
	// example for sending ps2 data to the first two seven segment displays
	//Hexadecimal_To_Seven_Segment hex1(ps2_out[3:0], seg1);
	//Hexadecimal_To_Seven_Segment hex2(ps2_out[7:4], seg2);
	
	Hexadecimal_To_Seven_Segment hex1(play_1_x_debug, HEX0);
	Hexadecimal_To_Seven_Segment hex2(play_1_y_debug, HEX1);
	// the other seven segment displays are currently set to 0
	Hexadecimal_To_Seven_Segment hex3(play_2_x_debug, HEX2);
	Hexadecimal_To_Seven_Segment hex4(play_2_y_debug, HEX3);
	Hexadecimal_To_Seven_Segment hex5(4'b0, seg5);
	Hexadecimal_To_Seven_Segment hex6(4'b0, seg6);
	Hexadecimal_To_Seven_Segment hex7(4'b0, seg7);
	Hexadecimal_To_Seven_Segment hex8(4'b0, seg8);
	
	// some LEDs that you could use for debugging if you wanted
	genvar i;
	generate
	for (i = 0; i < 8; i = i + 1) begin: lcdDebugLoop
	assign LEDG[i] = debug_vga_addr[i+4];
	end
	endgenerate
	
	assign LEDR0 = VGA_CTRL_CLK;
	assign
endmodule
