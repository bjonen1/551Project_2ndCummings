module barcode(clk, rst_n, BC, clr_ID_vld, ID_vld, ID);
	input clk, rst_n, BC, clr_ID_vld;
	output reg ID_vld;
	output reg [7:0] ID;
	
	reg [21:0] startCnt, sampCnt;
	reg [3:0] bitCnt;
	reg BC_filtered, BC1, BC2, BC3, BC4, count_samp;
	
	logic rst_count_start, count_start, rst_samp_cnt, samp_cnt_start, rst_bit_cnt, shift, set_ID_vld;
	
	typedef enum reg[1:0] {IDLE, STARTED, RCV} state_t;
	state_t state, nxt_state;
	
	//filter BC
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			BC4 <= 1'b0;
			BC3 <= 1'b0;
			BC2 <= 1'b0;
			BC1 <= 1'b0;
		end
		else begin
			BC1 <= BC;
			BC2 <= BC1;
			BC3 <= BC2;
			BC4 <= BC3;
		end
	
	//BC_filtered
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			BC_filtered <= 1'b0;
		else if(BC4 & BC3 & BC2)
			BC_filtered <= 1'b1;
		else if(~(BC4 | BC3 | BC2))
			BC_filtered <= 1'b0;
		
	//startCnt
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			startCnt <= 22'h0;
		else if(rst_count_start)
			startCnt <= 22'h0;
		else if(count_start)
			startCnt <= startCnt + 1;
			
	//sampCnt
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			sampCnt <= 22'h0;
		else if (rst_samp_cnt)
			sampCnt <= 22'h0;
		else if(count_samp)
			sampCnt <= sampCnt + 1;
			
	//sampCnt status
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			count_samp <= 1'b0;
		else if(rst_samp_cnt)
			count_samp <= 1'b0;
		else if(samp_cnt_start)
			count_samp <= 1'b1;
			
	//bitCnt
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			bitCnt <= 4'h0;
		else if(rst_bit_cnt)
			bitCnt <= 4'h0;
		else if(shift)
			bitCnt <= bitCnt + 1;
			
	//ID
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			ID <= 8'h00;
		else if(shift)
			ID <= {ID[6:0],BC};
	
	//ID_vld
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			ID_vld <= 1'b0;
		else if(clr_ID_vld)
			ID_vld <= 1'b0;
		else if(set_ID_vld)
			ID_vld <= 1'b1;
			
	//state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	
	//state logic
	always_comb begin
		//set defaults
		nxt_state = IDLE;
		set_ID_vld = 0;
		count_start = 0;
		shift = 0;
		rst_bit_cnt = 0;
		rst_samp_cnt = 0;
		rst_count_start = 0;
		samp_cnt_start = 0;
		
		case(state)
			IDLE:
				if(~BC_filtered) begin
					count_start = 1;
					nxt_state = STARTED;
				end
			STARTED:
				if(BC_filtered) begin
					count_start = 0;
					nxt_state = RCV;
				end
				else begin
					nxt_state = STARTED;
					count_start = 1;
				end
					
			default:
				if(bitCnt < 8) begin
					//need to start samp cnt if falling edge seen
					if(~BC4 && BC_filtered)
						samp_cnt_start = 1;
					shift = (sampCnt == startCnt);
					if(shift)
						rst_samp_cnt = 1;
					nxt_state = RCV;
				end
				else begin
					rst_bit_cnt = 1;
					rst_count_start = 1;
					rst_samp_cnt = 1;
					//if(ID[7] == 1'b0)
						set_ID_vld = 1;
				end
		endcase
	end
endmodule