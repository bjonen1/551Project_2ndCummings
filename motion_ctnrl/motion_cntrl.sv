module motion_cntrl(clk, rst_n, cnv_cmplt, go res, strt_cnv, IR_out_en, IR_mid_en, IR_in_en, lft, rht, chnnl);
	input clk, rst_n, cnv_cmplt;
	input [11:0] res;
	input go;
	
	output logic IR_out_en, IR_mid_en, IR_in_en;
	output reg [10:0] lft_reg, rht_reg;
	output reg [2:0] chnnl;
	output logic strt_cnv;
	
	wire [15:0] dst;
	
	reg [15:0] accum, pcomp;
	wire [13:0] pterm;
	reg [11:0] fwd;
	reg signed [11:0] error, intgrl, icomp;
	wire signed [11:0] iterm;
	logic [2:0] src1sel, src2sel;
	logic multiply, sub, mult2, mult4, saturate;
	
	typedef enum reg [3:0] {IDLE, MOD, CONV, CALC, CONV2, CALC1, CALC2, CALC3, CALC4, CALC5, CALC6, CALC7} state_t;
	state_t state, nxt_state;
	
	reg [2:0] chnnl_cnt;
	logic inc_chnnl_cnt;
	
	reg [11:0] timer_val;
	reg [11:0] timer_load;
	logic strt_timer, clr_timer, timer_done, load_timer;
	
	logic [2:0] IR_en;
	
	assign IR_in_en = IR_en[0];
	assign IR_mid_en = IR_en[1];
	assign IR_out_en = IR_en[2];
	
	assign IR_en = (chnnl_cnt == 0 || chnnl_cnt == 1) ? 3'b001:
				   (chnnl_cnt == 2 || chnnl_cnt == 3) ? 3'b010:
				   (chnnl_cnt == 4 || chnnl_cnt == 5) ? 3'b100;
	
	//define pterm, iterm
	assign pterm = 14'h3680;
	assign iterm = 12'h500;
	
	logic dst2accum, res2accum, dst2error, dst2intgrl, dest2icomp, dest2pcomp, dest2rht, dest2lft;
	
	//accum flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			accum <= 15'h0000;
		else if(res2accum)
			accum <= res;
		else if(dst2accum)
			accum <= dst;
	
	//error flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			error <= 12'h000;
		else if(dst2error)
			error <= dst[11:0];
	
	//Ingrl flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			intgrl <= 12'h000;
		else if (dst2ingrl)
			intgrl <= dst[11:0];
			
	//icomp flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			icomp <= 12'h000;
		else if (dst2icomp)
			icomp <= dst[11:0];
	
	//pcomp flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			pcomp <= 12'h000;
		else if(dst2pcomp)
			pcomp <= dst[11:0];
	
	//rht_reg flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rht_reg <= 11'h000;
		else if(dst2rht)
			rht_reg <= dst[10:0];
	
	//lft_reg flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			lft_reg <= 11'h000;
		else if(dst2rht)
			lft_reg <= dst[10:0];
			
	//channel count flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			chnnl_cnt <= 3'h0;
		else if(inc_chnnl_cnt)
			chnnl_cnt <= chnnl_cnt + 1;
		else if(clr_chnnl_cnt)
			chnnl_cnt <= 3'h0;
	
	//map chnnl_cnt to chnnl
	assign chnnl = (chnnl_cnt == 0) ? 3'b001 : 
				   (chnnl_cnt == 1) ? 3'b000 : 
				   (chnnl_cnt == 2) ? 3'b100 : 
				   (chnnl_cnt == 3) ? 3'b010 : 
				   (chnnl_cnt == 4) ? 3'b011 : 
				   (chnnl_cnt == 5) ? 3'b111 : chnnl_cnt;
	
	//timer
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			timer_cnt <= 12'h000;
		else if(clr_timer)
			timer_cnt <= 12'h000;
		else if(load_timer)
			timer_cnt <= timer_load;
		else if(strt_timer && !timer_done)
			timer_cnt <= timer_cnt - 1;
			
	assign timer_done = timer_cnt == 0;
	
	//state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	//next state logic
	always_comb begin
		dst2accum = 1'b0;
		res2accum = 1'b1;
		dst2error = 1'b0;
		dst2intgrl = 1'b0; 
		dest2icomp = 1'b0;
		dest2pcomp = 1'b0;
		dest2rht = 1'b0;
		dest2lft = 1'b0;
		

		src1sel = 3'h0;
		src2sel = 3'h0;
		multiply = 1'b0;
		sub = 1'b0;
		mult2 = 1'b0; 
		mult4 = 1'b0; 
		saturate = 1'b1;
		
		inc_chnnl_cnt = 1'b0;
		clr_chnnl_cnt = 1'b0;
		
		strt_timer = 1'b0;
		clr_timer = 1'b0;
		timer_done = 1'b0;
		load_timer = 1'b0;
		timer_load = 12'h000;
		
		strt_cnv = 1'b0;
		nxt_state = IDLE;
		
		case(state)
			IDLE:
				if(go) begin					
					timer_load = 12'd4095;
					load_timer = 1'b1;
					strt_timer = 1'b1;
					
					nxt_state = MOD;
				end
			MOD:
				if(timer_done) begin
					strt_cnv = 1'b1;
					nxt_state = CONV;
				else
					nxt_state = MOD;
			CONV:
				if(cnv_cmplt) begin
					clr_timer = 1'b1;
					case(chnnl)
						0: res2accum = 1'b1;
						2: begin
							dst2accum = 1'b1;
							src2sel = 3'b000;
							src1sel = 3'b000;
							mult2 = 1'b1;
						end
						4: begin
							dst2accum = 1'b1;
							src2sel = 3'b000;
							src1sel = 3'b000;
							mult4 = 1'b1;
						end
					endcase
					
					inc_chnnl_cnt = 1'b1;
					timer_load = 12'd31;
					load_timer = 1'b1;
					strt_timer = 1'b1;
					nxt_state = CALC;
				end
				else
					nxt_state = CONV;
			CALC:
				if(timer_done) begin
					strt_cnv = 1'b1;
					nxt_state = CONV2;
				end
				else
					nxt_state = CALC;
			CONV2:
				if(cnv_cmplt) begin
					clr_timer = 1'b1;
					case(chnnl)
						1: begin
							dst2accum = 1'b1;
							src2sel = 3'b000;
							src1sel = 3'b000;
							sub = 1'b1;
						end
						3: begin
							dst2accum = 1'b1;
							src2sel = 3'b000;
							src1sel = 3'b000;
							mult2 = 1'b1;
							sub = 1'b1;
						end
						5: begin
							dst2error = 1'b1;
							src2sel = 3'b000;
							src1sel = 3'b000;
							mult4 = 1'b1;
							sub = 1'b1;
						end
					endcase
					
					inc_chnnl_cnt = 1'b1;
					nxt_state = CALC1;
				end
				else
					nxt_state = CONV2;
			CALC1:
				if(chnnl == 6) begin
					dst2intgrl = 1'b1;
					src2sel = 3'b011;
					src1sel = 3'b001;
					nxt_state = CALC2;
				end
				else begin
					timer_load = 12'd4095;
					load_timer = 1'b1;
					strt_timer = 1'b1;
					
					nxt_state = MOD;
				end
			CALC2: begin
				dest2icomp = 1'b1;
				src2sel = 3'b001;
				src1sel = 3'b001;
				multiply = 1'b1;
				
				nxt_state = CALC3;
			end
			CALC3: begin
				dest2pcomp = 1'b1;
				src2sel = 3'b010;
				src1sel = 3'b100;
				multiply = 1'b1;
				
				nxt_state = CALC4;
			end
			CALC4: begin
				dest2accum = 1'b1;
				src2sel = 3'b100;
				src1sel = 3'b011;
				sub = 1'b1;
				
				nxt_state = CALC5;
			end
			CALC5: begin
				dst2rht = 1'b1;
				src2sel = 3'b000;
				src1sel = 3'b010;
				sub = 1'b1;
				
				nxt_state = CALC6;
			end
			CALC6: begin
				dest2accum = 1'b1;
				src2sel = 3'b100;
				src1sel = 3'b011;
				
				nxt_state = CALC7;
			end
			default: begin //CALC7
				dest2lft = 1'b1;
				src2sel = 3'b000;
				src1sel = 3'b010;
			end
		endcase
	end
endmodule