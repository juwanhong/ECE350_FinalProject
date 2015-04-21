module Grid(play_x, play_y, play_num, exc_out, clock, reset, super_enable
,player_grid_position, player_color_val,super_enable_out);
	input [31:0] play_x;
	input [31:0] play_y;
	input play_num;
	input clock, reset, super_enable;
	output [31:0] exc_out;
	output super_enable_out;
	output [3:0] player_color_val;
	output [11:0] player_grid_position;	

assign enable1 = is_play_one&super_enable&(~party_is_over);
assign enable2 = is_play_two&super_enable&(~party_is_over);
	wire is_play_one, is_play_two, play_num_t;
	wire [11:0] grid_address;
	wire [11:0] lagged_address;
	wire isCrash, write_Enable;
genvar j;
generate
	for (j = 0; j < 6; j = j + 1)begin: getaddr
		assign grid_address[j] = play_x[j];
		assign grid_address[j+6] = play_y[j];
		DFFx buffer_addr0(.d(play_x[j]), .q(lagged_address[j]), .clk(clock), .en(~party_is_over),.clrn(reset));
		DFFx buffer_addr1(.d(play_y[j]), .q(lagged_address[j+6]), .clk(clock), .en(~party_is_over),.clrn(reset));
		assign player_grid_position[j] = lagged_address[j];
		assign player_grid_position[j+6] = lagged_address[j+6];
	end
		DFFx buffer_(.d(play_num), .q(play_num_t), .clk(clock), .en(~party_is_over),.clrn(reset));
		DFFx df_super_enble(.d(super_enable), .q(super_enable_out), .clk(clock), .en(~party_is_over),.clrn(reset));
		DFFx buffer_crash(.d(isGameOver), .q(disab), .clk(clock), .en(~party_is_over),.clrn(reset));
	DFFx haltGame(.d(isWinOne | isWinTwo), .q(party_is_over), .clk(clock), .en(~party_is_over),.clrn(reset));
endgenerate

memoryGrid memGridCPU(
	.aclr(reset),
	.clock(clock),
	.data(~disab),
	.enable(~party_is_over),
	.rdaddress(grid_address),
	.rden(super_enable),
	.wraddress(lagged_address),
	.wren(~disab),
	.q(isGameOver));

	assign is_play_one = ~play_num_t;
	assign is_play_two = play_num_t;
	assign isWinOne = isGameOver&is_play_two;
	assign isWinTwo = isGameOver&is_play_one;
	
	assign exc_out[0] =  isWinOne | isWinTwo;
	assign exc_out[1] = isWinOne;
	assign exc_out[2] = isWinOne | isWinTwo;
	assign exc_out[3] = 1'b0;
	assign exc_out[4] = 1'b0;


wire party_is_over;

assign player_color_val[0] = is_play_one;
assign player_color_val[1] = is_play_two;
assign player_color_val[2] = 1'b0;
assign player_color_val[3] = 1'b0;

endmodule
