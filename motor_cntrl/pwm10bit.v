module pwm10bit(clk, rst_n, duty, PWM_sig);
	input clk, rst_n;
	input [9:0] duty;
	
	output reg PWM_sig;
	
	wire [9:0] cnt;
	reg d;
	
	cnt10bit cntr(.clk(clk), .rst_n(rst_n), .cnt(cnt));
	
	//assign d = &cnt | (~(duty==cnt) & PWM_sig);
	always @(*) begin
		if(duty > cnt)
			d = 1'b1;
		else
			d = 1'b0;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			PWM_sig <= 1'b0;
		else
			PWM_sig <= d;
	end
endmodule