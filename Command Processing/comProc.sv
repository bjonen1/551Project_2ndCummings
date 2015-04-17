module comProc(clk, rst_n, cmd_rdy, cmd, ID_vld, ID, Ok2Move, clr_cmd_rdy, go, clr_ID_vld, buzz, buzz_n, prox_en);
	input clk, rst_n, cmd_rdy, ID_vld, Ok2Move;
	input [7:0] cmd, ID;
	
	output reg clr_cmd_rdy, clr_ID_vld, go, buzz, buzz_n, prox_en;
	
	reg in_transit;
	reg [5:0] dest_ID;
	
	logic set_in_transit, clr_in_transit, set_dest_ID, piezoEn;
	
	typedef enum reg [3:0] {WAITRDY1, CHKGO1, WAITRDY2, CHKGO2, CHKIDVLD, CHKID} state_t;
	state_t state, nxt_state;
	
	//in_transit flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			in_transit <= 1'b0;
		else if(set_in_transit)
			in_transit <= 1'b1;
		else if(clr_in_transit)
			in_transit <= 1'b0;
			
	//go and buzzer logic
	assign go = in_transit & Ok2Move;
	assign piezoEn = in_transit & ~Ok2Move;
	assign prox_en = in_transit;
	
	//dest_ID flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			dest_ID <= 6'h00;
		else if(set_dest_ID)
			dest_ID <= cmd[5:0];
			
	//state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= WAITRDY1;
		else
			state <= nxt_state;
			
	//next state and output logic
	always_comb begin
		clr_cmd_rdy = 1'b0;
		clr_ID_vld = 1'b0;
		set_in_transit = 1'b0;
		clr_in_transit = 1'b0;
		set_dest_ID = 1'b0;
		nxt_state = WAITRDY1;
		
		case(state)
			WAITRDY1:
				if(cmd_rdy)
					nxt_state = CHKGO1;
			CHKGO1:
				if(cmd[7:6] == 2'b01) begin
					set_in_transit = 1'b1;
					set_dest_ID = 1'b1;
					nxt_state = WAITRDY2;
				end
			WAITRDY2:
				if(cmd_rdy)
					nxt_state = CHKGO2;
				else
					nxt_state = CHKIDVLD;
			CHKGO2:
				if(cmd[7:6] == 2'b01) begin
					set_in_transit = 1'b1;
					set_dest_ID = 1'b1;
					nxt_state = WAITRDY2;
				end
				else
					clr_in_transit = 1'b1;
			CHKIDVLD: 
				if(ID_vld) begin
					clr_ID_vld = 1'b1;
					nxt_state = CHKID;
				end
				else
					nxt_state = WAITRDY2;
			default: //CHKID
				if(ID == dest_ID)
					clr_in_transit = 1'b1;
		endcase
	end
endmodule