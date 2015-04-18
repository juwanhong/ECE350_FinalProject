module Grid(enable, player, in_x, in_y, clockWall_x, Wall_y, isCollision, walls, clock, reset);
	parameter gridWidth = 8;
	parameter gridHeight = 8;
	input clock, enable, reset;
	input player;
	input [gridWidth-1:0] in_x;
	input [gridHeight-1:0] in_y;
	output [gridWidth-1:0] Wall_x;
	output [gridHeight-1:0] Wall_y;
	output [gridWidth*gridHeight-1:0] walls;

assign walls = |isCrash;
wire [gridWidth*gridHeight-1:0] isCrash; // 8*x+y'th position says crash occurred at that position
genvar i, j;
generate
for (i = 0; i < gridWidth; i = i + 1)begin: X
wire [gridHeight-1:0] currX;

for (j = 0; j < gridHeight; j = j + 1)begin: Y
	wire [1:0] twall;
	pixel pix(.in(),.clock(clock), .enable(in_x[i]&in_y[j]&enable) ,.player(player),.crash(isCrash[8*i+j]), .isWall(twall));
	assign currx[j] = twall;
	assign isCrash[8*i+j] = twall;
end
assign Wall_x[i] = |currx;
end

for (i = 0; i < gridHeight; i = i + 1)begin: ctrl
wire [gridWidth-1:0] currY;
for (j = 0; j < gridWidth; j = j + 1)begin ctrl2
end
	assign currY[j] = X[j].Y[i].twall;
end
	assign Wall_y[i] = |currY[i];
endgenerate
endmodule


module pixel(in, enable, control, inplayer, crash, isWall, reset, clock);
	input in, inplayer, enable, reset, clock;
	input control;
	output crash, isWall;
	
	assign crash = inplayer&isWall;
	wire currplay, currwall;
	DFFx player(.d(inplayer), .q(currplay), .clk(clock), .en(enable),.clrn(reset));
	DFFx wall(.d(), .q(isWall), .clk(~clock), .en(enable),.clrn(reset));//is wall
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