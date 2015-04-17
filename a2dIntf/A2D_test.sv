module A2D_test(clk, RST_n, nxt_chnnl, LEDs, a2d_SS_n, MOSI, MISO, SCLK);
	input RST_n, nxt_chnnl, clk, MISO;
	output [7:0] LEDs;
	output MOSI, SCLK, a2d_SS_n;
	wire rst_n;
	wire button_rise_edge;
	wire strt_cnv;
	wire cnv_cmplt;
	wire [11:0] res;

//next_byte_logic
reg next_byte_reg1, next_byte_reg2, next_byte_reg3;
always@(negedge clk or negedge rst_n)begin
	if(~rst_n)
		next_byte_reg1 <= 1'b1;
	else
		next_byte_reg1 <= nxt_chnnl;
end

always@(negedge clk or negedge rst_n)begin
	if(~rst_n)
		next_byte_reg2 <= 1'b1;
	else
		next_byte_reg2 <= next_byte_reg1;
end

always@(negedge clk or negedge rst_n)begin
	if(~rst_n)
		next_byte_reg3 <= 1'b1;
	else
		next_byte_reg3 <= next_byte_reg2;
end

assign button_rise_edge = ((~next_byte_reg3) & next_byte_reg2);


//////RESET LOGIC

reg reset_flop1;
reg reset_flop2;

always @(negedge clk or negedge RST_n) begin
	if (!RST_n)
		reset_flop1 <= 1'b0;
	else
		reset_flop1 <= 1'b1;
end

always @(negedge clk or negedge RST_n) begin
	if (!RST_n)
		reset_flop2 <= 1'b0;
	else
		reset_flop2 <= reset_flop1;
end

assign rst_n = reset_flop2;


////DriveA2DLogic
reg [2:0] chnnl;
reg button_rise_to_start_cnv; //need a reg to make the trigger from button rise sync with the channel

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		chnnl <= 3'b000;
	else if (button_rise_edge & (chnnl == 3'b110))
		chnnl <= 3'b000;
	else if (button_rise_edge)
		chnnl <= chnnl + 1;
	else
		chnnl <= chnnl;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		button_rise_to_start_cnv <= 1'b0;
	else
		button_rise_to_start_cnv <= button_rise_edge;
end
assign strt_cnv = button_rise_to_start_cnv;



A2D_intf A2D_one(clk,rst_n,strt_cnv,cnv_cmplt,chnnl,res,a2d_SS_n,SCLK,MOSI,MISO);
assign LEDs = res[11:4];

endmodule
