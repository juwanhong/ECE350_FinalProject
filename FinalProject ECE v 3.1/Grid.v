module Grid(play_x, play_y, play_num, exc_out, clock, reset, super_enable
,player_pos_paint, new_wall_pos_paint, paint_val_play, paint_val_wall,super_enable_out);
	input [31:0] play_x;
	input [31:0] play_y;
	input play_num;
	input clock, reset, super_enable;
	output [31:0] exc_out;
	output super_enable_out;
	output [3:0] paint_val_play;
	output [3:0] paint_val_wall;
	output [11:0] player_pos_paint;
	output [11:0] new_wall_pos_paint;
	parameter gridWidth = 64;
	parameter gridHeight = 64;

	wire is_play_one, is_play_two;
	assign is_play_one = ~play_num;
	assign is_play_two = play_num;
	
	assign exc_out[0] = isCrash | isWinOne | isWinTwo;
	assign exc_out[1] = isWinOne;
	assign exc_out[2] = isWinOne | isWinTwo;
	assign exc_out[3] = 1'b0;
	assign exc_out[4] = isCrash;
	
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

	wire [gridWidth-1:0] crash_x;
	wire [gridHeight-1:0] crash_y;
	wire [(gridWidth)*(gridHeight)-1:0] vict_xy_1;
	wire [(gridWidth)*(gridHeight)-1:0] vict_xy_2;
	assign isCrash = (|crash_x)&(|crash_y);
	assign isWinOne = |vict_xy_1;
	assign isWinTwo = |vict_xy_2;

assign paint_val_play[0] = is_play_two;
assign paint_val_play[1] = 1'b0;
assign paint_val_play[2] = 1'b0;
assign paint_val_play[3] = 1'b0;

assign paint_val_wall[0] = is_play_two;
assign paint_val_wall[1] = 1'b1;
assign paint_val_wall[2] = 1'b0;
assign paint_val_wall[3] = 1'b0;

///// super-enable dff////////
DFFx df_super_enble(.d(super_enable), .q(super_enable_out), .clk(clock), .en(1'b1),.clrn(reset));

decoder6B decpla_x(.Enc(play_x_rel),.out(play_1_now_x));
decoder6B decpla_y(.Enc(play_y_rel),.out(play_2_now_y));
assign enable1 = is_play_one&super_enable;
assign enable2 = is_play_two&super_enable;
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
for (x = 0; x < gridWidth; x = x + 1)begin: M
	for (y = 0; y < gridHeight; y  = y + 1)begin: N
		wire isWallOne, isWallTwo;
		wire temp1, temp2;
		assign temp1 = play_1_now_y[y]&play_1_now_x[x];
		assign temp2 = play_2_now_y[y]&play_2_now_x[x];

		DFFx isWallOneMem(.d(temp1), .q(M[x].N[y].isWallOne)
							, .clk(clock), .en((~M[x].N[y].isWallOne)&enable1),.clrn(reset));
		DFFx isWallTwoMem(.d(temp2), .q(M[x].N[y].isWallTwo)
							, .clk(clock), .en((~M[x].N[y].isWallTwo)&enable2),.clrn(reset));

		assign vict_xy_1[x+y*gridWidth] = temp1&(M[x].N[y].isWallOne|M[x].N[y].isWallTwo);
		assign vict_xy_2[x+y*gridWidth] = temp2&(M[x].N[y].isWallOne|M[x].N[y].isWallTwo);
	end
end
endgenerate
endmodule