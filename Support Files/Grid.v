module Grid(play_x, play_y, is_play_one, is_play_two, isWinOne, isWinTwo, isCrash, clock, reset
,player_pos_paint, new_wall_pos_paint, paint_val_play, paint_val_wall);
	input [31:0] play_x;
	input [31:0] play_y;
	input is_play_one, is_play_two;
	output isWinOne, isWinTwo, isCrash;
	output [3:0] paint_val_play;
	output [3:0] paint_val_wall;
	output [11:0] player_pos_paint;
	output [11:0] new_wall_pos_paint;
	parameter gridWidth = 64;
	parameter gridHeight = 64;

	wire [gridWidth-1: 0] wall_p1_x;
	wire [gridWidth-1: 0] wall_p2_x;
	wire [gridWidth-1: 0] LOC_p1_x;
	wire [gridWidth-1: 0] LOC_p2_x;
	wire [gridHeight-1: 0] wall_p1_y;
	wire [gridHeight-1: 0] wall_p2_y;
	wire [gridHeight-1: 0] LOC_p1_y;
	wire [gridHeight-1: 0] LOC_p2_y;

	wire [5:0] play_x_rel;
	wire [5:0] play_y_rel;
	wire enable1, enable2;
	wire [63:0] play_1_now_x;
	wire [63:0] play_1_prev_x;
	wire [63:0] play_2_now_x;
	wire [63:0] play_2_prev_x;
	wire [63:0] play_1_now_y;
	wire [63:0] play_1_prev_y;
	wire [63:0] play_2_now_y;
	wire [63:0] play_2_prev_y;

	wire crash_x[gridWidth-1:0];
	wire crash_y[gridHeight-1:0];
	wire vict_xy_1[(gridWidth)*(gridHeight)-1:0];
	wire vict_xy_2[(gridWidth)*(gridHeight)-1:0];
	assign isCrash = (|crash_x)&(|crash_y);
	assign isWinOne = |vict_xy_1;
	assign isWinTwo = |vict_xy_2;

assign paint_val_play[0] = is_play_two;
assign paint_val_play[1] = 1;b0;
assign paint_val_play[2] = 1'b0;
assign paint_val_play[3] = 1;b0;

assign paint_val_wall[0] = is_play_two;
assign paint_val_wall[1] = 1'b1;
assign paint_val_wall[2] = 1'b0;
assign paint_val_wall[3] = 1;b0;

decoder6B decpla_x(.Enc(play_x_rel),.out(play_1_now_x));
decoder6B decpla_y(.Enc(play_y_rel),.out(play_2_now_y));
assign enable1 = is_play_one;
assign enable2 = is_play_two;
genvar x, y;
generate
for (x = 0; x < 6; x = x + 1)begin: multiplierLoop
	assign player_pos_paint[x+6] = play_y_rel[x];
	assign player_pos_paint[x] = play_x_rel[x];
	assign new_wall_pos_paint[x+6] = LOC_p2_y[x]&enable2 | LOC_p1_y[x]&enable1;
	assign new_wall_pos_paint[x] = LOC_p2_x[x]&enable2 | LOC_p1_y[x]&enable1;
end
for(x = 0; x < 6; x = x + 1)begin: selc
	assign play_x_rel[x] = play_x[x];
	assign play_y_rel[x] = play_y[x];
end
for (x = 0; x < gridWidth; x = x + 1)
begin: X
	DFFx df_x_p1_p(.d(play_1_now_x[x]), .q(LOC_p1_x[x]), .clk(clock), .en(enable1),.clrn(reset));
	DFFx df_x_p2_p(.d(play_2_now_x[x]), .q(LOC_p2_x[x]), .clk(clock), .en(enable2),.clrn(reset));
	assign crash_x[x] = LOC_p1_x[x]&LOC_p2_x[x];
end
for (y = 0; y < gridHeight; y = y + 1)
begin: Y
	DFFx df_y_p1_p(.d(play_1_now_y[y]), .q(LOC_p1_y[y]), .clk(clock), .en(enable1),.clrn(reset));
	DFFx df_y_p2_p(.d(play_2_now_y[y]), .q(LOC_p2_y[y]), .clk(clock), .en(enable2),.clrn(reset));
	assign crash_y[y] = LOC_p2_y[y]&LOC_p1_y[y];
