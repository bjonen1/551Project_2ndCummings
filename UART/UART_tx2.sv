module uart_tx(clk,rst_n,strt_tx,tx_data,tx_done,tx);

	input clk, rst_n, strt_tx;
	input [7:0] tx_data;
	output tx;
	output reg tx_done;
	
	logic set_done, clr_done, load, transmitting, shift;
	logic [3:0] bit_count;

	//output flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_done <= 1'b0;
		else
			if(set_done)
				tx_done <= 1'b1;
			else if(clr_done)
				tx_done <= 1'b0;
	end

	UART_SM sm(.clk(clk), .rst_n(rst_n), .trmt(strt_tx), .bit_count(bit_count), .shift(shift), .load(load), .transmitting(transmitting), .set_done(set_done), .clr_done(clr_done));
	
	UART_DP dp(.clk(clk), .rst_n(rst_n), .tx_data(tx_data), .tx_done(tx_done), .load(load), .transmitting(transmitting), .bit_count(bit_count), .shift(shift), .TX(tx));
endmodule

module UART_SM(clk, rst_n, trmt, bit_count, shift, load, transmitting, set_done, clr_done);

	input clk, rst_n, trmt, shift;
	input [3:0] bit_count;
	
	output logic load, transmitting, set_done, clr_done;
	
	typedef enum reg [1:0] {LOAD, TRANS} state_t;
	
	state_t state, nxt_state;
	
	//state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= LOAD;
		else
			state <= nxt_state;
	
	//next state and output logic
	always_comb begin
		load = 0;
		transmitting = 0;
		set_done = 0;
		clr_done = 0;
		nxt_state = LOAD;
		
		case(state)
			LOAD: begin
				if(trmt) begin
					load = 1;
					clr_done = 1;
					nxt_state = TRANS;
				end
			end
			default: begin
				transmitting = 1;
				if(bit_count == 10) begin
					set_done = 1;
					nxt_state = LOAD;
				end
				else
					nxt_state = TRANS;
			end
		endcase
	end

endmodule

module UART_DP(clk, rst_n, tx_data, tx_done, load, transmitting, bit_count, shift, TX);

	input clk, rst_n, load, transmitting, tx_done;
	input [7:0] tx_data;
	
	output reg [3:0] bit_count;
	output shift, TX;
	
	reg [11:0] baud_cnt;
	reg [9:0] tx_shft_reg;
	
	//bit counter
	always @(posedge clk)
		if(load)
			bit_count <= 3'h0;
		else if(bit_count > 10)
			bit_count <= 3'h0;
		else if(shift)
			bit_count <= bit_count + 1;
	
	//baud counter
	always @(posedge clk)
		if(load)
			baud_cnt <= 12'h000;
		else if(baud_cnt == 12'd2604)
			baud_cnt <= 12'h000;
		else if(transmitting)
			baud_cnt <= baud_cnt + 1;
			
	assign shift = (baud_cnt == 12'd2604) ? 1'b1: 1'b0;
	
	//TX flop
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			tx_shft_reg <= 10'h111;
		else if (load)
			tx_shft_reg <= {1'b1, tx_data, 1'b0};
		else if ((bit_count < 9) && shift)
			tx_shft_reg <= tx_shft_reg >> 1;
			
	assign TX = tx_shft_reg[0];

endmodule