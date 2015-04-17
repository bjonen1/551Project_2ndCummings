module barcode_tb();

	reg [21:0] period;
	reg [7:0] station_ID;
	reg send, clk, rst_n, clr_ID_vld;
	
	wire BC,BC_done,ID_vld;
	wire [7:0] ID;
	
	barcode_mimic mimic(.clk(clk),.rst_n(rst_n),.period(period),.send(send),.station_ID(station_ID),.BC_done(BC_done),.BC(BC));
	barcode reader(.clk(clk), .rst_n(rst_n), .BC(BC), .clr_ID_vld(clr_ID_vld), .ID_vld(ID_vld), .ID(ID));
	
	initial begin
		clr_ID_vld = 0;
		clk = 0;
		rst_n = 0;
		period = 22'h4532AF;
		station_ID = 8'h25;
		
		repeat(2)@(negedge clk);
		rst_n = 1;
		
		@(negedge clk);
		send = 1;
		repeat(2)@(negedge clk);
		send = 0;
		
		@(posedge BC_done);
		@(posedge clk);
		if(ID == station_ID && ID_vld)
			$display("It worked");
		else
			$display("It failed");
		
		$stop;
		
	end
	
	always
	#200 clk = ~clk;
endmodule