end
for (x = 0; x < gridWidth; x = x + i)begin: M
	for (y = 0; y < gridHeight; y  = y + 1)begin: N
		wire isWallOne, isWallTwo;
		wire temp1, temp2;
		temp1 = play_1_prev_y[y]&play_1_prev_x[x];
		temp2 = play_2_prev_y[y]&play_2_prev_x[x];

		DFFx isWallOneMem(.d(temp1), .q(M[x].N[y].isWallOne)
							, .clk(clock), .en((~M[x].N[y].isWallOne)&enable1),.clrn(reset));
		DFFx isWallTwoMem(.d(temp2), .q(M[x].N[y].isWallTwo)
							, .clk(clock), .en((~M[x].N[y].isWallTwo)&enable2),.clrn(reset));

		assign vict_xy_1[x*gridWidth+gridHeight] = temp1&(M[x].N[y].isWallOne|M[x].N[y].isWallTwo)
		assign vict_xy_2[x*gridWidth+gridHeight] = temp2&(M[x].N[y].isWallOne|M[x].N[y].isWallTwo)
	end
end
endgenerate
endmodule
`

module decoder6B(Enc, out);
	input [5:0] Enc;
	output [63:0] out;

wire [5:0] E;
assign E[0] = Enc[5];
assign E[1] = Enc[4];
assign E[2] = Enc[3];
assign E[3] = Enc[2];
assign E[4] = Enc[1];
assign E[5] = Enc[0];
assign out[0] = E[0]&E[1]&E[2]&E[3]&E[4]&E[5];
assign out[1] = E[0]&E[1]&E[2]&E[3]&E[4]&~E[5];
assign out[2] = E[0]&E[1]&E[2]&E[3]&~E[4]&E[5];
assign out[3] = E[0]&E[1]&E[2]&E[3]&~E[4]&~E[5];
assign out[4] = E[0]&E[1]&E[2]&~E[3]&E[4]&E[5];
assign out[5] = E[0]&E[1]&E[2]&~E[3]&E[4]&~E[5];
assign out[6] = E[0]&E[1]&E[2]&~E[3]&~E[4]&E[5];
assign out[7] = E[0]&E[1]&E[2]&~E[3]&~E[4]&~E[5];
assign out[8] = E[0]&E[1]&~E[2]&E[3]&E[4]&E[5];
assign out[9] = E[0]&E[1]&~E[2]&E[3]&E[4]&~E[5];
assign out[10] = E[0]&E[1]&~E[2]&E[3]&~E[4]&E[5];
assign out[11] = E[0]&E[1]&~E[2]&E[3]&~E[4]&~E[5];
assign out[12] = E[0]&E[1]&~E[2]&~E[3]&E[4]&E[5];
assign out[13] = E[0]&E[1]&~E[2]&~E[3]&E[4]&~E[5];
assign out[14] = E[0]&E[1]&~E[2]&~E[3]&~E[4]&E[5];
assign out[15] = E[0]&E[1]&~E[2]&~E[3]&~E[4]&~E[5];
assign out[16] = E[0]&~E[1]&E[2]&E[3]&E[4]&E[5];
assign out[17] = E[0]&~E[1]&E[2]&E[3]&E[4]&~E[5];
assign out[18] = E[0]&~E[1]&E[2]&E[3]&~E[4]&E[5];
assign out[19] = E[0]&~E[1]&E[2]&E[3]&~E[4]&~E[5];
assign out[20] = E[0]&~E[1]&E[2]&~E[3]&E[4]&E[5];
assign out[21] = E[0]&~E[1]&E[2]&~E[3]&E[4]&~E[5];
assign out[22] = E[0]&~E[1]&E[2]&~E[3]&~E[4]&E[5];
assign out[23] = E[0]&~E[1]&E[2]&~E[3]&~E[4]&~E[5];
assign out[24] = E[0]&~E[1]&~E[2]&E[3]&E[4]&E[5];
assign out[25] = E[0]&~E[1]&~E[2]&E[3]&E[4]&~E[5];
assign out[26] = E[0]&~E[1]&~E[2]&E[3]&~E[4]&E[5];
assign out[27] = E[0]&~E[1]&~E[2]&E[3]&~E[4]&~E[5];
assign out[28] = E[0]&~E[1]&~E[2]&~E[3]&E[4]&E[5];
assign out[29] = E[0]&~E[1]&~E[2]&~E[3]&E[4]&~E[5];
assign out[30] = E[0]&~E[1]&~E[2]&~E[3]&~E[4]&E[5];
assign out[31] = E[0]&~E[1]&~E[2]&~E[3]&~E[4]&~E[5];
assign out[32] = ~E[0]&E[1]&E[2]&E[3]&E[4]&E[5];
assign out[33] = ~E[0]&E[1]&E[2]&E[3]&E[4]&~E[5];
assign out[34] = ~E[0]&E[1]&E[2]&E[3]&~E[4]&E[5];
assign out[35] = ~E[0]&E[1]&E[2]&E[3]&~E[4]&~E[5];
assign out[36] = ~E[0]&E[1]&E[2]&~E[3]&E[4]&E[5];
assign out[37] = ~E[0]&E[1]&E[2]&~E[3]&E[4]&~E[5];
assign out[38] = ~E[0]&E[1]&E[2]&~E[3]&~E[4]&E[5];
assign out[39] = ~E[0]&E[1]&E[2]&~E[3]&~E[4]&~E[5];
assign out[40] = ~E[0]&E[1]&~E[2]&E[3]&E[4]&E[5];
assign out[41] = ~E[0]&E[1]&~E[2]&E[3]&E[4]&~E[5];
assign out[42] = ~E[0]&E[1]&~E[2]&E[3]&~E[4]&E[5];
assign out[43] = ~E[0]&E[1]&~E[2]&E[3]&~E[4]&~E[5];
assign out[44] = ~E[0]&E[1]&~E[2]&~E[3]&E[4]&E[5];
assign out[45] = ~E[0]&E[1]&~E[2]&~E[3]&E[4]&~E[5];
assign out[46] = ~E[0]&E[1]&~E[2]&~E[3]&~E[4]&E[5];
assign out[47] = ~E[0]&E[1]&~E[2]&~E[3]&~E[4]&~E[5];
assign out[48] = ~E[0]&~E[1]&E[2]&E[3]&E[4]&E[5];
assign out[49] = ~E[0]&~E[1]&E[2]&E[3]&E[4]&~E[5];
assign out[50] = ~E[0]&~E[1]&E[2]&E[3]&~E[4]&E[5];
assign out[51] = ~E[0]&~E[1]&E[2]&E[3]&~E[4]&~E[5];
assign out[52] = ~E[0]&~E[1]&E[2]&~E[3]&E[4]&E[5];
assign out[53] = ~E[0]&~E[1]&E[2]&~E[3]&E[4]&~E[5];
assign out[54] = ~E[0]&~E[1]&E[2]&~E[3]&~E[4]&E[5];
assign out[55] = ~E[0]&~E[1]&E[2]&~E[3]&~E[4]&~E[5];
assign out[56] = ~E[0]&~E[1]&~E[2]&E[3]&E[4]&E[5];
assign out[57] = ~E[0]&~E[1]&~E[2]&E[3]&E[4]&~E[5];
assign out[58] = ~E[0]&~E[1]&~E[2]&E[3]&~E[4]&E[5];
assign out[59] = ~E[0]&~E[1]&~E[2]&E[3]&~E[4]&~E[5];
assign out[60] = ~E[0]&~E[1]&~E[2]&~E[3]&E[4]&E[5];
assign out[61] = ~E[0]&~E[1]&~E[2]&~E[3]&E[4]&~E[5];
assign out[62] = ~E[0]&~E[1]&~E[2]&~E[3]&~E[4]&E[5];
assign out[63] = ~E[0]&~E[1]&~E[2]&~E[3]&~E[4]&~E[5];
endmodule