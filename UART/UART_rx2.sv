module uart_rcv(clk, rst_n, clr_rx_rdy, RX, rx_rdy, rx_data);
	input clk, rst_n, clr_rx_rdy, RX;
	output reg rx_rdy;
	output reg [7:0] rx_data;
	
	logic started, shift, set_rdy, wait_for_start, receiving;
	reg [9:0] data;
	reg [12:0] baud_count;
	reg [3:0] bit_count;
	reg rx_flopped, q1;
	
	typedef enum reg [1:0] {IDLE, RCV, DONE} state_t;
	
	state_t state, nxt_state;
	
	//double flop rx
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			q1 <= 1'b0;
			rx_flopped <= 1'b0;
		end
		else begin
			q1 <= RX;
			rx_flopped <= q1;
		end
			
	//data flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			data <= 0;
		else if(rx_rdy)
			data <= data;
		else if(shift)
			data <= {rx_flopped, data[9:1]};
			
	assign rx_data = data[8:1];
	
	//ready flop
	always_ff @(posedge clk, posedge clr_rx_rdy)
		if(clr_rx_rdy)
			rx_rdy <= 1'b0;
		else if(set_rdy)
			rx_rdy <= 1'b1;
			
	//baud counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			baud_count <= 10'h000;
		else if(clr_rx_rdy)
			baud_count <= 10'h000;
		else if(wait_for_start && baud_count == 12'd1302)
			baud_count <= 10'h000;
		else if(baud_count == 12'd2604)
			baud_count <= 10'h000;
		else if(receiving)
			baud_count <= baud_count + 1;
			
	assign shift = wait_for_start ? ((baud_count == 12'd1302) ? 1'b1 : 1'b0):
									((baud_count == 12'd2604) ? 1'b1: 1'b0);
									
	//bit counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			bit_count <= 3'h0;
		else if(clr_rx_rdy)
			bit_count <= 3'h0;
		else if(bit_count == 4'hB)
			bit_count <= 3'h0;
		else if(shift)
			bit_count <= bit_count + 1;
			
	//state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	//next state and output logic
	always_comb begin
		set_rdy = 0;
		wait_for_start = 0;
		receiving = 0;
		nxt_state = IDLE;
		
		case(state)
			IDLE: begin
				wait_for_start = 1;
				if(rx_flopped && ~q1)
					nxt_state = RCV;
			end
			RCV: begin
				receiving = 1;
				if(bit_count == 0)
					wait_for_start = 1;
				if(bit_count == 10) begin
					set_rdy = 1;
					nxt_state = DONE;
				end
				else
					nxt_state = RCV;
			end
			default: begin
				if(clr_rx_rdy)
					nxt_state = IDLE;
				else
					nxt_state = DONE;
			end
		endcase
	end
endmodule
