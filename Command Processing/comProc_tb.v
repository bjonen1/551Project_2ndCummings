module comProc_tb();

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
			
		//Test !cmd_rdy
			cmd_rdy = 1'b0;
			if(CP1.state != CP1.IDLE)
				$display("ERROR");
			else
				$display("IDLE state Test 1 - PASSED");
		//Test CMD_RDY, cmd != go
			cmd_rdy = 1'b1;
			cmd = {2'b10,6'b11_1111};
			if(CP1.state != CP1.IDLE)
				$display("ERROR");
			else
				$display("IDLE state Test 2 - PASSED");
					
		//Get to: Capture dest_ID
		Ok2Move = 1'b1;
		ID = {2'b00, ID_value}; //random ID with first 2-bits = 00 (ID valid condition);
		ID_vld = 1'b1;	
		cmd_rdy = 1'b1;
		cmd = {2'b01, ID[5:0]}; //cmd = go_signal	
		DEST_ID_CHECK = cmd[5:0];
		#20 if( CP1.dest_ID != DEST_ID_CHECK)
			$display("ERROR: dest_ID incorrect at time: ", $time);
			else if (CP1.set_in_transit != 1'b1)
				$display("ERROR:in_transit not set");
			else if (CP1.set_dest_ID != 1'b1)
				$display("ERROR: dest_ID not set");
			else begin
			$display("TEST: CMD_RDY&CMD=GO - PASSED");
			$display("dest_ID %d == %d cmd[5:0]", CP1.dest_ID, cmd[5:0]); 
			end
		
		//Test cmd == stop path
		#20 cmd = {2'b00, 6'b00_1101}; //stop condition w/ random 6 bits
		#20 if(CP1.in_transit != 1'b0)
				$display("ERROR: in_transit not cleared at time:  " ,$time);
			else begin
				$display("TEST: CMD = STOP - PASSED");
	
		//Get back to Capture dest_ID for next test
		#20 cmd = {2'b01, ID[5:0]}; //cmd = go_signal
		
		//Test cmd != go or stop, ID not valid
		#20 ID_vld = 1'b0;
		#20 cmd = {2'b10, 6'b00_1111}; //random cmd, not go nor stop
		#20 ID_vld = 1'b1;
		/*//#20 if(CP1.state != CP1.ID_VLD)
			//		$display("ERROR: no transition to ID_VLD",$time);
				//else
					//$display("Transition to ID_VLD - OK");	*/
		#26 if(CP1.state != CP1.CMD_RDY)
				$display("ERROR: incorrect state",$time);
			else
				$display("Returned to CMD_RDY - OK");
		
		//Test ID valid, ID != dest_ID **
		#20 ID = {2'b00, 6'b00_0011}; //changed (random) ID value
		#20 ID_vld = 1'b1;
		#20 if(CP1.in_transit != 1'b1)
				$display("ERROR: in_transit cleared in error");
			else begin
				$display("ID = %d", CP1.ID);
				$display("dest_ID = %d", CP1.dest_ID);
				$display("CP1.ID_vld = %d",CP1.ID_vld);
				end
				
		//Test CMD_RDY, CMD != go or stop, ID_valid, ID = dest_ID
		#20 rst_n = 1'b0;
		#20 rst_n = 1'b1;
			//Get to Capture dest_ID for test
		#20 Ok2Move = 1'b1;
		#20 ID = {2'b00, ID_value}; //random ID with first 2-bits = 00 (ID valid condition);
		#20 ID_vld = 1'b1;	
		#20 cmd_rdy = 1'b1;
		#20 cmd = {2'b01, ID_value}; //cmd = go signal	
			//change cmd != go
		#20 cmd = {2'b01,6'b00_1100};
		#10 if(clr_ID_vld != 1'b1) begin
				$display("ERROR: ID_vld not cleared");
				$display("clr_ID_vld = %d", CP1.clr_ID_vld, $time);
				end
			else 
				$display("ID_vld cleared");
				
		#10 if (in_transit != 1'b0) begin
				$display("ERROR: in_transit not cleared", $time);
				$display("clr_in_transit = %d",CP1.clr_in_transit);
				end
			else
				$display("in_transit cleared, Test: PASSED");
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
		
	end
	always
		#5 clk = ~clk;

endmodule