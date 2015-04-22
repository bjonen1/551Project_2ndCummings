module comProc(clk, rst_n, cmd_rdy, cmd, ID_vld, ID, Ok2Move, clr_cmd_rdy, go, clr_ID_vld, buzz, buzz_n, prox_en);
	input clk, rst_n, cmd_rdy, ID_vld, Ok2Move;
	input [7:0] cmd, ID;
	
	output reg clr_cmd_rdy, clr_ID_vld, go, buzz, buzz_n, prox_en;
	
	reg in_transit;
	reg [5:0] dest_ID;
	
	logic set_in_transit, clr_in_transit, set_dest_ID, piezoEn;
	
	typedef enum reg [2:0] {IDLE, CMD_RDY, ID_VLD} state_t;
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
			state <= IDLE;
		else
			state <= nxt_state;
			
	//next state and output logic
	always_comb begin
		clr_cmd_rdy = 1'b0;
		clr_ID_vld = 1'b0;
		set_in_transit = 1'b0;
		clr_in_transit = 1'b0;
		set_dest_ID = 1'b0;
		nxt_state = IDLE;
		
		case(state)
			IDLE:
				if(cmd == go && cmd_rdy) begin
					set_in_transit = 1'b1;
					set_dest_ID = 1'b1;
				end
			CMD_RDY:
				if(!cmd_rdy)
					nxt_state = ID_VLD;
				else if(cmd != go && cmd != stop)
					nxt_state = ID_VLD;
				else if(cmd == go) begin
					set_in_transit = 1'b1;
					set_dest_ID = 1'b1;
					nxt_state = CMD_RDY;
				end
				else //cmd == stop
					clr_in_transit = 1'b1;
			default:
				if(~ID_vld)
					nxt_state = CMD_RDY;
				else if(ID != dest_ID)begin
					clr_ID_vld = 1'b1;
					nxt_state = CMD_RDY;
				end					
				else begin //ID==dest_ID
					clr_ID_vld = 1'b1;
					clr_in_transit = 1'b1;
				end
		endcase
	end
endmodule