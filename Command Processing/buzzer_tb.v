module buzzer_tb();

	reg clk,rst_n, Ok2Move, cmd_rdy, ID_vld;
	wire clr_cmd_rdy, clr_ID_vld, go, buzz, buzz_n, in_transit;
	reg [7:0] cmd, ID;
	
	reg [5:0] extra_bits;
	reg [5:0] DEST_ID_CHECK;
	
	
	//Instantiation	
	comProc CP1(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd), .ID_vld(ID_vld),
		.Ok2Move(Ok2Move), .clr_cmd_rdy(clr_cmd_rdy), .go(go), .clr_ID_vld(clr_ID_vld),
		.buzz(buzz), .buzz_n(buzz_n), .in_transit(in_transit), .ID(ID));
		
	//integer i;
	//localparam GO_SIG = {2'b01, ID[5:0]}
	//localparam STOP_cmd = {2'b00,6'hxx};
	localparam ID_value = 6'b11_0101; //random ID value
	
	initial begin
		clk = 1'b0;
		rst_n = 1'b0;
		
		repeat(5)@(posedge clk);
			rst_n = 1'b1;
			
				//Test buzzer
		#20 rst_n = 1'b0;
		#20 rst_n = 1'b1;
		
		#20 Ok2Move = 1'b1;
		#20 ID = {2'b00, ID_value}; //random ID with first 2-bits = 00 (ID valid condition);
		#20 ID_vld = 1'b1;	
		#20 cmd_rdy = 1'b1;
		#20 cmd = {2'b01, ID_value}; //cmd = go signal	
		#20 Ok2Move = 1'b0;
		#10 $display("buzzer enable: %d ", CP1.piezoEn);
		if(CP1.piezoEn != 1'b1)
			$display("ERROR: buzzer not enabled");
		else
			$display("BUZZER enabled - OK");
		
		
	
		
	end
	
	always @(buzz)
		$display("Buzz toggled at time: " , $time);
	
	always
		#1 clk = ~clk;
		
endmodule