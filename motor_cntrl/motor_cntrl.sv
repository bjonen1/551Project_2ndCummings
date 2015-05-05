//`include "pwm10bit.v"
module motor_cntrl(clk, rst_n, rht, lft, fwd_rht, fwd_lft, rev_rht, rev_lft);
	input clk, rst_n;
	input [10:0] rht, lft;
	
	output fwd_rht, fwd_lft, rev_rht, rev_lft;
	
	wire pwmOutL,pwmOutR;
	
	//left motor
	pwm10bit pwmL(.clk(clk), .rst_n(rst_n), .duty(lft[9:0]), .PWM_sig(pwmOutL));
	
	assign fwd_lft = ~rst_n ? 0 : (lft[9:0] == 0) ? 1 :
					 (lft[10]) ? 0 : pwmOutL;
	assign rev_lft = ~rst_n ? 0 : (lft[9:0] == 0) ? 1 :
					 (lft[10]) ? pwmOutL : 0;
	
	//right motor
	pwm10bit pwmR(.clk(clk), .rst_n(rst_n), .duty(rht[9:0]), .PWM_sig(pwmOutR));
	
	assign fwd_rht = ~rst_n ? 0 : (rht[9:0] == 0) ? 1 :
					 (rht[10]) ? 0 : pwmOutR;
	assign rev_rht = ~rst_n ? 0 : (rht[9:0] == 0) ? 1 :
					 (rht[10]) ? pwmOutR : 0;
	
	
endmodule

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

module cnt10bit(clk, rst_n, cnt);
	input clk, rst_n;
	output reg [9:0] cnt;
	
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			cnt <= 10'h000;
		else
			cnt <= cnt + 1;
endmodule