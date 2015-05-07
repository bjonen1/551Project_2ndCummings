module duty_finder(clk, rst_n, pwm, duty, rdy);
	input clk, rst_n, pwm;
	output reg [9:0] duty;
	output reg rdy;
	
	logic set_duty, inc_high_time, reset_high_time;
	
	reg pwm_f;
	reg [9:0] high_time;
	
	//flop for edge detection of pwm
	always_ff @(posedge clk)
		pwm_f <= pwm;
		
	//ready flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rdy <= 1'b0;
		else if(reset_high_time)
			rdy <= 1'b0;
		else if(set_duty)
			rdy <= 1'b1;
			
	//counter for time spent high
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			high_time <= 10'h000;
		else if(reset_high_time)
			high_time <= 10'h000;
		else if(inc_high_time)
			high_time <= high_time + 1;
			
	//flop for duty
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			duty <= 10'h000;
		else if(set_duty)
			duty <= high_time;
	
	always_comb begin
		reset_high_time = 1'b0;
		set_duty = 1'b0;
		inc_high_time = 1'b0;
		
		if (((pwm == 0) && (pwm_f == 0)))
			reset_high_time = 1'b1;
		else if ((pwm_f == 1) && (pwm == 0)) 
			set_duty = 1'b1;
		else
			inc_high_time = 1'b1;
	end
	
endmodule